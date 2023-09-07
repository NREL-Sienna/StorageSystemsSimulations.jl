# Used for the Power Limits constraints
struct ReserveAssignmentBalanceOut <: PSI.ExpressionType end
struct ReserveAssignmentBalanceIn <: PSI.ExpressionType end

# Used for the SoC estimates
struct ReserveDeploymentBalanceOut <: PSI.ExpressionType end
struct ReserveDeploymentBalanceIn <: PSI.ExpressionType end
