// ============================================================================
// File: async_fifo_tb.sv
// Description: Self-checking Testbench for Asynchronous FIFO (Clock Domain Crossing)
// Author: Abhijit Karale
// Project: Synchronous & Asynchronous FIFO with Clock Domain Crossing (CDC)
// ============================================================================

`timescale 1ns / 1ps

module async_fifo_tb;

    parameter int DATA_WIDTH          = 32;
    parameter int DEPTH               = 16;
    parameter int ALMOST_FULL_THRESH  = 14;
    parameter int ALMOST_EMPTY_THRESH = 2;

    localparam int ADDR_WIDTH = $clog2(DEPTH);
    localparam int PTR_WIDTH  = ADDR_WIDTH + 1;

    // Asynchronous Clocks & Resets
    logic                  wclk;
    logic                  wrst_n;
    logic                  rclk;
    logic                  rrst_n;

    // DUT Signals
    logic                  w_en;
    logic [DATA_WIDTH-1:0] w_data;
    logic                  full;
    logic                  almost_full;

    logic                  r_en;
    logic [DATA_WIDTH-1:0] r_data;
    logic                  empty;
    logic                  almost_empty;

    // Clock periods (configurable to test clock ratio mismatch)
    real WCLK_PERIOD = 10.0; // 100 MHz
    real RCLK_PERIOD = 25.0; // 40 MHz (Fast write, Slow read)

    // Verification Variables
    int error_count     = 0;
    int cdc_error_count = 0;
    int items_written   = 0;
    int items_read      = 0;

    // Scoreboard Queue
    logic [DATA_WIDTH-1:0] expected_queue[$];

    // DUT Instantiation
    async_fifo #(
        .DATA_WIDTH         (DATA_WIDTH),
        .DEPTH              (DEPTH),
        .ALMOST_FULL_THRESH (ALMOST_FULL_THRESH),
        .ALMOST_EMPTY_THRESH(ALMOST_EMPTY_THRESH)
    ) dut (
        .*
    );

    // Instantiate CDC Assertion & Gray-Code Monitor
    cdc_monitor #(
        .PTR_WIDTH(PTR_WIDTH)
    ) monitor_inst (
        .wclk           (wclk),
        .wrst_n         (wrst_n),
        .wptr_gray      (dut.wptr_gray),
        .rclk           (rclk),
        .rrst_n         (rrst_n),
        .rptr_gray      (dut.rptr_gray),
        .cdc_error_count(cdc_error_count)
    );

    // Clock Generation Loops
    always #(WCLK_PERIOD / 2.0) wclk = ~wclk;
    always #(RCLK_PERIOD / 2.0) rclk = ~rclk;

    // Write Driver Process
    task automatic write_data(input logic [DATA_WIDTH-1:0] data);
        @(posedge wclk);
        if (!full) begin
            w_en   <= 1'b1;
            w_data <= data;
            expected_queue.push_back(data);
            items_written++;
        end else begin
            w_en   <= 1'b0;
        end
        @(posedge wclk);
        w_en <= 1'b0;
    endtask

    // Read Driver & Checker Process
    task automatic read_data();
        logic [DATA_WIDTH-1:0] exp_val;
        @(posedge rclk);
        if (!empty) begin
            r_en <= 1'b1;
            if (expected_queue.size() > 0) begin
                exp_val = expected_queue.pop_front();
                items_read++;
                #1; // Sample output before next clock edge increments read pointer
                if (r_data !== exp_val) begin
                    $display("[FAIL CDC READ @ %0t ps] Data Mismatch! Exp: 0x%0h, Got: 0x%0h", 
                             $time, exp_val, r_data);
                    error_count++;
                end else begin
                    $display("[PASS CDC READ @ %0t ps] Data Match: 0x%0h", $time, r_data);
                end
            end
            @(posedge rclk);
            r_en <= 1'b0;
        end else begin
            r_en <= 1'b0;
        end
    endtask

    // Main Verification Workflow
    initial begin
        wclk   = 0;
        rclk   = 0;
        wrst_n = 0;
        rrst_n = 0;
        w_en   = 0;
        r_en   = 0;
        w_data = 0;

        $display("=========================================================");
        $display("     STARTING ASYNCHRONOUS FIFO (CDC) TESTBENCH          ");
        $display("=========================================================");

        // Apply Reset
        #50;
        wrst_n = 1;
        rrst_n = 1;
        #20;

        $display("\n--- PHASE 1: Fast Write (100MHz), Slow Read (40MHz) ---");
        // Burst writes
        for (int i = 0; i < 20; i++) begin
            write_data(32'hB000_0000 + i);
        end

        // Wait and drain reads
        for (int i = 0; i < 20; i++) begin
            read_data();
        end

        #100;
        $display("\n--- PHASE 2: Dynamic Frequency Mismatch (W: 33MHz, R: 100MHz) ---");
        WCLK_PERIOD = 30.0; // 33.3 MHz
        RCLK_PERIOD = 10.0; // 100 MHz

        // Parallel write and read processes
        fork
            begin : WRITER_PROC
                for (int i = 0; i < 50; i++) begin
                    write_data($urandom());
                    #(WCLK_PERIOD * $urandom_range(1, 3));
                end
            end
            begin : READER_PROC
                for (int i = 0; i < 60; i++) begin
                    read_data();
                    #(RCLK_PERIOD * $urandom_range(1, 3));
                end
            end
        join

        // Final Drain
        while (expected_queue.size() > 0) begin
            read_data();
        end

        #200;

        // Final Summary Evaluation
        $display("\n=========================================================");
        $display("               CDC TEST SUMMARY REPORT                   ");
        $display("=========================================================");
        $display(" Total Items Written : %0d", items_written);
        $display(" Total Items Read    : %0d", items_read);
        $display(" CDC Hamming Errors  : %0d", cdc_error_count);
        $display(" Data Mismatches     : %0d", error_count);
        $display("=========================================================");

        if (error_count == 0 && cdc_error_count == 0) begin
            $display("    *** ASYNCHRONOUS FIFO CDC TESTBENCH PASSED ***");
        end else begin
            $display("    *** ASYNCHRONOUS FIFO CDC TESTBENCH FAILED ***");
        end
        $display("=========================================================");
        $finish;
    end

endmodule
