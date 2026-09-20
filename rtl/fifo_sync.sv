 // ============================================================================
 // File: fifo_sync.sv
 // Description: 2-Stage Flip-Flop Synchronizer for Clock Domain Crossing (CDC)
 // Author: Abhijit Karale
// Project: Synchronous & Asynchronous FIFO with Clock Domain Crossing (CDC)
// ============================================================================

`timescale 1ns / 1ps

module fifo_sync #(
    parameter int WIDTH = 4,
    parameter bit RESET_VAL_ZERO = 1'b1
) (
    input  logic             clk,
    input  logic             rst_n,
    input  logic [WIDTH-1:0] din,
    output logic [WIDTH-1:0] dout
);

    // 2-stage Flip-Flop synchronizer pipeline
    logic [WIDTH-1:0] sync_stage1;
    logic [WIDTH-1:0] sync_stage2;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sync_stage1 <= RESET_VAL_ZERO ? '0 : '1;
            sync_stage2 <= RESET_VAL_ZERO ? '0 : '1;
        end else begin
            sync_stage1 <= din;
            sync_stage2 <= sync_stage1;
        end
    end

    assign dout = sync_stage2;

endmodule
