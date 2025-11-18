# [Simulating operations with StorageSystemSimulations](@id sim_tutorial)

**Originally Contributed by**: Jose Daniel Lara

## Introduction

This tutorial demonstrates how to run multi-stage simulations with energy storage using `StorageSystemsSimulations.jl`. Multi-stage simulations are essential for:

- Coordinating day-ahead (DA) and real-time (RT) operations
- Passing energy targets and limits between stages using feedforwards
- Rolling horizon simulations with updating forecasts

You will learn how to:

1. Set up a day-ahead model with hourly resolution
2. Set up a real-time model with 5-minute resolution
3. Connect them with feedforward mechanisms
4. Run and analyze the simulation

## Load Packages

```@example sim_tutorial
using PowerSystems
using PowerSimulations
using StorageSystemsSimulations
using PowerSystemCaseBuilder
using HiGHS # solver
using Dates
```

## Data

!!! note

    `PowerSystemCaseBuilder.jl` is a helper library that makes it easier to reproduce examples in the documentation and tutorials. Normally you would pass your local files to create the system data instead of calling the function `build_system`.
    For more details visit [PowerSystemCaseBuilder Documentation](https://nrel-sienna.github.io/PowerSystems.jl/stable/tutorials/powersystembuilder/)

```@example sim_tutorial
c_sys5_bat = build_system(
    PSITestSystems,
    "c_sys5_bat_ems";
    add_single_time_series=true,
    add_reserves=true,
)
orcd = get_component(ReserveDemandCurve, c_sys5_bat, "ORDC1")
set_available!(orcd, false)
```

## Day-Ahead Model Template

The day-ahead model runs with hourly resolution and makes scheduling decisions for the next 24-48 hours:

```@example sim_tutorial
template_da = ProblemTemplate(CopperPlatePowerModel)
set_device_model!(template_da, ThermalStandard, ThermalStandardUnitCommitment)
set_device_model!(template_da, RenewableDispatch, RenewableFullDispatch)
set_device_model!(template_da, PowerLoad, StaticPowerLoad)
set_device_model!(template_da, Line, StaticBranch)
```

For the DA storage model, we use energy targeting to ensure the battery ends each day at a desired state:

```@example sim_tutorial
storage_model_da = DeviceModel(
    EnergyReservoirStorage,
    StorageDispatchWithReserves;
    attributes=Dict(
        "reservation" => false,  # Hourly resolution allows net charge/discharge
        "energy_target" => true,
        "cycling_limits" => true,
        "regularization" => false,
    ),
)
set_device_model!(template_da, storage_model_da)
```

```@example sim_tutorial
set_service_model!(template_da, ServiceModel(VariableReserve{ReserveUp}, RangeReserve))
set_service_model!(template_da, ServiceModel(VariableReserve{ReserveDown}, RangeReserve))
```

## Real-Time Model Template

The real-time model runs with 5-minute resolution and dispatches based on updated forecasts:

```@example sim_tutorial
template_rt = ProblemTemplate(CopperPlatePowerModel)
set_device_model!(template_rt, ThermalStandard, ThermalBasicDispatch)
set_device_model!(template_rt, RenewableDispatch, RenewableFullDispatch)
set_device_model!(template_rt, PowerLoad, StaticPowerLoad)
set_device_model!(template_rt, Line, StaticBranch)
```

For the RT storage model, we enable reservation (since 5-minute resolution requires exclusive modes) and regularization:

```@example sim_tutorial
storage_model_rt = DeviceModel(
    EnergyReservoirStorage,
    StorageDispatchWithReserves;
    attributes=Dict(
        "reservation" => true,  # Short intervals need exclusive charge/discharge
        "energy_target" => false,  # Will use feedforward instead
        "cycling_limits" => false,  # Cycling managed at DA level
        "regularization" => true,
    ),
)
set_device_model!(template_rt, storage_model_rt)
```

```@example sim_tutorial
set_service_model!(template_rt, ServiceModel(VariableReserve{ReserveUp}, RangeReserve))
set_service_model!(template_rt, ServiceModel(VariableReserve{ReserveDown}, RangeReserve))
```

## Building the Simulation

### Create the Decision Models

```@example sim_tutorial
models = SimulationModels(
    decision_models=[
        DecisionModel(
            template_da,
            c_sys5_bat;
            name="DA",
            optimizer=HiGHS.Optimizer,
            optimizer_attributes=Dict("mip_rel_gap" => 0.05),
        ),
        DecisionModel(
            template_rt,
            c_sys5_bat;
            name="RT",
            optimizer=HiGHS.Optimizer,
        ),
    ],
)
```

### Define the Simulation Sequence

The sequence defines how the models interact:
- DA runs first with 24-hour horizon, executing every 24 hours
- RT runs after DA with 1-hour horizon, executing every 5 minutes (12 times per hour)

```@example sim_tutorial
sequence = SimulationSequence(
    models=models,
    feedforwards=Dict(
        "RT" => [
            EnergyTargetFeedforward(
                component_type=EnergyReservoirStorage,
                source=EnergyVariable,
                affected_values=[EnergyVariable],
                target_period=12,  # Target at end of RT horizon (12 x 5min = 1 hour)
                penalty_cost=1e5,
            ),
        ],
    ),
    ini_cond_chronology=InterProblemChronology(),
)
```

### Create and Build the Simulation

```@example sim_tutorial
sim = Simulation(
    name="storage_simulation",
    steps=1,
    models=models,
    sequence=sequence,
    simulation_folder=mktempdir(),
)
build!(sim)
```

## Execute the Simulation

```@example sim_tutorial
execute!(sim)
```

## Accessing Results

### Read Simulation Results

```@example sim_tutorial
results = SimulationResults(sim)
da_results = get_decision_problem_results(results, "DA")
rt_results = get_decision_problem_results(results, "RT")
```

### Day-Ahead Storage Schedule

```@example sim_tutorial
# DA discharge power
da_discharge = read_variable(da_results, "ActivePowerOutVariable__EnergyReservoirStorage")
```

```@example sim_tutorial
# DA state of charge
da_energy = read_variable(da_results, "EnergyVariable__EnergyReservoirStorage")
```

### Real-Time Storage Dispatch

```@example sim_tutorial
# RT discharge power
rt_discharge = read_variable(rt_results, "ActivePowerOutVariable__EnergyReservoirStorage")
```

```@example sim_tutorial
# RT state of charge
rt_energy = read_variable(rt_results, "EnergyVariable__EnergyReservoirStorage")
```

## Understanding Feedforwards

### EnergyTargetFeedforward

The `EnergyTargetFeedforward` passes energy targets from DA to RT. This ensures the RT model aims to match the DA-scheduled state-of-charge at specified intervals.

**How it works:**
1. DA solves and produces an energy trajectory
2. RT receives the DA energy values as targets
3. RT adds a constraint: `energy[target_period] + slack >= target`
4. The slack variable is penalized in the objective function

**Parameters:**
- `target_period`: Which time step in the RT horizon to apply the target
- `penalty_cost`: Cost for missing the target ($/MWh deviation)

### EnergyLimitFeedforward

For cases where you want to limit total energy usage rather than target specific values, use `EnergyLimitFeedforward`:

```julia
EnergyLimitFeedforward(
    component_type=EnergyReservoirStorage,
    source=StorageEnergyOutput,
    affected_values=[ActivePowerOutVariable],
    number_of_periods=12,  # Sum over 12 periods
)
```

This constrains the sum of energy output over a period to not exceed the DA-scheduled amount.

## Advanced: Complete Coverage for Reserves

When operating in markets with stringent reserve requirements, you may want to ensure the battery can deliver ALL committed reserves simultaneously:

```julia
storage_model_conservative = DeviceModel(
    EnergyReservoirStorage,
    StorageDispatchWithReserves;
    attributes=Dict(
        "reservation" => true,
        "energy_target" => true,
        "cycling_limits" => true,
        "complete_coverage" => true,  # Conservative reserve coverage
        "regularization" => true,
    ),
)
```

With `complete_coverage => true`, the energy coverage constraints require:
- Enough stored energy to provide ALL up-reserves simultaneously
- Enough storage headroom for ALL down-reserves simultaneously

This is more conservative than the default, which only ensures each service can be provided independently.

## Troubleshooting Common Issues

### Bang-Bang Solutions

If the storage oscillates between full charge and full discharge every period, enable regularization:

```julia
"regularization" => true
```

### Infeasible Energy Targets

If the model becomes infeasible with energy targets, ensure:
- The target is achievable given the storage capacity and efficiency
- The horizon is long enough to reach the target from the initial state

### Cycling Limit Violations

If cycling limits cause infeasibility, you can:
1. Increase the cycle limit in the component
2. Enable slack variables with `use_slacks=true` in the DeviceModel

```julia
storage_model = DeviceModel(
    EnergyReservoirStorage,
    StorageDispatchWithReserves;
    attributes=Dict(
        "cycling_limits" => true,
        # other attributes...
    ),
    use_slacks=true,  # Allow violations with penalty
)
```
