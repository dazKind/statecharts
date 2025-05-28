package statecharts;

import haxe.macro.Expr;

class Signal<T>
{
    public var listeners:Array<T>;

    public function new() {
        listeners = [];
    }

    public function connect(_cb:T):Void {
        for (l in listeners)
            if (l == _cb) return;
        listeners.push(_cb);
    }

    public function disconnect(_cb:T):Void {
        for (l in listeners)
            if (l == _cb) {
                listeners.remove(l);
                return;
            }
    }

    public function clear():Void {
        listeners = [];
    }

    public function has(_cb:T):Bool {
        var found:Bool = false;
        for (l in listeners)
            if (l == _cb) {
                found = true;
                break;
            }
        return found;
    }

    macro inline public function emit( ethis : Expr, args:Array<Expr> ) {
        return macro {
            for (l in $ethis.listeners) {
                l($a{args});
            }
        }
    }
}