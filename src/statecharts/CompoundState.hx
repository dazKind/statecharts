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

    override public function step() {
        super.step();
        if (activeState != null)
            activeState.step();
    }

    override public function event(_evt:String):Bool {
        if (!active) return false;

        if (activeState != null && activeState.event(_evt)) {
            on_event_received.emit(_evt);
            return true;
        }

        return super.event(_evt);
    }

    override public function handleTransition(_t:Transition) {
        if (_t.to == this) {
            exit();
            enter(false);
            return;
        }

        if (children.indexOf(_t.to) > -1) {
            if (activeState != null)
                activeState.exit();

            activeState = _t.to;
            activeState.enter(false);
            return;
        }

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

        this.parent.handleTransition(_t);
    }
}