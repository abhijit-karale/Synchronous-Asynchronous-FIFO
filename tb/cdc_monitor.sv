// ============================================================================
// File: cdc_monitor.sv
// Description: CDC Assertion and Hamming Distance Monitor for Gray Code Verification
// Author: Abhijit Karale
// Project: Synchronous & Asynchronous FIFO with Clock Domain Crossing (CDC)
// ============================================================================

`timescale 1ns / 1ps

module cdc_monitor #(
    parameter int PTR_WIDTH = 5
) (
    input logic                 wclk,
    input logic                 wrst_n,
    input logic [PTR_WIDTH-1:0] wptr_gray,

    input logic                 rclk,
    input logic                 rrst_n,
    input logic [PTR_WIDTH-1:0] rptr_gray,

    output int                  cdc_error_count
);

    logic [PTR_WIDTH-1:0] wptr_gray_prev;
    logic [PTR_WIDTH-1:0] rptr_gray_prev;

    int w_error_count = 0;
    int r_error_count = 0;

    assign cdc_error_count = w_error_count + r_error_count;

    function automatic int hamming_distance(
        input logic [PTR_WIDTH-1:0] a,
        input logic [PTR_WIDTH-1:0] b
    );
        logic [PTR_WIDTH-1:0] diff;
        int h_dist;
        diff = a ^ b;
        h_dist = 0;
        for (int i = 0; i < PTR_WIDTH; i++) begin
            if (diff[i]) h_dist++;
        end
        return h_dist;
    endfunction

    // Check Write Pointer Gray code single-bit property on wclk
    always_ff @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wptr_gray_prev <= '0;
            w_error_count  <= 0;
        end else begin
            int h_dist;
            h_dist = hamming_distance(wptr_gray, wptr_gray_prev);
            if (h_dist > 1) begin
                $display("[CDC MONITOR ERROR @ %0t ps] Write pointer Gray code multi-bit transition! Dist=%0d (Prev: %b, Curr: %b)", 
                         $time, h_dist, wptr_gray_prev, wptr_gray);
                w_error_count <= w_error_count + 1;
            end
            wptr_gray_prev <= wptr_gray;
        end
    end

    // Check Read Pointer Gray code single-bit property on rclk
    always_ff @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rptr_gray_prev <= '0;
            r_error_count  <= 0;
        end else begin
            int h_dist;
            h_dist = hamming_distance(rptr_gray, rptr_gray_prev);
            if (h_dist > 1) begin
                $display("[CDC MONITOR ERROR @ %0t ps] Read pointer Gray code multi-bit transition! Dist=%0d (Prev: %b, Curr: %b)", 
                         $time, h_dist, rptr_gray_prev, rptr_gray);
                r_error_count <= r_error_count + 1;
            end
            rptr_gray_prev <= rptr_gray;
        end
    end

endmodule
