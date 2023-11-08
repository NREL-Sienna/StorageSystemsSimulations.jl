### Define Constraints using PSI.ConstraintType ###

# Constraints taken from PSI
# OutputActivePowerVariableLimitsConstraint
# InputActivePowerVariableLimitsConstraint
# EnergyBalanceConstraint

struct StateofChargeTargetConstraint <: PSI.ConstraintType end

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
struct StorageTotalReserveConstraint <: PSI.ConstraintType end
