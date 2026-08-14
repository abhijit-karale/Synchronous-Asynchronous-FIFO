// ============================================================================
// File: async_fifo.sv
// Description: Parameterizable Asynchronous FIFO RTL Module with CDC Logic
// Author: Abhijit Karale
// Project: Synchronous & Asynchronous FIFO with Clock Domain Crossing (CDC)
// ============================================================================

`timescale 1ns / 1ps

module async_fifo #(
    parameter int DATA_WIDTH          = 32,
    parameter int DEPTH               = 16,
    parameter int ALMOST_FULL_THRESH  = 14,
    parameter int ALMOST_EMPTY_THRESH = 2
) (
    // Write Domain Ports
    input  logic                  wclk,
    input  logic                  wrst_n,
    input  logic                  w_en,
    input  logic [DATA_WIDTH-1:0] w_data,
    output logic                  full,
    output logic                  almost_full,

    // Read Domain Ports
    input  logic                  rclk,
    input  logic                  rrst_n,
    input  logic                  r_en,
    output logic [DATA_WIDTH-1:0] r_data,
    output logic                  empty,
    output logic                  almost_empty
);

    localparam int ADDR_WIDTH = $clog2(DEPTH);
    localparam int PTR_WIDTH  = ADDR_WIDTH + 1;

    // Memory array
    logic [DATA_WIDTH-1:0] mem [0:DEPTH-1];

    // Write domain pointers
    logic [PTR_WIDTH-1:0] wptr_bin, wptr_bin_next;
    logic [PTR_WIDTH-1:0] wptr_gray, wptr_gray_next;
    logic [PTR_WIDTH-1:0] rptr_gray_sync;

    // Read domain pointers
    logic [PTR_WIDTH-1:0] rptr_bin, rptr_bin_next;
    logic [PTR_WIDTH-1:0] rptr_gray, rptr_gray_next;
    logic [PTR_WIDTH-1:0] wptr_gray_sync;

    // Converted binary pointers for count/almost calculation
    logic [PTR_WIDTH-1:0] rptr_bin_sync_wclk;
    logic [PTR_WIDTH-1:0] wptr_bin_sync_rclk;

    // ------------------------------------------------------------------------
    // Memory Write & Read Logic
    // ------------------------------------------------------------------------
    always_ff @(posedge wclk) begin
        if (w_en && !full) begin
            mem[wptr_bin[ADDR_WIDTH-1:0]] <= w_data;
        end
    end

    assign r_data = mem[rptr_bin[ADDR_WIDTH-1:0]];

    // ------------------------------------------------------------------------
    // Write Pointer & Gray Logic (wclk domain)
    // ------------------------------------------------------------------------
    assign wptr_bin_next  = wptr_bin + (w_en & ~full);
    assign wptr_gray_next = wptr_bin_next ^ (wptr_bin_next >> 1);

    always_ff @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wptr_bin  <= '0;
            wptr_gray <= '0;
        end else begin
            wptr_bin  <= wptr_bin_next;
            wptr_gray <= wptr_gray_next;
        end
    end

    // ------------------------------------------------------------------------
    // Read Pointer & Gray Logic (rclk domain)
    // ------------------------------------------------------------------------
    assign rptr_bin_next  = rptr_bin + (r_en & ~empty);
    assign rptr_gray_next = rptr_bin_next ^ (rptr_bin_next >> 1);

    always_ff @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rptr_bin  <= '0;
            rptr_gray <= '0;
        end else begin
            rptr_bin  <= rptr_bin_next;
            rptr_gray <= rptr_gray_next;
        end
    end

    // ------------------------------------------------------------------------
    // 2-Flop CDC Synchronizers
    // ------------------------------------------------------------------------
    // Synchronize Write Pointer Gray code into Read Clock Domain
    fifo_sync #(
        .WIDTH(PTR_WIDTH),
        .RESET_VAL_ZERO(1'b1)
    ) sync_wptr_to_rclk (
        .clk  (rclk),
        .rst_n(rrst_n),
        .din  (wptr_gray),
        .dout (wptr_gray_sync)
    );

    // Synchronize Read Pointer Gray code into Write Clock Domain
    fifo_sync #(
        .WIDTH(PTR_WIDTH),
        .RESET_VAL_ZERO(1'b1)
    ) sync_rptr_to_wclk (
        .clk  (wclk),
        .rst_n(wrst_n),
        .din  (rptr_gray),
        .dout (rptr_gray_sync)
    );

    // ------------------------------------------------------------------------
    // Full & Empty Flag Logic
    // ------------------------------------------------------------------------
    // Full flag in Write clock domain
    logic full_val;
    assign full_val = (wptr_gray_next == {~rptr_gray_sync[PTR_WIDTH-1:PTR_WIDTH-2],
                                           rptr_gray_sync[PTR_WIDTH-3:0]});

    always_ff @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            full <= 1'b0;
        end else begin
            full <= full_val;
        end
    end

    // Empty flag in Read clock domain
    logic empty_val;
    assign empty_val = (rptr_gray_next == wptr_gray_sync);

    always_ff @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            empty <= 1'b1;
        end else begin
            empty <= empty_val;
        end
    end

    // Gray-to-Binary modules for internal fill-level / almost flag estimations
    gray2bin #(.WIDTH(PTR_WIDTH)) g2b_rptr_wclk (.gray(rptr_gray_sync), .bin(rptr_bin_sync_wclk));
    gray2bin #(.WIDTH(PTR_WIDTH)) g2b_wptr_rclk (.gray(wptr_gray_sync), .bin(wptr_bin_sync_rclk));

    logic [PTR_WIDTH-1:0] w_diff, r_diff;
    assign w_diff = wptr_bin - rptr_bin_sync_wclk;
    assign r_diff = wptr_bin_sync_rclk - rptr_bin;

    assign almost_full  = (w_diff >= ALMOST_FULL_THRESH);
    assign almost_empty = (r_diff <= ALMOST_EMPTY_THRESH);

endmodule
