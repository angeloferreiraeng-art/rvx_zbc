# 05-route.tcl (ICC2)
file mkdir $REPORT_DIR

# pre-route checks
check_legality
check_pg_connectivity   ;# equivalente ao verify_pg_nets

# via redundante e opções de detail (app_options)
#set_app_options -name route_opt.detail.optimize_wire_via -value true

# antena: em ICC2 é opção do route, hop_layers como no Lucas
set_app_options -name route.detail.antenna -value true

# --- initial route ---
route_auto
redirect -f $REPORT_DIR/initial_route_drc.txt {check_routes}
redirect -f $REPORT_DIR/initial_route_timing_max.txt {report_timing -max_paths 10}
redirect -f $REPORT_DIR/initial_route_qor.txt {report_qor}
save_block -as ${TOP_MODULE_NAME}_initial_route

# --- post route optimization ---
route_opt
redirect -f $REPORT_DIR/post_route_drc.txt {check_routes}
redirect -f $REPORT_DIR/post_route_timing_max.txt {report_timing -max_paths 10}
redirect -f $REPORT_DIR/post_route_timing_min.txt {report_timing -delay_type min -max_paths 10}
redirect -f $REPORT_DIR/post_route_qor.txt {report_qor}
save_block -as ${TOP_MODULE_NAME}_post_route

# --- incremental (hold) ---
# em ICC2 o hold fixing já vem do CCD no route_opt; incremento extra:
#route_opt -from final_opto
#redirect -f $REPORT_DIR/incr_route_timing_min.txt {report_timing -delay_type min -max_paths 10}
#redirect -f $REPORT_DIR/incr_route_qor.txt {report_qor}
save_block -as ${TOP_MODULE_NAME}_route
save_lib


