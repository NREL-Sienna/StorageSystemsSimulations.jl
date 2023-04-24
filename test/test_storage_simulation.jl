@testset "Decision Model initial_conditions test for Storage" begin
    ######## Test with BookKeeping ########
    template = get_thermal_dispatch_template_network()
    c_sys5_bat = PSB.build_system(PSITestSystems, "c_sys5_bat"; force_build = true)
    set_device_model!(template, GenericBattery, BookKeeping)
    model = DecisionModel(template, c_sys5_bat; optimizer = HiGHS_optimizer)
    @test build!(model; output_dir = mktempdir(; cleanup = true)) == BuildStatus.BUILT
    check_energy_initial_conditions_values(model, GenericBattery)
    @test solve!(model) == RunStatus.SUCCESSFUL

    ######## Test with BatteryAncillaryServices ########
    template = get_thermal_dispatch_template_network()
    c_sys5_bat = PSB.build_system(PSITestSystems, "c_sys5_bat"; force_build = true)
    set_device_model!(template, GenericBattery, BatteryAncillaryServices)
    model = DecisionModel(template, c_sys5_bat; optimizer = HiGHS_optimizer)
    @test build!(model; output_dir = mktempdir(; cleanup = true)) == BuildStatus.BUILT
    check_energy_initial_conditions_values(model, GenericBattery)
    @test solve!(model) == RunStatus.SUCCESSFUL

    ######## Test with EnergyTarget ########
    template = get_thermal_dispatch_template_network()
    c_sys5_bat = PSB.build_system(PSITestSystems, "c_sys5_bat_ems"; force_build = true)
    set_device_model!(template, BatteryEMS, EnergyTarget)
    model = DecisionModel(template, c_sys5_bat; optimizer = HiGHS_optimizer)
    @test build!(model; output_dir = mktempdir(; cleanup = true)) == BuildStatus.BUILT
    check_energy_initial_conditions_values(model, BatteryEMS)
    @test solve!(model) == RunStatus.SUCCESSFUL
end

@testset "Emulation Model initial_conditions test for Storage" begin
    ######## Test with BookKeeping ########
    template = get_thermal_dispatch_template_network()
    c_sys5_bat = PSB.build_system(
        PSITestSystems,
        "c_sys5_bat";
        add_single_time_series = true,
        force_build = true,
    )
    set_device_model!(template, GenericBattery, BookKeeping)
    model = EmulationModel(template, c_sys5_bat; optimizer = HiGHS_optimizer)
    @test build!(model; executions = 10, output_dir = mktempdir(; cleanup = true)) ==
          BuildStatus.BUILT
    ic_data = PSI.get_initial_condition(
        PSI.get_optimization_container(model),
        InitialEnergyLevel(),
        GenericBattery,
    )
    for ic in ic_data
        name = PSY.get_name(ic.component)
        e_var = PSI.jump_value(PSI.get_value(ic))
        @test PSY.get_initial_energy(ic.component) == e_var
    end
    @test run!(model) == RunStatus.SUCCESSFUL

    ######## Test with BatteryAncillaryServices ########
    template = get_thermal_dispatch_template_network()
    c_sys5_bat = PSB.build_system(
        PSITestSystems,
        "c_sys5_bat";
        add_single_time_series = true,
        force_build = true,
    )
    set_device_model!(template, GenericBattery, BatteryAncillaryServices)
    model = EmulationModel(template, c_sys5_bat; optimizer = HiGHS_optimizer)
    @test build!(model; executions = 10, output_dir = mktempdir(; cleanup = true)) ==
          BuildStatus.BUILT
    ic_data = PSI.get_initial_condition(
        PSI.get_optimization_container(model),
        InitialEnergyLevel(),
        GenericBattery,
    )
    for ic in ic_data
        name = PSY.get_name(ic.component)
        e_var = PSI.jump_value(PSI.get_value(ic))
        @test PSY.get_initial_energy(ic.component) == e_var
    end
    @test run!(model) == RunStatus.SUCCESSFUL

    ######## Test with EnergyTarget ########
    template = get_thermal_dispatch_template_network()
    c_sys5_bat = PSB.build_system(
        PSITestSystems,
        "c_sys5_bat_ems";
        add_single_time_series = true,
        force_build = true,
    )
    set_device_model!(template, BatteryEMS, EnergyTarget)
    model = EmulationModel(template, c_sys5_bat; optimizer = HiGHS_optimizer)
    @test build!(model; executions = 10, output_dir = mktempdir(; cleanup = true)) ==
          BuildStatus.BUILT
    ic_data = PSI.get_initial_condition(
        PSI.get_optimization_container(model),
        InitialEnergyLevel(),
        BatteryEMS,
    )
    for ic in ic_data
        name = PSY.get_name(ic.component)
        e_var = PSI.jump_value(PSI.get_value(ic))
        @test PSY.get_initial_energy(ic.component) == e_var
    end
    @test run!(model) == RunStatus.SUCCESSFUL
end
