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

        var handled = 0;
        for (c in children) 
            handled += c.event(_evt) ? 1 : 0;

        if (handled > 0) {
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