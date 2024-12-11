### Define Constraints using PSI.ConstraintType ###

# Constraints taken from PSI
# OutputActivePowerVariableLimitsConstraint
# InputActivePowerVariableLimitsConstraint
# EnergyBalanceConstraint

"""
Struct to create the state of charge target constraint at the end of period.
Used when the attribute `energy_target = true`.

The specified constraint is formulated as:

```math
e^{st}_{T} + e^{st+} - e^{st-} = E^{st}_{T},
```
"""
struct StateofChargeTargetConstraint <: PSI.ConstraintType end

"""
Struct to create the state of charge constraint limits.

The specified constraint is formulated as:

```math
E_{st}^{min} \\le e^{st}_{t} \\le E_{st}^{max}, \\quad \\forall t \\in \\{1,\\dots, T\\}
```
"""
struct StateofChargeLimitsConstraint <: PSI.ConstraintType end

"""
Struct to create the storage cycling limits for the charge variable.
Used when `cycling_limits = true`.

The specified constraint is formulated as:

```math
\\sum_{t \\in \\mathcal{T}} \\left(\\sum_{p \\in \\mathcal{P}^{\\text{as}_\\text{dn}}} R^*_{p,t} sb_{stc,p,t} + p^{st,ch}_{t} \\right)\\eta^{ch}_{st} \\Delta t - c^{ch-} \\leq C_{st} E^{max}_{st}
```
"""
struct StorageCyclingCharge <: PSI.ConstraintType end
"""
Struct to create the storage cycling limits for the discharge variable.
Used when `cycling_limits = true`.

The specified constraint is formulated as:

```math
\\sum_{t \\in \\mathcal{T}} \\left(\\sum_{p \\in \\mathcal{P}^{\\text{as}_\\text{up}}} R^*_{p,t} sb_{std,p,t} + p^{st,ds}_{t}\\right)\\frac{1}{\\eta^{ds}_{st}} \\Delta t - c^{ds-} \\leq C_{st} E^{max}_{st}
```
"""
struct StorageCyclingDischarge <: PSI.ConstraintType end

## AS Provision Energy Constraints
"""
Struct to specify the lower and upper bounds of the discharge variable considering reserves.

The specified constraints are formulated as:

```math
\\begin{align*}
& p^{st, ds}_{t} + \\sum_{p \\in \\mathcal{P}^{\\text{as}_\\text{up}}} sb_{std,p,t} \\leq \\text{ss}^{st}_{t}P^{max,ds}_{st} \\quad \\forall t \\in \\{1,\\dots, T\\} \\\\
& p^{st, ds}_{t} - \\sum_{p \\in \\mathcal{P}^{\text{as}_\\text{dn}}} sb_{std,p,t} \\geq 0, \\quad \\forall t \\in \\{1,\\dots, T\\}
\\end{align*}
```
"""
struct ReserveDischargeConstraint <: PSI.ConstraintType end

"""
Struct to specify the lower and upper bounds of the charge variable considering reserves.

The specified constraints are formulated as:

```math
\\begin{align*}
&p^{st, ch}_{t} + \\sum_{p \\in \\mathcal{P}^{\\text{as}_\\text{dn}}} sb_{stc,p,t} \\leq (1 - \\text{ss}^{st}_{t})P^{max,ch}_{st}, \\quad \\forall t \\in \\{1,\\dots, T\\} \\\\
& p^{st, ch}_{t} - \\sum_{p \\in \\mathcal{P}^{\\text{as}_\\text{up}}} sb_{stc,p,t} \\geq 0, \\quad \\forall t \\in \\{1,\\dots, T\\}
\\end{align*}
```
"""
struct ReserveChargeConstraint <: PSI.ConstraintType end

