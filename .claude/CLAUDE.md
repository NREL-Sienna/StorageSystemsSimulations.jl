# StorageSystemsSimulations.jl — Claude Guide

Platform-wide Sienna conventions (performance, type stability, formatter, environments, code style) live in `.claude/Sienna.md` — read it too. This file is repo-specific and does not restate them.

## Purpose & Place in the Sienna Stack

StorageSystemsSimulations.jl is an **extension of PowerSimulations.jl (PSI)** that provides storage device formulations for optimization-based scheduling. It does not build its own solver stack: it defines PSI variable/constraint/expression/parameter types and dispatches PSI's `construct_device!` to assemble JuMP models through PowerSimulations.

Verified dependencies (`Project.toml` `[deps]`, do not assume others):

- `PowerSimulations` (compat `^0.36`) — the modeling engine; imported as `PSI`. `const PNM = PSI.PNM`, `const PM = PSI.PM` (PowerNetworkMatrices and PowerModels are reached through PSI, not direct deps).
- `PowerSystems` (compat `5`) — imported as `PSY`; device data model (`PSY.Storage`, `PSY.EnergyReservoirStorage`, `PSY.Reserve`, etc.).
- `InfrastructureSystems` (compat `3`) — imported as `IS`, with `ISOPT = IS.Optimization`.
- `JuMP` (1), `MathOptInterface` (`MOI`), `DataStructures` (`OrderedDict`), `Dates`, `LinearAlgebra`, `DocStringExtensions`.

Test-only deps (`test/Project.toml`, NOT main deps): `PowerSystemCaseBuilder` (`PSB`), `HiGHS`, `GLPK`, `Aqua`, `TimeSeries`, `OrderedCollections`.

## Architecture & `src/` Layout

Module file `src/StorageSystemsSimulations.jl` sets the export list and **include order** (respect it — core types are defined before the device models that use them):

- `core/definitions.jl` — constants only: `CYCLE_VIOLATION_COST`, `REG_COST`.
- `core/formulations.jl` — `abstract type AbstractStorageFormulation <: PSI.AbstractDeviceFormulation`; the exported `StorageDispatchWithReserves` struct (with the canonical attribute docstring).
- `core/variables.jl` — `PSI.VariableType`/`AuxVariableType` subtypes (ancillary-service charge/discharge, shortage/surplus, cycling slacks, regularization, `StorageEnergyOutput`).
- `core/constraints.jl` — `PSI.ConstraintType` subtypes (state-of-charge, cycling, reserve coverage/complete-coverage/total, regularization).
- `core/expressions.jl` — `PSI.ExpressionType` subtypes: `TotalReserveOffering` plus reserve assignment/deployment balance expressions.
- `core/parameters.jl` — `EnergyLimitParameter`, `EnergyTargetParameter` (`PSI.VariableValueParameter`).
- `core/initial_conditions.jl`, `core/feedforward.jl` — initial-condition setup and the `EnergyTargetFeedforward` / `EnergyLimitFeedforward` affect-feedforwards.
- `storage_models.jl` — the bulk: `PSI.get_variable_*` trait methods, `PSI.add_variables!`/`add_constraints!`/`add_to_expression!`/`add_proportional_cost!` dispatches, reserve range helpers. Starts with `#! format: off`.
- `storage_constructor.jl` — the `PSI.construct_device!` methods (the entry point; see below).
- `contingency_model.jl` — `PSI.add_event_constraints!` for `PSY.EnergyReservoirStorage` outage/contingency events.

## How It Plugs Into PowerSimulations

The package follows the standard PSI **DeviceModel / formulation** pattern. A user builds a `PSI.DeviceModel(StorageType, StorageDispatchWithReserves; attributes=…, use_slacks=…)` in a template; PSI then calls into `construct_device!` here.

