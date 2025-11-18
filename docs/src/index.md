# StorageSystemsSimulations.jl

```@meta
CurrentModule = StorageSystemsSimulations
```

## Overview

`StorageSystemsSimulations.jl` is a
[`PowerSimulations.jl`](https://nrel-sienna.github.io/PowerSimulations.jl/stable/)
extension to support formulations and models related to energy storage.

Operational Storage Models can have multiple combinations of different restrictions.
To manage these variations, `StorageSystemsSimulations.jl` relies on the
[`PowerSimulations.DeviceModel`](@extref) attributes feature. Formulations can have varying
implementations for different attributes defined in [`PowerSimulations.DeviceModel`](@extref).

## Problems You Can Solve

`StorageSystemsSimulations.jl` enables solving a variety of energy storage optimization problems:

### Energy Arbitrage
Optimize storage charge/discharge schedules to buy energy when prices are low and sell when prices are high. The formulation accounts for:
- Round-trip efficiency losses
- State-of-charge limits
- Power capacity constraints

### Ancillary Services Provision
Co-optimize storage for both energy arbitrage and ancillary services (reserves):
- **Reserve Up**: Capacity to increase discharge or decrease charging
- **Reserve Down**: Capacity to increase charging or decrease discharge
- Energy coverage constraints ensure the battery can actually deliver the committed reserves

### Cycling Limit Management
Limit battery degradation by constraining the total energy throughput:
- Set maximum cycles per optimization horizon
- Soft constraints with penalty costs allow violations when economically justified

### Multi-Stage Operations
Coordinate storage operations across different market timescales:
- Day-ahead (DA) scheduling with hourly resolution
- Real-time (RT) dispatch with 5-minute resolution
- Feedforward mechanisms pass energy targets and limits between stages

### State-of-Charge Targeting
Ensure the storage ends the optimization horizon at a desired energy level:
- Useful for maintaining energy reserves for the next period
- Soft constraints allow deviations with penalty costs

## Key Features

### Formulation Attributes

The [`StorageDispatchWithReserves`](@ref) formulation provides five configurable attributes:

| Attribute | Default | Description |
|:----------|:--------|:------------|
| `"reservation"` | `true` | Enforce exclusive charge OR discharge mode per period |
| `"cycling_limits"` | `false` | Limit total energy cycling over the horizon |
| `"energy_target"` | `false` | Set end-of-horizon state-of-charge target |
| `"complete_coverage"` | `false` | Require coverage of ALL reserves simultaneously |
| `"regularization"` | `false` | Smooth charge/discharge profiles |

### When to Use Each Attribute

- **`"reservation" => true`**: Use for short time resolutions (5-15 min) where the battery physically cannot charge and discharge in the same period
- **`"reservation" => false`**: Use for longer time resolutions (1 hour) where average power over the period can be net charge or discharge
- **`"cycling_limits" => true`**: Use when battery degradation costs are significant and you want to limit usage
- **`"energy_target" => true`**: Use when you need to ensure energy availability for the next optimization period
- **`"complete_coverage" => true`**: Use for conservative operation where all reserves must be deliverable simultaneously
- **`"regularization" => true`**: Use when the solver produces oscillating or bang-bang solutions due to price degeneracy

### Multi-Stage Coordination

For coordinating day-ahead and real-time operations, use the feedforward mechanisms:

- [`EnergyTargetFeedforward`](@ref): Pass energy targets from DA to RT
- [`EnergyLimitFeedforward`](@ref): Pass energy limits from DA to RT

## Quick Start

```julia
using PowerSystems
using PowerSimulations
using StorageSystemsSimulations

# Create your system with storage devices
# system = ...

# Create the template
template = ProblemTemplate(CopperPlatePowerModel)

# Add the storage model with desired attributes
storage_model = DeviceModel(
    EnergyReservoirStorage,
    StorageDispatchWithReserves;
    attributes = Dict(
        "reservation" => true,
        "cycling_limits" => false,
        "energy_target" => false,
        "regularization" => true,
    ),
)
set_device_model!(template, storage_model)

# Add reserve services if needed
set_service_model!(template, ServiceModel(VariableReserve{ReserveUp}, RangeReserve))
set_service_model!(template, ServiceModel(VariableReserve{ReserveDown}, RangeReserve))

# Build and solve
model = DecisionModel(template, system; optimizer = your_optimizer)
build!(model, output_dir = "output")
solve!(model)
```

See the [Tutorials](@ref op_problem_tutorial) for complete examples.

## About Sienna

`StorageSystemsSimulations.jl` is part of the National Renewable Energy Laboratory's
[Sienna ecosystem](https://nrel-sienna.github.io/Sienna/), an open source framework for
power system modeling, simulation, and optimization. The Sienna ecosystem can be
[found on Github](https://github.com/NREL-Sienna/Sienna). It contains three applications:

  - [Sienna\Data](https://nrel-sienna.github.io/Sienna/pages/applications/sienna_data.html) enables
    efficient data input, analysis, and transformation
  - [Sienna\Ops](https://nrel-sienna.github.io/Sienna/pages/applications/sienna_ops.html) enables
    enables system scheduling simulations by formulating and solving optimization problems
  - [Sienna\Dyn](https://nrel-sienna.github.io/Sienna/pages/applications/sienna_dyn.html) enables
    system transient analysis including small signal stability and full system dynamic
    simulations

Each application uses multiple packages in the [`Julia`](http://www.julialang.org)
programming language. `StorageSystemsSimulations.jl` is part of Sienna\Ops.

## Installation and Quick Links

  - [Sienna installation page](https://nrel-sienna.github.io/Sienna/SiennaDocs/docs/build/how-to/install/):
    Instructions to install `StorageSystemsSimulations.jl` and other Sienna\Ops packages
  - [Sienna Documentation Hub](https://nrel-sienna.github.io/Sienna/SiennaDocs/docs/build/index.html):
    Links to other Sienna packages' documentation
