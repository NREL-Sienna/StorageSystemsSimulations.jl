# [Solving an operation with StorageSystemSimulations](@id op_problem_tutorial)

**Originally Contributed by**: Jose Daniel Lara

## Introduction

This tutorial demonstrates how to solve a single-stage unit commitment problem with energy storage using `StorageSystemsSimulations.jl`. You will learn how to:

1. Set up a power system with storage devices
2. Configure the storage formulation with various attributes
3. Build and solve the optimization model
4. Access and analyze the results

## Load Packages

```@example op_problem
using PowerSystems
using PowerSimulations
using StorageSystemsSimulations
using PowerSystemCaseBuilder
using HiGHS # solver
```

## Data

!!! note

    `PowerSystemCaseBuilder.jl` is a helper library that makes it easier to reproduce examples in the documentation and tutorials. Normally you would pass your local files to create the system data instead of calling the function `build_system`.
    For more details visit [`PowerSystemCaseBuilder.jl`](https://nrel-sienna.github.io/PowerSystemCaseBuilder.jl/stable)

```@example op_problem
c_sys5_bat = build_system(
    PSITestSystems,
    "c_sys5_bat_ems";
    add_single_time_series=true,
    add_reserves=true,
)
orcd = get_component(ReserveDemandCurve, c_sys5_bat, "ORDC1")
set_available!(orcd, false)
```

Let's examine the storage device in our system:

```@example op_problem
batt = get_component(EnergyReservoirStorage, c_sys5_bat, "Bat2")

operation_cost = get_operation_cost(batt)
```

## Building the Problem Template

First, we create the template with the network model and device models for non-storage components:

```@example op_problem
template_uc = ProblemTemplate(PTDFPowerModel)
set_device_model!(template_uc, ThermalStandard, ThermalStandardUnitCommitment)
set_device_model!(template_uc, RenewableDispatch, RenewableFullDispatch)
set_device_model!(template_uc, PowerLoad, StaticPowerLoad)
set_device_model!(template_uc, Line, StaticBranch)
```

## Configuring the Storage Model

Now we configure the storage model with `StorageDispatchWithReserves`. The formulation supports several attributes that control its behavior:

- **`reservation`**: When `true`, enforces that storage operates exclusively in charge OR discharge mode each period
- **`energy_target`**: When `true`, adds constraints to reach a target state-of-charge at the end of the horizon
- **`cycling_limits`**: When `true`, limits the total energy cycling to prevent excessive battery wear
- **`regularization`**: When `true`, adds penalty terms to smooth charge/discharge profiles

```@example op_problem
storage_model = DeviceModel(
    EnergyReservoirStorage,
    StorageDispatchWithReserves;
    attributes=Dict(
        "reservation" => true,
        "energy_target" => false,
        "cycling_limits" => false,
        "regularization" => true,
    ),
)
set_device_model!(template_uc, storage_model)
```

## Adding Reserve Services

The storage can participate in ancillary services markets. We add models for both up and down reserves:

```@example op_problem
set_service_model!(template_uc, ServiceModel(VariableReserve{ReserveUp}, RangeReserve))
set_service_model!(template_uc, ServiceModel(VariableReserve{ReserveDown}, RangeReserve))
```

## Building and Solving the Model

Create the decision model and solve:

```@example op_problem
model = DecisionModel(
    template_uc,
    c_sys5_bat;
    optimizer=HiGHS.Optimizer,
    horizon=24,
    optimizer_attributes=Dict("mip_rel_gap" => 0.05),
)
build!(model, output_dir=mktempdir())
```

```@example op_problem
solve!(model)
```

## Accessing Results

### Storage Power Output

We can access the optimal charge and discharge power schedules:

```@example op_problem
res = OptimizationProblemResults(model)

# Get discharge power
p_out = read_variable(res, "ActivePowerOutVariable__EnergyReservoirStorage")
```

```@example op_problem
# Get charge power
p_in = read_variable(res, "ActivePowerInVariable__EnergyReservoirStorage")
```

### State of Charge

Access the energy (state-of-charge) trajectory:

```@example op_problem
energy = read_variable(res, "EnergyVariable__EnergyReservoirStorage")
```

### Reserve Allocations

If the storage participates in reserves, we can see the allocations:

```@example op_problem
# Reserve allocations for discharge
read_variable(res, "AncillaryServiceVariableDischarge__EnergyReservoirStorage")
```

### Objective Value

Check the total system cost:

```@example op_problem
get_objective_value(res)
```

## Alternative Configurations

### Without Reservation (for Hourly Models)

For models with hourly resolution, the storage can effectively charge and discharge in the same period (net power). Set `reservation => false`:

```julia
storage_model_no_res = DeviceModel(
    EnergyReservoirStorage,
    StorageDispatchWithReserves;
    attributes=Dict(
        "reservation" => false,  # Allow simultaneous charge/discharge
        "energy_target" => false,
        "cycling_limits" => false,
        "regularization" => false,
    ),
)
```

### With Energy Target

To ensure the battery ends at a specific state-of-charge:

```julia
storage_model_target = DeviceModel(
    EnergyReservoirStorage,
    StorageDispatchWithReserves;
    attributes=Dict(
        "reservation" => true,
        "energy_target" => true,  # Enforce end-of-horizon target
        "cycling_limits" => false,
        "regularization" => true,
    ),
)
```

!!! warning
    The energy target comes from the `storage_target` field in the `EnergyReservoirStorage` component. Make sure this value is set appropriately.

### With Cycling Limits

To limit battery degradation by constraining total cycles:

```julia
storage_model_cycling = DeviceModel(
    EnergyReservoirStorage,
    StorageDispatchWithReserves;
    attributes=Dict(
        "reservation" => true,
        "energy_target" => false,
        "cycling_limits" => true,  # Limit total energy throughput
        "regularization" => true,
    ),
)
```

!!! tip
    The cycle limit comes from the `cycle_limits` field in the `EnergyReservoirStorage` component. A value of 1.0 means the battery can fully charge and discharge once over the horizon.
