@testset "Storage Basic Storage With DC - PF" begin
    device_model = DeviceModel(
        EnergyReservoirStorage,
        StorageDispatchWithReserves;
        attributes = Dict{String, Any}(
            "reservation" => false,
            "cycling_limits" => false,
            "energy_target" => false,
            "complete_coverage" => false,
            "regularization" => false,
        ),
    )
    c_sys5_bat = PSB.build_system(PSITestSystems, "c_sys5_bat")
    model = DecisionModel(MockOperationProblem, DCPPowerModel, c_sys5_bat)
    mock_construct_device!(model, device_model)
    moi_tests(model, 72, 0, 72, 72, 24, false)
    psi_checkobjfun_test(model, GAEVF)
    model = DecisionModel(MockOperationProblem, DCPPowerModel, c_sys5_bat)
    mock_construct_device!(model, device_model; add_event_model = true)
    moi_tests(model, 72, 0, 120, 72, 24, false)
end

@testset "Storage Basic Storage With AC - PF" begin
    device_model = DeviceModel(
        EnergyReservoirStorage,
        StorageDispatchWithReserves;
        attributes = Dict{String, Any}(
            "reservation" => false,
            "cycling_limits" => false,
            "energy_target" => false,
            "complete_coverage" => false,
            "regularization" => false,
        ),
    )
    c_sys5_bat = PSB.build_system(PSITestSystems, "c_sys5_bat")
    model = DecisionModel(MockOperationProblem, ACPPowerModel, c_sys5_bat)
    mock_construct_device!(model, device_model)
    moi_tests(model, 96, 0, 96, 96, 24, false)
    psi_checkobjfun_test(model, GAEVF)
    model = DecisionModel(MockOperationProblem, ACPPowerModel, c_sys5_bat)
    mock_construct_device!(model, device_model; add_event_model = true)
    moi_tests(model, 96, 0, 144, 96, 24, false)
    # Outage constraint for reactive power is quadratic: 
    @test JuMP.num_constraints(PSI.get_jump_model(model), GQEVF, MOI.LessThan{Float64}) ==
          24
end

@testset "Storage with Reservation  & DC - PF" begin
    device_model = DeviceModel(EnergyReservoirStorage, StorageDispatchWithReserves)
    c_sys5_bat = PSB.build_system(PSITestSystems, "c_sys5_bat")
    model = DecisionModel(MockOperationProblem, DCPPowerModel, c_sys5_bat)
    mock_construct_device!(model, device_model)
    moi_tests(model, 96, 0, 72, 72, 24, true)
    psi_checkobjfun_test(model, GAEVF)
    model = DecisionModel(MockOperationProblem, DCPPowerModel, c_sys5_bat)
    mock_construct_device!(model, device_model; add_event_model = true)
    moi_tests(model, 96, 0, 120, 72, 24, true)
end

@testset "Storage with Reservation  & AC - PF" begin
    device_model = DeviceModel(EnergyReservoirStorage, StorageDispatchWithReserves)
    c_sys5_bat = PSB.build_system(PSITestSystems, "c_sys5_bat")
    model = DecisionModel(MockOperationProblem, ACPPowerModel, c_sys5_bat)
    mock_construct_device!(model, device_model)
    moi_tests(model, 120, 0, 96, 96, 24, true)
    psi_checkobjfun_test(model, GAEVF)
    model = DecisionModel(MockOperationProblem, ACPPowerModel, c_sys5_bat)
    mock_construct_device!(model, device_model; add_event_model = true)
    moi_tests(model, 120, 0, 144, 96, 24, true)
    # Outage constraint for reactive power is quadratic: 
    @test JuMP.num_constraints(PSI.get_jump_model(model), GQEVF, MOI.LessThan{Float64}) ==
          24
end

@testset "EnergyReservoirStorage with EnergyTarget with DC - PF" begin
    device_model = DeviceModel(
        EnergyReservoirStorage,
        StorageDispatchWithReserves;
        attributes = Dict{String, Any}(
            "reservation" => true,
            "cycling_limits" => false,
            "energy_target" => true,
            "complete_coverage" => false,
            "regularization" => false,
        ),
    )
    c_sys5_bat = PSB.build_system(PSITestSystems, "c_sys5_bat_ems")
    model = DecisionModel(MockOperationProblem, DCPPowerModel, c_sys5_bat)
    mock_construct_device!(model, device_model)
    moi_tests(model, 98, 0, 72, 72, 25, true)
    psi_checkobjfun_test(model, GAEVF)
    model = DecisionModel(MockOperationProblem, DCPPowerModel, c_sys5_bat)
    mock_construct_device!(model, device_model; add_event_model = true)
    moi_tests(model, 98, 0, 120, 72, 25, true)

    device_model = DeviceModel(
        EnergyReservoirStorage,
        StorageDispatchWithReserves;
        attributes = Dict{String, Any}(
            "reservation" => false,
            "cycling_limits" => false,
            "energy_target" => true,
            "complete_coverage" => false,
            "regularization" => false,
        ),
    )
    model = DecisionModel(MockOperationProblem, DCPPowerModel, c_sys5_bat)
    mock_construct_device!(model, device_model)
    moi_tests(model, 74, 0, 72, 72, 25, false)
    psi_checkobjfun_test(model, GAEVF)
    model = DecisionModel(MockOperationProblem, DCPPowerModel, c_sys5_bat)
    mock_construct_device!(model, device_model; add_event_model = true)
    moi_tests(model, 74, 0, 120, 72, 25, false)
