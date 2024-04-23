`timescale 1ns / 1ps
module AddressRegisterFile(
    input wire Clock,
    input wire [15:0] I,
    input wire [2:0] FunSel,
    input wire [2:0] RegSel,
    input wire [1:0] OutCSel,
    input wire [1:0] OutDSel,
    
    output reg [15:0] OutC,
    output reg [15:0] OutD
);

    wire [15:0] AR_reg, SP_reg, PC_reg;
  
    Register PC(.I(I), .FunSel(FunSel), .E(~RegSel[2]), .Clock(Clock), .Q(PC_reg));
    Register AR(.I(I), .FunSel(FunSel), .E(~RegSel[1]), .Clock(Clock), .Q(AR_reg));
    Register SP(.I(I), .FunSel(FunSel), .E(~RegSel[0]), .Clock(Clock), .Q(SP_reg));
 
  
    always @(*) begin
        case (OutCSel)
          2'b00: OutC <= PC_reg;
          2'b01: OutC <= PC_reg;
          2'b10: OutC <= AR_reg;
          2'b11: OutC <= SP_reg;
          default: OutC <= 8'b0;
        endcase
    
        case (OutDSel)
          2'b00: OutD <= PC_reg;
          2'b01: OutD <= PC_reg;
          2'b10: OutC <= AR_reg;
          2'b11: OutD <= SP_reg;
          default: OutD <= 8'b0;
        endcase
    end

endmodule