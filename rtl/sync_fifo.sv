// ============================================================================
// File: sync_fifo.sv
// Description: Parameterizable Synchronous FIFO RTL Module
// Author: Abhijit Karale
// Project: Synchronous & Asynchronous FIFO with Clock Domain Crossing (CDC)
// ============================================================================

`timescale 1ns / 1ps

module sync_fifo #(
    parameter int DATA_WIDTH          = 32,
    parameter int DEPTH               = 16,
    parameter int ALMOST_FULL_THRESH  = 14,
    parameter int ALMOST_EMPTY_THRESH = 2
) (
    input  logic                  clk,
    input  logic                  rst_n,

    // Write Interface
    input  logic                  w_en,
    input  logic [DATA_WIDTH-1:0] w_data,
    output logic                  full,
    output logic                  almost_full,

    // Read Interface
    input  logic                  r_en,
    output logic [DATA_WIDTH-1:0] r_data,
    output logic                  empty,
    output logic                  almost_empty,

    // Status
    output logic [$clog2(DEPTH+1)-1:0] data_count
);

    localparam int ADDR_WIDTH = $clog2(DEPTH);
    localparam int PTR_WIDTH  = ADDR_WIDTH + 1;

    // Memory array
    logic [DATA_WIDTH-1:0] mem [0:DEPTH-1];

    // Read and Write Pointers (Binary, with extra wrap-around bit)
    logic [PTR_WIDTH-1:0] w_ptr;
    logic [PTR_WIDTH-1:0] r_ptr;

    // Internal full/empty flags
    assign full  = (w_ptr[PTR_WIDTH-1] != r_ptr[PTR_WIDTH-1]) &&
                   (w_ptr[ADDR_WIDTH-1:0] == r_ptr[ADDR_WIDTH-1:0]);
    assign empty = (w_ptr == r_ptr);

    // Data count & almost flags
    logic [PTR_WIDTH-1:0] count_diff;
    assign count_diff  = w_ptr - r_ptr;
    assign data_count  = count_diff[$clog2(DEPTH+1)-1:0];
    assign almost_full = (data_count >= ALMOST_FULL_THRESH);
    assign almost_empty= (data_count <= ALMOST_EMPTY_THRESH);

    // Write operation
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            w_ptr <= '0;
        end else if (w_en && !full) begin
            mem[w_ptr[ADDR_WIDTH-1:0]] <= w_data;
            w_ptr <= w_ptr + 1'b1;
        end
    end

    // Read operation
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            r_ptr <= '0;
        end else if (r_en && !empty) begin
            r_ptr <= r_ptr + 1'b1;
        end
    end

    // Combinatorial output memory read
    assign r_data = mem[r_ptr[ADDR_WIDTH-1:0]];

endmodule