`storage_constructor.jl` defines four `PSI.construct_device!` methods keyed on `{St<:PSY.Storage, D<:StorageDispatchWithReserves, S}` where `S` is either `PM.AbstractPowerModel` (with reactive power) or `PM.AbstractActivePowerModel` (active-power-only), each split into `ArgumentConstructStage` (variables/expressions/parameters) and `ModelConstructStage` (constraints/objective). They branch on `PSI.get_attribute(model, …)` for `"reservation"`, `"energy_target"`, `"cycling_limits"`, `"complete_coverage"`, `"regularization"`, and on `PSI.has_service_model(model)`.

## Public API (exported)

- Formulation: `StorageDispatchWithReserves`.
- Variables: `AncillaryServiceVariableDischarge`, `AncillaryServiceVariableCharge`, `StorageEnergyShortageVariable`, `StorageEnergySurplusVariable`, `StorageChargeCyclingSlackVariable`, `StorageDischargeCyclingSlackVariable`, `StorageRegularizationVariableCharge`, `StorageRegularizationVariableDischarge`; aux var `StorageEnergyOutput`.
- Constraints: `StateofChargeLimitsConstraint`, `StorageCyclingCharge`, `StorageCyclingDischarge`, `ReserveCoverageConstraint`(`EndOfPeriod`), `ReserveCompleteCoverageConstraint`(`EndOfPeriod`), `StorageTotalReserveConstraint`, `ReserveDischargeConstraint`, `ReserveChargeConstraint`.
- Feedforward: `EnergyTargetFeedforward`, `EnergyLimitFeedforward`. Parameter: `EnergyLimitParameter`.

## Conventions & Gotchas

- This package adds methods to PSI/PSY generic functions (e.g. `PSI.construct_device!`, `PSI.add_variables!`, `PSI.get_variable_upper_bound`) — most public surface is **method dispatch on PSI functions**, not new exported functions. Branch on device/formulation/network types via dispatch, never `isa`/`<:`.
- `storage_models.jl` begins with `#! format: off` — the trait-method block is intentionally exempt from the formatter; do not reflow it.
- Setting `"energy_target"` together with `EnergyTargetFeedforward`/`EnergyLimitFeedforward` is an error by design (the formulation throws). Combining `"cycling_limits"` with `"energy_target"` is discouraged (both constrain energy).
- Contingency support is scoped to `PSY.EnergyReservoirStorage` via `PSI.add_event_constraints!`; events come from PSY supplemental attributes.
- Per global rules: do not modify PSI's `src/core/optimization_container.jl` — push fixes down into `construct_device!`/`add_*!` here.

## Optimization Model Construction Conventions

### `add_*!()` methods must not return collections
Methods that create variables, constraints, or expressions (`add_variables!`, `add_constraints!`, `add_expressions!`, etc.) must always end with a bare `return` (i.e., return `nothing`). They must never return dicts or collections of JuMP objects. Instead, instantiate the appropriate container via `add_*_container!` and store all created objects there.

### Inline expressions when possible
Expression construction should be inlined at the point of use. Only store an expression in a container when it is intended to be reused across multiple constraints or objective terms. Avoid creating expression containers solely as intermediate computation steps.

## Running tests, docs, formatter (verified commands)

Formatter (self-activates its own env):

```sh
julia --project=scripts/formatter -e 'include("scripts/formatter/formatter_code.jl")'
```

Tests — `test/runtests.jl` uses the classic `@includetests ARGS` runner: with no args it scans `test/` for `test_*.jl` files; with args it maps each via `string(f, ".jl")`, so a single file is invoked by its **`test_`-prefixed stem without extension**:

```sh
julia --project=test test/runtests.jl                              # full suite
julia --project=test test/runtests.jl test_storage_device_models   # one file (test_-prefixed stem)
julia --project=test -e 'using Pkg; Pkg.instantiate()'             # instantiate test env
```

Test files: `test_storage_device_models.jl`, `test_storage_simulation.jl`, `test_market_bid_cost.jl`, `test_events.jl` (shared helpers in `test/test_utils/`). Aqua quality checks run at the top of `runtests.jl`.

Docs:

```sh
julia --project=docs docs/make.jl
```
