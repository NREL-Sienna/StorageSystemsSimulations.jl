### Define Constraints using PSI.ConstraintType ###

# Constraints taken from PSI
# OutputActivePowerVariableLimitsConstraint
# InputActivePowerVariableLimitsConstraint
# EnergyBalanceConstraint

# EnergyTargetConstraint

struct StateofChargeLimitsConstraint <: PSI.ConstraintType end
struct StorageCyclingCharge <: PSI.ConstraintType end
struct StorageCyclingDischarge <: PSI.ConstraintType end

## AS Provision Energy Constraints
struct ReserveCoverageConstraint <: PSI.ConstraintType end
struct ReserveCoverageConstraintEndOfPeriod <: PSI.ConstraintType end
struct StorageTotalReserve <: PSI.ConstraintType end
