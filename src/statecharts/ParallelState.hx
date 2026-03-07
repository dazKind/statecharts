package statecharts;

import statecharts.Types;

class ParallelState extends State {
    override public function init(_sc:StateChart) {
        super.init(_sc);

        for (c in children) {
            c.parent = this;
            c.init(_sc);
        }
    }

    override public function enter(?_expectTransition = false) {
        super.enter(_expectTransition);
        for (c in children)
            c.enter(false);
    }

    override public function exit() {
        for (c in children)
            c.exit();
        super.exit();
    }

    override public function step() {
        super.step();
        for (c in children)
            c.step();
    }

    override public function event(_evt:String):Bool {
        if (!active) return false;

        on_event_received.emit(_evt);

        // broadcast to all children — each region processes independently
        var handled = 0;
        for (c in children) 
            handled += c.event(_evt) ? 1 : 0;

        if (handled > 0)
            return true;

        // no child handled it, check own transitions
        for (t in transitions)
            if (t.event == _evt && t.evaluateGuard()) {
                runTransition(t);
                return true;
            }

        return false;
    }

    // Note on transition conflicts: when multiple children of a parallel state
    // independently handle the same event and attempt transitions that leave
    // this parallel state, the transition queuing mechanism in StateChart
    // serializes them (the first fires, subsequent ones are skipped because
    // the source state is no longer active). There is no priority-based
    // conflict resolution as defined in SCXML (document-order priority).
    // This is acceptable for game-oriented use cases where parallel regions
    // are typically orthogonal (movement + animation, etc.).

    override public function handleTransition(_t:Transition) {
        if (_t.to == this) {
            exit();
            enter(false);
            return;
        }

        if (children.indexOf(_t.to) > -1) return;

        var next = _t.to;
        var previous = null;
        while (next != null) {
            if (next == this) { // we are an ancestor, previous holds the direct child we need to fwd the transition to
                previous.handleTransition(_t);
                return;
            }
            previous = next;
            next = next.parent;
        }

        this.parent.handleTransition(_t);
    }
}
