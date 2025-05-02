############################ Storage Generation Formulations ###############################
abstract type AbstractStorageFormulation <: PSI.AbstractDeviceFormulation end

"""
Formulation type to add storage formulation than can provide ancillary services. If a
storage unit does not contribute to any service, then the variables and constraints related to
services are ignored.

# Example

```julia
DeviceModel(
    StorageType, # E.g. EnergyReservoirStorage or GenericStorage
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

The formulation supports the following attributes when used in a [`PowerSimulations.DeviceModel`](@extref):

# Attributes

  - `"reservation"`: Forces the storage to operate exclusively on charge or discharge mode through the entire operation interval. We recommend setting this to `false` for models with relatively longer time resolutions (e.g., 1-Hr) since the storage can take simultaneous charge or discharge positions on average over the period.
  - `"cycling_limits"`: This limits the storage's energy cycling. A single charging (discharging) cycle is fully charging (discharging) the storage once. The calculation uses the total energy charge/discharge and the number of cycles. Currently, the formulation only supports a fixed value per operation period. Additional variables for [`StorageChargeCyclingSlackVariable`](@ref) and [`StorageDischargeCyclingSlackVariable`](@ref) are included in the model if `use_slacks` is set to `true`.
  - `"energy_target"`: Set a target at the end of the model horizon for the storage's state of charge. Currently, the formulation only supports a fixed value per operation period. Additional variables for [`StorageEnergyShortageVariable`](@ref) and [`StorageEnergySurplusVariable`](@ref) are included in the model if `use_slacks` is set to `true`.

!!! warning

    Combining cycle limits and energy target attributes is not recommended. Both
    attributes impose constraints on energy. There is no guarantee that the constraints can be satisfied simultaneously.

  - `"complete_coverage"`: This attribute implements constraints that require the battery to cover the sum of all the ancillary services it participates in simultaneously. It is equivalent to holding energy in case all the services get deployed simultaneously. This constraint is added to the constraints that cover each service independently and corresponds to a more conservative operation regime.
  - `"regularization"`: This attribute smooths the charge/discharge profiles to avoid bang-bang solutions via a penalty on the absolute value of the intra-temporal variations of the charge and discharge power. Solving for optimal storage dispatch can stall in models with large amounts of curtailment or long periods with negative or zero prices due to numerical degeneracy. The regularization term is scaled by the storage device's power limits to normalize the term and avoid additional penalties to larger storage units.

!!! danger

    Setting the energy target attribute in combination with [`EnergyTargetFeedforward`](@ref)
    or [`EnergyLimitFeedforward`](@ref) is not permitted and `StorageSystemsSimulations.jl`
    will throw an exception.

See the [`StorageDispatchWithReserves` Mathematical Model](@ref) for the full mathematical description.
"""
struct StorageDispatchWithReserves <: AbstractStorageFormulation end
