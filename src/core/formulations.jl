############################ Storage Generation Formulations ###############################
abstract type AbstractStorageFormulation <: PSI.AbstractDeviceFormulation end

"""
Formulation type to add storage formulation than can provide ancillary services. If a
storage unit does not contribute to any service, then the variables and constraints related to
services are ignored.

The formulation supports the following attributes. See Documentation for more details.

```julia
DeviceModel(
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
"""
struct StorageDispatchWithReserves <: AbstractStorageFormulation end
