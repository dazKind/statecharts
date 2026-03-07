package statecharts;

import statecharts.Types;

class CompoundState extends State {
    public var on_child_state_entered = new Signal<Void->Void>();
    public var on_child_state_exited = new Signal<Void->Void>();

    public var initialState:State = null;
    public var activeState:State = null;

    override public function init(_sc:StateChart) {
        super.init(_sc);

        for (c in children) {
            c.parent = this;
            c.init(_sc);
            c.on_state_entered.connect(() -> on_child_state_entered.emit());
            c.on_state_exited.connect(() -> on_child_state_exited.emit());
        }
    }

    override public function enter(?_expectTransition = false) {
        super.enter(_expectTransition);

        if (!_expectTransition) {
            if (initialState != null) {
                activeState = initialState;
                activeState.enter(_expectTransition);
            } else 
                trace('[CompoundState::enter] No initial state set for $name!!!');
        }
    }

    override public function exit() {
        if (activeState != null) {
            activeState.exit();
            activeState = null;
        }

        super.exit();
    }

    override public function shutdown() {
        on_child_state_entered.clear();
        on_child_state_exited.clear();
        super.shutdown();
    }

    override public function step() {
        super.step();
        if (activeState != null)
            activeState.step();
    }

    override public function event(_evt:String):Bool {
        if (!active) return false;

        on_event_received.emit(_evt);

        // depth-first: let active child handle it first
        if (activeState != null && activeState.event(_evt))
            return true;

        // otherwise check own transitions
        for (t in transitions)
            if (t.event == _evt && t.evaluateGuard()) {
                runTransition(t);
                return true;
            }

        return false;
    }

    override public function handleTransition(_t:Transition) {
        // Self-transition
        if (_t.to == this) {
            if (_t.type == Internal) {
                // local self-transition: don't exit/enter this state, just reset to initial child
                if (activeState != null)
                    activeState.exit();
                if (initialState != null) {
                    activeState = initialState;
                    activeState.enter(false);
                }
            } else {
                // external self-transition: full exit and re-enter
                exit();
                enter(false);
            }
            return;
        }

        // Target is a direct child
        if (children.indexOf(_t.to) > -1) {
            if (activeState != null)
                activeState.exit();

            activeState = _t.to;
            activeState.enter(false);
            return;
        }

        // Target is a deeper descendant — walk up from target to find which
        // direct child is an ancestor of the target
        var next = _t.to;
        var previous = null;
        while (next != null) {
            if (next == this) { // we are an ancestor, previous holds the direct child
                if (activeState != previous) {
                    if (activeState != null)
                        activeState.exit();
                    activeState = previous;
                    activeState.enter(true);
                }
                previous.handleTransition(_t);
                return;
            }
            previous = next;
            next = next.parent;
        }

        // Target is outside this subtree — delegate to parent
        this.parent.handleTransition(_t);
    }
}
