# ModelSim / QuestaSim run script for Synchronous FIFO
vlib work
vlog -sv ../rtl/sync_fifo.sv ../tb/sync_fifo_tb.sv
vsim -c sync_fifo_tb
add wave -position insertpoint sim:/sync_fifo_tb/dut/*
run -all
exit
