package statecharts;

import statecharts.Types;

class HistoryState extends State {
    
    var hasDeepHistory = false;
    var lastState:State = null;

    public function new(_name:String, _deep:Bool) {
        super(_name);
        hasDeepHistory = _deep;
    }

    override public function init(_sc:StateChart) {
        super.init(_sc);
        this.parent.on_state_exited.connect(_storeLastState);
    }

    override public function enter(?_expectTransition = false) {
        active = true;
        on_state_entered.emit();

        if (lastState != null) {
            // history exists: transition to the remembered state
            var tr = new Transition();
            tr.from = this;
            tr.to = lastState;
            runTransition(tr);
        } else {
            // no history yet: follow default (eventless) transitions
            for (t in transitions)
                if (!t.hasEvent() && t.evaluateGuard()) {
                    runTransition(t);
                    break;
                }
        }
    }

    function _storeLastState() {
        for (c in this.parent.children) {
            if (c == this) continue;
            if (c.active) {
                if (hasDeepHistory)
                    lastState = _findDeepestActive(c);
                else
                    lastState = c;
                break;
            }
        }
    }

    // Walk down the active child chain to find the deepest active leaf state.
    // For compound states this follows the single active child.
    // For parallel states, deep history stores the parallel state itself
    // (restoring it will re-enter all its regions from their initial states;
    //  full parallel configuration recall is not yet supported).
    function _findDeepestActive(_state:State):State {
        if (Std.isOfType(_state, CompoundState)) {
            var cs:CompoundState = cast _state;
            if (cs.activeState != null)
                return _findDeepestActive(cs.activeState);
        }
        return _state;
    }
}
