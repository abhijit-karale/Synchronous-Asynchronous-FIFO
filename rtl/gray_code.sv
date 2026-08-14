// ============================================================================
// File: gray_code.sv
// Description: Parameterizable Binary to Gray and Gray to Binary Converters
// Author: Abhijit Karale
// Project: Synchronous & Asynchronous FIFO with Clock Domain Crossing (CDC)
// ============================================================================

`timescale 1ns / 1ps

module bin2gray #(
    parameter int WIDTH = 4
) (
    input  logic [WIDTH-1:0] bin,
    output logic [WIDTH-1:0] gray
);

    assign gray = bin ^ (bin >> 1);

endmodule

module gray2bin #(
    parameter int WIDTH = 4
) (
    input  logic [WIDTH-1:0] gray,
    output logic [WIDTH-1:0] bin
);

    always_comb begin
        bin[WIDTH-1] = gray[WIDTH-1];
        for (int i = WIDTH - 2; i >= 0; i--) begin
            bin[i] = bin[i+1] ^ gray[i];
        end
    end

endmodule
