module SequenceCounter(
    input Clock,
    input Reset,
    input Increment,
    output reg [2:0] SCOut = 3'b000
);
    always@(posedge Clock)
        begin
            if(Reset)
                SCOut <= 0;
            else if(Increment)
                SCOut <= SCOut + 1;
            else
                SCOut <= SCOut;
        end   
endmodule

module Decoder3to8(
    input wire Enable,
    input wire [2:0] TimeDecoderInput,
    output reg [7:0] TimeDecoderOutput
);

    always@(*) begin
        if(Enable) 
        begin
            case(TimeDecoderInput)
                3'b000 : TimeDecoderOutput = 8'b00000001;   // T0 
                3'b001 : TimeDecoderOutput = 8'b00000010;   // T1
                3'b010 : TimeDecoderOutput = 8'b00000100;   // T2
                3'b011 : TimeDecoderOutput = 8'b00001000;   // T3
                3'b100 : TimeDecoderOutput = 8'b00010000;   // T4
                3'b101 : TimeDecoderOutput = 8'b00100000;   // T5
                3'b110 : TimeDecoderOutput = 8'b01000000;   // T6
                3'b111 : TimeDecoderOutput = 8'b10000000;   // T7
                default: TimeDecoderOutput = 8'b00000000;   // T0
            endcase    
        end 
        else
        begin
            TimeDecoderOutput = TimeDecoderOutput;    
        end
    end  
endmodule

