set NDM_LIBS {}
set FRAME_LIBS {}
set LEF_FILES {/pdk/ihp/ihp130/ixc013g2_iocell/lef/ixc013g2_iocell_v5p8.lef /pdk/ihp/ihp130/ixc013g2ng_stdcell/lef/ixc013g2ng_phys.lef}
set DB_FILES {}
set TECH_FILE "/home/ciexpert/angelo.ferreira/FASE2/rvx_zbc/workflow/_pdk/ixc013g2ng_tech.tf"

set_app_options -name lib.workspace.create_cached_lib -value true
set_app_options -name lib.workspace.include_design_filters -value {ANTENNACELLN2JI ANTENNACELLNP2JI ANTENNACELLP2JI DECAP10JI DECAP25JI DECAP3JI DECAP5JI FEED10JI FEED1JI FEED25JI FEED2JI FEED3JI FEED5JI corner filler10u filler1u filler2u filler4u gndcore gndpad ixc013_asig ixc013_b16m ixc013_b16mpdn ixc013_b16mpup ixc013_i16x power_cut4u power_cut60u vddcore vddpad}
#suppress_messages

set_app_options -name lib.workspace.allow_read_aggregate_lib -value true
create_workspace EXPLORE_physical_only -flow physical_only -technology $TECH_FILE -scale_factor 10000
read_lef $LEF_FILES
process_workspaces -check_options {-allow_missing} -force -directory CLIBs -output EXPLORE_physical_only.ndm