"""
Struct to specify the individual product ancillary service coverage at the beginning of the period for charge and discharge variables.

The specified constraints are formulated as:

```math
\\begin{align*}
& sb_{stc,p,1}  \\eta^{ch}_{st} N_{p} \\Delta t \\le E_{st}^{max} - e^{st}_0, \\quad \\forall p \\in \\mathcal{P}^{as_{dn}} \\\\
& sb_{stc,p,t}  \\eta^{ch}_{st} N_{p} \\Delta t \\le E_{st}^{max} - e^{st}_{t-1}, \\quad \\forall p \\in \\mathcal{P}^{as_{dn}},  \\forall t \\in \\{2,\\dots, T\\} \\\\
& sb_{std,p,1}  \\frac{1}{\\eta^{ds}_{st}} N_{p} \\Delta t \\leq e^{st}_0 - E^{min}_{st}, \\quad \\forall p \\in \\mathcal{P}^{as_{up}} \\\\
& sb_{std,p,t}  \\frac{1}{\\eta^{ds}_{st}} N_{p} \\Delta t \\leq e^{st}_{t-1} - E^{min}_{st}, \\quad \\forall p \\in \\mathcal{P}^{as_{up}},  \\forall t \\in \\{2,\\dots, T\\} 
\\end{align*}
```
"""
struct ReserveCoverageConstraint <: PSI.ConstraintType end
"""
Struct to specify the individual product ancillary service coverage at the end of the period for charge and discharge variables.

The specified constraints are formulated as:

```math
\\begin{align*}
& sb_{stc,p,t}  \\eta^{ch}_{st} N_{p} \\Delta t \\le E_{st}^{max} - e^{st}_{t}, \\quad \\forall p \\in \\mathcal{P}^{as_{dn}}, \\forall t \\in \\{1,\\dots, T\\} \\\\
& sb_{std,p,t}  \\frac{1}{\\eta^{ds}_{st}} N_{p} \Delta t \\leq e^{st}_{t}- E^{min}_{st} & \\forall p \\in \\mathcal{P}^{as_{up}}, \\forall t \\in \\{1,\\dots, T\\}
\\end{align*}
```
"""
struct ReserveCoverageConstraintEndOfPeriod <: PSI.ConstraintType end

"""
Struct to specify all products ancillary service coverage at the beginning of the period for charge and discharge variables.
Used when the attribute `complete_coverage = true`.

The specified constraints are formulated as:

```math
\\begin{align*}
& \\sum_{p \\in \\mathcal{P}^{\\text{as}_\\text{dn}}} sb_{stc,p,1}  \\eta^{ch}_{st} N_{p} \\Delta t \\le E_{st}^{max} - e^{st}_0 \\\\
& \\sum_{p \\in \\mathcal{P}^{\\text{as}_\\text{dn}}}  sb_{stc,p,t} \\eta^{ch}_{st} N_{p} \\Delta t \\le E_{st}^{max} - e^{st}_{t-1}, \\quad \\forall t \\in \\{2,\\dots, T\\} \\\\
& \\sum_{p \\in \\mathcal{P}^{\\text{as}_\\text{up}}} sb_{std,p,1}  \\frac{1}{\\eta^{ds}_{st}} N_{p} \\Delta t \\leq e^{st}_0 - E^{min}_{st} \\\\
& \\sum_{p \\in \\mathcal{P}^{\\text{as}_\\text{up}}} sb_{std,p,t}  \\frac{1}{\\eta^{ds}_{st}} N_{p} \\Delta t \\leq e^{st}_{t-1}- E^{min}_{st}, \\quad \\forall t \\in \\{2,\\dots, T\\}
\\end{align*}
```
"""
struct ReserveCompleteCoverageConstraint <: PSI.ConstraintType end

"""
Struct to specify all products ancillary service coverage at the end of the period for charge and discharge variables.
Used when the attribute `complete_coverage = true`.

The specified constraints are formulated as:

```math
\\begin{align*}
& \\sum_{p \\in \\mathcal{P}^{\\text{as}_\\text{dn}}}  sb_{stc,p,t}  \\eta^{ch}_{st} N_{p} \\Delta t \\le E_{st}^{max} - e^{st}_{t}, \\quad \\forall t \\in \\{1,\\dots, T\\}  \\\\
& \\sum_{p \\in \\mathcal{P}^{\\text{as}_\\text{up}}} sb_{std,p,t}  \\frac{1}{\\eta^{ds}_{st}} N_{p} \\Delta t \\leq e^{st}_{t}- E^{min}_{st}, \\quad \\forall t \\in \\{1,\\dots, T\\}
\\end{align*}
```
"""
struct ReserveCompleteCoverageConstraintEndOfPeriod <: PSI.ConstraintType end

