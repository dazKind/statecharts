package statecharts;

import statecharts.Types;

// A final state designates that its parent compound state has completed.
// When entered, it sets the parent's completed flag and generates a
// "done.state.<parentName>" event so other parts of the chart can react.
// Final states do not process events or outgoing transitions.
class FinalState extends State {

    override public function enter(?_expectTransition = false) {
        active = true;
        on_state_entered.emit();

        // mark parent as completed and raise the done event
        if (parent != null) {
            parent.completed = true;
            chart.sendEvent('done.state.${parent.name}');
        }
    }

    override public function event(_evt:String):Bool {
        // final states do not process events
        return false;
    }

    override public function handleTransition(_t:Transition) {
        // final states have no outgoing transitions;
        // delegate to parent so the done event can drive transitions there
        if (this.parent != null)
            this.parent.handleTransition(_t);
    }
}
