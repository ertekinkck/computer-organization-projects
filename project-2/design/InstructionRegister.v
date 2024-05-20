`timescale 1ns / 1ps

module InstructionRegister(Clock, Write, LH, I, IROut);

    input Clock, Write, LH;
    input [7:0] I;
    output reg [15:0] IROut;

    always @(posedge Clock) begin
        if (Write == 1) begin
            case (LH)
                1'b1: IROut <= {I, IROut[7:0]};
                1'b0: IROut <= {IROut[15:8], I};
                
                default: IROut <= IROut;
            endcase
        end else begin
            IROut = IROut;
            end
    end
endmodule