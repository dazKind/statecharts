package statecharts;

import statecharts.Types;

class AtomicState extends State {
    override public function handleTransition(_t:Transition) {
        this.parent.handleTransition(_t);
    }
}