package statecharts;

using StringTools;

//
@:structInit
class Guard {
    public var name:String = "";
    public var satisfied:Transition->Bool = (_t:Transition) -> false;
}

//
class Transition {
    public var on_taken:Signal<Transition->Void> = new Signal();

    public var from:State = null;
    public var to:State;
    public var event:String = null;
    public var guard:Guard = null;
    public var delaySecs:Float = 0.0;

    public function new() {}

    public function hasEvent():Bool return this.event != null && this.event.length > 0;
    
    public function evaluateGuard():Bool {
        if (this.guard == null) return true;
        if (this.from == null) return false;
        return this.guard.satisfied(this);
    }

    public function getId():String {
        var id:String = '${from.name}_${to.name}( ${event != null ? event : "* always"} )';
        if (guard != null)
            id += '[ ${guard.name} ]';
        return id;
    }

    public function getLabel():String {
        var label:String = event != null ? 'on "$event"' : '* always';
        if (guard != null)
            label += '\n${guard.name.replace("(_t) -> ", "")}';
        return label;
    }
}

//
class State {
    public var on_state_entered:Signal<Void->Void> = new Signal();
    public var on_state_exited:Signal<Void->Void> = new Signal();
    public var on_state_stepped:Signal<Void->Void> = new Signal();
    
    public var on_event_received:Signal<String->Void> = new Signal();
    
    public var on_transition_pending:Signal<Float->Float->Void> = new Signal();

    public var on_state_processing:Signal<Float->Void> = new Signal();
    
    public var active = false;
    public var name:String = null;

    public var transitions:Array<Transition> = [];
    var pendingTransition:Transition = null;
    var pendingTransitionTime:Float = 0;

    var chart:StateChart;

    var parent:State = null;
    public var children:Array<State> = [];

    public function new(_name:String) {
        this.name = _name;
    }

    public function add(_s:State) {
        children.remove(_s);
        children.push(_s);
        _s.parent = this;
    }
    
    public function remove(_s:State) {
        if (children.remove(_s))
            _s.parent = null;
    }

    public function init(_sc:StateChart) {
        chart = _sc;
        for (t in transitions) {
            t.from = this; 
            if (!t.hasEvent()) // register automatic transition
                chart.registerAutomaticTransition(t);
        }
    }

    public function shutdown() {
        on_state_entered.clear();
        on_state_exited.clear();
        on_state_stepped.clear();
        on_event_received.clear();
        on_transition_pending.clear();
        on_state_processing.clear();
    }

    public function enter(?_expectTransition = false) {
        active = true;
        on_state_entered.emit();
        for (t in transitions)
            if (!t.hasEvent() && t.evaluateGuard()) {
                runTransition(t);
                break;
            }
    }

    public function exit() {
        pendingTransition = null;
        pendingTransitionTime = 0;
        active = false;
        on_state_exited.emit();
    }

    public function step() {
        on_state_stepped.emit();
    }

    public function process(_dt:Float) {
        on_state_processing.emit(_dt);

        if (pendingTransition != null) {
            pendingTransitionTime -= _dt;
            on_transition_pending.emit(pendingTransition.delaySecs, pendingTransitionTime > 0.0 ? pendingTransitionTime : 0.0);

            if (pendingTransitionTime <= 0) {
                var tmp = pendingTransition;
                pendingTransition = null;
                pendingTransitionTime = 0;
                chart.runTransition(tmp);
            }
        }
    }

    public function event(_evt:String):Bool {
        if (!active) return false;

        on_event_received.emit(_evt);

        for (t in transitions)
            if (t.event == _evt && t.evaluateGuard()) {
                runTransition(t);
                return true;
            }

        return false;
    }

    public function handleTransition(_t:Transition) {} // override

    public function runTransition(_t:Transition) {
        if (_t.delaySecs > 0.0)
            queueTransition(_t);
        else
            chart.runTransition(_t);
    }

    function queueTransition(_t:Transition) {
        if (pendingTransition == null) {
            pendingTransition = _t;
            pendingTransitionTime = _t.delaySecs;
        }
    }
}

//
class StateChart {

    @nostore public static var chartTypes = new Map<String, StateChart>();
    @nostore public static var chartInstances = new Array<StateChart>();

    public var on_event_received:Signal<String->Void> = new Signal();

    var instanceName:String;
    var root:State = null;

    var queuedEvents:Array<String> = [];
    var eventProcessingActive = false;

    var queuedTransitions:Array<Transition> = [];
    var transitionProcessingActive = false;

    var automaticTransitions:Array<Transition> = [];

    public function new(_instanceName:String) {
        instanceName = _instanceName;
    }

    public function addRoot(_s:State) {
        root = _s;
    }

    public function getRoot():State return root;
    public function getInstanceName():String return instanceName;

    public function init() {
        // this chart is built and now register its type and instance
        chartTypes.set(root.name, this);
        chartInstances.remove(this);
        chartInstances.push(this);

        root.init(this);
        root.enter();
    }

    public function shutdown() {
        // find all active children and exit them in reverse order!
        if (root.active) {
            var toExit = [];
            var open = [root];
            while (open.length > 0) {
                var cur = open.pop();
                toExit.push(cur);
                for (c in cur.children)
                    if (c.active)
                        open.push(c);
            }
            toExit.reverse();
            for (s in toExit) {
                s.exit();
                s.shutdown();
            }
        }

        // clear instance tracker
        chartInstances.remove(this);
        chartTypes.remove(root.name);

        // clear, finally
        queuedEvents = null;
        queuedTransitions = null;
        automaticTransitions = null;

        on_event_received.clear();
    }

    public function registerAutomaticTransition(_t:Transition) {
        automaticTransitions.remove(_t);
        automaticTransitions.push(_t);
    }

    // update functions
    public function step() {
        root.step();
    }

    public function process(_dt:Float) {
        for (t in automaticTransitions) {
            if (t.from.active && t.evaluateGuard())
                t.from.runTransition(t);
        }
        
        var open = [root];
        while (open.length > 0) {
            var cur = open.shift();
            if (cur.active/* && cur.on_state_processing.listeners.length > 0*/)
                cur.process(_dt);
            open = open.concat(cur.children);
        }
    }

    // event & transition handling
    public function sendEvent(_evt:String) {
        if (eventProcessingActive) {
            queuedEvents.push(_evt);
            return;
        }

        eventProcessingActive = true;
        
        on_event_received.emit(_evt);
        root.event(_evt);

        while (queuedEvents.length > 0) {
            var next = queuedEvents.shift();
            on_event_received.emit(next);
            root.event(next);
        }

        eventProcessingActive = false;
    }

    public function runTransition(_t:Transition) {
        if (transitionProcessingActive) {
            queuedTransitions.push(_t);
            return;
        }

        transitionProcessingActive = true;
        
        _doRunTransition(_t);

        while (queuedTransitions.length > 0) {
            var next = queuedTransitions.shift();
            _doRunTransition(next);
        }

        transitionProcessingActive = false;
    }

    function _doRunTransition(_t:Transition) {
        if (_t.from.active) {
            _t.on_taken.emit(_t);
            _t.from.handleTransition(_t);
        } else 
            trace('Ignoring request for transitioning from ${_t.from.name} to ${_t.to.name} as the source state is no longer active. Check whether your trigger multiple state changes within a single frame.');
    }
}


