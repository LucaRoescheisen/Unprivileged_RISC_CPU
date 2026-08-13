open_project ./vivado/un_risc5.xpr

# Always reset failed runs
reset_run impl_1

# Set more aggressive implementation directives before launching
set_property STEPS.OPT_DESIGN.ARGS.DIRECTIVE Explore [get_runs impl_1]
set_property STEPS.PLACE_DESIGN.ARGS.DIRECTIVE Explore [get_runs impl_1]
set_property STEPS.PHYS_OPT_DESIGN.IS_ENABLED true [get_runs impl_1]
set_property STEPS.PHYS_OPT_DESIGN.ARGS.DIRECTIVE AggressiveExplore [get_runs impl_1]
set_property STEPS.ROUTE_DESIGN.ARGS.DIRECTIVE Explore [get_runs impl_1]

# Launch implementation through bitstream
launch_runs impl_1 -to_step write_bitstream -jobs 8 -verbose
wait_on_run impl_1
open_run impl_1

# Reports (post-implementation)
report_timing_summary -file ./vivado/reports/impl/impl_timing_rpt.txt
report_utilization      -file ./vivado/reports/impl/impl_util_rpt.txt
report_clock_utilization -file ./vivado/reports/impl/impl_clk_rpt.txt
report_drc              -file ./vivado/reports/drc/impl_drc.rpt