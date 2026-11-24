# 1. Design library (NDM ref libs only)
#create_lib ${TOP_MODULE_NAME}.dlib \
#    -technology $TECH_FILE \
#    -ref_libs [list $NDM_SC_LIB $NDM_IO_LIB]

#try opening lib, creates new if emptyi

set DESIGN_INITIAL ${TOP_MODULE_NAME}_initial

if { [catch {open_lib $OUT_LIBRARY }] } {
	create_lib $OUT_LIBRARY \
	-technology $TECH_FILE \
	-ref_libs [list $NDM_SC_LIB $NDM_IO_LIB \
	/pdk/ihp/ihp130/ixc013g2_iocell/lef/ixc013g2_iocell_v5p8.lef \
	/pdk/ihp/ihp130/ixc013g2ng_stdcell/lef/ixc013g2ng_phys.lef]

	    set link_library "* \
        ${STD_LIB_PATH_SETUP}/ixc013g2ng_stdcell_fast_1p32V_m40C.db \
        ${STD_LIB_PATH_SETUP}/ixc013g2ng_stdcell_typ_1p20V_25C.db \
        ${STD_LIB_PATH_SETUP}/ixc013g2ng_stdcell_slow_1p08V_125C.db\
        ${IO_LIB_PATH_SETUP}/ixc013g2_iocell_fast_1p32V_3p6V_m40C.db \
        ${IO_LIB_PATH_SETUP}/ixc013g2_iocell_typ_1p2V_3p3V_25C.db \
        ${IO_LIB_PATH_SETUP}/ixc013g2_iocell_slow_1p08V_3p0V_125C.db"
	
	get_libs
	get_lib_cells -quiet *corner*
	get_lib_cells -quiet *FEED*


	# 2. Parasitics: IHP ships a single .tlu+, used for both late and early
	read_parasitic_tech -tlup $TLUP_FILE -name rcTLU

	# 3. Post-synthesis netlist
	read_verilog $PRE_LAYOUT_VER_NETLIST -top $TOP_MODULE_NAME
	link_block

	#set_parasitic_parameters -late_spec rcTLU -early_spec rcTLU

	# 5. Constraints
	read_sdc $SDC_FILE

	# 6. Save
	save_block -as ${DESIGN_INITIAL}
	save_lib
}
open_block ${OUT_LIBRARY}:${DESIGN_INITIAL}
