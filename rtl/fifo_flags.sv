// ============================================================================
// File: fifo_flags.sv
// Description: Full, Empty, Almost Full, and Almost Empty Flag Generation Logic
// Author: Abhijit Karale
// Project: Synchronous & Asynchronous FIFO with Clock Domain Crossing (CDC)
// ============================================================================

`timescale 1ns / 1ps

module fifo_flags #(
    parameter int DEPTH = 16,
    parameter int PTR_WIDTH = 5, // ADDR_WIDTH + 1 for wrap-around bit
    parameter int ALMOST_FULL_THRESH = 14,
    parameter int ALMOST_EMPTY_THRESH = 2
) (
    // Synchronous inputs (or synchronized Gray pointers in CDC)
    input  logic [PTR_WIDTH-1:0] wptr_bin,
    input  logic [PTR_WIDTH-1:0] rptr_bin,
    input  logic [PTR_WIDTH-1:0] wptr_gray,
    input  logic [PTR_WIDTH-1:0] rptr_gray_sync, // Synchronized R-ptr into W-clk domain
    input  logic [PTR_WIDTH-1:0] rptr_gray,
    input  logic [PTR_WIDTH-1:0] wptr_gray_sync, // Synchronized W-ptr into R-clk domain

    // Status outputs
    output logic                 full_sync,
    output logic                 empty_sync,
    output logic                 full_async,
    output logic                 empty_async,
    output logic                 almost_full,
    output logic                 almost_empty,
    output logic [$clog2(DEPTH+1)-1:0] data_count
);

    localparam int ADDR_WIDTH = PTR_WIDTH - 1;

    // --- Synchronous FIFO Flag & Count Logic ---
    logic [PTR_WIDTH-1:0] diff;
    assign diff = wptr_bin - rptr_bin;

    assign full_sync    = (wptr_bin[PTR_WIDTH-1] != rptr_bin[PTR_WIDTH-1]) &&
                          (wptr_bin[PTR_WIDTH-2:0] == rptr_bin[PTR_WIDTH-2:0]);
    assign empty_sync   = (wptr_bin == rptr_bin);
    assign data_count   = diff[$clog2(DEPTH+1)-1:0];

    // --- Asynchronous FIFO Gray-Code Flag Logic ---
    // Full condition: Top 2 MSBs inverted, remaining LSBs equal
    assign full_async   = (wptr_gray == {~rptr_gray_sync[PTR_WIDTH-1:PTR_WIDTH-2], 
                                         rptr_gray_sync[PTR_WIDTH-3:0]});

    // Empty condition: Read Gray pointer matches synchronized Write Gray pointer
    assign empty_async  = (rptr_gray == wptr_gray_sync);

    // Almost flags based on calculated difference
    assign almost_full  = (diff >= ALMOST_FULL_THRESH);
    assign almost_empty = (diff <= ALMOST_EMPTY_THRESH);

endmodule
