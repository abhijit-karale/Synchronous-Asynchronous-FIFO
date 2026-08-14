// ============================================================================
// File: fifo_sequences.sv
// Description: Reusable Test Sequences and Stimulus Helpers for FIFO Verification
// Author: Abhijit Karale
// Project: Synchronous & Asynchronous FIFO with Clock Domain Crossing (CDC)
// ============================================================================

`timescale 1ns / 1ps

package fifo_sequences_pkg;

    parameter int DATA_WIDTH = 32;

    // Transaction structure
    typedef struct {
        bit [DATA_WIDTH-1:0] data;
        int delay;
    } fifo_trans_t;

    // Helper to generate a random 32-bit vector
    function automatic bit [DATA_WIDTH-1:0] get_rand_data();
        return $urandom();
    endfunction

endpackage: fifo_sequences_pkg