end

@testset "EnergyReservoirStorage with EnergyTarget With AC - PF" begin
    device_model = DeviceModel(
        EnergyReservoirStorage,
        StorageDispatchWithReserves;
        attributes = Dict{String, Any}(
            "reservation" => true,
            "cycling_limits" => false,
            "energy_target" => true,
            "complete_coverage" => false,
            "regularization" => false,
        ),
    )
    c_sys5_bat = PSB.build_system(PSITestSystems, "c_sys5_bat_ems")
    model = DecisionModel(MockOperationProblem, ACPPowerModel, c_sys5_bat)
    mock_construct_device!(model, device_model)
    moi_tests(model, 122, 0, 96, 96, 25, true)
    psi_checkobjfun_test(model, GAEVF)
    model = DecisionModel(MockOperationProblem, ACPPowerModel, c_sys5_bat)
    mock_construct_device!(model, device_model; add_event_model = true)
    moi_tests(model, 122, 0, 144, 96, 25, true)

    device_model = DeviceModel(
        EnergyReservoirStorage,
        StorageDispatchWithReserves;
        attributes = Dict{String, Any}(
            "reservation" => false,
            "cycling_limits" => false,
            "energy_target" => true,
            "complete_coverage" => false,
            "regularization" => false,
        ),
    )
    c_sys5_bat = PSB.build_system(PSITestSystems, "c_sys5_bat_ems")
    model = DecisionModel(MockOperationProblem, ACPPowerModel, c_sys5_bat)
    mock_construct_device!(model, device_model)
    moi_tests(model, 98, 0, 96, 96, 25, false)
    psi_checkobjfun_test(model, GAEVF)
    model = DecisionModel(MockOperationProblem, ACPPowerModel, c_sys5_bat)
    mock_construct_device!(model, device_model; add_event_model = true)
    moi_tests(model, 98, 0, 144, 96, 25, false)
    # Outage constraint for reactive power is quadratic: 
    @test JuMP.num_constraints(PSI.get_jump_model(model), GQEVF, MOI.LessThan{Float64}) ==
          24
end

### Feedforward Test ###
# TODO: Feedforward debugging
@testset "Test EnergyTargetFeedforward to EnergyReservoirStorage with StorageDispatch model" begin
    device_model = DeviceModel(
        EnergyReservoirStorage,
        StorageDispatchWithReserves;
        attributes = Dict{String, Any}(
            "reservation" => true,
            "cycling_limits" => false,
            "energy_target" => false,
            "complete_coverage" => false,
            "regularization" => false,
        ),
    )

    ff_et = EnergyTargetFeedforward(;
        component_type=EnergyReservoirStorage,
        source=EnergyVariable,
        affected_values=[EnergyVariable],
        target_period=24,
        penalty_cost=1e5,
    )

    PSI.attach_feedforward!(device_model, ff_et)
    sys = PSB.build_system(PSITestSystems, "c_sys5_bat")
    model = DecisionModel(MockOperationProblem, DCPPowerModel, sys)
    mock_construct_device!(model, device_model; built_for_recurrent_solves = true)
    moi_tests(model, 122, 0, 72, 73, 24, true)
    model = DecisionModel(MockOperationProblem, DCPPowerModel, sys)
    mock_construct_device!(
        model,
        device_model;
        built_for_recurrent_solves = true,
        add_event_model = true,
    )
    moi_tests(model, 170, 0, 120, 73, 24, true)
end

@testset "Test EnergyTargetFeedforward to EnergyReservoirStorage with StorageDispatch model" begin
    device_model = DeviceModel(
        EnergyReservoirStorage,
        StorageDispatchWithReserves;
        attributes = Dict{String, Any}(
            "reservation" => true,
            "cycling_limits" => false,
            "energy_target" => false,
            "complete_coverage" => false,
            "regularization" => false,
        ),
    )

    ff_et = EnergyTargetFeedforward(;
        component_type=EnergyReservoirStorage,
        source=EnergyVariable,
        affected_values=[EnergyVariable],
        target_period=24,
        penalty_cost=1e5,
    )

    PSI.attach_feedforward!(device_model, ff_et)
    sys = PSB.build_system(PSITestSystems, "c_sys5_bat_ems")
    model = DecisionModel(MockOperationProblem, DCPPowerModel, sys)
    mock_construct_device!(model, device_model; built_for_recurrent_solves = true)
    moi_tests(model, 122, 0, 72, 73, 24, true)
    model = DecisionModel(MockOperationProblem, DCPPowerModel, sys)
    mock_construct_device!(
        model,
        device_model;
        built_for_recurrent_solves = true,
        add_event_model = true,
    )
    moi_tests(model, 170, 0, 120, 73, 24, true)
