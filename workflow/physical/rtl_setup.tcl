
set SOURCE_DIR  	"$FLOW_ROOT/inp_data/source"           
set REPORT_DIR  	"$FLOW_ROOT/out_data/reports/pnr"   
set PRE_LAYOUT_DIR	"$FLOW_ROOT/out_data/pre_layout"    
set POST_LAYOUT_DIR	"$FLOW_ROOT/out_data/post_layout"   


set PRE_LAYOUT_VER_NETLIST  "$PRE_LAYOUT_DIR/${DESIGN}.v"   
set PRE_LAYOUT_DDC_NETLIST  "$PRE_LAYOUT_DIR/${DESIGN}.ddc" 
set SDC_FILE                "$PRE_LAYOUT_DIR/${DESIGN}.sdc" 

set POST_LAYOUT_VER_NETLIST "$POST_LAYOUT_DIR/${DESIGN}_final.v"   
set SPEF_FILE               "$POST_LAYOUT_DIR/${DESIGN}_final.spef"
set SDF_FILE                "$POST_LAYOUT_DIR/${DESIGN}_final.sdf" 


