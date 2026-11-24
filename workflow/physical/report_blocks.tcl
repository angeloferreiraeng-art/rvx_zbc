# Open the file in append mode ("a"); if it doesn't exist, it will be created
set TIMING_REPORT [open "timing_report.log" a]
set QOR_REPORT [open "qor_report.log" a]
set POWER_REPORT [open "power_report.log" a]
set DRC_REPORT [open "drc_report.log" a]


# Get all blocks and iterate
foreach_in_collection blk [get_blocks] {
    set blk_name [get_attribute $blk full_name]
    
    # Switch the current block context (modify according to the actual command; commonly current_block or open_block)
    current_block $blk_name

	echo "WRITING FOR BLOCK ${blk_name}"    
    # Write the block name as a separator to the file
    puts $TIMING_REPORT "=========================================="
    puts $TIMING_REPORT "Block: $blk_name"
    puts $TIMING_REPORT "=========================================="
    report_timing >> $TIMING_REPORT

    puts $QOR_REPORT "=========================================="
    puts $QOR_REPORT "Block: $blk_name"
    puts $QOR_REPORT "=========================================="
    report_qor >> $QOR_REPORT 
    
    puts $POWER_REPORT "=========================================="
    puts $POWER_REPORT "Block: $blk_name"
    puts $POWER_REPORT "=========================================="
    report_power >> $POWER_REPORT 
    
    puts $DRC_REPORT "=========================================="
    puts $DRC_REPORT "Block: $blk_name"
    puts $DRC_REPORT "=========================================="
     report_constraints -all_violators >> $DRC_REPORT 

}



close $TIMING_REPORT
close $POWER_REPORT
close $QOR_REPORT
close $DRC_REPORT
