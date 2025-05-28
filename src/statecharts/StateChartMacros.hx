package statecharts;

import haxe.macro.Expr;
import haxe.macro.Context;

using haxe.macro.ExprTools;
using StringTools;

class StateChartMacros {
    macro public static function createChartFromXml( ethis : Expr, args:Array<Expr> ) {
        var xml:Xml = Xml.parse(args[0].getValue());
        var states = [];
        var hierarchy = [];
        var transitions = [];
        var signals = [];

        var open:Array<Xml> = [xml.firstElement()];
        while (open.length > 0) {
            var cur = open.shift();

            var classNameTokens = cur.nodeName.split(".");
            var typePath:TypePath = {
                sub: null,
                params: [],
                name: classNameTokens.pop(),
                pack: classNameTokens
            };

            // todo: check if this is a valid type

            var vname = cur.get('name');
            var external = cur.get('external');
            if (external != null)
                states.push( macro $i{vname} = new $typePath($v{vname}) );
            else
                states.push( macro var $vname = new $typePath($v{vname}) );


            switch (typePath.name) {
                case 'CompoundState': {
                    if (cur.get('initial') != null) {
                        // make sure our initial is a child of this state
                        var initialName = cur.get('initial');
                        var hasValidInitial = false;
                        for (c in cur.elements()) {
                            if (c.get('name') == initialName) {
                                hasValidInitial = true;
                                break;
                            }
                        }
                        if (hasValidInitial)
                            hierarchy.push(macro $i{vname}.initialState = $i{initialName});
                        else
                            Context.fatalError('${typePath.name}.${vname} has a non-existant initial state "${initialName}"', Context.currentPos());
                    }
                }
            }

            if (cur.parent != null && cur.parent.nodeType == Xml.XmlType.Element)
                hierarchy.push(macro $i{cur.parent.get('name')}.add($i{vname}) );
            else if (cur.parent.nodeType == Xml.XmlType.Document) {
                hierarchy.push(macro __sc.addRoot($i{vname}));
            }

            var trs = [];
            for (c in cur.elements()) {
                if (c.nodeName.startsWith("on_")) {
                    var sname = c.nodeName;
                    signals.push(Context.parse('$vname.$sname.connect(${c.get("fn")})', Context.currentPos()));
                }
                else if (c.nodeName == "Transition") {
                    var taken = macro null;
                    var tr_signals = c.elements();
                    for (t in tr_signals) {
                        switch (t.nodeName) {
                            case 'on_taken': {
                                var fn = Context.parse(t.get('fn'), Context.currentPos());
                                taken = macro tr.on_taken.connect(${fn});
                            }
                        }
                    }

                    var delay = macro null;
                    if (c.get('delaySecs') != null) {
                        delay = Context.parse('tr.delaySecs = ${c.get('delaySecs')}', Context.currentPos());
                    }

                    var guard = macro null;
                    if (c.get('guard') != null) {
                        var v = c.get('guard');
                        guard = Context.parse('{name:"$v", satisfied:$v}', Context.currentPos());
                    }
                    
                    var event = macro null;
                    if (c.get('event') != null)
                        event = macro $v{c.get('event')};

                    var tr = macro {
                        var tr = new Transition();
                        tr.to = $i{c.get('to')};
                        tr.guard = $guard;
                        tr.event = $event;
                        $taken;
                        $delay;
                        $i{vname}.transitions.push(tr);
                    };

                    transitions.push(macro ${tr});
                }
                else
                    open.push(c);
            }
        }

        return macro {
            var __sc = new StateChart($ethis);
            $b{states.concat(hierarchy.concat(transitions.concat(signals)))};
            __sc;
        };
    }
}