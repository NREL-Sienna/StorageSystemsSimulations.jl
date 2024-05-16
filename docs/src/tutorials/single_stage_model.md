# [Solving an operation with StorageSystemSimulations](@id op_problem_tutorial)

**Originally Contributed by**: Jose Daniel Lara

## Introduction

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
    For more details visit [PowerSystemCaseBuilder Documentation](https://nrel-sienna.github.io/PowerSystems.jl/stable/tutorials/powersystembuilder/)

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

```@example op_problem
batt = get_component(EnergyReservoirStorage, c_sys5_bat, "Bat2")

operation_cost = get_operation_cost(batt)
```

```@example op_problem
template_uc = ProblemTemplate(PTDFPowerModel)
set_device_model!(template_uc, ThermalStandard, ThermalStandardUnitCommitment)
set_device_model!(template_uc, RenewableDispatch, RenewableFullDispatch)
set_device_model!(template_uc, PowerLoad, StaticPowerLoad)
set_device_model!(template_uc, Line, StaticBranch)
```

```@example op_problem
storage_model = DeviceModel(
    EnergyReservoirStorage,
    StorageDispatchWithReserves;
    attributes=Dict(
        "reservation" => true,
        "energy_target" => false,
        "cycling_limits" => false,
        "regulatization" => true,
    ),
)
set_device_model!(template_uc, storage_model)
```

```@example op_problem
set_service_model!(template_uc, ServiceModel(VariableReserve{ReserveUp}, RangeReserve))
set_service_model!(template_uc, ServiceModel(VariableReserve{ReserveDown}, RangeReserve))
```
