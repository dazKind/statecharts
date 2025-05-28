// This doesnt compile, but is a list of different charts that I use in different projects that can serve as reference on how to use different statechart features - daz


class Samples {
    function squashPlayer() {
        // a player controller with movement(ground, falling, jumping) and status effects (idle, boost - jumped on an enemy, it plays an animation, hurting - received damage)
        state = "player".createChartFromXml(
            <ParallelState name="ingame">

                <CompoundState name="movement" initial="grounded">
                    <AtomicState name="grounded">
                        <Transition to="jumping" event="jump" guard="this._checkGround" />
                        <Transition to="falling" event="fall" />

                        <on_state_processing fn="this._grounded" />
                    </AtomicState>

                    <AtomicState name="jumping">
                        <Transition to="falling" event="fall" />

                        <on_state_entered fn="this._enter_jumping" />
                        <on_state_processing fn="this._jumping" />
                    </AtomicState>

                    <AtomicState name="falling">
                        <Transition to="grounded" guard="this._checkGround" />

                        <on_state_processing fn="this._falling" />
                    </AtomicState>
                </CompoundState>

                <CompoundState name="body" initial="idle">
                    <AtomicState name="idle">
                        <Transition to="hurting" event="collision" />
                        <Transition to="boost" event="boost" />

                        <!--<on_state_entered fn="()->trace('idle')" />-->
                    </AtomicState>

                    <AtomicState name="boost">
                        <Transition to="idle" guard="(_)->anim.state('boost').stopped" />
                        <Transition to="hurting" event="collision" />
                        <Transition to="boost" event="boost" />

                        <on_state_entered fn="this._boostStart" />
                        <on_state_exited fn="this._boostStop" />
                        <on_state_processing fn="this._boostProcessing" />
                    </AtomicState>

                    <AtomicState name="hurting">
                        <Transition to="idle" delaySecs="1" />
                        <Transition to="boost" event="boost" />

                        <on_state_entered fn="this._hurtStart" />
                        <on_state_exited fn="this._hurtStop" />
                        <on_state_processing fn="this._hurtProcessing" />
                    </AtomicState>
                </CompoundState>

            </ParallelState>
        );
    }

    function cortexResourceContext() {
        // A statechart controlling (un-)loading, reloading and dependencies of Resources/Assets in cortex
        sc = StateChartMacros.createChartFromXml(_id,
            <CompoundState name="ResourceContext" initial="unloaded">

                <AtomicState name="unloaded">
                    <Transition to="loading" guard="this._should_reload" />
                    <Transition to="loading" event="load" />

                    <on_state_entered fn="this._enter_unload" />
                    <on_state_exited fn="this._exit_unload" />
                </AtomicState>

                <AtomicState name="loading">
                    <Transition to="loading_dependencies" event="load_complete" guard="this._has_dependencies" />
                    <Transition to="loaded" event="load_complete" guard="this._has_no_dependencies" />
                    <Transition to="unloaded" event="load_error" />
                    <Transition to="unloaded" event="unload" />

                    <on_state_entered fn="this._enter_loading" />
                </AtomicState>

                <AtomicState name="loading_dependencies">
                    <Transition to="unloaded" event="reload">
                        <on_taken fn="this._unloading_for_reload" />
                    </Transition>
                    <Transition to="loaded" guard="this._all_deps_loaded" />

                    <on_state_entered fn="this._enter_loading_dependencies" />
                </AtomicState>

                <AtomicState name="loaded">
                    <Transition to="loading_dependencies" event="reload_dependencies">
                        <on_taken fn="this._reload_dependencies" />
                    </Transition>
                    <Transition to="unloaded" event="reload">
                        <on_taken fn="this._unloading_for_reload" />
                    </Transition>
                    <Transition to="unloaded" event="unload">
                        <on_taken fn="this._unloading" />
                    </Transition>

                    <on_state_entered fn="this._enter_loaded" />
                </AtomicState>

            </CompoundState>
        );
    }

