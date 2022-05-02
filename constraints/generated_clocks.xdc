create_generated_clock -name action_clock -source [get_ports clock] -divide_by 2 -invert [get_pins action_clock_reg/Q]
create_generated_clock -name control_clock -source [get_ports clock] -divide_by 2 [get_pins control_clock_reg/Q]
