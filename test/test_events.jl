@testset "Storage outage" begin
    dates_ts =
        collect(DateTime("2024-01-01T00:00:00"):Hour(1):DateTime("2024-01-02T23:00:00"))
    outage_data = fill!(Vector{Int64}(undef, 48), 0)
    outage_data[10:15] .= 1
    outage_timeseries = TimeArray(dates_ts, outage_data)
    res = _run_fixed_forced_outage_sim_with_timeseries(;
        sys_emulator=build_system(
            PSITestSystems,
            "c_sys5_bat";
            add_single_time_series=true,
            force_build=true,
        ),
        networks=repeat([PSI.CopperPlatePowerModel], 3),
        optimizers=repeat([HiGHS_optimizer], 3),
        outage_status_timeseries=outage_timeseries,
        device_type=EnergyReservoirStorage,
        device_names=["Bat"],
    )
    em = get_emulation_problem_results(res)
    status = read_realized_variable(
        em,
        "AvailableStatusParameter__EnergyReservoirStorage",
        table_format=TableFormat.WIDE,
    )
    apv_out = read_realized_variable(
        em,
        "ActivePowerOutVariable__EnergyReservoirStorage",
        table_format=TableFormat.WIDE,
    )
    apv_in = read_realized_variable(
        em,
        "ActivePowerInVariable__EnergyReservoirStorage",
        table_format=TableFormat.WIDE,
    )
    for (ix, x) in enumerate(outage_data[1:24])
        @test x != Int64(status[!, "Bat"][ix])
        if Int64(status[!, "Bat"][ix]) == 0.0
            @test apv_out[!, "Bat"][ix] == 0.0
            @test apv_in[!, "Bat"][ix] == 0.0
        end
    end
end
