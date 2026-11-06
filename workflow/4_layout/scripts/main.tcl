
#----------------- Preamble ----------------------------------
set SCRIPT_DIR     [file dirname [file normalize [info script]]]
set PRJ_ROOT_SETUP [file dirname [file dirname $SCRIPT_DIR]]
set FLOW_ROOT_SETUP [file dirname $SCRIPT_DIR]
set LOCAL_PDK_DIR "$PRJ_ROOT_SETUP/_pdk"
set LOCAL_LC_DIR "$PRJ_ROOT_SETUP/_lc"
set OUT_LIBRARY $PRJ_ROOT_SETUP/output/design.dlib
# top design
set TOP_MODULE_NAME "top_pad_rvx"
set DESIGN          "rvx"
# dirs
set PRJ_ROOT        $PRJ_ROOT_SETUP
set FLOW_ROOT       $FLOW_ROOT_SETUP

set SOURCE_DIR  	"$FLOW_ROOT/inp_data/source"           
set REPORT_DIR  	"$FLOW_ROOT/out_data/reports/pnr"   
set PRE_LAYOUT_DIR	"$PRJ_ROOT_SETUP/out_data/pre_layout"    
set POST_LAYOUT_DIR	"$FLOW_ROOT/out_data/post_layout"   

#---------------Basic Set up ----------------------------

source $SCRIPT_DIR/pdk_setup.tcl
source $SCRIPT_DIR/set_context.tcl
#----------------------- Main steps ----------------------------

source $SCRIPT_DIR/floorplan.tcl
source $SCRIPT_DIR/placement.tcl

#source $SCRIPT_DIR/clocks.tcl
#source $SCRIPT_DIR/route.tcl
#source ../scripts/post_route_fix.tcl

source $SCRIPT_DIR/cap_fix.tcl
#--------------------- Reporting and exporting ----------------------------
report_constraints -all_violators
#source ../scripts/07-export.tcl
#start_gui
exit
