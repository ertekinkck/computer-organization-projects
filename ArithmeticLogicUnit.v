`timescale 1ns / 1ps
module ArithmeticLogicUnit(
    input wire [15:0] A ,
    input wire [15:0] B,
    input wire [4:0] FunSel,
    input Clock,
    input WF,
    output reg [15:0] ALUOut,
    output reg [3:0] FlagsOut
);
    reg [8:0] temp2;
    reg [7:0] A_s, B_s;
    reg [16:0] temp3;
    
initial begin
    FlagsOut = 4'h1;

end

always @(posedge Clock) begin
// Z C N O -> [3, 2, 1, 0]
//######### 8 BIT OPERATIONS ########
//----------------------------------
      case (FunSel)
        5'b00000: begin                      
                      FlagsOut[3] = (A_s == 0); // Zero flag
                      FlagsOut[1] = A_s[7]; // Negative flag
                  end
        5'b00001: begin 
                      FlagsOut[3] = (B_s == 0); // Zero flag
                      FlagsOut[1] = B_s[7]; // Negative flag
                  end
        5'b00010: begin
                      FlagsOut[3] = ((~A_s) == 0); // Zero flag
                      FlagsOut[1] = ~A_s[7]; // Negative flag
                  end
        5'b00011: begin
                      FlagsOut[3] = ((~B_s) == 0); // Zero flag
                      FlagsOut[1] = ~B_s[7]; // Negative flag
                  end    
        5'b00100: begin
                     FlagsOut[0] = (A_s[7] & B_s[7] & ~ALUOut[7]) | (~A_s[7] & ~B_s[7] & ALUOut[7]); // Overflow flag
                     FlagsOut[3] = (ALUOut == 0); // Zero flag
                     FlagsOut[1] = ALUOut[7]; // Negative flag
                     FlagsOut[2] = temp2[8]; // Carry flag
                  end
        5'b00101: begin
                     FlagsOut[0] = ((A_s[7] & B_s[7]) | (B_s[7] & FlagsOut[2]) | (A_s[7] & FlagsOut[2])); // Overflow flag
                     FlagsOut[3] = (ALUOut == 0); // Zero flag
                     FlagsOut[1] = ALUOut[7]; // Negative flag
                     FlagsOut[2] = temp2[8]; // Carry flag  
                  end
        5'b00110: begin
                     FlagsOut[0] = (A_s[7] & ~B_s[7] & ALUOut[7]) | (~A_s[7] & B_s[7] & ~ALUOut[7]); // Overflow flag
                     FlagsOut[3] = (ALUOut == 0); // Zero flag
                     FlagsOut[1] = ALUOut[7]; // Negative flag
                     FlagsOut[2] = (ALUOut < 0); // Carry flag
                  end
        5'b00111: begin
                     FlagsOut[3] = (ALUOut == 0); // Zero flag
                     FlagsOut[1] = ALUOut[7]; // Negative flag    
                  end
        5'b01000: begin
                     
                     FlagsOut[3] = (ALUOut == 0); // Zero flag
                     FlagsOut[1] = ALUOut[7]; // Negative flag
                  end
        5'b01001: begin
                     FlagsOut[3] = (ALUOut == 0); // Zero flag
                     FlagsOut[1] = ALUOut[7]; // Negative flag
                  end
        5'b01010: begin
                     
                     FlagsOut[3] = (ALUOut == 0); // Zero flag
                     FlagsOut[1] = ALUOut[7]; // Negative flag
                  end
        5'b01011: begin 
                     ALUOut = A_s << 1; // Perform logical shift left by 1
                     FlagsOut[3] = (ALUOut == 0); // Zero flag
                     FlagsOut[2] = temp2[8];
                     FlagsOut[1] = ALUOut[7]; // Negative flag
                 end    
        5'b01100: begin 
                     ALUOut = A_s >> 1; // Perform logical shift right by 1
                     FlagsOut[3] = (ALUOut == 0); // Zero flag
                      FlagsOut[2] = temp2[8];   
                     FlagsOut[1] = 0; // Negative flag (always 0 after logical shift right)
                  end 
        5'b01101: begin
                     ALUOut = A_s >>> 1; // Perform arithmetic shift right by 1
                     FlagsOut[3] = (ALUOut == 0); // Zero flag
                     FlagsOut[2] = temp2[8];
                 end 
        5'b01110: begin
                     FlagsOut[2] = temp2[8];
                     FlagsOut[3] = (ALUOut == 0); // Zero flag
                     FlagsOut[1] = ALUOut[7]; // Negative flag
                 end 
        5'b01111: begin
                     FlagsOut[2] = temp2[8];
                     FlagsOut[3] = (ALUOut == 0); // Zero flag
                     FlagsOut[1] = ALUOut[7]; // Negative flag
                 end
//  ###################### 16 BIT OPERATION ####################
// --------------------------------------------------------------
    5'b10000: begin
                 FlagsOut[3] = (A == 0); // Zero flag
                 FlagsOut[1] = A[7]; // Negative flag
             end
    5'b10001: begin
                 FlagsOut[3] = (B == 0); // Zero flag
                 FlagsOut[1] = B[7]; // Negative flag
             end
    5'b10010: begin
                 FlagsOut[3] = ((~A) == 0); // Zero flag
                 FlagsOut[1] = ~A[7]; // Negative flag
             end
    5'b10011: begin
                 FlagsOut[3] = ((~B) == 0); // Zero flag
                 FlagsOut[1] = ~B[7]; // Negative flag
             end
    5'b10100: begin
                 FlagsOut[0] = (A[15] & B[15] & ~ALUOut[15]) | (~A[15] & ~B[15] & ALUOut[15]); // Overflow flag
                 FlagsOut[3] = (ALUOut == 0); // Zero flag
                 FlagsOut[1] = ALUOut[15]; // Negative flag
                 FlagsOut[2] = (ALUOut > 65535); // Carry flag for signed addition

             end
    5'b10101: begin
                 FlagsOut[3] = (ALUOut == 0); // Zero flag
                 FlagsOut[2] = temp3[16]; // Carry flag 
                 FlagsOut[1] = ALUOut[15]; // Negative flag
                 FlagsOut[0] = ((A[15] & B[15] & FlagsOut[2] & ~temp3[15]) | (~A[15] & ~B[15] & ~FlagsOut[2] & ~temp3[15]));
             end
    5'b10110: begin
                 FlagsOut[0] = (A[15] & ~B[15] & ALUOut[15]) | (~A[15] & B[15] & ~ALUOut[15]); // Overflow flag
                 FlagsOut[3] = (ALUOut == 0); // Zero flag
                 FlagsOut[1] = ALUOut[15]; // Negative flag
                 FlagsOut[2] = (ALUOut < 0); // Carry flag
             end
    5'b10111: begin
                 FlagsOut[3] = (ALUOut == 0); // Zero flag
                 FlagsOut[1] = ALUOut[15]; // Negative flag   
             end
    5'b11000: begin
                 FlagsOut[3] = (ALUOut == 0); // Zero flag
                 FlagsOut[1] = ALUOut[15]; // Negative flag
             end
    5'b11001: begin
                 FlagsOut[3] = (ALUOut == 0); // Zero flag
                 FlagsOut[1] = ALUOut[15]; // Negative flag
             end
    5'b11010: begin
                 FlagsOut[3] = (ALUOut == 0); // Zero flag
                 FlagsOut[1] = ALUOut[15]; // Negative flag
             end
    5'b11011: begin
                 FlagsOut[2] = A[15]; // Carry flag (bit shifted out)
                 FlagsOut[3] = (ALUOut == 0); // Zero flag
                 FlagsOut[1] = ALUOut[15]; // Negative flag
             end
    5'b11100: begin
                 FlagsOut[2] = A[0]; // Carry flag (bit shifted out)
                 FlagsOut[3] = (ALUOut == 0); // Zero flag
                 FlagsOut[1] = 0; // Negative flag (always 0 after logical shift right)
             end
    5'b11101: begin
                 
                 FlagsOut[2] = A[0]; // Carry flag (bit shifted out)
                 FlagsOut[3] = (ALUOut == 0); // Zero flag
                 FlagsOut[1] = ALUOut[15]; // Negative flag 
             end
    5'b11110: begin
                
                 FlagsOut[2] = A[0]; // Carry flag (bit shifted out)
                 FlagsOut[3] = (ALUOut == 0); // Zero flag
                 FlagsOut[1] = ALUOut[15]; // Negative flag
             end
    5'b11111: begin
                 
                 FlagsOut[2] = A[0]; // Carry flag (bit shifted out)
                 FlagsOut[3] = (ALUOut == 0); // Zero flag
                 FlagsOut[1] = ALUOut[15]; // Negative flag
             end
  endcase
end

always @(*) begin
    A_s = A[7:0];
    B_s = B[7:0];
// Z C N O -> [3, 2, 1, 0]
//######### 8 BIT OPERATIONS ########
//----------------------------------

      case (FunSel)
        5'b00000: begin
                      ALUOut = A_s;
                  end
        5'b00001: begin
                      ALUOut = B_s;
                  end
        5'b00010: begin
                      ALUOut = ~A_s;
                  end
        5'b00011: begin
                      ALUOut = ~B_s;
                  end    
        5'b00100: begin
                     temp2 = A_s + B_s;
                     ALUOut = temp2[7:0];
                  end
        5'b00101: begin
                     ALUOut = A_s + B_s + FlagsOut[2]; // Add A, B, and Carry

                  end
        5'b00110: begin
                     ALUOut = A_s + (~B_s + 8'b00000001); // Subtract B from A
                     
                  end
       
        5'b00111: begin
                     ALUOut = A_s & B_s; // Perform bitwise AND operation
                     
                  end
        5'b01000: begin
                     ALUOut = A_s | B_s; // Perform bitwise OR operation

                  end
        5'b01001: begin
                     ALUOut = A_s ^ B_s; // Perform bitwise XOR operation
                     

                  end
        5'b01010: begin
                     ALUOut = ~(A_s & B_s); // Perform bitwise NAND operation
                     

                  end
        5'b01011: begin 

                     temp2 = A_s << 1; // Perform logical shift left by 1
                     ALUOut = temp2[7:0];
                 end    
        5'b01100: begin 

                     temp2 = A_s >> 1; // Perform logical shift right by 1
                     ALUOut = temp2[7:0];
                  end 
        5'b01101: begin

                     ALUOut = A_s >>> 1; // Perform arithmetic shift right by 1
                
                 end 
        5'b01110: begin
                     ALUOut = {A_s[6:0], FlagsOut[2]}; // Perform circular shift left by 1
                
                 end 
        5'b01111: begin
                     ALUOut = {FlagsOut[2], A_s[7:1]}; // Perform circular shift right by 1
            
                 end
                 
//  ###################### 16 BIT OPERATION ####################
// --------------------------------------------------------------

    5'b10000: begin
                 ALUOut = A;

             end
    5'b10001: begin
                 ALUOut = B;

             end
    5'b10010: begin
                 ALUOut = ~A;

             end
    5'b10011: begin
                 ALUOut = ~B;

             end
    5'b10100: begin
                 temp3 = A + B;  
                 ALUOut = temp3[15:0];

             end
    5'b10101: begin
                 temp3 = A + B + FlagsOut[2]; // Add A, B, and Carry
                 ALUOut = temp3[15:0];

             end
    5'b10110: begin
                 temp3 = A + (~B + 1); // Subtract B from A
                 ALUOut = temp3[15:0];
             end
    5'b10111: begin
                 ALUOut = A & B; // Perform bitwise AND operation

             end
    5'b11000: begin
                 ALUOut = A | B; // Perform bitwise OR operation
                  
             end
    5'b11001: begin
                 ALUOut = A ^ B; // Perform bitwise XOR operation

             end
    5'b11010: begin
                 ALUOut = ~(A & B); // Perform bitwise NAND operation

             end
    5'b11011: begin
                 temp3 = A << 1; // Perform logical shift left by 1
                 ALUOut = temp3[15:0];
             end
    5'b11100: begin
             temp3 = A >> 1; // Perform logical shift right by 1
             ALUOut = temp3[15:0];
             end
    5'b11101: begin
                 ALUOut = A >>> 1; // Perform arithmetic shift right by 1
 
             end
    5'b11110: begin
                 ALUOut = {A[14:0], FlagsOut[2]}; // Perform circular shift left by 1
                 
             end
    5'b11111: begin
                 ALUOut = {FlagsOut[2], A[15:1]}; // Perform circular shift right by 1
                 
             end
  endcase
end


endmodule