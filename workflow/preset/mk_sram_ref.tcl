# ============================================================
# IHP SG13G2 SRAM NDM Compilation Script
# ===========================================================
set ROOT_PATH [file normalize ../..]
set PDK_ROOT        "${ROOT_PATH}/ihp130/ihp-sg13g2"
set SRAM_DIR        "$PDK_ROOT/libs.ref/sg13g2_sram"
set TECH_LEF        "$PDK_ROOT/libs.ref/sg13g2_stdcell/lef/sg13g2_tech.lef"
set MACRO_PATH       "$SRAM_DIR/lef"
set LIB_PATH "$SRAM_DIR/lib"

# 2. Liberty file paths (modify file names according to actual directory)
set LIB_TYP         "_typ_1p20V_25C.lib"
set LIB_SLOW        "_slow_1p08V_125C.lib"
set LIB_FAST        "_fast_1p32V_m55C.lib"

set OUTPUT_NDM      "./sg13g2_sram_mc.ndm"
set LIB_NAME sram

set MEM_MACROS {"RM_IHPSG13_1P_1024x16_c2_bm_bist"\
		"RM_IHPSG13_1P_1024x32_c2_bm_bist"\
		"RM_IHPSG13_1P_1024x64_c2_bm_bist"\
		"RM_IHPSG13_1P_1024x8_c2_bm_bist"\
		"RM_IHPSG13_1P_2048x32_c2_bm_bist"\
		"RM_IHPSG13_1P_2048x64_c2_bm_bist"\
		"RM_IHPSG13_1P_256x16_c2_bm_bist"\
		"RM_IHPSG13_1P_256x32_c2_bm_bist"\
		"RM_IHPSG13_1P_256x48_c2_bm_bist"\
		"RM_IHPSG13_1P_256x64_c2_bm_bist"\
		"RM_IHPSG13_1P_256x8_c3_bm_bist"\
		"RM_IHPSG13_1P_4096x16_c3_bm_bist"\
		"RM_IHPSG13_1P_4096x8_c3_bm_bist"\
		"RM_IHPSG13_1P_512x16_c2_bm_bist"\
		"RM_IHPSG13_1P_512x32_c2_bm_bist"\
		"RM_IHPSG13_1P_512x64_c2_bm_bist"\
		"RM_IHPSG13_1P_512x8_c3_bm_bist"\
		"RM_IHPSG13_1P_64x16_c2"\
		"RM_IHPSG13_1P_64x64_c2_bm_bist"\
		"RM_IHPSG13_1P_8192x32_c4"\
		"RM_IHPSG13_2P_1024x16_c2_bm_bist"\
		"RM_IHPSG13_2P_1024x32_c2_bm_bist"\
		"RM_IHPSG13_2P_256x16_c2_bm_bist"\
		"RM_IHPSG13_2P_256x32_c2_bm_bist"\
		"RM_IHPSG13_2P_256x8_c2_bm_bist"\
		"RM_IHPSG13_2P_512x16_c2_bm_bist"\
		"RM_IHPSG13_2P_512x32_c2_bm_bist"\
		"RM_IHPSG13_2P_512x8_c2_bm_bist"\
		"RM_IHPSG13_2P_64x22_c2_bm_bist"\
		"RM_IHPSG13_2P_64x32_c2"\

}

# ----------------------------- workspace --------------------------------------
# Technology comes from the tech LEF (no .tf), so read it first.
create_workspace -flow exploration $LIB_NAME
 
read_lef  $TECH_LEF            

foreach m $MEM_MACROS {
    read_lef  $MACRO_PATH/$m.lef            ;# macro abstract (CLASS BLOCK
	read_lib ${LIB_PATH}/${m}${LIB_TYP}
	read_lib ${LIB_PATH}/${m}${$LIB_SLOW}
	read_lib ${LIB_PATH}/${m}${$LIB_FAST}

}
exit
 
# ----------------------------- check & commit ---------------------------------
check_workspace                           ;# LEF <-> Liberty consistency
commit_workspace -output $OUTPUT_NDM
 
exit


