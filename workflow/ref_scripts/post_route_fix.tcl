route_eco -reroute modified_nets_first_then_others \
          -utilize_dangling_wires true   ;# option names vary by version

# or just re-run the optimization pass
#route_detail -incremental true -initial_drc_from_input true
#route_opt
