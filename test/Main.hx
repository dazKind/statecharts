import statecharts.Types;

import statecharts.Types;
import statecharts.*;

using statecharts.StateChartMacros;

class Main {
    public static function main() {

        var sm:StateChart = null;

        sm = "testSimpleSequence".createChartFromXml(
            <CompoundState name="DemoState" initial="Screen05">

                <AtomicState name="Screen01">
                    <Transition to="Screen02" event="next" delaySecs="1"/>

                    <on_state_entered fn="()->{ trace('Screen01 entered'); sm.sendEvent('next'); }" />
                </AtomicState>

                <AtomicState name="Screen02">
                    <Transition to="Screen03" event="next" delaySecs="1"/>

                    <on_state_entered fn="()->{ trace('Screen02 entered'); sm.sendEvent('next'); }" />
                </AtomicState>

                <AtomicState name="Screen03">
                    <Transition to="Screen04" event="next" delaySecs="1"/>

                    <on_state_entered fn="()->{ trace('Screen03 entered'); sm.sendEvent('next'); }" />
                </AtomicState>

                <AtomicState name="Screen04">
                    <Transition to="Screen05" event="next" delaySecs="1"/>

                    <on_state_entered fn="()->{ trace('Screen04 entered'); sm.sendEvent('next'); }" />
                </AtomicState>

                <AtomicState name="Screen05">
                    <Transition to="Screen01" event="next" delaySecs="1"/>

                    <on_state_entered fn="()->{ trace('Screen05 entered'); sm.sendEvent('next'); }" />
                </AtomicState>

            </CompoundState>
        );

        sm.init();

        final delta =0.1666;
        while (true) {
            sm.process(delta);
            Sys.sleep(delta);
        }
    }
}