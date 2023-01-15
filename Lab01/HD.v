module HD(
           code_word1,
           code_word2,
           out_n
       );
input  [6:0]code_word1, code_word2;
output reg signed[5:0] out_n;

// Wire & Registers variable
wire word1_p1, word1_p2, word1_p3;
wire word2_p1, word2_p2, word2_p3;
wire word1_c1, word1_c2, word1_c3;
wire word2_c1, word2_c2, word2_c3;
wire [1:0] c_cal_word1,c_cal_word2;
reg signed [3:0] code_word1_correct = 4'b0000, code_word2_correct = 4'b0000;
reg [1:0] opt = 2'b00;


CalculateCircle CalculateCircle_world1(.p1(code_word1[6]) , .p2(code_word1[5]) , .p3(code_word1[4]), .x1(code_word1[3]), .x2(code_word1[2]), .x3(code_word1[1]), .x4(code_word1[0]),
                                       .c1(word1_c1), .c2(word1_c2), .c3(word1_c3));
CalculateCircle CalculateCircle_world2(.p1(code_word2[6]) , .p2(code_word2[5]) , .p3(code_word2[4]), .x1(code_word2[3]), .x2(code_word2[2]), .x3(code_word2[1]), .x4(code_word2[0]),
                                       .c1(word2_c1), .c2(word2_c2), .c3(word2_c3));

// code_word1
always @(*)
begin
    if(word1_c1 && word1_c2 && word1_c3 == 1)
    begin
        opt[1] = code_word1[3];
    end
    else if(word1_c1 && word1_c2 == 1)
    begin
        opt[1] = code_word1[2];
    end
    else if (word1_c1 && word1_c3 == 1)
    begin
        opt[1] = code_word1[1];
    end
    else if(word1_c2 && word1_c3 == 1)
    begin
        opt[1] = code_word1[0];
    end
    else
    begin
        if(word1_c1 == 1)
        begin
            opt[1] = code_word1[6];
        end
        else if(word1_c2 == 1)
        begin
            opt[1] = code_word1[5];
        end
        else
        begin
            opt[1] = code_word1[4];
        end
    end
end
always @(*)
begin
    if(word1_c1 && word1_c2 && word1_c3 == 1)
    begin
        code_word1_correct[3] = ~code_word1[3];
        code_word1_correct[2] = code_word1[2];
        code_word1_correct[1] = code_word1[1];
        code_word1_correct[0] = code_word1[0];
    end
    else if(word1_c1 && word1_c2 == 1)
    begin
        code_word1_correct[3] = code_word1[3];
        code_word1_correct[2] = ~code_word1[2];
        code_word1_correct[1] = code_word1[1];
        code_word1_correct[0] = code_word1[0];
    end
    else if (word1_c1 && word1_c3 == 1)
    begin
        code_word1_correct[3] = code_word1[3];
        code_word1_correct[2] = code_word1[2];
        code_word1_correct[1] = ~code_word1[1];
        code_word1_correct[0] = code_word1[0];
    end
    else if(word1_c2 && word1_c3 == 1)
    begin
        code_word1_correct[3] = code_word1[3];
        code_word1_correct[2] = code_word1[2];
        code_word1_correct[1] = code_word1[1];
        code_word1_correct[0] = ~code_word1[0];
    end
    else
    begin
        code_word1_correct[3] = code_word1[3];
        code_word1_correct[2] = code_word1[2];
        code_word1_correct[1] = code_word1[1];
        code_word1_correct[0] = code_word1[0];
    end
end
// code_word2
always @(*)
begin
    if(word2_c1 && word2_c2 && word2_c3 == 1)
    begin
        opt[0] = code_word2[3];
    end
    else if(word2_c1 && word2_c2 == 1)
    begin
        opt[0] = code_word2[2];
    end
    else if(word2_c1 && word2_c3 == 1)
    begin
        opt[0] = code_word2[1];
    end
    else if(word2_c2 && word2_c3 == 1)
    begin
        opt[0] = code_word2[0];
    end
    else
    begin
        if(word2_c1 == 1)
        begin
            opt[0] = code_word2[6];
        end
        else if(word2_c2 == 1)
        begin
            opt[0] = code_word2[5];
        end
        else
        begin
            opt[0] = code_word2[4];
        end
    end
end
always @(*)
begin
    if(word2_c1 && word2_c2 && word2_c3 == 1)
    begin
        code_word2_correct[3] = ~code_word2[3];
        code_word2_correct[2] = code_word2[2];
        code_word2_correct[1] = code_word2[1];
        code_word2_correct[0] = code_word2[0];
    end
    else if(word2_c1 && word2_c2 == 1)
    begin
        code_word2_correct[3] = code_word2[3];
        code_word2_correct[2] = ~code_word2[2];
        code_word2_correct[1] = code_word2[1];
        code_word2_correct[0] = code_word2[0];
    end
    else if(word2_c1 && word2_c3 == 1)
    begin
        code_word2_correct[3] = code_word2[3];
        code_word2_correct[2] = code_word2[2];
        code_word2_correct[1] = ~code_word2[1];
        code_word2_correct[0] = code_word2[0];
    end
    else if(word2_c2 && word2_c3 == 1)
    begin
        code_word2_correct[3] = code_word2[3];
        code_word2_correct[2] = code_word2[2];
        code_word2_correct[1] = code_word2[1];
        code_word2_correct[0] = ~code_word2[0];
    end
    else
    begin
        code_word2_correct[3] = code_word2[3];
        code_word2_correct[2] = code_word2[2];
        code_word2_correct[1] = code_word2[1];
        code_word2_correct[0] = code_word2[0];
    end
end
// opt case
always@(*)
begin
    case (opt)
        2'b00:
        begin
            out_n = 2*code_word1_correct + code_word2_correct;
        end
        2'b01:
        begin
            out_n = 2*code_word1_correct - code_word2_correct;
        end
        2'b10:
        begin
            out_n = code_word1_correct - 2*code_word2_correct;
        end
        default:
        begin
            out_n = code_word1_correct + 2*code_word2_correct;
        end
    endcase
end

endmodule


    module CalculateCircle(
        p1, p2, p3, x1, x2, x3, x4,
        c1, c2, c3,);
input p1, p2, p3, x1, x2, x3, x4;
output c1, c2, c3;

assign c1 = p1 ^ x1 ^ x2 ^ x3;
assign c2 = p2 ^ x1 ^ x2 ^ x4;
assign c3 = p3 ^ x1 ^ x3 ^ x4;

endmodule
