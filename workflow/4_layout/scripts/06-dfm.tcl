# 05-route.tcl (ICC2)

file mkdir $REPORT_DIR

# roteamento completo (global + track + detail)
route_auto

# checagens
redirect -f $REPORT_DIR/route_drc.txt {check_routes}
redirect -f $REPORT_DIR/route_timing_max.txt {report_timing -max_paths 10}
redirect -f $REPORT_DIR/route_timing_min.txt {report_timing -delay_type min -max_paths 10}
redirect -f $REPORT_DIR/route_qor.txt {report_qor}

save_block -as ${TOP_MODULE_NAME}_route
save_lib
