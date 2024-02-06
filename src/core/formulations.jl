############################ Storage Generation Formulations ###############################
abstract type AbstractStorageFormulation <: PSI.AbstractDeviceFormulation end

"""
Formulation type to add storage formulation than can provide ancillary services.

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
)
```
"""
struct StorageDispatchWithReserves <: AbstractStorageFormulation end
