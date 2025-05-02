# StorageSystemsSimulations.jl

```@meta
CurrentModule = StorageSystemsSimulations
```

## Overview

`StorageSystemsSimulations.jl` is a
[`PowerSimulations.jl`](https://nrel-sienna.github.io/PowerSimulations.jl/stable/)
extension to support formulations and models related to energy storage.

Operational Storage Models can have multiple combinations of different restrictions.
To manage these variations, `StorageSystemsSimulations.jl` relies on the
[`PowerSimulations.DeviceModel`](@extref) attributes feature. Formulations can have varying
implementations for different attributes defined in [`PowerSimulations.DeviceModel`](@extref).

## About Sienna

`StorageSystemsSimulations.jl` is part of the National Renewable Energy Laboratory's
[Sienna ecosystem](https://nrel-sienna.github.io/Sienna/), an open source framework for
power system modeling, simulation, and optimization. The Sienna ecosystem can be
[found on Github](https://github.com/NREL-Sienna/Sienna). It contains three applications:

  - [Sienna\Data](https://nrel-sienna.github.io/Sienna/pages/applications/sienna_data.html) enables
    efficient data input, analysis, and transformation
  - [Sienna\Ops](https://nrel-sienna.github.io/Sienna/pages/applications/sienna_ops.html) enables
    enables system scheduling simulations by formulating and solving optimization problems
  - [Sienna\Dyn](https://nrel-sienna.github.io/Sienna/pages/applications/sienna_dyn.html) enables
    system transient analysis including small signal stability and full system dynamic
    simulations

Each application uses multiple packages in the [`Julia`](http://www.julialang.org)
programming language. `StorageSystemsSimulations.jl` is part of Sienna\Ops.

## Installation and Quick Links

  - [Sienna installation page](https://nrel-sienna.github.io/Sienna/SiennaDocs/docs/build/how-to/install/):
    Instructions to install `StorageSystemsSimulations.jl` and other Sienna\Ops packages
  - [Sienna Documentation Hub](https://nrel-sienna.github.io/Sienna/SiennaDocs/docs/build/index.html):
    Links to other Sienna packages' documentation
