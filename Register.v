`timescale 1ns / 1ps

module Register(
  input Clock,
  input E,
  input [15:0] I,
  input [2:0] FunSel,
  output reg [15:0] Q
);

initial begin
    Q = 16'h0000;
end

    always @(*) begin
      if (E) begin
        case (FunSel)
          3'b000: Q = Q - 1'b1; // Q = Q-1: Decrement
          3'b001: Q = Q + 1'b1; // Q = Q+1: Increment
          3'b010: Q = I;        // Q = I: Load
          3'b011: Q = 16'h0000;   // Clear
          3'b100: Q = {8'b0000_0000, I[7:0]}; // Q (15-8) ? Clear, Q (7-0) ? I (7-0) (Write Low)
          3'b101: Q = {Q[15:8], I[7:0]}; // Q (7-0) ? I (7-0) (Only Write Low)
          3'b110: Q = {I[7:0], Q[7:0]}; // Q (15-8) ? I (7-0) (Only Write High)
          3'b111: Q = {{8{I[7]}}, I[7:0]}; // Q (15-8) ? Sign Extend (I (7)), Q (7-0) ? I (7-0) (Write Low)
          default: Q = Q; // Default to no operation
        endcase
      end else begin
        Q = Q; // No operation
      end
    end

endmodule