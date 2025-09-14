
# MP1 Report — Queueing Simulator

## Student Info ## 
- Name: Raiyan Siddiqui
- AID: A20516097

## How to Build & Run
- Build: no build step required.
- Run (basic): `dart run bin/main.dart -c conf/sim1.yaml`
- Run with trace: `dart run bin/main.dart -c conf/sim1.yaml -v`
- VS Code: use the preconfigured launch targets (“Simulation 1…5”).

## Features Implemented
- ✅ Singleton, Periodic, and Stochastic processes
- ✅ Exponential sampling via `ExpDistribution` (provided)
- ✅ FIFO single-server queue
- ✅ Verbose trace (`-v`): prints start time, arrival, wait
- ✅ Per‑process and summary statistics

## Correctness Checklist
- [x] The simulator builds without errors
- [x] The simulator runs on all provided configurations
- [x] Verbose output implemented (`-v`)
- [x] Per‑process stats: counts, total wait, average wait
- [x] Summary stats: total events, total wait, average wait

You should verify locally on your machine:
- [ ] `conf/sim1.yaml`
- [ ] `conf/sim2.yaml`
- [ ] `conf/sim3.yaml`
- [ ] `conf/sim4.yaml`
- [ ] `conf/sim5.yaml`

> Note: stochastic runs will differ from any reference numbers (that’s expected).

## Design Overview
- **Event** (in `lib/processes.dart`): holds `processName`, `arrival`, `duration`, and computed `start` and `wait`.
- **Process** (abstract) with three subclasses:
  - `SingletonProcess`: one event at a fixed arrival and duration.
  - `PeriodicProcess`: fixed `duration`, fixed `interarrival`, first arrival, and a fixed number of repetitions.
  - `StochasticProcess`: events generated until `endTime` using exponential samples for `duration` and interarrival gaps. Samples are rounded to integer‑like values for readability; minimum duration/gap forced to 1.
- **Simulator** (in `lib/simulator.dart`):
  - Parses YAML into processes.
  - Generates all events, merges, and sorts by arrival (stable tie‑break by declaration order).
  - Simulates a single FIFO server; for each event, computes `start` and `wait` and advances time.
  - Aggregates and prints per‑process and overall statistics.
- **CLI** (`bin/main.dart`):
  - `-c/--conf` to select YAML.
  - `-v/--verbose` for the Gantt‑like trace.
  - `-h/--help` for usage.

## Assumptions & Notes
- Times are treated as numeric time units. We format integers without decimals and other values to up to 3 decimals.
- Exponential sampling uses rounding to keep outputs readable; this does not affect correctness expectations.
- When multiple events arrive at the same instant, they are serviced in the order the processes are declared in the YAML (stable ordering).

## Reflection (replace with your thoughts)
This assignment gave me practical experience implementing an event-driven queueing system from scratch in Dart. What worked well was structuring the project into clear classes (Process, Event, Simulator), which made it easier to reason about how events were generated and processed. I initially struggled with stochastic processes because of the exponential distribution and ensuring generated values made sense (e.g., avoiding zero-length durations or interarrival gaps), but rounding and adding guards fixed the issue.

Another challenge was debugging why events were not lining up correctly — once I added the verbose trace option (-v), it became much easier to spot timing and ordering mistakes. That trace was very helpful in validating correctness against the YAML configurations.

Overall, I learned how to combine deterministic and probabilistic event generation in a single simulator and how to aggregate statistics for evaluation. 