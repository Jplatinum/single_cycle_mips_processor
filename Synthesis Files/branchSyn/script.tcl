# ECE552 Extra Credit

source ./synopsys_dc.setup

# Read RTL
read_file -format verilog { branch_predictor.v MetaDataArray.v multicycle_memory.v DataArray.v arbiter.v BitCell.v cache_fill_FSM.v comp_instructions.v cont_instructions.v CPU.v D-Flip-Flop.v dcache.v decode0.v D_E_pipe.v execute0.v E_M_pipe.v fetch0.v forwarding_unit.v F_D_pipe.v hazard_detection.v hlt_unit.v icache.v memory0.v mem_instructions.v M_W_pipe.v PC_reg.v ReadDecoder_4_16.v Register.v RegisterFile.v writeback0.v WriteDecoder_4_16.v }

set current_design cpu
link

###########################################
# Define clock and set don't mess with it #
###########################################
# clk with frequency of 400 MHz
create_clock -name "clk" -period 2.5 -waveform { 0 1.25 } { clk }
set_false_path -from [get_ports rst_n]
set compile_delete_unloaded_sequential_cells false
set compile_seqmap_propagate_constants false
set_dont_touch_network [find port clk]
# pointer to all inputs except clk
set prim_inputs [remove_from_collection [all_inputs] [find port clk]]
# pointer to all inputs except clk and rst_n
set prim_inputs_no_rst [remove_from_collection $prim_inputs [find port rst_n]]
# Set clk uncertainty (skew)
set_clock_uncertainty 0.15 clk

#########################################
# Set input delay & drive on all inputs #
#########################################
set_input_delay -clock clk 0.25 [copy_collection $prim_inputs]
#set_driving_cell -lib_cell ND2D2BWP -library tcbn40lpbwptc $prim_inputs_no_rst
# rst_n goes to many places so don't touch
set_dont_touch_network [find port rst_n]

##########################################
# Set output delay & load on all outputs #
##########################################
set_output_delay -clock clk 0.5 [all_outputs]
set_load 0.1 [all_outputs]

#############################################################
# Wire load model allows it to estimate internal parasitics #
#############################################################
# set_wire_load_model -name TSMC32K_Lowk_Conservative -library tcbn40lpbwptc

######################################################
# Max transition time is important for Hot-E reasons #
######################################################
set_max_transition 0.1 [current_design]




######################################################
# NEW: Area driven goal
######################################################
set_max_area 0
set compile_effort low
compile -map_effort high -area_effort high


########################################
# Now actually synthesize for 1st time #
########################################
check_design
uniquify -force


#############################################
# Take a look at area, max, and min timings #
#############################################
report_hierarchy > branch_cpu_hierarchy.syn.txt
report_qor > branch_cpu_qor.syn.txt

#### write out final netlist ######
write -format verilog -output branch_cpu.syn.vg
#### write out sdc ######
write_sdc cpu.syn.sdc