# [Simulating operations with StorageSystemSimulations](@id sim_tutorial)

**Originally Contributed by**: Jose Daniel Lara

## Introduction

## Load Packages

```@example op_problem
using PowerSystems
using PowerSimulations
using StorageSystemSimulations
using PowerSystemCaseBuilder
using HiGHS # solver
```

## Data

!!! note
    
    `PowerSystemCaseBuilder.jl` is a helper library that makes it easier to reproduce examples in the documentation and tutorials. Normally you would pass your local files to create the system data instead of calling the function `build_system`.
    For more details visit [PowerSystemCaseBuilder Documentation](https://nrel-sienna.github.io/PowerSystems.jl/stable/tutorials/powersystembuilder/)
