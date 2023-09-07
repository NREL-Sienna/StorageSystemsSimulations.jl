### Define Constraints using PSI.ConstraintType ###

struct StatusOutOn <: PSI.ConstraintType end
struct StatusInOn <: PSI.ConstraintType end

## AS Provision
struct ReserveCoverageConstraint <: PSI.ConstraintType end
struct ReserveCoverageConstraintEndOfPeriod <: PSI.ConstraintType end
struct ChargingReservePowerLimit <: PSI.ConstraintType end
struct DischargingReservePowerLimit <: PSI.ConstraintType end

## Auxiliary for Output
struct AuxiliaryReserveConstraint <: PSI.ConstraintType end
struct ReserveBalance <: PSI.ConstraintType end

struct BatteryStatusChargeOn <: PSI.ConstraintType end
struct BatteryStatusDischargeOn <: PSI.ConstraintType end
struct BatteryBalance <: PSI.ConstraintType end
struct CyclingCharge <: PSI.ConstraintType end
struct CyclingDischarge <: PSI.ConstraintType end
