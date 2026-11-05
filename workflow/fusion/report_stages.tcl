
proc report_stages { stage } {
	global OUT_LIBRARY
	set TIMING_REPORT ""
	set QOR_REPORT ""
	set DRC_REPORT ""
	redirect -f $REPORT_DIR/post_route_drc.txt {check_routes}
	redirect -f $REPORT_DIR/post_route_timing_max.txt {report_timing -max_paths 10}
	redirect -f $REPORT_DIR/post_route_timing_min.txt {report_timing -delay_type min -max_paths 10}
	redirect -f $REPORT_DIR/post_route_qor.txt {report_qor}

}
