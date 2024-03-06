# StorageSystemsSimulations.jl

```@meta
CurrentModule = StorageSystemsSimulations
```

## Overview

`StorageSimulations.jl` is a `PowerSimulations.jl` extension to support formulations and models
related to energy storage including batteries and other long-durantion storage devices.

The codebase for `StorageSimulations.jl` contains storage specific [`VariableType`](@ref vars), [`AuxVariableType`](@ref aux_vars), [`ConstraintType`](@ref cons), [`ParameterType`](@ref params) and [`FeedForward`](@ref ff) used for modeling the operations of energy storage systems.

A Storage Operational Model can have multiple combinations of different restrictions depending on the modeling objectives. For instance,
it might be relevant to a study to consider cycling limits or employ energy targets coming from a planning model. To manage all these variations `StorageSimulations.jl` heavily uses the `DeviceModel` attributes feature to configure the storage model.

For example, the formulation `StorageDispatchWithReserves` can be parametrized as follows when added to a `PowerSimulations.jl` model:

```julia
storage_model = DeviceModel(
    StorageType, # E.g. BatteryEMS or GenericStorage
    StorageDispatchWithReserves;
    attributes=Dict(
        "reservation" => true,
        "cycling_limits" => false,
        "energy_target" => false,
        "complete_coverage" => false,
        "regularization" => true,
    ),
    use_slacks=false,
)
```

!!! tip
    
    Each formulation can have different implementations for attributes. Carefully review the formulation library pages to understand how to configure the storage model according to your requirements

## Installation

The latest stable release of PowerSimulations can be installed using the Julia package manager with

```
(@v1.10) pkg> add PowerSimulations StorageSystemsSimulations
```

For the current development version, "checkout" this package with

```
(@v1.10) pkg> add PowerSimulations StorageSystemsSimulations#main
```

An appropriate optimization solver is required for running StorageSystemsSimulations models. Refer to [`JuMP.jl` solver's page](https://jump.dev/JuMP.jl/stable/installation/#Install-a-solver) to select the most appropriate for the application of interest.

StorageSystemsSimulations has been developed as part of the Scalable Integrated Infrastructure Planning (SIIP) initiative at the U.S. Department of Energy's National Renewable Energy
Laboratory ([NREL](https://www.nrel.gov/)).