    function simpleDoor() {
        // a simple door that reacts to trigger and collision events
        sc = StateChartMacros.createChartFromXml(this.get_name(),

            <CompoundState name="doorController" initial="closed">

                <AtomicState name="closed">
                    <Transition to="opening" event="trigger" />

                    <on_state_entered fn="() -> sfxDoorClosing.play()" />
                    <on_state_exited fn="() -> { sfxDoorOpening.play(); this.shouldOpen = true; }" />
                </AtomicState>

                <AtomicState name="opening">
                    <Transition to="open" guard="(_t) -> this.isOpenBlocked || door.rotation_degrees.y >= 90.0" />
                    <Transition to="open" event="trigger" />
                    <Transition to="blocked" event="collision" />

                    <on_state_physics_processing fn="this._opening" />
                </AtomicState>

                <AtomicState name="open">
                    <Transition to="closing" event="trigger" guard="(_t) -> this.shouldOpen == false" />
                    <Transition to="opening" event="trigger" guard="(_t) -> this.shouldOpen == true" />

                    <on_state_entered fn="() -> {
                        this.shouldOpen = !this.shouldOpen;
                        sfxDoorBlocked.play();
                    }" />
                </AtomicState>

                <AtomicState name="blocked">
                    <Transition to="closing" event="trigger" guard="(_t) -> this.shouldOpen == false" />
                    <Transition to="opening" event="trigger" guard="(_t) -> this.shouldOpen == true" />

                    <on_state_entered fn="() -> {
                        this.shouldOpen = !this.shouldOpen;
                        sfxDoorBlocked.play();
                    }" />
                </AtomicState>

                <AtomicState name="closing">
                    <Transition to="closed" guard="(_t) -> door.rotation_degrees.y <= 0.0" />
                    <Transition to="open" guard="(_t) -> this.isCloseBlocked == true" />
                    <Transition to="open" event="trigger" />
                    <Transition to="blocked" event="collision" />

                    <on_state_physics_processing fn="this._closing" />
                </AtomicState>

            </CompoundState>

        );
    }

    function fpsPlayerController() {
        // FPS controller from an earlier hxgodot project. Deals with multiple movement and logic states
        sc = StateChartMacros.createChartFromXml(this.get_name(),

            <CompoundState name="fpsController" initial="alive">

                <ParallelState name="alive">
                    <!-- Stance controls the movement and collision of the player -->
                    <CompoundState name="stance" initial="walking">
                        <AtomicState name="walking">
                            <Transition to="crouching" guard="this._checkCrouching" />

                            <on_state_entered fn="this._enter_walking" />
                        </AtomicState>

                        <AtomicState name="crouching">
                            <Transition to="walking" guard="this._checkWalking" />

                            <on_state_entered fn="this._enter_crouching" />
                            <!-- <on_state_entered fn="this._exit_crouching" /> -->
                        </AtomicState>

                        <on_state_physics_processing fn="this._stance" />
                    </CompoundState>

                    <!-- movement -->
                    <CompoundState name="movement" initial="noclip">
                        <AtomicState name="noclip">
                            <on_state_entered fn="this._enter_noclip" />
                            <on_state_exited fn="this._exit_noclip" />
                            <on_state_physics_processing fn="this._noclip" />

                            <Transition to="ingame" guard="(_t) -> ThiefGame.cv_noclip == false" />
                        </AtomicState>

                        <CompoundState name="ingame" initial="grounded">
                            <AtomicState name="grounded">
                                <Transition to="jumping" event="jump" guard="this._checkGround" />
                                <Transition to="falling" event="fall" />

                                <on_state_entered fn="this._enter_grounded" />
                                <on_state_exited fn="this._exit_grounded" />
                                <on_state_physics_processing fn="this._grounded" />
                            </AtomicState>

                            <AtomicState name="jumping">
                                <Transition to="falling" event="fall" />

                                <on_state_entered fn="this._enter_jumping" />
                                <on_state_physics_processing fn="this._jumping" />
                            </AtomicState>

                            <AtomicState name="falling">
                                <Transition to="grounded" guard="this._checkGround">
                                    <on_taken fn="(_:Transition) -> sfxJumpLand.play()" />
                                </Transition>

                                <on_state_entered fn="this._enter_falling" />
                                <on_state_exited fn="this._exit_falling" />
                                <on_state_physics_processing fn="this._falling" />
                            </AtomicState>

                            <AtomicState name="climbing">
                                <Transition to="jumping" event="jump" />
                                <Transition to="falling" event="exit_climbing" />

                                <on_state_physics_processing fn="this._climbing" />
                            </AtomicState>

                            <Transition to="noclip" guard="(_t) -> ThiefGame.cv_noclip == true" />
                            <Transition to="climbing" event="enter_climbing" />

                            <on_state_physics_processing fn="this._ingame" />
                        </CompoundState>
                    </CompoundState>

                    <!-- view -->
                    <AtomicState name="view">
                        <on_state_entered fn="this._enter_view" />
                        <on_state_exited fn="this._exit_view" />
                        <on_state_physics_processing fn="this._view" />
                        <on_state_input fn="this._input_view" />
                    </AtomicState>

                    <Transition to="dead" guard="this._checkDead"/>
                </ParallelState>

                <AtomicState name="dead">
                </AtomicState>

            </CompoundState>
        );
    }
}