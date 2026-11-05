# ==============================================================================
# auto_iopad.tcl  --  Pad placement on the I/O ring (ICC2)
# RVX / IHP130. Deterministic spacing.
# Requires: initialize_floorplan and create_io_ring already done (02-floorplan).
# ==============================================================================

# ------------------------------------------------------------------------------
# 0. Geometric parameters (measured from the IHP130 library)
# ------------------------------------------------------------------------------
set die_width        2500     ;# must match initialize_floorplan
set corner_pad_size  310      ;# IHP corner size (310x310)
set corner_clearance 100      ;# design clearance after the corner
set pad_width        60       ;# IHP pad width (i16x/b16m = 60)

set exclusion_zone   [expr {$corner_pad_size + $corner_clearance}]
set available_space  [expr {$die_width - (2 * $exclusion_zone)}]

puts "Info: exclusion_zone=$exclusion_zone  available_space=$available_space"

# ------------------------------------------------------------------------------
# 1. Pad order per edge
#    ICC2 direction: left(up) top(->) right(down) bottom(<-)
# ------------------------------------------------------------------------------
set side_pads(left) {
    IOVDD_0
    PAD_CLK PAD_RSTN
    PAD_URX PAD_UTX
    VDD_0 VSS_0
    IOVSS_0
}
set side_pads(top) {
    IOVDD_1
    PAD_SCLK PAD_MOSI PAD_MISO PAD_CS
    IOVSS_1
}
set side_pads(right) {
    IOVDD_2
    PAD_SDA PAD_SCL
    PAD_GPIO_0 PAD_GPIO_1 PAD_GPIO_2 PAD_GPIO_3
    VDD_2 VSS_2
    IOVSS_2
}
set side_pads(bottom) {
    IOVDD_3
    PAD_GPIO_4 PAD_GPIO_5 PAD_GPIO_6 PAD_GPIO_7
    IOVSS_3
}

# ------------------------------------------------------------------------------
# 2. Fixed spacing per edge (integer gap, remainder absorbed by the first gap)
#    Integer division avoids fractional leftovers that no filler cell can cover
#    (the smallest IHP filler is 1um).
# ------------------------------------------------------------------------------
foreach side {left top right bottom} {
    set pads            $side_pads($side)
    set num_pads        [llength $pads]
    set total_pad_width [expr {$num_pads * $pad_width}]
    set gap_space       [expr {$available_space - $total_pad_width}]

    if {$gap_space < 0} {
        puts "WARNING: Edge $side overflows the available space (pads=$total_pad_width > $available_space)"
    }

    if {$num_pads > 1} {
        set gap       [expr {$gap_space / ($num_pads - 1)}]
        set remainder [expr {$gap_space % ($num_pads - 1)}]
    } else {
        set gap       0
        set remainder 0
    }

    puts "Info: Edge $side -> $num_pads pads, gap=$gap um, remainder=$remainder um"

    set c     [list]
    set first 1
    set idx   0
    foreach p $pads {
        if {$first} {
            lappend c $p
            set first 0
        } else {
            incr idx
            if {$idx == 1} {
                lappend c [expr {$gap + $remainder}] $p
            } else {
                lappend c $gap $p
            }
        }
    }

    set_signal_io_constraints -io_guide_object "io_ring.$side" -constraint $c
}

# ------------------------------------------------------------------------------
# 3. Place the pads on the ring
# ------------------------------------------------------------------------------
puts "Info: Running place_io..."
place_io

# ------------------------------------------------------------------------------
# 4. Ring checks
# ------------------------------------------------------------------------------
check_io_placement -overlap all
check_io_placement -signal_constraints

puts "Info: Pad placement completed."




# # ==============================================================================
# # auto_iopad.tcl  --  Pad placement on the I/O ring (ICC2)
# # RVX MUL / IHP130. Deterministic spacing.
# # Requires: initialize_floorplan and create_io_ring already done (02-floorplan).
# # ==============================================================================

# # ------------------------------------------------------------------------------
# # 0. Geometric parameters (measured from the IHP130 library)
# # ------------------------------------------------------------------------------
# set die_width        2500     ;# must match initialize_floorplan
# set corner_pad_size  310      ;# IHP corner size (310x310)
# set corner_clearance 101      ;# design clearance after the corner
# set pad_width        60       ;# IHP pad width (i16x/b16m = 60)

# set exclusion_zone   [expr {$corner_pad_size + $corner_clearance}]
# set available_space  [expr {$die_width - (2 * $exclusion_zone)}]

# puts "Info: exclusion_zone=$exclusion_zone  available_space=$available_space"

# # ------------------------------------------------------------------------------
# # 1. Pad order per edge
# # ------------------------------------------------------------------------------
# set side_pads(left) {
#     IOVDD_0
#     PAD_CLK PAD_RSTN
#     PAD_URX PAD_UTX
#     VDD_0 VSS_0
#     IOVSS_0
# }
# set side_pads(top) {
#     IOVDD_1
#     PAD_SCLK PAD_MOSI PAD_MISO PAD_CS
#     IOVSS_1
# }
# set side_pads(right) {
#     IOVDD_2
#     PAD_SDA PAD_SCL
#     PAD_GPIO_0 PAD_GPIO_1 PAD_GPIO_2 PAD_GPIO_3
#     VDD_2 VSS_2
#     IOVSS_2
# }
# set side_pads(bottom) {
#     IOVDD_3
#     PAD_GPIO_4 PAD_GPIO_5 PAD_GPIO_6 PAD_GPIO_7
#     IOVSS_3
# }
# # ------------------------------------------------------------------------------
# # 2. Fixed spacing per edge (uniform, deterministic gap)
# # ------------------------------------------------------------------------------
# foreach side {left top right bottom} {
#     set pads     $side_pads($side)
#     set num_pads [llength $pads]

#     set total_pad_width [expr {$num_pads * $pad_width}]
#     set gap_space       [expr {$available_space - $total_pad_width}]

#     if {$num_pads > 1} {
#         set gap [expr {int(round(double($gap_space) / ($num_pads - 1)))}]
#     } else {
#         set gap 0
#     }
#     if {$gap_space < 0} {
#         puts "WARNING: Edge $side overflows the available space (pads=$total_pad_width > $available_space)"
#     }
#     puts "Info: Edge $side -> $num_pads pads, gap=$gap um"

#     set c [list]
#     set first 1
#     foreach p $pads {
#         if {$first} {
#             lappend c $p
#             set first 0
#         } else {
#             lappend c $gap $p
#         }
#     }
#     set_signal_io_constraints -io_guide_object "io_ring.$side" -constraint $c
# }

# # ------------------------------------------------------------------------------
# # 3. Place the pads on the ring
# # ------------------------------------------------------------------------------
# puts "Info: Running place_io..."
# place_io

# # ------------------------------------------------------------------------------
# # 4. Ring checks
# # ------------------------------------------------------------------------------
# # check_io_placement -overlap all
# # check_io_placement -signal_constraints
# puts "Info: Pad placement completed."
