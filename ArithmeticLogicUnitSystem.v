`timescale 1ns / 1ps

module MUX_4(
    input wire [15:0] I1,
    input wire Clock,
    input wire [15:0] I2,
    input wire [7:0] I3,
    input wire [7:0] I4,
    input wire [1:0] selector,
    output reg [15:0] MUX_output
);
    always @(*)begin
        case(selector)
        2'b00: MUX_output <= I1;
        2'b01: MUX_output <= I2; 
        2'b10: MUX_output <= {{8'b0}, I3 };
        2'b11: MUX_output <= { {8'b0}, I4};
        endcase
    end
endmodule

//------------------------------------------------------------------------------------------------------------

 module MUX_2(
    input wire [15:0] I1,
    input wire [15:0] I2,
    input wire Clock,
    input wire selector,
    
    output reg [7:0] MUX_output
);
    always @(*)begin
    case(selector)
    1'b0: MUX_output <= I1[7:0];
    1'b1: MUX_output <= I2[7:0]; 
    endcase
    end
endmodule

//---------------------------------------------------------------------------------------------------------

module ArithmeticLogicUnitSystem(
    input Clock,
    input wire [2:0] RF_OutASel,
    input wire [2:0] RF_OutBSel,
    input wire [2:0] RF_FunSel,
    
    input wire [3:0] RF_RegSel,
    input wire [3:0] RF_ScrSel,
    input wire [4:0] ALU_FunSel,
    
    input wire [1:0] ARF_OutCSel,
    input wire [1:0] ARF_OutDSel,
    
    input wire [2:0] ARF_FunSel,
    input wire [2:0] ARF_RegSel,
    
    input wire       IR_LH,
    input wire       IR_Write,
    input wire       Mem_CS,
    input wire       Mem_WR,
    
    input wire       ALU_WF,
    
    input wire [1:0] MuxASel,
    input wire [1:0] MuxBSel,
    input wire       MuxCSel
    
); 
    
    wire [15:0] OutA, OutB;
    wire [15:0] IROut;
    wire [15:0] MuxAOut, MuxBOut, MuxCOut, ALUOut, OutC, Address;
    wire [7:0] MemOut;
    wire [3:0] ALUOutFlag;

    RegisterFile RF(.Clock(Clock), .I(MuxAOut), .FunSel(RF_FunSel), .RegSel(RF_RegSel), .ScrSel(RF_ScrSel), .OutASel(RF_OutASel), .OutBSel(RF_OutBSel), .OutA(OutA), .OutB(OutB));
    InstructionRegister IR(.Clock(Clock), .LH(IR_LH), .IROut(IROut), .I(MemOut), .Write(IR_Write));
    MUX_4 MuxA(.Clock(Clock), .I1(ALUOut), .I2(OutC), .I3(IROut[7:0]), .I4(MemOut), .selector(MuxASel), .MUX_output(MuxAOut));
    MUX_4 MuxB(.Clock(Clock), .I1(ALUOut), .I2(OutC), .I3(IROut[7:0]), .I4(MemOut), .selector(MuxBSel), .MUX_output(MuxBOut));
    MUX_2 MuxC(.Clock(Clock), .I1(ALUOut), .I2(8'b00000000), .selector(MuxCSel), .MUX_output(MuxCOut));
    ArithmeticLogicUnit ALU(.A(MuxCOut), .B(OutB), .FunSel(ALU_FunSel), .ALUOut(ALUOut), .FlagsOut(ALUOutFlag), .Clock(Clock), .WF(ALU_WF));
    Memory MEM(.Clock(Clock), .Address(OutC), .MemOut(MemOut), .WR(Mem_WR), .CS(Mem_CS), .Data(ALUOut));
    AddressRegisterFile ARF(.Clock(Clock), .I(MuxBOut), .FunSel(ARF_FunSel), .OutCSel(ARF_OutCSel), .OutDSel(ARF_OutDSel), .RegSel(ARF_RegSel), .OutC(OutC), .OutD(Address));
    
  
endmodule