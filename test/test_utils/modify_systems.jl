function modify_ren_curtailment_cost!(sys)
    rdispatch = get_components(RenewableDispatch, sys)
    for ren in rdispatch
        # We consider 15 $/MWh as a reasonable cost for renewable curtailment
        cost = TwoPartCost(15.0, 0.0)
        set_operation_cost!(ren, cost)
    end
    return
end

function _build_battery(
    bus::PSY.Bus,
    energy_capacity,
    rating,
    efficiency_in,
    efficiency_out,
)
    name = string(bus.number) * "_BATTERY"
    device = EnergyReservoirStorage(;
        name=name,
        available=true,
        bus=bus,
        prime_mover_type=PSY.PrimeMovers.BA,
        initial_energy=0.2,
        state_of_charge_limits=(min=energy_capacity * 0.0, max=energy_capacity),
        rating=rating,
        active_power=rating,
        cycle_limits=1000.0,
        storage_target=1.0,
        input_active_power_limits=(min=0.0, max=rating),
        output_active_power_limits=(min=0.0, max=rating),
        efficiency=(in=efficiency_in, out=efficiency_out),
        reactive_power=0.0,
        reactive_power_limits=nothing,
        base_power=100.0,
        operation_cost=PSY.StorageCost(
            energy_shortage_cost=1000.0,
            energy_surplus_cost=1000.0,
            fixed=0.0,
            shut_down=0.0,
            start_up=0.0,
            variable=VariableCost(3.0),
        ),
    )
    return device
end

function add_battery_to_bus!(sys::System, bus_name::String)
    bus = get_component(Bus, sys, bus_name)
    bat = _build_battery(bus, 8.0, 4.0, 0.93, 0.93)
    add_component!(sys, bat)
    for s in get_components(Reserve, sys)
        add_service!(bat, s, sys)
    end
    return
end
