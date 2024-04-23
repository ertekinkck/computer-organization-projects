`timescale 1ns / 1ps
module RegisterFile(
    input wire Clock,
    input wire [15:0] I,
    input wire [2:0] FunSel,
    input wire [3:0] RegSel,
    input wire [3:0] ScrSel,
    input wire [2:0] OutASel,
    input wire [2:0] OutBSel,
    
    output reg [15:0] OutA,
    output reg [15:0] OutB
);

    wire [15:0] q_R1, q_R2, q_R3, q_R4;
    wire [15:0] q_S1, q_S2, q_S3, q_S4;

    always @(*) begin
          
    case(OutASel)
        3'b000: OutA <= q_R1;
        3'b001: OutA <= q_R2;
        3'b010: OutA <= q_R3;
        3'b011: OutA <= q_R4;
        3'b100: OutA <= q_S1;
        3'b101: OutA <= q_S2;
        3'b110: OutA <= q_S3;
        3'b111: OutA <= q_S4;
        endcase
    case(OutBSel)
        3'b000: OutB <= q_R1;
        3'b001: OutB <= q_R2;
        3'b010: OutB <= q_R3;
        3'b011: OutB <= q_R4;
        3'b100: OutB <= q_S1;
        3'b101: OutB <= q_S2;
        3'b110: OutB <= q_S3;
        3'b111: OutB <= q_S4;
        endcase 
    end
    
    Register R1(.I(I), .FunSel(FunSel), .E(~RegSel[3]), .Clock(Clock), .Q(q_R1));
    Register R2(.I(I), .FunSel(FunSel), .E(~RegSel[2]), .Clock(Clock), .Q(q_R2));
    Register R3(.I(I), .FunSel(FunSel), .E(~RegSel[1]), .Clock(Clock), .Q(q_R3));
    Register R4(.I(I), .FunSel(FunSel), .E(~RegSel[0]), .Clock(Clock), .Q(q_R4));
    Register S1(.I(I), .FunSel(FunSel), .E(~ScrSel[3]), .Clock(Clock), .Q(q_S1));
    Register S2(.I(I), .FunSel(FunSel), .E(~ScrSel[2]), .Clock(Clock), .Q(q_S2));
    Register S3(.I(I), .FunSel(FunSel), .E(~ScrSel[1]), .Clock(Clock), .Q(q_S3));
    Register S4(.I(I), .FunSel(FunSel), .E(~ScrSel[0]), .Clock(Clock), .Q(q_S4));
    
endmodule