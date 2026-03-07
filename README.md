
# Statecharts for Haxe

Implementation of [statecharts.dev](https://statecharts.dev) for Haxe.

## Features

Based on the Harel statechart formalism, this library provides:

- **Atomic states** — leaf states with no children
- **Compound states** — hierarchical states with exactly one active child and an initial state
- **Parallel states** — AND-states where all children are active simultaneously
- **Final states** — completion states that generate `done.state.<parentName>` events
- **History states** — shallow and deep pseudo-states that remember the last active configuration
- **Guards** — boolean conditions on transitions
- **Events** — string-based event triggers with depth-first child-first propagation
- **Automatic (eventless) transitions** — transitions that fire immediately or when a guard becomes true
- **Delayed transitions** — transitions that fire after a specified duration
- **Local/internal transitions** — transitions that skip exiting/entering the compound source state
- **Entry/exit actions** — signals fired when states are entered or exited
- **Transition actions** — signals fired when a specific transition is taken
- **Process/tick actions** — signals fired each frame with delta time (game loop integration)
- **Event queuing** — re-entrant safe event and transition processing
- **XML macro DSL** — compile-time XML-to-code generation for declarative statechart definitions

## Installation

Add to your `haxelib.json` dependencies or use directly:

```
haxelib dev statecharts /path/to/statecharts
```

## Quick Start

### Programmatic API

```haxe
import statecharts.Types;
import statecharts.CompoundState;
import statecharts.AtomicState;
import statecharts.FinalState;

var sc = new StateChart("myChart");

var root = new CompoundState("root");
var idle = new AtomicState("idle");
var active = new AtomicState("active");
var done = new FinalState("done");

root.add(idle);
root.add(active);
root.add(done);
root.initialState = idle;

// Add transitions
var t1 = new Transition();
t1.to = active;
t1.event = "activate";
idle.transitions.push(t1);

var t2 = new Transition();
t2.to = done;
t2.event = "finish";
active.transitions.push(t2);

// Connect signals
idle.on_state_entered.connect(() -> trace("Entered idle"));
active.on_state_entered.connect(() -> trace("Entered active"));

sc.addRoot(root);
sc.init();

sc.sendEvent("activate"); // transitions to active
sc.sendEvent("finish");   // transitions to done, emits done.state.root
```

### XML Macro DSL

```haxe
var sm = StateChartMacros.createChartFromXml("myChart", '
    <CompoundState name="root" initial="idle">
        <AtomicState name="idle">
            <Transition to="active" event="start" />
            <on_state_entered fn="onIdleEntered" />
        </AtomicState>
        <AtomicState name="active">
            <Transition to="idle" event="stop" />
            <Transition to="idle" event="reset" type="internal" />
        </AtomicState>
        <FinalState name="completed">
        </FinalState>
    </CompoundState>
');
sm.init();
```

### XML DSL Attributes

**State elements**: `CompoundState`, `AtomicState`, `ParallelState`, `FinalState`, `HistoryState`

| Attribute | Applies to | Description |
|-----------|-----------|-------------|
| `name` | All states | State identifier (required) |
| `initial` | `CompoundState` | Name of the initial child state |
| `deep` | `HistoryState` | `"true"` for deep history, omit for shallow |
| `external` | All states | Use a pre-declared variable instead of `var` |

**Transition element**: `<Transition>`

| Attribute | Description |
|-----------|-------------|
| `to` | Target state name (required) |
| `event` | Event name trigger (omit for automatic transition) |
| `guard` | Guard expression (Haxe expression string) |
| `delaySecs` | Delay in seconds before transition fires |
| `type` | `"internal"` for local transition (default: external) |

**Signal elements**: `<on_state_entered>`, `<on_state_exited>`, `<on_taken>`, etc.

| Attribute | Description |
|-----------|-------------|
| `fn` | Haxe expression for the callback function |

## Game Loop Integration

The library is designed for game update loops:

```haxe
// In your game loop:
sc.process(deltaTime);  // ticks delayed transitions, evaluates automatic guards
sc.step();              // emits on_state_stepped signals
```

## Signals

Each state exposes these signals:

| Signal | Type | When |
|--------|------|------|
| `on_state_entered` | `Void->Void` | State is entered |
| `on_state_exited` | `Void->Void` | State is exited |
| `on_state_stepped` | `Void->Void` | `step()` is called |
| `on_state_processing` | `Float->Void` | `process(dt)` is called |
| `on_event_received` | `String->Void` | Event reaches this state |
| `on_transition_pending` | `Float->Float->Void` | Delayed transition countdown `(total, remaining)` |

`CompoundState` adds:

| Signal | Type | When |
|--------|------|------|
| `on_child_state_entered` | `Void->Void` | Any direct child is entered |
| `on_child_state_exited` | `Void->Void` | Any direct child is exited |

`Transition` exposes:

| Signal | Type | When |
|--------|------|------|
| `on_taken` | `Transition->Void` | This transition fires |

## License

MIT
