package statecharts;

import statecharts.Types;

// TODO: does this work alright?
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
        on_state_entered.emit();
        if (lastState == null) {
            var tr = new Transition();
            tr.from = this;
            tr.to = lastState;
            runTransition(tr);
        }
        else
            for (t in transitions)
                if (!t.hasEvent() && t.evaluateGuard()) {
                    runTransition(t);
                    break;
                }
    }

    function _storeLastState() {
        for (c in this.parent.children) {
            if (c == this) continue;
            if (c.active) {
                lastState = c;
                break;
            }
        }
    }
}
