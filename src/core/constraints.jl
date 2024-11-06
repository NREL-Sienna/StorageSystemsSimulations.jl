### Define Constraints using PSI.ConstraintType ###

# Constraints taken from PSI
# OutputActivePowerVariableLimitsConstraint
# InputActivePowerVariableLimitsConstraint
# EnergyBalanceConstraint

struct StateofChargeTargetConstraint <: PSI.ConstraintType end

"""
Struct to create the constraints to limit the state of charge of the storage system.

The specified constraints are given by:

```math
0 \\leq e^{st}_{t}\\leq E^{max}_{st} \\quad \\forall t \\in \\mathcal{T}
```
"""
struct StateofChargeLimitsConstraint <: PSI.ConstraintType end
struct StorageCyclingCharge <: PSI.ConstraintType end
struct StorageCyclingDischarge <: PSI.ConstraintType end

## AS Provision Energy Constraints
struct ReserveDischargeConstraint <: PSI.ConstraintType end
struct ReserveChargeConstraint <: PSI.ConstraintType end
struct ReserveCoverageConstraint <: PSI.ConstraintType end
struct ReserveCoverageConstraintEndOfPeriod <: PSI.ConstraintType end
struct ReserveCompleteCoverageConstraint <: PSI.ConstraintType end
struct ReserveCompleteCoverageConstraintEndOfPeriod <: PSI.ConstraintType end
"""
TODO: Rodrigo
"""
struct StorageTotalReserveConstraint <: PSI.ConstraintType end
"""
TODO: Rodrigo
"""
struct StorageRegularizationConstraintCharge <: PSI.ConstraintType end
"""
TODO: Rodrigo
"""
struct StorageRegularizationConstraintDischarge <: PSI.ConstraintType end