module CPUSystem(
    input Clock,
    input Reset,
    output wire [7:0] T
);  
    reg  IR_LH, IR_Write, Mem_CS, Mem_WR, ALU_WF, MuxCSel, SCReset, IncrementSC, S;
    reg [1:0] ARF_OutCSel, ARF_OutDSel, MuxASel, MuxBSel, Rsel; 
    reg [2:0] RF_OutASel, RF_OutBSel, RF_FunSel, ARF_FunSel, SReg1, SReg2, DstReg;
    reg [2:0] ARF_RegSel;
    reg [3:0] RF_RegSel;
    reg [3:0] RF_ScrSel; 
    reg [3:0] RF_ScrSel_Extra;
    reg [4:0] ALU_FunSel;
    reg [5:0] OpCode;
    wire [2:0] TimeDecoderInput;
    wire [3:0] ALUOutFlag;
    wire [7:0] MemOut;
    wire [15:0] Address, IROut, ALUOut, MuxAOut, OutA, OutB, OutC;
    
   ArithmeticLogicUnitSystem _ALUSystem(.Clock(Clock), .RF_OutASel(RF_OutASel), .RF_OutBSel(RF_OutBSel), .RF_FunSel(RF_FunSel), .RF_RegSel(RF_RegSel),
                              .RF_ScrSel(RF_ScrSel), .ALU_FunSel(ALU_FunSel), .ALUOut(ALUOut), .ARF_OutCSel(ARF_OutCSel), .ARF_OutDSel(ARF_OutDSel), .ARF_FunSel(ARF_FunSel),
                              .ARF_RegSel(ARF_RegSel), .IROut(IROut), .IR_LH(IR_LH), .IR_Write(IR_Write), .Mem_CS(Mem_CS), .Mem_WR(Mem_WR),.MemOut(MemOut), .ALU_WF(ALU_WF), .MuxASel(MuxASel),
                              .MuxBSel(MuxBSel), .MuxCSel(MuxCSel), .Address(Address), .MuxAOut(MuxAOut), .OutA(OutA), .OutB(OutB), .OutC(OutC), .ALUOutFlag(ALUOutFlag));
                              
   SequenceCounter SC(Clock, SCReset, IncrementSC, TimeDecoderInput);
   Decoder3to8 TimeDecoder(1'b1,TimeDecoderInput, T);

    initial begin
        _ALUSystem.RF.R1.Q=16'h000a;
    end
    always @(*) begin
        if (!Reset) begin
            SCReset = 1;
        end
        if (Reset) begin
            SCReset = 0;
            IncrementSC = 1; // SC + 1
            case(T)
                1: begin  // IR LOW 8 BIT IS LOADING      // T = 0
                    RF_RegSel = 4'b1111; 
                    RF_ScrSel = 4'b1111;
                    IR_Write = 1; // Enable instruction register
                    IR_LH = 1'b0; 
                    Mem_WR = 1'b0; // memory read
                    Mem_CS = 1'b0; // memory enable
                    ARF_OutDSel = 2'b00; 
                    ARF_RegSel = 3'b011; // pc register enable
                    ARF_FunSel = 3'b001; // Pc register + 1 
                end
                2: begin //IR'nin son 8 biti y kleniyor.        // T = 1      
                    IR_LH = 1'b1; // son 8 biti y kle                      
                    OpCode = IROut[15:10];
                end  
                
                // OPCODE (6-bit) + RSEL (2-bit) + ADDRESS (8-bit)
                // OPCODE (6-bit) + S (1-bit) + DstReg (3-bit) + SReg1 (3-bit) + SReg2 (3-bit)

                4: begin // Fetch i lemi bitti. //Decode i lemi de yap lm   oldu bu a amada. // T = 2
                    ARF_RegSel = 3'b111; // PC register  disable et, artmamas  gerekiyor.
                    MuxBSel = 2'b00; // ARF'e aluout giri  yap yor.
                    Rsel = IROut[9:8]; // Rsel'i al.
                    IR_Write = 0; // Instruction register'i kapat.
                    Mem_CS = 1'b1; // Memory'yi disable et
                    SReg2 = IROut[2:0]; // SReg2'yi al.
                    SReg1 = IROut[5:3]; // SReg1'i al.
                    DstReg = IROut[8:6]; // DstReg'i al.
                    S = IROut[9]; // S'yi al.
                    case (OpCode)
                        6'b000000: begin // BRA PC <- PC + VALUE
                            _ALUSystem.ARF.AR.Q=16'hx;
                            _ALUSystem.ARF.SP.Q=16'hx;
                            _ALUSystem.ALU.FlagsOut=4'bxxxx;                                
                            MuxASel = 2'b11;
                            //$display("Rsel: %h", Rsel);
                            case (Rsel)
                                2'b00: begin // S1 and S2 is enabled.
                                    RF_ScrSel = 4'b0111;
                                    RF_OutASel = 3'b100;
                                    RF_ScrSel_Extra = 4'b1011;
                                    RF_OutBSel = 3'b101;
                                end
                                2'b01: begin // S2 and S1 is enabled.
                                    RF_ScrSel = 4'b1011;
                                    RF_OutASel = 3'b101;
                                    RF_ScrSel_Extra = 4'b0111;
                                    RF_OutBSel = 3'b100;
                                end
                                2'b10: begin // S3 and S1 is enabled.
                                    RF_ScrSel = 4'b1101;
                                    RF_OutASel = 3'b110;
                                    RF_ScrSel_Extra = 4'b0111;
                                    RF_OutBSel = 3'b100;
                                end
                                2'b11: begin // S4 and S1 is enabled.
                                    RF_ScrSel = 4'b1110;
                                    RF_OutASel = 3'b111;
                                    RF_ScrSel_Extra = 4'b0111;
                                    RF_OutBSel = 3'b100;
                                end                             
                            endcase
                            RF_FunSel = 3'b010; // Q = I    // S1 is loading.                            
                        end
                        6'b000001: begin // BNE IF Z=0 THEN PC <- PC + VALUE 
                            _ALUSystem.ARF.AR.Q=16'hx;
                            _ALUSystem.ARF.SP.Q=16'hx;                          
                            if(_ALUSystem.ALUOutFlag[3] == 0)begin
                                MuxASel = 2'b11;
                                case (Rsel)
                                    2'b00: begin // S1 and S2 is enabled.
                                        RF_ScrSel = 4'b0111;
                                        RF_OutASel = 3'b100;
                                        RF_ScrSel_Extra = 4'b1011;
                                        RF_OutBSel = 3'b101;
                                    end
                                    2'b01: begin // S2 and S1 is enabled.
                                        RF_ScrSel = 4'b1011;
                                        RF_OutASel = 3'b101;
                                        RF_ScrSel_Extra = 4'b0111;
                                        RF_OutBSel = 3'b100;
                                    end
                                    2'b10: begin // S3 and S1 is enabled.
                                        RF_ScrSel = 4'b1101;
                                        RF_OutASel = 3'b110;
                                        RF_ScrSel_Extra = 4'b0111;
                                        RF_OutBSel = 3'b100;
                                    end
                                    2'b11: begin // S4 and S1 is enabled.
                                        RF_ScrSel = 4'b1110;
                                        RF_OutASel = 3'b111;
                                        RF_ScrSel_Extra = 4'b0111;
                                        RF_OutBSel = 3'b100;
                                    end                             
                                endcase
                                RF_FunSel = 3'b010; // Q = I    // S1 is loading.                                
                            end else begin
                                SCReset = 1;
                            end
                        end
                        6'b000010: begin // BEQ IF Z=1 THEN PC <- PC + VALUE
                            _ALUSystem.ARF.AR.Q=16'hx;
                            _ALUSystem.ARF.SP.Q=16'hx;
                            if(_ALUSystem.ALUOutFlag[3] == 1)begin
                                MuxASel = 2'b11;
                                case (Rsel)
                                    2'b00: begin // S1 and S2 is enabled.
                                        RF_ScrSel = 4'b0111;
                                        RF_OutASel = 3'b100;
                                        RF_ScrSel_Extra = 4'b1011;
                                        RF_OutBSel = 3'b101;
                                    end
                                    2'b01: begin // S2 and S1 is enabled.
                                        RF_ScrSel = 4'b1011;
                                        RF_OutASel = 3'b101;
                                        RF_ScrSel_Extra = 4'b0111;
                                        RF_OutBSel = 3'b100;
                                    end
                                    2'b10: begin // S3 and S1 is enabled.
                                        RF_ScrSel = 4'b1101;
                                        RF_OutASel = 3'b110;
                                        RF_ScrSel_Extra = 4'b0111;
                                        RF_OutBSel = 3'b100;
                                    end
                                    2'b11: begin // S4 and S1 is enabled.
                                        RF_ScrSel = 4'b1110;
                                        RF_OutASel = 3'b111;
                                        RF_ScrSel_Extra = 4'b0111;
                                        RF_OutBSel = 3'b100;
                                    end                             
                                endcase
                                RF_FunSel = 3'b010; // Q = I    // S1 is loading.                                 
                            end else begin
                                SCReset = 1;
                            end
                        end
                        6'b000011: begin // POP SP <- SP + 1, Rx <- M[SP]
                            _ALUSystem.ARF.AR.Q=16'hx;
                            _ALUSystem.ALU.FlagsOut=4'bxxxx;                            
                            ARF_RegSel = 3'b110; // SP register  enable et
                            ARF_FunSel = 3'b001; // SP register  1 art r
                            
                            Mem_WR = 1'b0; // Memory'nin read modunu a 
                            Mem_CS = 1'b0; // Memory'yi enable et
                            ARF_OutDSel = 2'b11; // SP register  memout'a gidiyor.
                            MuxASel = 2'b10; // MuxAOut memout'a gidiyor.
                            RF_FunSel = 3'b010; // Q = I    // Sx is loading.
                            case (Rsel)
                                2'b00: begin // S1 is enabled.
                                    RF_RegSel = 4'b0111;
                                end
                                2'b01: begin // S2 is enabled.
                                    RF_RegSel = 4'b1011;
                                end
                                2'b10: begin // S3 is enabled.
                                    RF_RegSel = 4'b1101;
                                end
                                2'b11: begin // S4 is enabled.
                                    RF_RegSel = 4'b1110;
                                end                             
                            endcase
                        end
                        6'b000100: begin // PSH M[SP] <- Rx, SP <- SP - 1
                            _ALUSystem.ARF.AR.Q=16'hx;
                            _ALUSystem.ALU.FlagsOut=4'bxxxx;                            
                            Mem_WR = 1'b1; // Memory'nin write modunu a 
                            Mem_CS = 1'b0; // Memory'yi enable et
                            ARF_OutDSel = 2'b11; // SP register  address'e gidiyor.
                            ALU_FunSel = 10000; // Aluout'a A gidiyor.
                            MuxCSel = 1'b0; // AluOut[7:0] memory'e yaz l yor.
                            case (Rsel)
                                2'b00: begin // R1 is enabled.
                                    RF_RegSel = 4'b0111;
                                    RF_OutASel = 3'b000;
                                end
                                2'b01: begin // R2 is enabled.
                                    RF_RegSel = 4'b1011;
                                    RF_OutASel = 3'b001;
                                end
                                2'b10: begin // R3 is enabled.
                                    RF_RegSel = 4'b1101;
                                    RF_OutASel = 3'b010;
                                end
                                2'b11: begin // R4 is enabled.
                                    RF_RegSel = 4'b1110;
                                    RF_OutASel = 3'b011;
                                end                             
                            endcase
                        end
                        6'b000101: begin // INC DstReg <- SReg1 + 1
                      
                            ALU_FunSel = 5'b10000;                            
                            case(SReg1)
                                3'b000: ARF_OutCSel = 2'b00;
                                3'b001: ARF_OutCSel = 2'b01;
                                3'b010: ARF_OutCSel = 2'b11;
                                3'b011: ARF_OutCSel = 2'b10;
                                3'b100: RF_OutASel = 3'b000;
                                3'b101: RF_OutASel = 3'b001;
                                3'b110: RF_OutASel = 3'b010;
                                3'b111: RF_OutASel = 3'b011;
                            endcase
                            case(DstReg)
                                3'b000: ARF_RegSel = 3'b011;
                                3'b001: ARF_RegSel = 3'b011;
                                3'b010: ARF_RegSel = 3'b110;
                                3'b011: ARF_RegSel = 3'b101;
                                3'b100: RF_RegSel = 4'b0111;
                                3'b101: RF_RegSel = 4'b1011;
                                3'b110: RF_RegSel = 4'b1101;
                                3'b111: RF_RegSel = 4'b1110;                           
                            endcase 
                            if (DstReg[2] == 0 & SReg1[2] == 0) begin
                                MuxBSel = 2'b01;
                                ARF_FunSel = 3'b010;
                            end
                            if (DstReg[2] == 1 & SReg1[2] == 0) begin
                                MuxASel = 2'b01;
                                RF_FunSel = 3'b010;
                            end
                            if (DstReg[2] == 0 & SReg1[2] == 1) begin
                                MuxBSel = 2'b00;
                                ARF_FunSel = 3'b010;
                            end
                            if (DstReg[2] == 1 & SReg1[2] == 1) begin
                                MuxASel = 2'b00;
                                RF_FunSel = 3'b010;
                            end   
                        end
                        6'b000110: begin // DEC DstReg <- SReg1 - 1                       
                            ALU_FunSel = 5'b10000;
                            case(SReg1)
                                3'b000: ARF_OutCSel = 2'b00;
                                3'b001: ARF_OutCSel = 2'b01;
                                3'b010: ARF_OutCSel = 2'b11;
                                3'b011: ARF_OutCSel = 2'b10;
                                3'b100: RF_OutASel = 3'b000;
                                3'b101: RF_OutASel = 3'b001;
                                3'b110: RF_OutASel = 3'b010;
                                3'b111: RF_OutASel = 3'b011;
                            endcase
                            case(DstReg)
                                3'b000: ARF_RegSel = 3'b011;
                                3'b001: ARF_RegSel = 3'b011;
                                3'b010: ARF_RegSel = 3'b110;
                                3'b011: ARF_RegSel = 3'b101;
                                3'b100: RF_RegSel = 4'b0111;
                                3'b101: RF_RegSel = 4'b1011;
                                3'b110: RF_RegSel = 4'b1101;
                                3'b111: RF_RegSel = 4'b1110;                           
                            endcase 
                            if (DstReg[2] == 0 & SReg1[2] == 0) begin
                                MuxBSel = 2'b01;
                                ARF_FunSel = 3'b010;
                            end
                            if (DstReg[2] == 1 & SReg1[2] == 0) begin
                                MuxASel = 2'b01;
                                RF_FunSel = 3'b010;
                            end
                            if (DstReg[2] == 0 & SReg1[2] == 1) begin
                                MuxBSel = 2'b00;
                                ARF_FunSel = 3'b010;
                            end
                            if (DstReg[2] == 1 & SReg1[2] == 1) begin
                                MuxASel = 2'b00;
                                RF_FunSel = 3'b010;
                            end  
                        end
                        6'b000111: begin // LSL DstReg <- LSL SReg1                            
                            ALU_FunSel = 5'b10000;                           
                            case(SReg1)
                                3'b000: ARF_OutCSel = 2'b00;
                                3'b001: ARF_OutCSel = 2'b01;
                                3'b010: ARF_OutCSel = 2'b11;
                                3'b011: ARF_OutCSel = 2'b10;
                                3'b100: RF_OutASel = 3'b000;
                                3'b101: RF_OutASel = 3'b001;
                                3'b110: RF_OutASel = 3'b010;
                                3'b111: RF_OutASel = 3'b011;
                            endcase
                            RF_RegSel = 4'b0111;
                            RF_FunSel = 3'b010;
                            if (SReg1[2] == 0) begin //MUXASEL
                                MuxASel = 2'b01; // OUTC
                            end
                            if (SReg1[2] == 1) begin
                                MuxASel = 2'b00;                                                       
                            end
                        end
                        6'b001000: begin // LSR DstReg <- LSR SReg1                    
                            ALU_FunSel = 5'b10000;                           
                            case(SReg1)
                                3'b000: ARF_OutCSel = 2'b00;
                                3'b001: ARF_OutCSel = 2'b01;
                                3'b010: ARF_OutCSel = 2'b11;
                                3'b011: ARF_OutCSel = 2'b10;
                                3'b100: RF_OutASel = 3'b000;
                                3'b101: RF_OutASel = 3'b001;
                                3'b110: RF_OutASel = 3'b010;
                                3'b111: RF_OutASel = 3'b011;
                            endcase
                            RF_RegSel = 4'b0111;
                            RF_FunSel = 3'b010;
                            if (SReg1[2] == 0) begin //MUXASEL
                                MuxASel = 2'b01; // OUTC
                            end
                            if (SReg1[2] == 1) begin
                                MuxASel = 2'b00;                                                       
                            end
                        end
                        6'b001001: begin // ASR DstReg <- ASR SReg1
                      
                            ALU_FunSel = 5'b10000;                           
                            case(SReg1)
                                3'b000: ARF_OutCSel = 2'b00;
                                3'b001: ARF_OutCSel = 2'b01;
                                3'b010: ARF_OutCSel = 2'b11;
                                3'b011: ARF_OutCSel = 2'b10;
                                3'b100: RF_OutASel = 3'b000;
                                3'b101: RF_OutASel = 3'b001;
                                3'b110: RF_OutASel = 3'b010;
                                3'b111: RF_OutASel = 3'b011;
                            endcase
                            RF_RegSel = 4'b0111;
                            RF_FunSel = 3'b010;
                            if (SReg1[2] == 0) begin //MUXASEL
                                MuxASel = 2'b01; // OUTC
                            end
                            if (SReg1[2] == 1) begin
                                MuxASel = 2'b00;                                                       
                            end                        
                        end
                        6'b001010: begin // CSL DstReg <- CSL SReg1                        
                            ALU_FunSel = 5'b10000;                           
                            case(SReg1)
                                3'b000: ARF_OutCSel = 2'b00;
                                3'b001: ARF_OutCSel = 2'b01;
                                3'b010: ARF_OutCSel = 2'b11;
                                3'b011: ARF_OutCSel = 2'b10;
                                3'b100: RF_OutASel = 3'b000;
                                3'b101: RF_OutASel = 3'b001;
                                3'b110: RF_OutASel = 3'b010;
                                3'b111: RF_OutASel = 3'b011;
                            endcase
                            RF_RegSel = 4'b0111;
                            RF_FunSel = 3'b010;
                            if (SReg1[2] == 0) begin //MUXASEL
                                MuxASel = 2'b01; // OUTC
                            end
                            if (SReg1[2] == 1) begin
                                MuxASel = 2'b00;                                                       
                            end                        
                        end
                        6'b001011: begin // CSR DstReg <- CSR SReg1                         
                            ALU_FunSel = 5'b10000;                           
                            case(SReg1)
                                3'b000: ARF_OutCSel = 2'b00;
                                3'b001: ARF_OutCSel = 2'b01;
                                3'b010: ARF_OutCSel = 2'b11;
                                3'b011: ARF_OutCSel = 2'b10;
                                3'b100: RF_OutASel = 3'b000;
                                3'b101: RF_OutASel = 3'b001;
                                3'b110: RF_OutASel = 3'b010;
                                3'b111: RF_OutASel = 3'b011;
                            endcase
                            RF_RegSel = 4'b0111;
                            RF_FunSel = 3'b010;
                            if (SReg1[2] == 0) begin //MUXASEL
                                MuxASel = 2'b01; // OUTC
                            end
                            if (SReg1[2] == 1) begin
                                MuxASel = 2'b00;                                                       
                            end                        
                        end
                        6'b001100: begin // AND DstReg <- SReg1 AND SReg2;                        
                            case (SReg1)
                                3'b000: ARF_OutCSel = 2'b00;
                                3'b001: ARF_OutCSel = 2'b01;
                                3'b010: ARF_OutCSel = 2'b11;
                                3'b011: ARF_OutCSel = 2'b10;
                                3'b100: RF_OutASel = 3'b000;
                                3'b101: RF_OutASel = 3'b001;
                                3'b110: RF_OutASel = 3'b010;
                                3'b111: RF_OutASel = 3'b011;
                            endcase
                            if (SReg1[2] == 0) begin
                                MuxASel = 2'b01;
                                RF_ScrSel = 4'b0111;
                                RF_FunSel = 3'b010;
                                RF_OutASel = 3'b100;
                            end                             
                        end
                        6'b001101: begin // ORR DstReg <- SReg1 OR SReg2                         
                            case (SReg1)
                                3'b000: ARF_OutCSel = 2'b00;
                                3'b001: ARF_OutCSel = 2'b01;
                                3'b010: ARF_OutCSel = 2'b11;
                                3'b011: ARF_OutCSel = 2'b10;
                                3'b100: RF_OutASel = 3'b000;
                                3'b101: RF_OutASel = 3'b001;
                                3'b110: RF_OutASel = 3'b010;
                                3'b111: RF_OutASel = 3'b011;
                            endcase
                            if (SReg1[2] == 0) begin
                                MuxASel = 2'b01;
                                RF_ScrSel = 4'b0111;
                                RF_FunSel = 3'b010;
                                RF_OutASel = 3'b100;
                            end                             
                        end
                        6'b001110: begin // NOT DstReg <- NOT SReg1                         
                            ALU_FunSel = 5'b10000;                           
                            case(SReg1)
                                3'b000: ARF_OutCSel = 2'b00;
                                3'b001: ARF_OutCSel = 2'b01;
                                3'b010: ARF_OutCSel = 2'b11;
                                3'b011: ARF_OutCSel = 2'b10;
                                3'b100: RF_OutASel = 3'b000;
                                3'b101: RF_OutASel = 3'b001;
                                3'b110: RF_OutASel = 3'b010;
                                3'b111: RF_OutASel = 3'b011;
                            endcase
                            RF_RegSel = 4'b0111;
                            RF_FunSel = 3'b010;
                            if (SReg1[2] == 0) begin //MUXASEL
                                MuxASel = 2'b01; // OUTC
                            end
                            if (SReg1[2] == 1) begin
                                MuxASel = 2'b00;                                                       
                            end                        
                        end
                        6'b001111: begin // XOR DstReg <- SReg1 XOR SReg2                        
                            case (SReg1)
                                3'b000: ARF_OutCSel = 2'b00;
                                3'b001: ARF_OutCSel = 2'b01;
                                3'b010: ARF_OutCSel = 2'b11;
                                3'b011: ARF_OutCSel = 2'b10;
                                3'b100: RF_OutASel = 3'b000;
                                3'b101: RF_OutASel = 3'b001;
                                3'b110: RF_OutASel = 3'b010;
                                3'b111: RF_OutASel = 3'b011;
                            endcase
                            if (SReg1[2] == 0) begin
                                MuxASel = 2'b01;
                                RF_ScrSel = 4'b0111;
                                RF_FunSel = 3'b010;
                                RF_OutASel = 3'b100;
                            end                             
                        end
                        6'b010000: begin // NAND DstReg <- SReg1 NAND SReg2                         
                            case (SReg1)
                                3'b000: ARF_OutCSel = 2'b00;
                                3'b001: ARF_OutCSel = 2'b01;
                                3'b010: ARF_OutCSel = 2'b11;
                                3'b011: ARF_OutCSel = 2'b10;
                                3'b100: RF_OutASel = 3'b000;
                                3'b101: RF_OutASel = 3'b001;
                                3'b110: RF_OutASel = 3'b010;
                                3'b111: RF_OutASel = 3'b011;
                            endcase
                            if (SReg1[2] == 0) begin
                                MuxASel = 2'b01;
                                RF_ScrSel = 4'b0111;
                                RF_FunSel = 3'b010;
                                RF_OutASel = 3'b100;
                            end                         
                        end
                        6'b010001: begin // MOVH DstReg[15:8] <- IMMEDIATE (8-bit)
                            case (DstReg)
                                3'b000: begin 
                                    ARF_RegSel = 3'b011; 
                                    MuxBSel = 2'b11; 
                                end
                                3'b001: begin 
                                    ARF_RegSel = 3'b011; 
                                    MuxBSel = 2'b11; 
                                end
                                3'b010: begin 
                                    ARF_RegSel = 3'b110; 
                                    MuxBSel = 2'b11; 
                                end
                                3'b011: begin 
                                    ARF_RegSel = 3'b101; 
                                    MuxBSel = 2'b11; 
                                end
                                3'b100: begin 
                                    RF_RegSel = 4'b0111; 
                                    MuxASel = 2'b11; 
                                    end
                                3'b101: begin 
                                    RF_RegSel = 4'b1011; 
                                    MuxASel = 2'b11; 
                                    end
                                3'b110: begin 
                                    RF_RegSel = 4'b1101; 
                                    MuxASel = 2'b11; 
                                    end
                                3'b111: begin 
                                    RF_RegSel = 4'b1110; 
                                    MuxASel = 2'b11; 
                                    end
                            endcase
                            if (DstReg[2] == 0) begin
                                ARF_FunSel = 3'b110;
                            end
                            if (DstReg[2] == 1) begin
                                RF_FunSel = 3'b110;
                            end                        
                        end
                        6'b010010: begin // LDR (16-bit) Rx <- M[AR] (AR is 16-bit register) 
                            ARF_OutDSel = 2'b10;
                            Mem_WR = 1'b0;
                            Mem_CS = 1'b0;
                            MuxASel = 2'b10;
                            case (Rsel)
                                2'b00: RF_RegSel = 4'b0111;
                                2'b01: RF_RegSel = 4'b1011;
                                2'b10: RF_RegSel = 4'b1101;
                                2'b11: RF_RegSel = 4'b1110;
                            endcase
                            RF_FunSel = 3'b010;                                                              
                        end
                        6'b010011: begin // STR (16-bit) M[AR] <- Rx (AR is 16-bit register)
                            case (Rsel)
                                2'b00: RF_OutASel = 3'b000;
                                2'b01: RF_OutASel = 3'b001;
                                2'b10: RF_OutASel = 3'b010;
                                2'b11: RF_OutASel = 3'b001;
                            endcase
                            ALU_FunSel = 5'b10000;
                            ARF_OutDSel = 2'b10;
                            ARF_RegSel = 3'b101;
                            ARF_FunSel = 3'b001;
                            MuxCSel = 1'b0;
                            Mem_CS = 0;
                            Mem_WR = 1;
                        end
                        6'b010100: begin // MOVL DstReg[7:0] <-  IMMEDIATE (8-bit)
                            case (DstReg)
                                3'b000: begin 
                                    ARF_RegSel = 3'b011; 
                                    MuxBSel = 2'b11; 
                                end
                                3'b001: begin 
                                    ARF_RegSel = 3'b011; 
                                    MuxBSel = 2'b11; 
                                end
                                3'b010: begin 
                                    ARF_RegSel = 3'b110; 
                                    MuxBSel = 2'b11; 
                                end
                                3'b011: begin 
                                    ARF_RegSel = 3'b101; 
                                    MuxBSel = 2'b11; 
                                end
                                3'b100: begin 
                                    RF_RegSel = 4'b0111; 
                                    MuxASel = 2'b11; 
                                    end
                                3'b101: begin 
                                    RF_RegSel = 4'b1011; 
                                    MuxASel = 2'b11; 
                                    end
                                3'b110: begin 
                                    RF_RegSel = 4'b1101; 
                                    MuxASel = 2'b11; 
                                    end
                                3'b111: begin 
                                    RF_RegSel = 4'b1110; 
                                    MuxASel = 2'b11; 
                                    end
                            endcase
                            if (DstReg[2] == 0) begin
                                ARF_FunSel = 3'b101;
                            end
                            if (DstReg[2] == 1) begin
                                RF_FunSel = 3'b101;
                            end                                
                        end
                        6'b010101: begin // ADD DstReg <- SReg1 + SReg2
                            case (SReg1)
                                3'b000: ARF_OutCSel = 2'b00;
                                3'b001: ARF_OutCSel = 2'b01;
                                3'b010: ARF_OutCSel = 2'b11;
                                3'b011: ARF_OutCSel = 2'b10;
                                3'b100: RF_OutASel = 3'b000;
                                3'b101: RF_OutASel = 3'b001;
                                3'b110: RF_OutASel = 3'b010;
                                3'b111: RF_OutASel = 3'b011;
                            endcase
                            if (SReg1[2] == 0) begin
                                MuxASel = 2'b01;
                                RF_ScrSel = 4'b0111;
                                RF_FunSel = 3'b010;
                                RF_OutASel = 3'b100;
                            end                              
                        end
                        6'b010110: begin // ADC DstReg <- SReg1 + SReg2 + CARRY
                            case (SReg1)
                                3'b000: ARF_OutCSel = 2'b00;
                                3'b001: ARF_OutCSel = 2'b01;
                                3'b010: ARF_OutCSel = 2'b11;
                                3'b011: ARF_OutCSel = 2'b10;
                                3'b100: RF_OutASel = 3'b000;
                                3'b101: RF_OutASel = 3'b001;
                                3'b110: RF_OutASel = 3'b010;
                                3'b111: RF_OutASel = 3'b011;
                            endcase
                            if (SReg1[2] == 0) begin
                                MuxASel = 2'b01;
                                RF_ScrSel = 4'b0111;
                                RF_FunSel = 3'b010;
                                RF_OutASel = 3'b100;
                            end                         
                        end
                        6'b010111: begin // SUB DstReg <- SReg1 - SReg2
                            case (SReg1)
                                3'b000: ARF_OutCSel = 2'b00;
                                3'b001: ARF_OutCSel = 2'b01;
                                3'b010: ARF_OutCSel = 2'b11;
                                3'b011: ARF_OutCSel = 2'b10;
                                3'b100: RF_OutASel = 3'b000;
                                3'b101: RF_OutASel = 3'b001;
                                3'b110: RF_OutASel = 3'b010;
                                3'b111: RF_OutASel = 3'b011;
                            endcase
                            if (SReg1[2] == 0) begin
                                MuxASel = 2'b01;
                                RF_ScrSel = 4'b0111;
                                RF_FunSel = 3'b010;
                                RF_OutASel = 3'b100;
                            end                         
                        end
                        6'b011000: begin // MOVS DstReg <- SReg1, Flags will change
                            ALU_WF = 1;
                            case (SReg1)
                                3'b000: ARF_OutCSel = 2'b00;
                                3'b001: ARF_OutCSel = 2'b01;
                                3'b010: ARF_OutCSel = 2'b11;
                                3'b011: ARF_OutCSel = 2'b10;
                                3'b100: RF_OutASel = 3'b000;
                                3'b101: RF_OutASel = 3'b001;
                                3'b110: RF_OutASel = 3'b010;
                                3'b111: RF_OutASel = 3'b011;
                            endcase
                            if (SReg1[2] == 0) begin
                                MuxASel=2'b01;
                                RF_ScrSel = 4'b0111;
                                RF_FunSel = 3'b010;
                                RF_OutBSel = 3'b100;
                                ALU_FunSel = 5'b10001;
                            end
                            if(SReg1[2] == 1)begin
                                ALU_FunSel = 5'b10000;
                            end                          
                        end
                        6'b011001: begin // ADDS DstReg <- SReg1 + SReg2, Flags will change
                            ALU_WF = 1;
                            case (SReg1)
                                3'b000: ARF_OutCSel = 2'b00;
                                3'b001: ARF_OutCSel = 2'b01;
                                3'b010: ARF_OutCSel = 2'b11;
                                3'b011: ARF_OutCSel = 2'b10;
                                3'b100: RF_OutASel = 3'b000;
                                3'b101: RF_OutASel = 3'b001;
                                3'b110: RF_OutASel = 3'b010;
                                3'b111: RF_OutASel = 3'b011;
                            endcase
                            if (SReg1[2] == 0) begin
                                MuxASel = 2'b01;
                                RF_ScrSel = 4'b0111;
                                RF_FunSel = 3'b010;
                                RF_OutASel = 3'b100;
                            end                         
                        end
                        6'b011010: begin // SUBS DstReg <- SReg1 - SReg2, Flags will change
                            ALU_WF = 1;
                            case (SReg1)
                                3'b000: ARF_OutCSel = 2'b00;
                                3'b001: ARF_OutCSel = 2'b01;
                                3'b010: ARF_OutCSel = 2'b11;
                                3'b011: ARF_OutCSel = 2'b10;
                                3'b100: RF_OutASel = 3'b000;
                                3'b101: RF_OutASel = 3'b001;
                                3'b110: RF_OutASel = 3'b010;
                                3'b111: RF_OutASel = 3'b011;
                            endcase
                            if (SReg1[2] == 0) begin
                                MuxASel = 2'b01;
                                RF_ScrSel = 4'b0111;
                                RF_FunSel = 3'b010;
                                RF_OutASel = 3'b100;
                            end                        
                        end
                        6'b011011: begin // ANDS DstReg <- SReg1 AND SReg2, Flags will change
                            ALU_WF = 1;
                            case (SReg1)
                                3'b000: ARF_OutCSel = 2'b00;
                                3'b001: ARF_OutCSel = 2'b01;
                                3'b010: ARF_OutCSel = 2'b11;
                                3'b011: ARF_OutCSel = 2'b10;
                                3'b100: RF_OutASel = 3'b000;
                                3'b101: RF_OutASel = 3'b001;
                                3'b110: RF_OutASel = 3'b010;
                                3'b111: RF_OutASel = 3'b011;
                            endcase
                            if (SReg1[2] == 0) begin
                                MuxASel = 2'b01;
                                RF_ScrSel = 4'b0111;
                                RF_FunSel = 3'b010;
                                RF_OutASel = 3'b100;
                            end                          
                        end
                        6'b011100: begin // ORRS DstReg <- SReg1 OR SReg2, Flags will change
                            ALU_WF = 1;
                            case (SReg1)
                                3'b000: ARF_OutCSel = 2'b00;
                                3'b001: ARF_OutCSel = 2'b01;
                                3'b010: ARF_OutCSel = 2'b11;
                                3'b011: ARF_OutCSel = 2'b10;
                                3'b100: RF_OutASel = 3'b000;
                                3'b101: RF_OutASel = 3'b001;
                                3'b110: RF_OutASel = 3'b010;
                                3'b111: RF_OutASel = 3'b011;
                            endcase
                            if (SReg1[2] == 0) begin
                                MuxASel = 2'b01;
                                RF_ScrSel = 4'b0111;
                                RF_FunSel = 3'b010;
                                RF_OutASel = 3'b100;
                            end                          
                        end
                        6'b011101: begin // XORS DstReg <- SReg1 XOR SReg2, Flags will change
                            ALU_WF = 1;
                            case (SReg1)
                                3'b000: ARF_OutCSel = 2'b00;
                                3'b001: ARF_OutCSel = 2'b01;
                                3'b010: ARF_OutCSel = 2'b11;
                                3'b011: ARF_OutCSel = 2'b10;
                                3'b100: RF_OutASel = 3'b000;
                                3'b101: RF_OutASel = 3'b001;
                                3'b110: RF_OutASel = 3'b010;
                                3'b111: RF_OutASel = 3'b011;
                            endcase
                            if (SReg1[2] == 0) begin
                                MuxASel = 2'b01;
                                RF_ScrSel = 4'b0111;
                                RF_FunSel = 3'b010;
                                RF_OutASel = 3'b100;
                            end                          
                        end
                        6'b011110: begin // BX M[SP] <- PC, PC <- Rx
                            ARF_OutCSel = 2'b00;
                            MuxASel = 2'b01;
                            RF_ScrSel = 4'b0111;
                            RF_FunSel = 3'b010;    
                        end
                        6'b011111: begin // BL PC <- M[SP]
                            Mem_WR = 1'b0;
                            Mem_CS = 1'b0;                        
                            ARF_OutDSel = 2'b11;
                            MuxBSel = 2'b10;
                            ARF_RegSel = 3'b011;
                            ARF_FunSel = 3'b010;
                        end
                        6'b100000: begin // LDRIM Rx <- VALUE (VALUE defined in ADDRESS bits)
                            MuxASel = 2'b11;
                            case (Rsel)
                                2'b00: begin // R1 is enabled.
                                    RF_RegSel = 4'b0111;
                                end
                                2'b01: begin // R2 is enabled.
                                    RF_RegSel = 4'b1011;
                                end
                                2'b10: begin // R3 is enabled.
                                    RF_RegSel = 4'b1101;
                                end
                                2'b11: begin // R4 is enabled.
                                    RF_RegSel = 4'b1110;
                                end                             
                            endcase
                            RF_FunSel = 3'b010;                            
                        end
                        6'b100001: begin // STRIM M[AR+OFFSET] <- Rx (AR is 16-bit register) (OFFSET defined in Address bits)
                            RF_FunSel = 3'b100;
                            MuxASel = 2'b11;
                            RF_ScrSel = 4'b0111;                            
                            RF_OutASel = 3'b100;                            
                        end                          
                    endcase                      
                end                
                8: begin // EXECUTE  T = 3                    
                    case (OpCode)
                        6'b000000: begin // BRA PC <- PC + VALUE                        
                            ARF_OutCSel = 2'b00; // PC'y  ARF'nin   k   na veriyor.
                            MuxASel = 2'b01; // RF input is changing.
                            RF_ScrSel = RF_ScrSel_Extra;  //S2'ye PC y kleniyor.
                            ALU_FunSel = 5'b10100; // A + B                            
                        end
                        6'b000001: begin // BNE IF Z=0 THEN PC <- PC + VALUE 
                            ARF_OutCSel = 2'b00; // PC'y  ARF'nin   k   na veriyor.
                            MuxASel = 2'b01; // RF input is changing.
                            RF_ScrSel = RF_ScrSel_Extra;  //S2'ye PC y kleniyor.                            
                            ALU_FunSel = 5'b10100;
                        end
                        6'b000010: begin // BEQ IF Z=1 THEN PC <- PC + VALUE
                            ARF_OutCSel = 2'b00; // PC'y  ARF'nin   k   na veriyor.
                            MuxASel = 2'b01; // RF input is changing.
                            RF_ScrSel = RF_ScrSel_Extra;  //S2'ye PC y kleniyor.                            
                            ALU_FunSel = 5'b10100; // A + B  
                        end
                        6'b000011: begin // POP SP <- SP + 1, Rx <- M[SP]
                            RF_ScrSel = 4'b1111;
                            Mem_CS = 1'b1; // Memory'yi disable et
                            ARF_RegSel = 3'b111; // SP register  disable et
                            SCReset = 1;
                        end
                        6'b000100: begin // PSH M[SP] <- Rx, SP <- SP - 1
                            MuxCSel = 1'b1; // AluOut[15:8] memory'e yaz l yor.
                            ARF_RegSel = 3'b110; // SP register  enable et
                            ARF_FunSel = 3'b00;  // SP register  1 azalt   // 1 clock cycle s recek.
                        end
                        6'b000101: begin // INC DstReg <- SReg1 + 1
                            if (DstReg[2] == 0) begin
                                ARF_FunSel = 3'b001;
                            end
                            if (DstReg[2] == 1) begin
                                RF_FunSel = 3'b001;
                            end
                            SCReset = 1;
                        end
                        6'b000110: begin // DEC DstReg <- SReg1 - 1
                            if (DstReg[2] == 0) begin
                                ARF_FunSel = 3'b000;
                            end
                            if (DstReg[2] == 1) begin
                                RF_FunSel = 3'b000;
                            end
                            SCReset = 1;
                        end
                        6'b000111: begin // LSL DstReg <- LSL SReg1
                            RF_OutASel = 3'b000;
                            ALU_FunSel = 5'b11011;
                            case(DstReg)
                                3'b000: ARF_RegSel = 3'b011;
                                3'b001: ARF_RegSel = 3'b011;
                                3'b010: ARF_RegSel = 3'b110;
                                3'b011: ARF_RegSel = 3'b101;
                                3'b100: RF_RegSel = 4'b0111;
                                3'b101: RF_RegSel = 4'b1011;
                                3'b110: RF_RegSel = 4'b1101;
                                3'b111: RF_RegSel = 4'b1110;                           
                            endcase
                            if (DstReg[2] == 0) begin
                                MuxBSel = 2'b00;
                                ARF_FunSel = 3'b010;
                            end
                            if (DstReg[2] == 1) begin
                                MuxASel = 2'b00;
                                RF_FunSel = 3'b010;
                            end
                        end
                        6'b001000: begin // LSR DstReg <- LSR SReg1
                            RF_OutASel = 3'b000;
                            ALU_FunSel = 5'b11100;
                            case(DstReg)
                                3'b000: ARF_RegSel = 3'b011;
                                3'b001: ARF_RegSel = 3'b011;
                                3'b010: ARF_RegSel = 3'b110;
                                3'b011: ARF_RegSel = 3'b101;
                                3'b100: RF_RegSel = 4'b0111;
                                3'b101: RF_RegSel = 4'b1011;
                                3'b110: RF_RegSel = 4'b1101;
                                3'b111: RF_RegSel = 4'b1110;                           
                            endcase
                            if (DstReg[2] == 0) begin
                                MuxBSel = 2'b00;
                                ARF_FunSel = 3'b010;
                            end
                            if (DstReg[2] == 1) begin
                                MuxASel = 2'b00;
                                RF_FunSel = 3'b010;
                            end                        
                        end
                        6'b001001: begin // ASR DstReg <- ASR SReg1
                            RF_OutASel = 3'b000;
                            ALU_FunSel = 5'b11101;
                            case(DstReg)
                                3'b000: ARF_RegSel = 3'b011;
                                3'b001: ARF_RegSel = 3'b011;
                                3'b010: ARF_RegSel = 3'b110;
                                3'b011: ARF_RegSel = 3'b101;
                                3'b100: RF_RegSel = 4'b0111;
                                3'b101: RF_RegSel = 4'b1011;
                                3'b110: RF_RegSel = 4'b1101;
                                3'b111: RF_RegSel = 4'b1110;                           
                            endcase
                            if (DstReg[2] == 0) begin
                                MuxBSel = 2'b00;
                                ARF_FunSel = 3'b010;
                            end
                            if (DstReg[2] == 1) begin
                                MuxASel = 2'b00;
                                RF_FunSel = 3'b010;
                            end                        
                        end
                        6'b001010: begin // CSL DstReg <- CSL SReg1
                            RF_OutASel = 3'b000;
                            ALU_FunSel = 5'b11110;
                            case(DstReg)
                                3'b000: ARF_RegSel = 3'b011;
                                3'b001: ARF_RegSel = 3'b011;
                                3'b010: ARF_RegSel = 3'b110;
                                3'b011: ARF_RegSel = 3'b101;
                                3'b100: RF_RegSel = 4'b0111;
                                3'b101: RF_RegSel = 4'b1011;
                                3'b110: RF_RegSel = 4'b1101;
                                3'b111: RF_RegSel = 4'b1110;                           
                            endcase
                            if (DstReg[2] == 0) begin
                                MuxBSel = 2'b00;
                                ARF_FunSel = 3'b010;
                            end
                            if (DstReg[2] == 1) begin
                                MuxASel = 2'b00;
                                RF_FunSel = 3'b010;
                            end                        
                        end
                        6'b001011: begin // CSR DstReg <- CSR SReg1  
                            RF_OutASel = 3'b000;
                            ALU_FunSel = 5'b11111;
                            case(DstReg)
                                3'b000: ARF_RegSel = 3'b011;
                                3'b001: ARF_RegSel = 3'b011;
                                3'b010: ARF_RegSel = 3'b110;
                                3'b011: ARF_RegSel = 3'b101;
                                3'b100: RF_RegSel = 4'b0111;
                                3'b101: RF_RegSel = 4'b1011;
                                3'b110: RF_RegSel = 4'b1101;
                                3'b111: RF_RegSel = 4'b1110;                           
                            endcase
                            if (DstReg[2] == 0) begin
                                MuxBSel = 2'b00;
                                ARF_FunSel = 3'b010;
                            end
                            if (DstReg[2] == 1) begin
                                MuxASel = 2'b00;
                                RF_FunSel = 3'b010;
                            end                        
                        end
                        6'b001100: begin // AND DstReg <- SReg1 AND SReg2
                            case (SReg2)
                                3'b000: ARF_OutCSel = 2'b00;
                                3'b001: ARF_OutCSel = 2'b01;
                                3'b010: ARF_OutCSel = 2'b11;
                                3'b011: ARF_OutCSel = 2'b10;
                                3'b100: RF_OutBSel = 3'b000;
                                3'b101: RF_OutBSel = 3'b001;
                                3'b110: RF_OutBSel = 3'b010;
                                3'b111: RF_OutBSel = 3'b011;
                            endcase
                            if (SReg2[2] == 0) begin
                                MuxASel = 2'b01;
                                RF_ScrSel = 4'b1011;
                                RF_FunSel = 3'b010;
                                RF_OutBSel = 3'b101;
                            end                            
                        end
                        6'b001101: begin // ORR DstReg <- SReg1 OR SReg2
                            case (SReg2)
                                3'b000: ARF_OutCSel = 2'b00;
                                3'b001: ARF_OutCSel = 2'b01;
                                3'b010: ARF_OutCSel = 2'b11;
                                3'b011: ARF_OutCSel = 2'b10;
                                3'b100: RF_OutBSel = 3'b000;
                                3'b101: RF_OutBSel = 3'b001;
                                3'b110: RF_OutBSel = 3'b010;
                                3'b111: RF_OutBSel = 3'b011;
                            endcase
                            if (SReg2[2] == 0) begin
                                MuxASel = 2'b01;
                                RF_ScrSel = 4'b1011;
                                RF_FunSel = 3'b010;
                                RF_OutBSel = 3'b101;
                            end                         
                        end
                        6'b001110: begin // NOT DstReg <- NOT SReg1
                            RF_OutASel = 3'b000;
                            ALU_FunSel = 5'b10010;
                            case(DstReg)
                                3'b000: ARF_RegSel = 3'b011;
                                3'b001: ARF_RegSel = 3'b011;
                                3'b010: ARF_RegSel = 3'b110;
                                3'b011: ARF_RegSel = 3'b101;
                                3'b100: RF_RegSel = 4'b0111;
                                3'b101: RF_RegSel = 4'b1011;
                                3'b110: RF_RegSel = 4'b1101;
                                3'b111: RF_RegSel = 4'b1110;                           
                            endcase
                            if (DstReg[2] == 0) begin
                                MuxBSel = 2'b00;
                                ARF_FunSel = 3'b010;
                            end
                            if (DstReg[2] == 1) begin
                                MuxASel = 2'b00;
                                RF_FunSel = 3'b010;
                            end                        
                        end
                        6'b001111: begin // XOR DstReg <- SReg1 XOR SReg2
                            case (SReg2)
                                3'b000: ARF_OutCSel = 2'b00;
                                3'b001: ARF_OutCSel = 2'b01;
                                3'b010: ARF_OutCSel = 2'b11;
                                3'b011: ARF_OutCSel = 2'b10;
                                3'b100: RF_OutBSel = 3'b000;
                                3'b101: RF_OutBSel = 3'b001;
                                3'b110: RF_OutBSel = 3'b010;
                                3'b111: RF_OutBSel = 3'b011;
                            endcase
                            if (SReg2[2] == 0) begin
                                MuxASel = 2'b01;
                                RF_ScrSel = 4'b1011;
                                RF_FunSel = 3'b010;
                                RF_OutBSel = 3'b101;
                            end                         
                        end
                        6'b010000: begin // NAND DstReg <- SReg1 NAND SReg2
                            case (SReg2)
                                3'b000: ARF_OutCSel = 2'b00;
                                3'b001: ARF_OutCSel = 2'b01;
                                3'b010: ARF_OutCSel = 2'b11;
                                3'b011: ARF_OutCSel = 2'b10;
                                3'b100: RF_OutBSel = 3'b000;
                                3'b101: RF_OutBSel = 3'b001;
                                3'b110: RF_OutBSel = 3'b010;
                                3'b111: RF_OutBSel = 3'b011;
                            endcase
                            if (SReg2[2] == 0) begin
                                MuxASel = 2'b01;
                                RF_ScrSel = 4'b1011;
                                RF_FunSel = 3'b010;
                                RF_OutBSel = 3'b101;
                            end                         
                        end
                        6'b010001: begin // MOVH DstReg[15:8] <- IMMEDIATE (8-bit)
                            ARF_RegSel = 4'b1111;
                            RF_RegSel = 4'b1111;
                            SCReset = 1'b1;
                        end
                        6'b010010: begin
                            Mem_CS = 1;
                            SCReset = 1'b1;
                        end
                        6'b010011: begin // STR (16-bit) M[AR] <- Rx (AR is 16-bit register)
                            MuxCSel = 1'b1;
                            ARF_RegSel = 3'b111;
                        end
                        6'b010100: begin // MOVL DstReg[7:0] <- IMMEDIATE (8-bit)
                            ARF_RegSel = 4'b1111;
                            RF_RegSel = 4'b1111;
                            SCReset = 1'b1;                        
                        end
                        6'b010101: begin // ADD DstReg <- SReg1 + SReg2
                            case (SReg2)
                                3'b000: ARF_OutCSel = 2'b00;
                                3'b001: ARF_OutCSel = 2'b01;
                                3'b010: ARF_OutCSel = 2'b11;
                                3'b011: ARF_OutCSel = 2'b10;
                                3'b100: RF_OutBSel = 3'b000;
                                3'b101: RF_OutBSel = 3'b001;
                                3'b110: RF_OutBSel = 3'b010;
                                3'b111: RF_OutBSel = 3'b011;
                            endcase
                            if (SReg2[2] == 0) begin
                                MuxASel = 2'b01;
                                RF_ScrSel = 4'b1011;
                                RF_FunSel = 3'b010;
                                RF_OutBSel = 3'b101;
                            end                          
                        end
                        6'b010110: begin // ADC DstReg <- SReg1 + SReg2 + CARRY
                            case (SReg2)
                                3'b000: ARF_OutCSel = 2'b00;
                                3'b001: ARF_OutCSel = 2'b01;
                                3'b010: ARF_OutCSel = 2'b11;
                                3'b011: ARF_OutCSel = 2'b10;
                                3'b100: RF_OutBSel = 3'b000;
                                3'b101: RF_OutBSel = 3'b001;
                                3'b110: RF_OutBSel = 3'b010;
                                3'b111: RF_OutBSel = 3'b011;
                            endcase
                            if (SReg2[2] == 0) begin
                                MuxASel = 2'b01;
                                RF_ScrSel = 4'b1011;
                                RF_FunSel = 3'b010;
                                RF_OutBSel = 3'b101;
                            end                           
                        end
                        6'b010111: begin // SUB DstReg <- SReg1 - SReg2
                            case (SReg2)
                                3'b000: ARF_OutCSel = 2'b00;
                                3'b001: ARF_OutCSel = 2'b01;
                                3'b010: ARF_OutCSel = 2'b11;
                                3'b011: ARF_OutCSel = 2'b10;
                                3'b100: RF_OutBSel = 3'b000;
                                3'b101: RF_OutBSel = 3'b001;
                                3'b110: RF_OutBSel = 3'b010;
                                3'b111: RF_OutBSel = 3'b011;
                            endcase
                            if (SReg2[2] == 0) begin
                                MuxASel = 2'b01;
                                RF_ScrSel = 4'b1011;
                                RF_FunSel = 3'b010;
                                RF_OutBSel = 3'b101;
                            end                           
                        end
                        6'b011000: begin // MOVS DstReg <- SReg1, Flags will change
                            case (DstReg)
                                3'b000: ARF_RegSel = 3'b011;
                                3'b001: ARF_RegSel = 3'b011;
                                3'b010: ARF_RegSel = 3'b110;
                                3'b011: ARF_RegSel = 3'b101;
                                3'b100: RF_RegSel = 4'b0111;
                                3'b101: RF_RegSel = 4'b1011;
                                3'b110: RF_RegSel = 4'b1101;
                                3'b111: RF_RegSel = 4'b1110;
                            endcase
                            if (DstReg[2] == 0) begin
                                MuxBSel = 2'b00;
                                ARF_FunSel = 3'b010;
                            end
                            if (DstReg[2] == 1) begin
                                MuxASel = 2'b00;
                                RF_FunSel = 3'b010;
                            end                                                                                     
                        end
                        6'b011001: begin // ADDS DstReg <- SReg1 + SReg2, Flags will change
                            case (SReg2)
                                3'b000: ARF_OutCSel = 2'b00;
                                3'b001: ARF_OutCSel = 2'b01;
                                3'b010: ARF_OutCSel = 2'b11;
                                3'b011: ARF_OutCSel = 2'b10;
                                3'b100: RF_OutBSel = 3'b000;
                                3'b101: RF_OutBSel = 3'b001;
                                3'b110: RF_OutBSel = 3'b010;
                                3'b111: RF_OutBSel = 3'b011;
                            endcase
                            if (SReg2[2] == 0) begin
                                MuxASel = 2'b01;
                                RF_ScrSel = 4'b1011;
                                RF_FunSel = 3'b010;
                                RF_OutBSel = 3'b101;
                            end                         
                        end
                        6'b011010: begin // SUBS DstReg <- SReg1 - SReg2, Flags will change
                            case (SReg2)
                                3'b000: ARF_OutCSel = 2'b00;
                                3'b001: ARF_OutCSel = 2'b01;
                                3'b010: ARF_OutCSel = 2'b11;
                                3'b011: ARF_OutCSel = 2'b10;
                                3'b100: RF_OutBSel = 3'b000;
                                3'b101: RF_OutBSel = 3'b001;
                                3'b110: RF_OutBSel = 3'b010;
                                3'b111: RF_OutBSel = 3'b011;
                            endcase
                            if (SReg2[2] == 0) begin
                                MuxASel = 2'b01;
                                RF_ScrSel = 4'b1011;
                                RF_FunSel = 3'b010;
                                RF_OutBSel = 3'b101;
                            end                           
                        end
                        6'b011011: begin // ANDS DstReg <- SReg1 AND SReg2, Flags will change
                            case (SReg2)
                                3'b000: ARF_OutCSel = 2'b00;
                                3'b001: ARF_OutCSel = 2'b01;
                                3'b010: ARF_OutCSel = 2'b11;
                                3'b011: ARF_OutCSel = 2'b10;
                                3'b100: RF_OutBSel = 3'b000;
                                3'b101: RF_OutBSel = 3'b001;
                                3'b110: RF_OutBSel = 3'b010;
                                3'b111: RF_OutBSel = 3'b011;
                            endcase
                            if (SReg2[2] == 0) begin
                                MuxASel = 2'b01;
                                RF_ScrSel = 4'b1011;
                                RF_FunSel = 3'b010;
                                RF_OutBSel = 3'b101;
                            end                         
                        end
                        6'b011100: begin // ORRS DstReg <- SReg1 OR SReg2, Flags will change
                            case (SReg2)
                                3'b000: ARF_OutCSel = 2'b00;
                                3'b001: ARF_OutCSel = 2'b01;
                                3'b010: ARF_OutCSel = 2'b11;
                                3'b011: ARF_OutCSel = 2'b10;
                                3'b100: RF_OutBSel = 3'b000;
                                3'b101: RF_OutBSel = 3'b001;
                                3'b110: RF_OutBSel = 3'b010;
                                3'b111: RF_OutBSel = 3'b011;
                            endcase
                            if (SReg2[2] == 0) begin
                                MuxASel = 2'b01;
                                RF_ScrSel = 4'b1011;
                                RF_FunSel = 3'b010;
                                RF_OutBSel = 3'b101;
                            end                         
                        end
                        6'b011101: begin // XORS DstReg <- SReg1 XOR SReg2, Flags will change
                            case (SReg2)
                                3'b000: ARF_OutCSel = 2'b00;
                                3'b001: ARF_OutCSel = 2'b01;
                                3'b010: ARF_OutCSel = 2'b11;
                                3'b011: ARF_OutCSel = 2'b10;
                                3'b100: RF_OutBSel = 3'b000;
                                3'b101: RF_OutBSel = 3'b001;
                                3'b110: RF_OutBSel = 3'b010;
                                3'b111: RF_OutBSel = 3'b011;
                            endcase
                            if (SReg2[2] == 0) begin
                                MuxASel = 2'b01;
                                RF_ScrSel = 4'b1011;
                                RF_FunSel = 3'b010;
                                RF_OutBSel = 3'b101;
                            end                        
                        end
                        6'b011110: begin // BX M[SP] <- PC, PC <- Rx 
                            Mem_CS = 0;
                            Mem_WR = 1;
                            ARF_OutDSel = 2'b11;
                            RF_OutASel = 3'b100;
                            ALU_FunSel = 5'b10000;
                            MuxCSel = 1'b0;
                            ARF_RegSel = 3'b110;
                            ARF_FunSel = 3'b001;                             
                        end
                        6'b011111: begin // BL PC <- M[SP]
                            ARF_RegSel = 3'b111;
                            Mem_CS = 1'b1;                        
                            SCReset = 1'b1;                            
                        end
                        6'b100000: begin // LDRIM Rx <- VALUE (VALUE defined in ADDRESS bits)
                            RF_RegSel = 4'b1111;
                            SCReset = 1;
                        end
                        6'b100001: begin // STRIM M[AR+OFFSET] <- Rx (AR is 16-bit register) (OFFSET defined in Address bits)
                            RF_ScrSel = 4'b1011;
                            RF_FunSel = 3'b010;
                            ARF_OutCSel = 2'b10;
                            MuxASel = 2'b01;
                            RF_OutBSel = 3'b101;
                            ALU_FunSel = 5'b10100;                            
                        end                      
                    endcase    
                end
                16: begin // EXECUTE T = 4
                    case (OpCode)
                        6'b000000: begin // BRA PC <- PC + VALUE
                            ARF_FunSel = 3'b010; // PC registar'a y kleme yap. 
                            ARF_RegSel = 3'b011;
                            RF_ScrSel = 4'b0011;                           
                            RF_FunSel = 3'b011;
                            SCReset = 1;
                        end
                        6'b000001: begin // BNE IF Z=0 THEN PC <- PC + VALUE                             
                            ARF_FunSel = 3'b010; // PC registar'a y kleme yap. 
                            ARF_RegSel = 3'b011;
                            RF_ScrSel = 4'b0011;                           
                            RF_FunSel = 3'b011;
                            SCReset = 1;                          
                        end
                        6'b000010: begin // BEQ IF Z=1 THEN PC <- PC + VALUE
                            ARF_FunSel = 3'b010; // PC registar'a y kleme yap. 
                            ARF_RegSel = 3'b011;
                            RF_ScrSel = 4'b0011;                           
                            RF_FunSel = 3'b011;
                            SCReset = 1;                          
                        end
                        6'b000100: begin // PSH M[SP] <- Rx, SP <- SP - 1
                            ARF_RegSel = 3'b111;
                            Mem_CS = 1'b1; // Memory'yi disable et
                            SCReset = 1;
                        end
                        6'b000111: begin // LSL DstReg <- LSL SReg1
                            SCReset = 1;
                        end
                        6'b001000: begin // LSR DstReg <- LSR SReg1
                            SCReset = 1;
                        end
                        6'b001001: begin // ASR DstReg <- ASR SReg1
                            SCReset = 1;
                        end
                        6'b001010: begin // CSL DstReg <- CSL SReg1
                            SCReset = 1;
                        end
                        6'b001011: begin // CSR DstReg <- CSR SReg1  
                            SCReset = 1;
                        end
                        6'b001100: begin // AND DstReg <- SReg1 AND SReg2
                            ALU_FunSel = 5'b10111;
                            case(DstReg)
                                3'b000: ARF_RegSel = 3'b011;
                                3'b001: ARF_RegSel = 3'b011;
                                3'b010: ARF_RegSel = 3'b110;
                                3'b011: ARF_RegSel = 3'b101;
                                3'b100: RF_RegSel = 4'b0111;
                                3'b101: RF_RegSel = 4'b1011;
                                3'b110: RF_RegSel = 4'b1101;
                                3'b111: RF_RegSel = 4'b1110;                           
                            endcase
                            if(DstReg[2] == 0)begin
                                MuxBSel = 2'b00;
                                ARF_FunSel = 3'b010;
                            end
                            if(DstReg[2] == 1)begin
                                MuxASel = 2'b00;
                                RF_FunSel = 3'b010;
                            end                                                                                      
                        end
                        6'b001101: begin // ORR DstReg <- SReg1 OR SReg2
                            ALU_FunSel = 5'b11000;
                            case(DstReg)
                                3'b000: ARF_RegSel = 3'b011;
                                3'b001: ARF_RegSel = 3'b011;
                                3'b010: ARF_RegSel = 3'b110;
                                3'b011: ARF_RegSel = 3'b101;
                                3'b100: RF_RegSel = 4'b0111;
                                3'b101: RF_RegSel = 4'b1011;
                                3'b110: RF_RegSel = 4'b1101;
                                3'b111: RF_RegSel = 4'b1110;                           
                            endcase
                            if(DstReg[2] == 0)begin
                                MuxBSel = 2'b00;
                                ARF_FunSel = 3'b010;
                            end
                            if(DstReg[2] == 1)begin
                                MuxASel = 2'b00;
                                RF_FunSel = 3'b010;
                            end                        
                        end
                        6'b001110: begin // NOT DstReg <- NOT SReg1
                            SCReset = 1;
                        end
                        6'b001111: begin // XOR DstReg <- SReg1 XOR SReg2
                            ALU_FunSel = 5'b11001;
                            case(DstReg)
                                3'b000: ARF_RegSel = 3'b011;
                                3'b001: ARF_RegSel = 3'b011;
                                3'b010: ARF_RegSel = 3'b110;
                                3'b011: ARF_RegSel = 3'b101;
                                3'b100: RF_RegSel = 4'b0111;
                                3'b101: RF_RegSel = 4'b1011;
                                3'b110: RF_RegSel = 4'b1101;
                                3'b111: RF_RegSel = 4'b1110;                           
                            endcase
                            if(DstReg[2] == 0)begin
                                MuxBSel = 2'b00;
                                ARF_FunSel = 3'b010;
                            end
                            if(DstReg[2] == 1)begin
                                MuxASel = 2'b00;
                                RF_FunSel = 3'b010;
                            end                        
                        end
                        6'b010000: begin // NAND DstReg <- SReg1 NAND SReg2
                            ALU_FunSel = 5'b11010;
                            case(DstReg)
                                3'b000: ARF_RegSel = 3'b011;
                                3'b001: ARF_RegSel = 3'b011;
                                3'b010: ARF_RegSel = 3'b110;
                                3'b011: ARF_RegSel = 3'b101;
                                3'b100: RF_RegSel = 4'b0111;
                                3'b101: RF_RegSel = 4'b1011;
                                3'b110: RF_RegSel = 4'b1101;
                                3'b111: RF_RegSel = 4'b1110;                           
                            endcase
                            if(DstReg[2] == 0)begin
                                MuxBSel = 2'b00;
                                ARF_FunSel = 3'b010;
                            end
                            if(DstReg[2] == 1)begin
                                MuxASel = 2'b00;
                                RF_FunSel = 3'b010;
                            end                        
                        end
                        6'b010011: begin // STR (16-bit) M[AR] <- Rx (AR is 16-bit register)
                            SCReset = 1;
                            Mem_CS = 1;
                        end
                        6'b010101: begin // ADD DstReg <- SReg1 + SReg2
                            ALU_FunSel = 5'b10100;
                            case(DstReg)
                                3'b000: ARF_RegSel = 3'b011;
                                3'b001: ARF_RegSel = 3'b011;
                                3'b010: ARF_RegSel = 3'b110;
                                3'b011: ARF_RegSel = 3'b101;
                                3'b100: RF_RegSel = 4'b0111;
                                3'b101: RF_RegSel = 4'b1011;
                                3'b110: RF_RegSel = 4'b1101;
                                3'b111: RF_RegSel = 4'b1110;                           
                            endcase
                            if(DstReg[2] == 0)begin
                                MuxBSel = 2'b00;
                                ARF_FunSel = 3'b010;
                            end
                            if(DstReg[2] == 1)begin
                                MuxASel = 2'b00;
                                RF_FunSel = 3'b010;
                            end                            
                        end
                        6'b010110: begin // ADC DstReg <- SReg1 + SReg2 + CARRY
                            ALU_FunSel = 5'b10101;
                            case(DstReg)
                                3'b000: ARF_RegSel = 3'b011;
                                3'b001: ARF_RegSel = 3'b011;
                                3'b010: ARF_RegSel = 3'b110;
                                3'b011: ARF_RegSel = 3'b101;
                                3'b100: RF_RegSel = 4'b0111;
                                3'b101: RF_RegSel = 4'b1011;
                                3'b110: RF_RegSel = 4'b1101;
                                3'b111: RF_RegSel = 4'b1110;                           
                            endcase
                            if(DstReg[2] == 0)begin
                                MuxBSel = 2'b00;
                                ARF_FunSel = 3'b010;
                            end
                            if(DstReg[2] == 1)begin
                                MuxASel = 2'b00;
                                RF_FunSel = 3'b010;
                            end                         
                        end
                        6'b010111: begin // SUB DstReg <- SReg1 - SReg2
                            ALU_FunSel = 5'b10110;
                            case(DstReg)
                                3'b000: ARF_RegSel = 3'b011;
                                3'b001: ARF_RegSel = 3'b011;
                                3'b010: ARF_RegSel = 3'b110;
                                3'b011: ARF_RegSel = 3'b101;
                                3'b100: RF_RegSel = 4'b0111;
                                3'b101: RF_RegSel = 4'b1011;
                                3'b110: RF_RegSel = 4'b1101;
                                3'b111: RF_RegSel = 4'b1110;                           
                            endcase
                            if(DstReg[2] == 0)begin
                                MuxBSel = 2'b00;
                                ARF_FunSel = 3'b010;
                            end
                            if(DstReg[2] == 1)begin
                                MuxASel = 2'b00;
                                RF_FunSel = 3'b010;
                            end                         
                        end
                        6'b011000: begin // MOVS DstReg <- SReg1, Flags will change
                            RF_ScrSel =4'b0111;
                            RF_FunSel =3'b011;
                            SCReset = 1'b1;                        
                        end
                        6'b011001: begin // ADDS DstReg <- SReg1 + SReg2, Flags will change
                            ALU_FunSel = 5'b10100;
                            case(DstReg)
                                3'b000: ARF_RegSel = 3'b011;
                                3'b001: ARF_RegSel = 3'b011;
                                3'b010: ARF_RegSel = 3'b110;
                                3'b011: ARF_RegSel = 3'b101;
                                3'b100: RF_RegSel = 4'b0111;
                                3'b101: RF_RegSel = 4'b1011;
                                3'b110: RF_RegSel = 4'b1101;
                                3'b111: RF_RegSel = 4'b1110;                           
                            endcase
                            if(DstReg[2] == 0)begin
                                MuxBSel = 2'b00;
                                ARF_FunSel = 3'b010;
                            end
                            if(DstReg[2] == 1)begin
                                MuxASel = 2'b00;
                                RF_FunSel = 3'b010;
                            end                          
                        end
                        6'b011010: begin // SUBS DstReg <- SReg1 - SReg2, Flags will change
                            ALU_FunSel = 5'b10110;
                            case(DstReg)
                                3'b000: ARF_RegSel = 3'b011;
                                3'b001: ARF_RegSel = 3'b011;
                                3'b010: ARF_RegSel = 3'b110;
                                3'b011: ARF_RegSel = 3'b101;
                                3'b100: RF_RegSel = 4'b0111;
                                3'b101: RF_RegSel = 4'b1011;
                                3'b110: RF_RegSel = 4'b1101;
                                3'b111: RF_RegSel = 4'b1110;                           
                            endcase
                            if(DstReg[2] == 0)begin
                                MuxBSel = 2'b00;
                                ARF_FunSel = 3'b010;
                            end
                            if(DstReg[2] == 1)begin
                                MuxASel = 2'b00;
                                RF_FunSel = 3'b010;
                            end                        
                        end
                        6'b011011: begin // ANDS DstReg <- SReg1 AND SReg2, Flags will change
                            ALU_FunSel = 5'b10111;
                            case(DstReg)
                                3'b000: ARF_RegSel = 3'b011;
                                3'b001: ARF_RegSel = 3'b011;
                                3'b010: ARF_RegSel = 3'b110;
                                3'b011: ARF_RegSel = 3'b101;
                                3'b100: RF_RegSel = 4'b0111;
                                3'b101: RF_RegSel = 4'b1011;
                                3'b110: RF_RegSel = 4'b1101;
                                3'b111: RF_RegSel = 4'b1110;                           
                            endcase
                            if(DstReg[2] == 0)begin
                                MuxBSel = 2'b00;
                                ARF_FunSel = 3'b010;
                            end
                            if(DstReg[2] == 1)begin
                                MuxASel = 2'b00;
                                RF_FunSel = 3'b010;
                            end                        
                        end
                        6'b011100: begin // ORRS DstReg <- SReg1 OR SReg2, Flags will change
                            ALU_FunSel = 5'b11000;
                            case(DstReg)
                                3'b000: ARF_RegSel = 3'b011;
                                3'b001: ARF_RegSel = 3'b011;
                                3'b010: ARF_RegSel = 3'b110;
                                3'b011: ARF_RegSel = 3'b101;
                                3'b100: RF_RegSel = 4'b0111;
                                3'b101: RF_RegSel = 4'b1011;
                                3'b110: RF_RegSel = 4'b1101;
                                3'b111: RF_RegSel = 4'b1110;                           
                            endcase
                            if(DstReg[2] == 0)begin
                                MuxBSel = 2'b00;
                                ARF_FunSel = 3'b010;
                            end
                            if(DstReg[2] == 1)begin
                                MuxASel = 2'b00;
                                RF_FunSel = 3'b010;
                            end                          
                        end
                        6'b011101: begin // XORS DstReg <- SReg1 XOR SReg2, Flags will change
                            ALU_FunSel = 5'b11001;
                            case(DstReg)
                                3'b000: ARF_RegSel = 3'b011;
                                3'b001: ARF_RegSel = 3'b011;
                                3'b010: ARF_RegSel = 3'b110;
                                3'b011: ARF_RegSel = 3'b101;
                                3'b100: RF_RegSel = 4'b0111;
                                3'b101: RF_RegSel = 4'b1011;
                                3'b110: RF_RegSel = 4'b1101;
                                3'b111: RF_RegSel = 4'b1110;                           
                            endcase
                            if(DstReg[2] == 0)begin
                                MuxBSel = 2'b00;
                                ARF_FunSel = 3'b010;
                            end
                            if(DstReg[2] == 1)begin
                                MuxASel = 2'b00;
                                RF_FunSel = 3'b010;
                            end                         
                        end
                        6'b011110: begin // BX M[SP] <- PC, PC <- Rx
                            ARF_RegSel = 3'b111;
                            MuxCSel = 1'b1;         
                        end
                        6'b011111: begin // BL PC <- M[SP]
                        end
                        6'b100000: begin // LDRIM Rx <- VALUE (VALUE defined in ADDRESS bits)
                        end
                        6'b100001: begin // STRIM M[AR+OFFSET] <- Rx (AR is 16-bit register) (OFFSET defined in Address bits)
                            RF_RegSel = 4'b1111;
                            RF_ScrSel = 4'b1111;                           
                            MuxBSel = 2'b00;
                            ARF_RegSel = 3'b101;
                            ARF_FunSel = 3'b010;
                        end                           
                    endcase    
                end
                32: begin // EXECUTE T = 5
                    case (OpCode)
                        6'b001100: begin // AND DstReg <- SReg1 AND SReg2
                            RF_ScrSel = 4'b0011;
                            RF_FunSel = 3'b011;
                            SCReset = 1;
                        end
                        6'b001101: begin // ORR DstReg <- SReg1 OR SReg2
                            RF_ScrSel = 4'b0011;
                            RF_FunSel = 3'b011;                            
                            SCReset = 1;
                        end
                        6'b001111: begin // XOR DstReg <- SReg1 XOR SReg2
                            RF_ScrSel = 4'b0011;
                            RF_FunSel = 3'b011;                            
                            SCReset = 1;
                        end
                        6'b010000: begin // NAND DstReg <- SReg1 NAND SReg2
                            RF_ScrSel = 4'b0011;
                            RF_FunSel = 3'b011;                            
                            SCReset = 1;
                        end
                        6'b010101: begin // ADD DstReg <- SReg1 + SReg2
                            RF_RegSel = 4'b1111;
                            RF_ScrSel = 4'b0011;
                            RF_FunSel = 3'b011;
                            SCReset = 1;
                        end
                        6'b010110: begin // ADC DstReg <- SReg1 + SReg2 + CARRY
                            RF_RegSel = 4'b1111;
                            RF_ScrSel = 4'b0011;
                            RF_FunSel = 3'b011;
                            SCReset = 1;                        
                        end
                        6'b010111: begin // SUB DstReg <- SReg1 - SReg2
                            RF_RegSel = 4'b1111;
                            RF_ScrSel = 4'b0011;
                            RF_FunSel = 3'b011;
                            SCReset = 1;                        
                        end
                        6'b011001: begin // ADDS DstReg <- SReg1 + SReg2, Flags will change
                            RF_RegSel = 4'b1111;
                            RF_ScrSel = 4'b0011;
                            RF_FunSel = 3'b011;
                            SCReset = 1;                        
                        end
                        6'b011010: begin // SUBS DstReg <- SReg1 - SReg2, Flags will change
                            RF_RegSel = 4'b1111;
                            RF_ScrSel = 4'b0011;
                            RF_FunSel = 3'b011;
                            SCReset = 1;                         
                        end
                        6'b011011: begin // ANDS DstReg <- SReg1 AND SReg2, Flags will change
                            RF_ScrSel = 4'b0011;
                            RF_FunSel = 3'b011;
                            SCReset = 1;                        
                        end
                        6'b011100: begin // ORRS DstReg <- SReg1 OR SReg2, Flags will change
                            RF_ScrSel = 4'b0011;
                            RF_FunSel = 3'b011;                            
                            SCReset = 1;                        
                        end
                        6'b011101: begin // XORS DstReg <- SReg1 XOR SReg2, Flags will change
                            RF_ScrSel = 4'b0011;
                            RF_FunSel = 3'b011;                            
                            SCReset = 1;                        
                        end
                        6'b011110: begin // BX M[SP] <- PC, PC <- Rx
                            RF_ScrSel = 4'b0111;
                            RF_FunSel = 3'b011;
                            Mem_CS = 1;
                            case (Rsel)
                                2'b00: begin // R1 is enabled.
                                    RF_OutASel = 3'b000;
                                end
                                2'b01: begin // R2 is enabled.
                                    RF_OutASel = 3'b001;
                                end
                                2'b10: begin // R3 is enabled.
                                    RF_OutASel = 3'b010;
                                end
                                2'b11: begin // R4 is enabled.
                                    RF_OutASel = 3'b011;
                                end                             
                            endcase
                            MuxBSel = 2'b00;
                            ARF_FunSel = 3'b010;
                            ARF_RegSel = 3'b011;                                                       
                        end
                        6'b011111: begin // BL PC <- M[SP]
                        end
                        6'b100000: begin // LDRIM Rx <- VALUE (VALUE defined in ADDRESS bits)
                        end
                        6'b100001: begin // STRIM M[AR+OFFSET] <- Rx (AR is 16-bit register) (OFFSET defined in Address bits)
                            case (Rsel)
                                2'b00: begin // R1 is enabled.
                                    RF_OutASel = 3'b000;
                                end
                                2'b01: begin // R2 is enabled.
                                    RF_OutASel = 3'b001;
                                end
                                2'b10: begin // R3 is enabled.
                                    RF_OutASel = 3'b010;
                                end
                                2'b11: begin // R4 is enabled.
                                    RF_OutASel = 3'b011;
                                end                             
                            endcase
                            RF_ScrSel = 4'b0000;
                            RF_FunSel = 3'b011;
                            ALU_FunSel = 5'b10000;
                            ARF_FunSel = 3'b001;
                            Mem_CS = 0;
                            Mem_WR = 1;
                            MuxCSel = 1'b0;
                            ARF_OutDSel = 10;
                        end                      
                    endcase
                end                
                64: begin // EXECUTE T = 6
                    case (OpCode)
                        6'b011110: begin // BX M[SP] <- PC, PC <- Rx 
                            SCReset = 1;
                        end
                        6'b100001: begin // STRIM M[AR+OFFSET] <- Rx (AR is 16-bit register) (OFFSET defined in Address bits)
                            RF_ScrSel = 4'b1111;
                            ARF_RegSel = 3'b111;
                            MuxCSel = 1'b1;
                        end                         
                    endcase
                end
                128:begin // EXECUTE T = 7
                    case (OpCode)
                        6'b100001: begin // STRIM M[AR+OFFSET] <- Rx (AR is 16-bit register) (OFFSET defined in Address bits)
                            Mem_CS = 1;
                            SCReset = 1;
                        end                         
                    endcase
                end
            endcase
        end
    end                                       
endmodule
