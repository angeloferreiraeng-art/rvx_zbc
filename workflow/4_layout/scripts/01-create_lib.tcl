# 1. Design library (NDM ref libs only)
#create_lib ${TOP_MODULE_NAME}.dlib \
#    -technology $TECH_FILE \
#    -ref_libs [list $NDM_SC_LIB $NDM_IO_LIB]


create_lib ${TOP_MODULE_NAME}.dlib \
    -technology $TECH_FILE \
    -ref_libs [list $NDM_SC_LIB $NDM_IO_LIB \
                    /pdk/ihp/ihp130/ixc013g2_iocell/lef/ixc013g2_iocell_v5p8.lef \
                    /pdk/ihp/ihp130/ixc013g2ng_stdcell/lef/ixc013g2ng_phys.lef]

get_libs
get_lib_cells -quiet *corner*
get_lib_cells -quiet *FEED*


# 2. Parasitics: IHP ships a single .tlu+, used for both late and early
read_parasitic_tech -tlup $TLUP_FILE -name rcTLU

# 3. Post-synthesis netlist
read_verilog $PRE_LAYOUT_VER_NETLIST -top $TOP_MODULE_NAME
link_block

# 4. Mode / corner / scenario
create_mode   func
create_corner slow
create_scenario -mode func -corner slow -name func_slow
current_scenario func_slow

set_parasitic_parameters -late_spec rcTLU -early_spec rcTLU

# 5. Constraints
read_sdc $SDC_FILE

# 6. Save
save_block -as ${TOP_MODULE_NAME}_initial
save_lib
