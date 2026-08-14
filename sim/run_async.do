# ModelSim / QuestaSim run script for Asynchronous FIFO (CDC)
vlib work
vlog -sv ../rtl/gray_code.sv ../rtl/fifo_sync.sv ../rtl/fifo_flags.sv ../rtl/async_fifo.sv ../tb/fifo_sequences.sv ../tb/cdc_monitor.sv ../tb/async_fifo_tb.sv
vsim -c async_fifo_tb
add wave -position insertpoint sim:/async_fifo_tb/dut/*
run -all
exit
