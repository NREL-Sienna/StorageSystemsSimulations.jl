# Public API

```@meta
CurrentModule = StorageSystemsSimulations
DocTestSetup  = quote
    using StorageSystemsSimulations
end
```

## Formulations

```@docs
StorageDispatchWithReserves
```

## [Variables](@id vars)

```@docs
AncillaryServiceVariableDischarge
AncillaryServiceVariableCharge
StorageEnergyShortageVariable
StorageEnergySurplusVariable
StorageChargeCyclingSlackVariable
StorageDischargeCyclingSlackVariable
StorageRegularizationVariableCharge
StorageRegularizationVariableDischarge
```

## [Auxiliary Variables](@id aux_vars)

```@docs
StorageEnergyOutput
```

## [Constraints](@id cons)

```@docs
StateofChargeLimitsConstraint
StateofChargeTargetConstraint
StorageCyclingCharge
StorageCyclingDischarge
ReserveCoverageConstraint
ReserveCoverageConstraintEndOfPeriod
ReserveCompleteCoverageConstraint
ReserveCompleteCoverageConstraintEndOfPeriod
StorageTotalReserveConstraint
ReserveDischargeConstraint
ReserveChargeConstraint
StorageRegularizationConstraintCharge
StorageRegularizationConstraintDischarge
```

## [Parameters](@id params)

```@docs
EnergyLimitParameter
```

## [FeedForwards](@id ffs)

```@docs
EnergyTargetFeedforward
EnergyLimitFeedforward
```
