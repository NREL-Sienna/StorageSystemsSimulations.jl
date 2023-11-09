struct TotalReserveOffering <: PSI.ExpressionType end

abstract type StorageReserveDischargeExpression <: PSI.ExpressionType end
abstract type StorageReserveChargeExpression <: PSI.ExpressionType end

# Used for the Power Limits constraints
struct ReserveAssignmentBalanceUpDischarge <: StorageReserveDischargeExpression end
struct ReserveAssignmentBalanceUpCharge <: StorageReserveChargeExpression end
struct ReserveAssignmentBalanceDownDischarge <: StorageReserveDischargeExpression end
struct ReserveAssignmentBalanceDownCharge <: StorageReserveChargeExpression end

# Used for the SoC estimates
struct ReserveDeploymentBalanceUpDischarge <: StorageReserveDischargeExpression end
struct ReserveDeploymentBalanceUpCharge <: StorageReserveChargeExpression end
struct ReserveDeploymentBalanceDownDischarge <: StorageReserveDischargeExpression end
struct ReserveDeploymentBalanceDownCharge <: StorageReserveChargeExpression end

should_write_resulting_value(::Type{StorageReserveDischargeExpression}) = true
should_write_resulting_value(::Type{StorageReserveChargeExpression}) = true
