# library dir & path
set PDK_ROOT_PATH            "/pdk/ihp/ihp130"
            
set STD_CELL_LIB_DIR     $STD_LIB_PATH_SETUP                
set IO_CELL_LIB_DIR	 $IO_LIB_PATH_SETUP                 

set LOCAL_PDK_DIR "$FLOW_ROOT/_pdk"
set LOCAL_LC_DIR "$FLOW_ROOT/_lc"



# --- NDM reference (gerados por nos no lm_shell) ---
set NDM_SC_LIB   "$LOCAL_LC_DIR/libs/ixc013g2ng_stdcell.ndm"
set NDM_IO_LIB   "$LOCAL_LC_DIR/libs/ixc013g2_iocell.ndm"

set PDK_MAIN_FILES [list ${NDM_SC_LIB} ${NDM_IO_LIB} \
	${PDK_ROOT_PATH}/ixc013g2_iocell/lef/ixc013g2_iocell_v5p8.lef \
	${PDK_ROOT_PATH}/ixc013g2ng_stdcell/lef/ixc013g2ng_phys.lef]

set PDK_CORNER_FILES "* \
        ${STD_LIB_PATH_SETUP}/ixc013g2ng_stdcell_fast_1p32V_m40C.db \
        ${STD_LIB_PATH_SETUP}/ixc013g2ng_stdcell_typ_1p20V_25C.db \
        ${STD_LIB_PATH_SETUP}/ixc013g2ng_stdcell_slow_1p08V_125C.db\
        ${IO_LIB_PATH_SETUP}/ixc013g2_iocell_fast_1p32V_3p6V_m40C.db \
        ${IO_LIB_PATH_SETUP}/ixc013g2_iocell_typ_1p2V_3p3V_25C.db \
        ${IO_LIB_PATH_SETUP}/ixc013g2_iocell_slow_1p08V_3p0V_125C.db"


# --- tech (o mesmo .tf usado para gerar os NDM) ---
set PDK_TECH_FILE    "${LOCAL_PDK_DIR}/ixc013g2ng_tech.tf"

# --- parasitics (TLUPlus) ---
# IHP fornece um unico .tlu+ (sem max/min separados); mesmo arquivo nos dois corners.
# Consumido pelo read_parasitic_tech DEPOIS do create_lib (no script de fluxo).
set TLUP_FILE "${PDK_ROOT_PATH}/ixc013g2ng_stdcell/lef/tluplus/sg13g2.tlu+"
set TLUP_MAX  $TLUP_FILE
set TLUP_MIN  $TLUP_FILE
# Sem layer map dedicado de RC neste PDK (o .tlu+ traz o mapeamento embutido).


# set ANTENNA_RULE_FILE    "./scripts/antenna_rules.tcl"

set PDK_RUNSET_DRC "${PDK_ROOT_PATH}/SG12G2_618_rev1.3.1/Calibre/RunSets/sg13_drc.runset \
			${PDK_ROOT_PATH}/SG12G2_618_rev1.3.1/Calibre/RunSets/sg13_drc.runSetList "

set PDK_RUNSET_DESIGN "${PDK_ROOT_PATH}/SG12G2_618_rev1.3.1/Calibre/RunSets/sg13_lvs.runset \
				${PDK_ROOT_PATH}/SG12G2_618_rev1.3.1/Calibre/RunSets/sg13_xrc.runset \
				${PDK_ROOT_PATH}/SG12G2_618_rev1.3.1/Calibre/RunSets/sg13_fill.runset"


set_app_options -name signoff.check_drc.runset -value $PDK_RUNSET_DRC
set_app_options -name signoff.check_design.runset -value $PDK_RUNSET_DESIGN
# --- Layout fisico (streamout final) ---
# IHP fornece o layout em OpenAccess (oa/), NAO em GDS.
#   OA stdcell: /pdk/ihp/ihp130/ixc013g2ng_stdcell/oa/ixc013g2ng_stdcell/
#   tech.db do OA:  .../oa/ixc013g2ng_stdcell/tech.db
# So usado no streamout final (write_gds com merge do OA, ou strmout via Virtuoso).
# Nao bloqueia floorplan/place/cts/route.
set OA_STDCELL_DIR "${PDK_ROOT_PATH}/ixc013g2ng_stdcell/oa/ixc013g2ng_stdcell"
# set OA_IOCELL_DIR  "<<< localizar equivalente em ixc013g2_iocell/oa se existir >>>"


#NOTE: variables probably not used.
set IO_LIB_PATH_SETUP	      $PDK_ROOT_PATH/ixc013g2_iocell/db
set STD_LIB_PATH_SETUP        $PDK_ROOT_PATH/ixc013g2ng_stdcell/db
set STD_VERILOG_PATH_SETUP    $PDK_ROOT_PATH/ixc013g2ng_stdcell/verilog/ixc013g2ng_stdcell.v
 

#TODO: MOVE THIS TO PAD SETUP
# --- power/ground nets (core + IO ring) ---
# Nomes conforme pinos das celulas do IHP:
#   Pads expoem 4 rails: VDDCORE/VSSCORE (core) e VDDPAD/VSSPAD (io 3.3V)
#   Stdcells expoem VDD/VSS -> mesmo rail de core, mapear para VDDCORE/VSSCORE
set PWR_NET    "VDDCORE"  ;# core power  (stdcell VDD conecta aqui)
set GND_NET    "VSSCORE"  ;# core ground (stdcell VSS conecta aqui)
set IOPWR_NET  "VDDPAD"   ;# io power  (3.3V)
set IOGND_NET  "VSSPAD"   ;# io ground (3.3V)

# pinos PG das stdcells (diferem do nome do rail do pad)
set STD_PWR_PIN "VDD"
set STD_GND_PIN "VSS"

# --- fillers / corner do anel de I/O (confirmados no LEF de I/O) ---
#set PAD_FILLER   "filler10u filler4u filler2u filler1u"
#set PAD_CORNER   "corner"
# I/O corner and fillers come from the LEF (auto lib EXPLORE_physical_only),
# since the lm_shell NDM only holds the 9 cells that have timing models.
set PAD_CORNER "EXPLORE_physical_only/corner"
set PAD_FILLER "filler10u filler4u filler2u filler1u"



# --- fillers / antenna (stdcell) ---
# IHP: FEED* = fillers (feedthrough), do maior para o menor.
#      DECAP* = decoupling caps (opcional, para preencher + desacoplar).
#      ANTENNACELL* = diodos de antena (3 variantes).
set METAL_FILLER "FEED25JI FEED10JI FEED5JI FEED3JI FEED2JI FEED1JI"
set FILLER       "FEED1JI"
set DECAP_CELL   "DECAP25JI DECAP10JI DECAP5JI DECAP3JI"
set ANTENNA_CELL "ANTENNACELLN2JI"
 
# --- fillers / corner do anel de I/O (confirmados no LEF de I/O) ---
set PAD_FILLER   "filler10u filler4u filler2u filler1u"
set PAD_CORNER   "corner"
 

