# 04-cts.tcl (ICC2)

file mkdir $REPORT_DIR

check_clock_tree

remove_clock_uncertainty [all_clocks]

clock_opt

redirect -f $REPORT_DIR/cts_timing_max.txt {report_timing -max_paths 10}
redirect -f $REPORT_DIR/cts_timing_min.txt {report_timing -delay_type min -max_paths 10}
redirect -f $REPORT_DIR/cts_clock_qor.txt  {report_clock_qor}
redirect -f $REPORT_DIR/cts_qor.txt        {report_qor}

save_block -as ${TOP_MODULE_NAME}_cts
save_lib