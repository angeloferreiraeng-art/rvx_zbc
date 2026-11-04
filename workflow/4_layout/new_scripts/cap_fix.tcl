
proc fix_min_cap {forced} {
	global TOP_MODULE_NAME
	global OUT_LIBRARY
	set DESIGN_DECAP ${TOP_MODULE_NAME}_decaped

	if {$forced || [catch {open_block ${OUT_LIBRARY}:${DESIGN_DECAP} }] } {


		# ---- user knobs -------------------------------------------------------------
		set MINCAP_REQ    0.02     ;# required cap from the report (lib units, pF)
		set MINCAP_MARGIN 1.5      ;# buffer pin cap must be >= REQ * MARGIN
		# Pad receiver outputs to fix. Failing in your report: GPIO 0,2,3,4,5 and CLK.
		# GPIO 1,6,7 passed only marginally, so they are included for stability.
		set MINCAP_PADS {PAD_CLK PAD_GPIO_0 PAD_GPIO_1 PAD_GPIO_2 PAD_GPIO_3
			PAD_GPIO_4 PAD_GPIO_5 PAD_GPIO_6 PAD_GPIO_7}

		# ---- pick the smallest buffer whose INPUT pin cap >= REQ*MARGIN --------------
		set need   [expr {$MINCAP_REQ * $MINCAP_MARGIN}]
		set best   ""
		set bestc  1e9
		foreach_in_collection lc [get_lib_cells -filter "is_buffer==true"] {        ;# [CHECK]
			echo "USING BUFFER CELL $lc"
			if {[get_attribute -quiet $lc dont_use] eq "true"} { continue }
			set ipin [get_lib_pins -quiet -of_objects $lc -filter "direction==in"]
			if {[sizeof_collection $ipin] != 1} { continue }
			# [CHECK] attribute may be "capacitance" or "capacitance_max"/"capacitance_min"
			set c [get_attribute -quiet $ipin capacitance]
			if {$c eq ""} { continue }
			if {$c >= $need && $c < $bestc} {
				set best  $lc
				set bestc $c
	    }
		}
		if {$best eq ""} {
			error "mincap_fix: no buffer with input cap >= $need found. Run: \
			list_attributes -application -class lib_pin   to find the right cap attribute."
		}
		set BUF_REF [get_object_name $best]
		# ---- insert one buffer per pad DOUT net -------------------------------------
		set i 0
		foreach pad $MINCAP_PADS {
			set drv [get_pins -quiet $pad/DOUT]
			if {[sizeof_collection $drv] == 0} { puts "mincap_fix: no $pad/DOUT, skipped"; continue }
			insert_buffer $drv $BUF_REF \
			-new_cell_names mincap_buf_$i -new_net_names mincap_net_$i
			incr i
		}
		set_dont_touch [get_cells mincap_buf_*]
		connect_pg_net -automatic
		legalize_placement

		save_block -as ${DESIGN_DECAP}
	}
}
