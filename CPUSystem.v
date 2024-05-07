module SequenceCounter(input Clock, input Reset, 
    input Increment, output reg [2:0] SCOut = 3'b0);
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

module Decoder6to64(Enable,OpDecoderInput,OpDecoderOutput); // input 6 bit, 
    input wire Enable;
    input wire [5:0] OpDecoderInput;
    output reg [15:0] OpDecoderOutput;
    
    always @(*)
    begin
        if(Enable) begin
        case(OpDecoderInput)
            6'b000000: OpDecoderOutput = 64'h0000000000000001;      
            6'b000001: OpDecoderOutput = 64'h0000000000000002; 
            6'b000010: OpDecoderOutput = 64'h0000000000000004; 
            6'b000011: OpDecoderOutput = 64'h0000000000000008;  
            6'b000100: OpDecoderOutput = 64'h0000000000000010; 
            6'b000101: OpDecoderOutput = 64'h0000000000000020; 
            6'b000110: OpDecoderOutput = 64'h0000000000000040; 
            6'b000111: OpDecoderOutput = 64'h0000000000000080; 
            6'b001000: OpDecoderOutput = 64'h0000000000000100; 
            6'b001001: OpDecoderOutput = 64'h0000000000000200; 
            6'b001010: OpDecoderOutput = 64'h0000000000000400; 
            6'b001011: OpDecoderOutput = 64'h0000000000000800; 
            6'b001100: OpDecoderOutput = 64'h0000000000001000; 
            6'b001101: OpDecoderOutput = 64'h0000000000002000; 
            6'b001110: OpDecoderOutput = 64'h0000000000004000; 
            6'b001111: OpDecoderOutput = 64'h0000000000008000; 
            6'b010000: OpDecoderOutput = 64'h0000000000010000; 
            6'b010001: OpDecoderOutput = 64'h0000000000020000; 
            6'b010010: OpDecoderOutput = 64'h0000000000040000; 
            6'b010011: OpDecoderOutput = 64'h0000000000080000; 
            6'b010100: OpDecoderOutput = 64'h0000000000100000; 
            6'b010101: OpDecoderOutput = 64'h0000000000200000; 
            6'b010110: OpDecoderOutput = 64'h0000000000400000; 
            6'b010111: OpDecoderOutput = 64'h0000000000800000; 
            6'b011000: OpDecoderOutput = 64'h0000000001000000; 
            6'b011001: OpDecoderOutput = 64'h0000000002000000; 
            6'b011010: OpDecoderOutput = 64'h0000000004000000; 
            6'b011011: OpDecoderOutput = 64'h0000000008000000; 
            6'b011100: OpDecoderOutput = 64'h0000000010000000; 
            6'b011101: OpDecoderOutput = 64'h0000000020000001; 
            6'b011110: OpDecoderOutput = 64'h0000000040000001; 
            6'b011111: OpDecoderOutput = 64'h0000000080000001; 
            6'b100000: OpDecoderOutput = 64'h0000000100000001; 
            6'b100001: OpDecoderOutput = 64'h0000000200000001; 
            default : OpDecoderOutput = OpDecoderOutput;
        endcase
        end
        else
        begin
            OpDecoderOutput = OpDecoderOutput;
        end
    end
endmodule

module Decoder2to8(
    input wire Enable,
    input wire [2:0] TimeDecoderInput,
    output reg [7:0] TimeDecoderOutput );

    always@(*) begin
        if(Enable) 
        begin
            case(TimeDecoderInput)
                3'b000 : TimeDecoderOutput = 8'b00000001;
                3'b001 : TimeDecoderOutput = 8'b00000010;
                3'b010 : TimeDecoderOutput = 8'b00000100;
                3'b011 : TimeDecoderOutput = 8'b00001000;
                3'b100 : TimeDecoderOutput = 8'b00010000;
                3'b101 : TimeDecoderOutput = 8'b00100000;
                3'b110 : TimeDecoderOutput = 8'b01000000;
                3'b111 : TimeDecoderOutput = 8'b10000000;
                default: TimeDecoderOutput = 8'b00000000;
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
    output reg [7:0] T );  // T is a sequence counter's output
    reg [1:0] ARF_OutCSel, ARF_OutDSel, MuxASel, MuxBSel; 
    reg [2:0] RF_OutASel, RF_OutBSel, RF_FunSel, ARF_FunSel, ARF_RegSel;
    reg [3:0] RF_RegSel, RF_ScrSel;
    reg [4:0] ALU_FunSel;
    reg IR_LH, IR_Write, Mem_CS, Mem_WR, ALU_WF, MuxCSel;
    reg SCReset;
    reg  [2:0] TimeDecoderInput;
    wire [63:0] D;
    wire [1:0] RSel;
    reg  [15:0] temp;
    wire [7:0] Address;

    ArithmeticLogicUnitSystem _ALUSystem(.Clock(Clock), .RF_OutASel(RF_OutASel), .RF_OutBSel(RF_OutBSel), .RF_FunSel(RF_FunSel), .RF_RegSel(RF_RegSel),
                              .RF_ScrSel(RF_ScrSel), .ALU_FunSel(ALU_FunSel), .ARF_OutCSel(ARF_OutCSel), .ARF_OutDSel(ARF_OutDSel), .ARF_FunSel(ARF_FunSel),
                              .ARF_RegSel(ARF_RegSel), .IR_LH(IR_LH), .IR_Write(IR_Write), .Mem_CS(Mem_CS), .Mem_WR(Mem_WR), .ALU_WF(ALU_WF), .MuxASel(MuxASel),
                              .MuxBSel(MuxBSel), .MuxCSel(MuxCSel));
                              
    Decoder2to8 TimeDecoder(1,TimeDecoderInput, T);
    SequenceCounter SC(Clock, SCReset, 1'b1, TimeDecoderInput);
    Decoder6to64 OpDecoderInput(1, _ALUSystem.IR.IR_OUT[15:10], D);
   
   initial begin
        IncrementSC = 1;    
   end

  always @(*) begin
    if (Reset) begin
    SCReset = 1;
    ARF_FunSel = 3'b000;
    end
    if (!Reset) begin
    // Fetch cycle (T0, T1, T2)
      if (T[0]) begin
      //dump_input = 1'b0; anlamadım
      IR_LH = 1'b0; // low partı seç
      Mem_WR = 1'b0; // Memory'nin read modunu aç
      Mem_CS = 1'b0; // Memory'yi enable et
      ARF_OutDSel = 2'b00; // Memory'nin address kısmına giden outu için PC'yi seç
      // Increment PC_past and PC
      ARF_FunSel = 3'b001; // Pc registeri 1 artır
      ARF_RegSel <= 3'b011; // PC registerı enable et
      IncrementSC = 1;
      //RF_RSel = 4'b0000; anlamadım
      end

      if (T[1]) begin
      // IR(8-15) <-
      IR_LH = 1'b1;
      // <- M[PC]
      Mem_WR = 0; // Memory'nin read modunu aç
      Mem_CS = 0; // Memory'yi enable et
      ARF_OutDSel = 2'b00;    
      // Increment PC_past and PC
      ARF_FunSel = 3'b001;
      ARF_RegSel = 3'b011;

      IncrementSC = 1;
      //RF_RSel = 4'b0000; anlamadım.
      end
           
      // Memorydeki instructionumuz instruction registera başarılı bir şekilde alındı.
      
      // Bra işlemi
      if (T[2] && D[0]) begin            
        MuxASel = 2'b11; // IR'nin ilk 8 bitini muxa'nın çıkışına verdik.
        RF_RegSel = 4'b0011; // Register file'daki r1 ve r2 registerlı açtık
        RF_FunSel = 3'b111; // registtera ilk 8 biti yükle son 8 bit sign extend
        ALU_FunSel = 5'b10100; // A + B 16 bit
        RF_OutASel = 3'b000; // OUTA'ya R1'i ver 
        RF_Funsel = 3'b011; // Registerları clearla.
        IncrementSC = 1; // SC'yi 1 artır.

    end
            
            
      if (T[3] && D[0]) begin
          ARF_OutCSel = 2'b00; // OUTC için PC'yi seçtik
          MuxASel = 2'b01; // Çıkışa OUTC'yi verdik.
          RF_FunSel = 3'b010; // Registerlara loadladık.
          RF_OutBSel = 3'b001; // OUTB'ye r2yi verdik.
          ALU_FunSel = 5'b10100; // A + B 16 bit
          ARF_FunSel = 3'b011; // Registerları clearla. 

          Mem_CS = 1; // disable memory
          SCReset = 1; // reset counter
  
      end


      
    end
  end
endmodule