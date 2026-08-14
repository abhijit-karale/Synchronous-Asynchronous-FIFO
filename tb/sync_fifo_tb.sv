// ============================================================================
// File: sync_fifo_tb.sv
// Description: Self-checking Testbench for Synchronous FIFO
// Author: Abhijit Karale
// Project: Synchronous & Asynchronous FIFO with Clock Domain Crossing (CDC)
// ============================================================================

`timescale 1ns / 1ps

module sync_fifo_tb;

    parameter int DATA_WIDTH          = 32;
    parameter int DEPTH               = 16;
    parameter int ALMOST_FULL_THRESH  = 14;
    parameter int ALMOST_EMPTY_THRESH = 2;

    // Clock and Reset
    logic                  clk;
    logic                  rst_n;

    // DUT Signals
    logic                  w_en;
    logic [DATA_WIDTH-1:0] w_data;
    logic                  full;
    logic                  almost_full;

    logic                  r_en;
    logic [DATA_WIDTH-1:0] r_data;
    logic                  empty;
    logic                  almost_empty;

    logic [$clog2(DEPTH+1)-1:0] data_count;

    // Testbench Variables
    int error_count = 0;
    int test_count  = 0;

    // Scoreboard Queue
    logic [DATA_WIDTH-1:0] scoreboard_q[$];

    // DUT Instantiation
    sync_fifo #(
        .DATA_WIDTH         (DATA_WIDTH),
        .DEPTH              (DEPTH),
        .ALMOST_FULL_THRESH (ALMOST_FULL_THRESH),
        .ALMOST_EMPTY_THRESH(ALMOST_EMPTY_THRESH)
    ) dut (
        .*
    );

    // Clock Generation: 100 MHz (10ns period)
    always #5 clk = ~clk;

    // Helper task: Write data into FIFO
    task automatic write_fifo(input logic [DATA_WIDTH-1:0] data);
        @(posedge clk);
        w_en   <= 1'b1;
        w_data <= data;
        if (!full) begin
            scoreboard_q.push_back(data);
        end
        @(posedge clk);
        w_en   <= 1'b0;
    endtask

    // Helper task: Read data from FIFO and compare with scoreboard
    task automatic read_fifo();
        logic [DATA_WIDTH-1:0] expected;
        @(posedge clk);
        r_en <= 1'b1;
        if (!empty) begin
            expected = scoreboard_q.pop_front();
            #1; // Sample output after clock edge
            if (r_data !== expected) begin
                $display("[FAIL @ %0t ps] Data Mismatch! Expected: 0x%0h, Got: 0x%0h", 
                         $time, expected, r_data);
                error_count++;
            end else begin
                $display("[PASS @ %0t ps] Read Data Match: 0x%0h", $time, r_data);
            end
        end
        @(posedge clk);
        r_en <= 1'b0;
    endtask

    // Main Test Stimulus
    initial begin
        clk   = 0;
        rst_n = 0;
        w_en  = 0;
        r_en  = 0;
        w_data= 0;

        $display("=========================================================");
        $display("       STARTING SYNCHRONOUS FIFO TESTBENCH               ");
        $display("=========================================================");

        // Step 1: Reset Test
        #20;
        rst_n = 1;
        @(posedge clk);
        if (empty !== 1'b1 || full !== 1'b0) begin
            $display("[FAIL] Reset state incorrect: empty=%b, full=%b", empty, full);
            error_count++;
        end else begin
            $display("[PASS] Reset state verified (empty=1, full=0).");
        end

        // Step 2: Burst Write to Full
        $display("\n--- TEST 1: Burst Write to FULL ---");
        for (int i = 0; i < DEPTH; i++) begin
            write_fifo(32'hA000_0000 + i);
        end
        @(posedge clk);
        if (full === 1'b1) begin
            $display("[PASS] FIFO correctly flagged FULL.");
        end else begin
            $display("[FAIL] FIFO full flag failed to assert! full=%b", full);
            error_count++;
        end

        // Step 3: Burst Read to Empty
        $display("\n--- TEST 2: Burst Read to EMPTY ---");
        for (int i = 0; i < DEPTH; i++) begin
            read_fifo();
        end
        @(posedge clk);
        if (empty !== 1'b1) begin
            $display("[FAIL] FIFO empty flag failed to assert! empty=%b", empty);
            error_count++;
        end else begin
            $display("[PASS] FIFO correctly flagged EMPTY.");
        end

        // Step 4: Pointer Wrap-around & Random Transactions (100 iterations)
        $display("\n--- TEST 3: Pointer Wrap-around & Random Transactions ---");
        for (int i = 0; i < 100; i++) begin
            bit do_write, do_read;
            do_write = $urandom_range(0, 1);
            do_read  = $urandom_range(0, 1);

            if (do_write && !full) begin
                write_fifo($urandom());
            end
            if (do_read && !empty) begin
                read_fifo();
            end
        end

        // Drain remaining items from queue
        while (scoreboard_q.size() > 0) begin
            read_fifo();
        end

        // Final Summary
        $display("\n=========================================================");
        if (error_count == 0) begin
            $display("    *** SYNCHRONOUS FIFO TESTBENCH PASSED (0 ERRORS) ***");
        end else begin
            $display("    *** SYNCHRONOUS FIFO TESTBENCH FAILED (%0d ERRORS) ***", error_count);
        end
        $display("=========================================================");
        $finish;
    end

endmodule