"""
Struct to specify an auxiliary constraint for adding charge and discharge into a single active power reserve variable.

The specified constraint is formulated as:

```math
sb_{stc, p, t} + sb_{std, p, t} = r_{p,t}, \\quad \\forall p \\in \\mathcal{P}, \\forall t \\in \\{1,\\dots, T\\}
```
"""
struct StorageTotalReserveConstraint <: PSI.ConstraintType end

"""
Struct to specify the auxiliary constraints for regularization terms in the objective function for the charge variable.
Used when the attribute `regularization = true`.

The specified constraints are formulated as:

```math
\\begin{align*}
& \\left(\\sum_{p \\in \\mathcal{P}^{\\text{as}_\\text{dn}}} R^*_{p,t-1} sb_{stc,p,t-1} + p^{st,ch}_{t-1}  - \\sum_{p \\in \\mathcal{P}^{\\text{as}_\\text{up}}} R^*_{p,t-1} sb_{stc,p,t-1}\\right) - \\left(\\sum_{p \\in \\mathcal{P}^{\\text{as}_\\text{dn}}} R^*_{p,t} sb_{stc,p,t} + p^{st,ch}_{t}  - \\sum_{p \\in \\mathcal{P}^{\\text{as}_\\text{up}}} R^*_{p,t} sb_{stc,p,t}\\right) \\le z^{st, ch}_{t}, \\forall t \\in \\{2,\\dots, T\\}\\\\
& \\left(\\sum_{p \\in \\mathcal{P}^{\\text{as}_\\text{dn}}} R^*_{p,t-1} sb_{stc,p,t-1} + p^{st,ch}_{t-1}  - \\sum_{p \\in \\mathcal{P}^{\\text{as}_\\text{up}}} R^*_{p,t-1} sb_{stc,p,t-1}\\right) - \\left(\\sum_{p \\in \\mathcal{P}^{\\text{as}_\\text{dn}}} R^*_{p,t} sb_{stc,p,t} + p^{st,ch}_{t}  - \\sum_{p \\in \\mathcal{P}^{\\text{as}_\\text{up}}} R^*_{p,t} sb_{stc,p,t}\\right) \\ge -z^{st, ch}_{t}, \\forall t \\in \\{2,\\dots, T\\}
\\end{align*}
```
"""
struct StorageRegularizationConstraintCharge <: PSI.ConstraintType end

"""
Struct to specify the auxiliary constraints for regularization terms in the objective function for the discharge variable.
Used when the attribute `regularization = true`.

The specified constraints are formulated as:

```math
\\begin{align*}
& \\left(\\sum_{p \\in \\mathcal{P}^{\\text{as}_\\text{up}}} R^*_{p,t-1} sb_{std,p,t-1} + p^{st,ds}_{t-1} - \\sum_{p \\in \\mathcal{P}^{\\text{as}_\\text{dn}}} R^*_{p,t-1} sb_{std,p,t-1}\\right) -\\left(\\sum_{p \\in \\mathcal{P}^{\\text{as}_\\text{up}}} R^*_{p,t} sb_{std,p,t} + p^{st,ds}_{t} - \\sum_{p \\in \\mathcal{P}^{\\text{as}_\text{dn}}} R^*_{p,t} sb_{std,p,t}\\right) \\le z^{st, ds}_{t}, \\forall t \\in \\{2,\\dots, T\\}\\\\
& \\left(\\sum_{p \\in \\mathcal{P}^{\\text{as}_\\text{up}}} R^*_{p,t-1} sb_{std,p,t-1} + p^{st,ds}_{t-1} - \\sum_{p \\in \\mathcal{P}^{\\text{as}_\\text{dn}}} R^*_{p,t-1} sb_{std,p,t-1}\\right) -\\left(\\sum_{p \\in \\mathcal{P}^{\\text{as}_\\text{up}}} R^*_{p,t} sb_{std,p,t} + p^{st,ds}_{t} - \\sum_{p \\in \\mathcal{P}^{\\text{as}_\text{dn}}} R^*_{p,t} sb_{std,p,t}\\right) \\ge -z^{st, ds}_{t}, \\forall t \\in \\{2,\\dots, T\\}
\\end{align*}
```
"""
struct StorageRegularizationConstraintDischarge <: PSI.ConstraintType end
