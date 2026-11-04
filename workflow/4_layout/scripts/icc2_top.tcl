source ../../_setup/setup.tcl
source ../scripts/icc2_setup.tcl
source ../scripts/01-create_lib.tcl
source ../scripts/02-floorplan.tcl
echo "FLOORPLAN IS GO"
source ../scripts/03-placement.tcl
echo "PLACEMENT IS GO"

source ../scripts/quickfix1.tcl
source ../scripts/04-cts.tcl
echo "CTS IS GO"
source ../scripts/05-route.tcl
echo "ROUTING IS GO"
#source ../scripts/post_route_fix.tcl
report_constraints -all_violators
#source ../scripts/07-export.tcl
#start_gui
exit
