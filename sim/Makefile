# ============================================================================
# File: Makefile
# Description: Multi-Simulator Makefile for Sync & Async FIFO Verification
# Author: Abhijit Karale
# Project: Synchronous & Asynchronous FIFO with Clock Domain Crossing (CDC)
# ============================================================================

SIM ?= iverilog

RTL_DIR = ../rtl
TB_DIR  = ../tb

RTL_SRCS = $(RTL_DIR)/gray_code.sv \
           $(RTL_DIR)/fifo_sync.sv \
           $(RTL_DIR)/fifo_flags.sv \
           $(RTL_DIR)/sync_fifo.sv \
           $(RTL_DIR)/async_fifo.sv

SYNC_TB_SRCS  = $(RTL_SRCS) $(TB_DIR)/sync_fifo_tb.sv
ASYNC_TB_SRCS = $(RTL_SRCS) $(TB_DIR)/fifo_sequences.sv $(TB_DIR)/cdc_monitor.sv $(TB_DIR)/async_fifo_tb.sv

.PHONY: all run_sync_fifo run_async_fifo clean

all: run_sync_fifo run_async_fifo

run_sync_fifo:
ifeq ($(SIM), iverilog)
	iverilog -g2012 -o sync_sim.vvp $(SYNC_TB_SRCS)
	vvp sync_sim.vvp | tee coverage_sync.txt
else
	vlib work
	vlog -sv $(SYNC_TB_SRCS)
	vsim -c -do run_sync.do
endif

run_async_fifo:
ifeq ($(SIM), iverilog)
	iverilog -g2012 -o async_sim.vvp $(ASYNC_TB_SRCS)
	vvp async_sim.vvp | tee coverage_async.txt
else
	vlib work
	vlog -sv $(ASYNC_TB_SRCS)
	vsim -c -do run_async.do
endif

clean:
	rm -f *.vvp *.vcd *.log *.txt
	rm -rf work/