end

@testset "Test Reserves from Storage" begin
    template = get_thermal_dispatch_template_network(CopperPlatePowerModel)
    device_model = DeviceModel(
        EnergyReservoirStorage,
        StorageDispatchWithReserves;
        attributes = Dict{String, Any}(
            "reservation" => true,
            "cycling_limits" => false,
            "energy_target" => true,
            "complete_coverage" => true,
            "regularization" => true,
        ),
    )
    set_device_model!(template, device_model)
    set_device_model!(template, RenewableDispatch, FixedOutput)
    set_service_model!(
        template,
        ServiceModel(VariableReserve{ReserveUp}, RangeReserve, "Reserve3"),
    )
    set_service_model!(
        template,
        ServiceModel(VariableReserve{ReserveDown}, RangeReserve, "Reserve4"),
    )

    c_sys5_bat = PSB.build_system(PSITestSystems, "c_sys5_bat"; add_reserves = true)
    model = DecisionModel(template, c_sys5_bat)
    @test build!(model; output_dir = mktempdir(; cleanup = true)) ==
          PSI.ModelBuildStatus.BUILT
    moi_tests(model, 458, 0, 574, 286, 125, true)

    device_model = DeviceModel(
        EnergyReservoirStorage,
        StorageDispatchWithReserves;
        attributes = Dict{String, Any}(
            "reservation" => false,
            "cycling_limits" => false,
            "energy_target" => true,
            "complete_coverage" => true,
            "regularization" => true,
        ),
    )
    set_device_model!(template, device_model)
    model = DecisionModel(template, c_sys5_bat)
    @test build!(model; output_dir = mktempdir(; cleanup = true)) ==
          PSI.ModelBuildStatus.BUILT
    moi_tests(model, 434, 0, 574, 286, 125, false)
end

@testset "Test AreaPTDF System Balance" begin
    sys = build_system(PSISystems, "two_area_pjm_DA")
    transform_single_time_series!(sys, Hour(2), Hour(2))
    bat = EnergyReservoirStorage(;
        name = "bat",
        available = true,
        bus = get_bus(sys, 11),
        prime_mover_type = PrimeMovers.BA,
        storage_technology_type = StorageTech.OTHER_CHEM,
        storage_capacity = 4.0,
        storage_level_limits = (min = 0.0, max = 1.0),
        initial_storage_capacity_level = 0.5,
        rating = 4.0,
        active_power = 4.0,
        input_active_power_limits = (min = 0.0, max = 2.0),
        output_active_power_limits = (min = 0.0, max = 2.0),
        efficiency = (in = 0.9, out = 0.9),
        reactive_power = 0.0,
        reactive_power_limits = (min = -2.0, max = 2.0),
        base_power = 100.0,
    )
    add_component!(sys, bat)

    template = get_thermal_dispatch_template_network(AreaPTDFPowerModel)
    device_model = DeviceModel(
        EnergyReservoirStorage,
        StorageDispatchWithReserves;
        attributes = Dict{String, Any}(
            "reservation" => true,
            "cycling_limits" => false,
            "energy_target" => true,
            "complete_coverage" => false,
            "regularization" => true,
        ),
    )
    set_device_model!(template, device_model)
    set_device_model!(template, RenewableDispatch, RenewableFullDispatch)

    model = DecisionModel(template, sys)
    @test build!(model; output_dir = mktempdir(; cleanup = true)) ==
          PSI.ModelBuildStatus.BUILT
    moi_tests(model, 40, 0, 56, 52, 13, true)
end

#=
@testset "Test EnergyLimitFeedforward to EnergyReservoirStorage with BookKeeping model" begin
    device_model = DeviceModel(EnergyReservoirStorage, BookKeeping)

    ff_il = EnergyLimitFeedforward(;
        component_type=EnergyReservoirStorage,
        source=ActivePowerOutVariable,
        affected_values=[ActivePowerOutVariable],
        number_of_periods=12,
    )

    PSI.attach_feedforward!(device_model, ff_il)
    sys = PSB.build_system(PSITestSystems, "c_sys5_bat")
    model = DecisionModel(MockOperationProblem, DCPPowerModel, sys)
    mock_construct_device!(model, device_model; built_for_recurrent_solves=true)
    moi_tests(model, 121, 0, 74, 72, 24, true)
end

@testset "Test EnergyLimitFeedforward to EnergyReservoirStorage with BatteryAncillaryServices model" begin
    device_model = DeviceModel(EnergyReservoirStorage, BatteryAncillaryServices)

    ff_il = EnergyLimitFeedforward(;
        component_type=EnergyReservoirStorage,
        source=ActivePowerOutVariable,
        affected_values=[ActivePowerOutVariable],
        number_of_periods=12,
    )

    PSI.attach_feedforward!(device_model, ff_il)
    sys = PSB.build_system(PSITestSystems, "c_sys5_bat")
    model = DecisionModel(MockOperationProblem, DCPPowerModel, sys)
    mock_construct_device!(model, device_model; built_for_recurrent_solves=true)
    moi_tests(model, 121, 0, 74, 72, 24, true)
end
=#
