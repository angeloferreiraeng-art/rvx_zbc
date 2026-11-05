#group_path -name INREG -from [all_inputs]
#group_path -name REGOUT -to [all_outputs]
#group_path -name FEEDTHROUGH -from [all_inputs] -to [all_outputs]

#set CLOCK_PERIOD 1.0


create_mode   func
create_corner slow
create_scenario -mode func -corner slow -name func_slow
current_scenario func_slow


#create_mode func
#create_clock -name master_clk -period $CLOCK_PERIOD [get_ports clock] 

#create_corner typical
#set_parasitic_parameters -early_spec rcTLU -late_spec rcTLU
#set_process_number 1
#set_process_label typical
#set_voltage -object_list VDDCORE 1.20
#set_voltage -object_list VSSCORE 0.0
#set_voltage -object_list VDDPAD 1.20
#set_voltage -object_list VSSPAD 0.0
#set_temperature 25


#create_scenario -mode func -corner typical
#set_scenario_status func::typical -setup true -hold false
#create_clock -name master_clk -period $CLOCK_PERIOD [get_ports clock] 
#current_scenario func::typical




# Create Path Groups for reporting
#create_corner tt_25c
#set_parasitic_parameters -early_spec rcTLU -late_spec rcTLU
#set_process_number 1
#set_process_label typical
#set_voltage -object_list VDDCORE 1.20
#set_voltage -object_list VSSCORE 0.0
#set_voltage -object_list VDDPAD 1.20
#set_voltage -object_list VSSPAD 0.0
#set_temperature 25

#create_corner ff_m40c
#set_parasitic_parameters -late_spec rcTLU -early_spec rcTLU
#set_process_number 1
#set_process_label fast
#set_voltage -object_list VDDCORE 1.65
#set_voltage -object_list VSSCORE 0.0
#set_voltage -object_list VDDPAD 1.65
#set_voltage -object_list VSSPAD 0.0
#set_temperature -40



#create_corner ss_125c
#set_parasitic_parameters -late_spec rcTLU -early_spec rcTLU
#set_process_number 1
#set_process_label slow
#set_voltage -object_list VDDCORE 1.08
#set_voltage -object_list VSSCORE 0.0
#set_voltage -object_list VDDPAD 1.08
#set_voltage -object_list VSSPAD 0.0
#set_temperature 125


#create_mode func
#create_clock -name master_clk -period $CLOCK_PERIOD [get_ports clock] 

#create_scenario -mode func -corner tt_25c
#set_scenario_status func::tt_25c -setup true -hold false
#create_clock -name master_clk -period $CLOCK_PERIOD [get_ports clock] 

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

