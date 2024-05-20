module Project2Test();
    reg Clock, Reset;
    wire [7:0] Tx;
    always 
    begin
        Clock = 1; 
        #50; 
        Clock = 0; 
        #50; // 50 ns period
    end
    initial begin
       #1;
       Reset = 1;
       #1;
       Reset = 0;
       #1;
       Reset = 1;
    end
    CPUSystem _CPUSystem( 
            .Clock(Clock),
            .Reset(Reset),
            .T(Tx)
        );
    always @(negedge Clock)
        if (Reset) // skip during reset
        begin
            $display("Output Values:");
            $display("T: %d", Tx);
            $display("Address Register File: PC: %d, AR: %d, SP: %d", _CPUSystem._ALUSystem.ARF.PC.Q, _CPUSystem._ALUSystem.ARF.AR.Q, _CPUSystem._ALUSystem.ARF.SP.Q);
            $display("Instruction Register : %d", _CPUSystem._ALUSystem.IR.IROut);
            $display("Register File Registers: R1: %d, R2: %d, R3: %d, R4: %d", _CPUSystem._ALUSystem.RF.R1.Q, _CPUSystem._ALUSystem.RF.R2.Q, _CPUSystem._ALUSystem.RF.R3.Q, _CPUSystem._ALUSystem.RF.R4.Q);
            $display("Register File Scratch Registers: S1: %d, S2: %d, S3: %d, S4: %d", _CPUSystem._ALUSystem.RF.S1.Q, _CPUSystem._ALUSystem.RF.S2.Q, _CPUSystem._ALUSystem.RF.S3.Q, _CPUSystem._ALUSystem.RF.S4.Q);
            $display("ALU Flags: Z: %d, N: %d, C: %d, O: %d", _CPUSystem._ALUSystem.ALU.FlagsOut[3], _CPUSystem._ALUSystem.ALU.FlagsOut[2], _CPUSystem._ALUSystem.ALU.FlagsOut[1], _CPUSystem._ALUSystem.ALU.FlagsOut[0]);
            $display("ALU Result: ALUOut: %d", _CPUSystem._ALUSystem.ALU.ALUOut);
            $display("OpCode: %h", _CPUSystem.OpCode);
            $display("\n");
            
        end
endmodule