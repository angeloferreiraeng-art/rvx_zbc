# 03-placement.tcl (ICC2)

file mkdir $REPORT_DIR


set DESIGN_PLACEMENT ${TOP_MODULE_NAME}_placement

proc mk_placement {forced} {
	global TOP_MODULE_NAME
	global OUT_LIBRARY
	set DESIGN_PLACEMENT ${TOP_MODULE_NAME}_placement

	if {$forced || [catch {open_block ${OUT_LIBRARY}:${DESIGN_PLACEMENT} }] } {

		# pre-placement checks
		#redirect -f $REPORT_DIR/pre_place_check.txt {check_design -checks pre_place}
		#redirect -f $REPORT_DIR/pre_place_check.txt {check_design -checks pre_placement_stage}

		# app options de placement
		set_app_options -name place.coarse.continue_on_missing_scandef -value true
		#set_app_options -name place_opt.flow.optimize_dft -value false

		set_app_options -name compile.auto_floorplan.optimize_small_design -value true


		#create_bound -name center_bound -type soft -boudary {{650 650} {1850 1850}} [get_cells u_core/*]
		#set_auto_floorplan_constraints
		# placement + optimização (comando forte do ICC2)
		place_opt

		# reports
		#redirect -f $REPORT_DIR/place_opt_timing_max.txt {report_timing -max_paths 10}
		#redirect -f $REPORT_DIR/place_opt_timing_min.txt {report_timing -delay_type min -max_paths 10}
		#redirect -f $REPORT_DIR/place_opt_qor.txt        {report_qor}
		#redirect -f $REPORT_DIR/place_opt_power.txt      {report_power}
		#redirect -f $REPORT_DIR/place_opt_congestion.txt {report_congestion}
		#redirect -f $REPORT_DIR/place_opt_utilization.txt {report_utilization}

		#save_block -as ${TOP_MODULE_NAME}_place_opt

		# hold fix incremental
		#set_fix_hold [all_clocks]
		#optimize_placement -incremental

		# reports pós-incremental
		#redirect -f $REPORT_DIR/place_inc_timing_max.txt {report_timing -max_paths 10}
		#redirect -f $REPORT_DIR/place_inc_timing_min.txt {report_timing -delay_type min -max_paths 10}
		#redirect -f $REPORT_DIR/place_inc_qor.txt        {report_qor}

		save_block -as ${DESIGN_PLACEMENT}
		save_lib
	}
}

