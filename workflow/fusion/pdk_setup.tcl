# library dir & path
set PDK_PATH_SETUP            "/pdk/ihp/ihp130"
set IO_LIB_PATH_SETUP	      $PDK_PATH_SETUP/ixc013g2_iocell/db
set STD_LIB_PATH_SETUP        $PDK_PATH_SETUP/ixc013g2ng_stdcell/db
set STD_VERILOG_PATH_SETUP    $PDK_PATH_SETUP/ixc013g2ng_stdcell/verilog/ixc013g2ng_stdcell.v

#set SYN_TECH_DIR	 $SYN_TECH_DIR_SETUP                
set STD_CELL_LIB_DIR     $STD_LIB_PATH_SETUP                
set IO_CELL_LIB_DIR	 $IO_LIB_PATH_SETUP                 

set PRE_LAYOUT_VER_NETLIST  "$PRE_LAYOUT_DIR/${DESIGN}.v"   
set PRE_LAYOUT_DDC_NETLIST  "$PRE_LAYOUT_DIR/${DESIGN}.ddc" 
set SDC_FILE                "$PRE_LAYOUT_DIR/${DESIGN}.sdc" 

set POST_LAYOUT_VER_NETLIST "$POST_LAYOUT_DIR/${DESIGN}_final.v"   
set SPEF_FILE               "$POST_LAYOUT_DIR/${DESIGN}_final.spef"
set SDF_FILE                "$POST_LAYOUT_DIR/${DESIGN}_final.sdf" 

# set ANTENNA_RULE_FILE    "./scripts/antenna_rules.tcl"


# --- NDM reference (gerados por nos no lm_shell) ---
set NDM_SC_LIB   "$LOCAL_LC_DIR/libs/ixc013g2ng_stdcell.ndm"
set NDM_IO_LIB   "$LOCAL_LC_DIR/libs/ixc013g2_iocell.ndm"

# --- tech (o mesmo .tf usado para gerar os NDM) ---
set TECH_FILE    "$LOCAL_PDK_DIR/ixc013g2ng_tech.tf"

# --- parasitics (TLUPlus) ---
# IHP fornece um unico .tlu+ (sem max/min separados); mesmo arquivo nos dois corners.
# Consumido pelo read_parasitic_tech DEPOIS do create_lib (no script de fluxo).
set TLUP_FILE "/pdk/ihp/ihp130/ixc013g2ng_stdcell/lef/tluplus/sg13g2.tlu+"
set TLUP_MAX  $TLUP_FILE
set TLUP_MIN  $TLUP_FILE
# Sem layer map dedicado de RC neste PDK (o .tlu+ traz o mapeamento embutido).

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
 
# --- Layout fisico (streamout final) ---
# IHP fornece o layout em OpenAccess (oa/), NAO em GDS.
#   OA stdcell: /pdk/ihp/ihp130/ixc013g2ng_stdcell/oa/ixc013g2ng_stdcell/
#   tech.db do OA:  .../oa/ixc013g2ng_stdcell/tech.db
# So usado no streamout final (write_gds com merge do OA, ou strmout via Virtuoso).
# Nao bloqueia floorplan/place/cts/route.
set OA_STDCELL_DIR "/pdk/ihp/ihp130/ixc013g2ng_stdcell/oa/ixc013g2ng_stdcell"
# set OA_IOCELL_DIR  "<<< localizar equivalente em ixc013g2_iocell/oa se existir >>>"

