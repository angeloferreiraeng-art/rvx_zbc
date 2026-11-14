set CLOCK_PERIOD 20.0

load_upf $SCRIPT_DIR/power.upf
commit_upf
connect_supply_net VSSPAD -ports [get_pins */VSSPAD]
connect_supply_net VSSCORE -ports [get_pins */VSSCORE]
connect_supply_net VDDPAD -ports [get_pins */VDDPAD]
connect_supply_net VDDCORE -ports [get_pins */VDDCORE]


# UM: testing here

# ---- modes ----
create_mode func
current_mode func

# ---- corners ----
create_corner tt_25c
current_corner tt_25c
set_parasitic_parameters -early_spec rcTLU -late_spec rcTLU
set_process_number 1
set_process_label typical
set_temperature 25
set_voltage 1.20 -object_list [get_supply_nets VDDCORE]
set_voltage 3.30 -object_list [get_supply_nets VDDPAD]
set_voltage 0.00 -object_list [get_supply_nets VSSCORE]
set_voltage 0.00 -object_list [get_supply_nets VSSPAD]


create_corner ss_125c
current_corner ss_125c
set_parasitic_parameters -early_spec rcTLU -late_spec rcTLU
set_process_number 1
set_process_label slow
set_temperature 125
set_voltage 1.08 -object_list [get_supply_nets VDDCORE]
set_voltage 3.00 -object_list [get_supply_nets VDDPAD]
set_voltage 0.00 -object_list [get_supply_nets VSSCORE]
set_voltage 0.00 -object_list [get_supply_nets VSSPAD]


#create_corner ff_m40c
#current_corner ff_m40c
#set_parasitic_parameters -early_spec rcTLU -late_spec rcTLU
#set_process_number 1
#set_process_label fast
#set_temperature -40
#set_voltage 1.65 -object_list [get_supply_nets VDDCORE]
#set_voltage 3.60 -object_list [get_supply_nets VDDPAD]
#set_voltage 0.00 -object_list [get_supply_nets VSSCORE]
#set_voltage 0.00 -object_list [get_supply_nets VSSPAD]

# ---- scenario ----
create_scenario -mode func -corner tt_25c
current_scenario func::tt_25c
set_scenario_status func::tt_25c -active true -setup true -hold false
create_clock -name master_clk -period $CLOCK_PERIOD [get_ports clock]

create_scenario -mode func -corner ss_125c
current_scenario func::ss_125c
set_scenario_status func::ss_125c -active true -setup true -hold false
create_clock -name master_clk -period $CLOCK_PERIOD [get_ports clock]

#create_scenario -mode func -corner ff_m40c
#current_scenario func::ff_m40c
#set_scenario_status func::ff_m40c -active true -setup true -hold false
#create_clock -name master_clk -period $CLOCK_PERIOD [get_ports clock]



remove_corners default


#create_scenario -mode func -corner ff_m40c
#set_scenario_status func::ff_m40c -setup true -hold false
#create_clock -name master_clk -period $CLOCK_PERIOD [get_ports clock] 

#create_scenario -mode func -corner ss_125c
#set_scenario_status func::ss_125c -setup true -hold false
#create_clock -name master_clk -period $CLOCK_PERIOD [get_ports clock] 


#create_mode high_freq
#create_clock -name master_clk -period 3.0 [get_ports clock]
#create_scenario -mode high_freq -corner tt_25c
#set_scenario_status high_freq::tt_25c -setup true -hold false

#create_mode low_freq
#create_clock -name master_clk -period 50.0 [get_ports clock]
#create_scenario -mode low_freq -corner tt_25c
#set_scenario_status low_freq::tt_25c -setup true -hold false

#create_scenario -mode low_freq -corner ss_125c -name worst_case
#set_scenario_status worst_case -setup true -hold false

#create_scenario -mode high_freq -corner ff_m40c -name best_case
#set_scenario_status best_case -setup true -hold false

#create_mode initial
#create_scenario -mode initial -corner tt_25c
#create_clock -name master_clk -period $CLOCK_PERIOD [get_ports clock]
#set_scenario_status initial::tt_25c -hold true -setup false -leakage_power true -dynamic_power true

#create_mode switching
#create_clock -name master_clk -period $CLOCK_PERIOD [get_ports clock]
#create_scenario -mode switching -corner tt_25c
#set_scenario_status switching::tt_25c -hold true -setup false -leakage_power true -dynamic_power true
#set_switching_activity -toggle_rate 0.5 -static_probability 0.3 [get_ports cmdin]
#set_switching_activity -toggle_rate 0.7 -static_probability 0.5 [get_ports {dn_1, din_2, din_3}] 
#infer_switching_activity


#create_mode test
#create_scenario -mode test -corner tt_25c
#create_clock -name master_clk -period $CLOCK_PERIOD [get_ports clock]
#set_scenario_status test::tt_25c -hold false -leakage_power false -dynamic_power false

