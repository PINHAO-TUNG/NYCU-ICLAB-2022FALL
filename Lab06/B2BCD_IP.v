//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   File Name   : B2BCD_IP.v
//   Module Name : B2BCD_IP
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

module B2BCD_IP #(parameter WIDTH = 4, parameter DIGIT = 2) (
    // Input signals
    Binary_code,
    // Output signals
    BCD_code
);

// ===============================================================
// Declaration
// ===============================================================
input        [WIDTH-1:0] Binary_code;
output reg [DIGIT*4-1:0] BCD_code;

integer i,j;
// ===============================================================
// Soft IP DESIGN
// ===============================================================
generate
    if(WIDTH == 8) 
    begin
        always @(*) 
        begin
            BCD_code = {4'b0000,Binary_code};
            for (i=0; i< 5; i=i+1) begin
                if(i<3)
                begin
                    for (j=0; j<1; j=j+1) begin
                        if(BCD_code[8-i+4*j -: 4] > 4)
                            BCD_code[8-i+4*j -: 4] = BCD_code[8-i+4*j -: 4] + 4'd3;
                        else 
                            BCD_code[8-i+4*j -: 4] = BCD_code[8-i+4*j -: 4];
                    end
                end
                else
                begin
                    for (j=0; j<2; j=j+1) begin
                        if(BCD_code[8-i+4*j -: 4] > 4)
                            BCD_code[8-i+4*j -: 4] = BCD_code[8-i+4*j -: 4] + 4'd3;
                        else 
                            BCD_code[8-i+4*j -: 4] = BCD_code[8-i+4*j -: 4];
                    end
                end
            end
        end
    end    
    else if(WIDTH == 12) 
    begin
        always @(*) 
        begin
            BCD_code = {4'b0000,Binary_code};
            for (i=0; i< 9; i=i+1) begin 
                if(i<3)
                begin
                    for (j=0; j<1; j=j+1) begin
                        if(BCD_code[12-i+4*j -: 4] > 4)
                            BCD_code[12-i+4*j -: 4] = BCD_code[12-i+4*j -: 4] + 4'd3;
                        else 
                            BCD_code[12-i+4*j -: 4] = BCD_code[12-i+4*j -: 4];
                    end
                end
                else if(i>2 && i<6)
                begin
                    for (j=0; j<2; j=j+1) begin
                        if(BCD_code[12-i+4*j -: 4] > 4)
                            BCD_code[12-i+4*j -: 4] = BCD_code[12-i+4*j -: 4] + 4'd3;
                        else 
                            BCD_code[12-i+4*j -: 4] = BCD_code[12-i+4*j -: 4];
                    end
                end
                else
                begin
                    for (j=0; j<3; j=j+1) begin
                        if(BCD_code[12-i+4*j -: 4] > 4)
                            BCD_code[12-i+4*j -: 4] = BCD_code[12-i+4*j -: 4] + 4'd3;
                        else 
                            BCD_code[12-i+4*j -: 4] = BCD_code[12-i+4*j -: 4];
                    end
                end
            end
        end
    end
    else if(WIDTH == 16) 
    begin
        always @(*) 
        begin
            BCD_code = {4'b0000,Binary_code};
            for (i=0; i< 13; i=i+1) begin
                if(i<3)
                begin
                    for (j=0; j<1; j=j+1) begin
                        if(BCD_code[16-i+4*j -: 4] > 4)
                            BCD_code[16-i+4*j -: 4] = BCD_code[16-i+4*j -: 4] + 4'd3;
                        else 
                            BCD_code[16-i+4*j -: 4] = BCD_code[16-i+4*j -: 4];
                    end
                end
                else if(i>2 && i<6)
                begin
                    for (j=0; j<2; j=j+1) begin
                        if(BCD_code[16-i+4*j -: 4] > 4)
                            BCD_code[16-i+4*j -: 4] = BCD_code[16-i+4*j -: 4] + 4'd3;
                        else 
                            BCD_code[16-i+4*j -: 4] = BCD_code[16-i+4*j -: 4];
                    end
                end
                else if(i>5 && i<9)
                begin
                    for (j=0; j<3; j=j+1) begin
                        if(BCD_code[16-i+4*j -: 4] > 4)
                            BCD_code[16-i+4*j -: 4] = BCD_code[16-i+4*j -: 4] + 4'd3;
                        else 
                            BCD_code[16-i+4*j -: 4] = BCD_code[16-i+4*j -: 4];
                    end
                end
                else if(i>8 && i<12)
                begin
                    for (j=0; j<4; j=j+1) begin
                        if(BCD_code[16-i+4*j -: 4] > 4)
                            BCD_code[16-i+4*j -: 4] = BCD_code[16-i+4*j -: 4] + 4'd3;
                        else 
                            BCD_code[16-i+4*j -: 4] = BCD_code[16-i+4*j -: 4];
                    end
                end
                else
                begin
                    for (j=0; j<5; j=j+1) begin
                        if(BCD_code[16-i+4*j -: 4] > 4)
                            BCD_code[16-i+4*j -: 4] = BCD_code[16-i+4*j -: 4] + 4'd3;
                        else 
                            BCD_code[16-i+4*j -: 4] = BCD_code[16-i+4*j -: 4];
                    end
                end
            end
        end
    end
    else if(WIDTH == 20) 
    begin
        always @(*) 
        begin
            BCD_code = {8'b00000000,Binary_code};
            for(i=0; i<17; i=i+1) begin 
                if(i<3)
                begin
                    for (j=0; j<1; j=j+1) begin
                        if(BCD_code[20-i+4*j -: 4] > 4)
                            BCD_code[20-i+4*j -: 4] = BCD_code[20-i+4*j -: 4] + 4'd3;
                        else 
                            BCD_code[20-i+4*j -: 4] = BCD_code[20-i+4*j -: 4];
                    end
                end
                else if(i>2 && i<6)
                begin
                    for (j=0; j<2; j=j+1) begin
                        if(BCD_code[20-i+4*j -: 4] > 4)
                            BCD_code[20-i+4*j -: 4] = BCD_code[20-i+4*j -: 4] + 4'd3;
                        else 
                            BCD_code[20-i+4*j -: 4] = BCD_code[20-i+4*j -: 4];
                    end
                end
                else if(i>5 && i<9)
                begin
                    for (j=0; j<3; j=j+1) begin
                        if(BCD_code[20-i+4*j -: 4] > 4)
                            BCD_code[20-i+4*j -: 4] = BCD_code[20-i+4*j -: 4] + 4'd3;
                        else 
                            BCD_code[20-i+4*j -: 4] = BCD_code[20-i+4*j -: 4];
                    end
                end
                else if(i>8 && i<12)
                begin
                    for (j=0; j<4; j=j+1) begin
                        if(BCD_code[20-i+4*j -: 4] > 4)
                            BCD_code[20-i+4*j -: 4] = BCD_code[20-i+4*j -: 4] + 4'd3;
                        else 
                            BCD_code[20-i+4*j -: 4] = BCD_code[20-i+4*j -: 4];
                    end
                end
                else if(i>11 && i<15)
                begin
                    for (j=0; j<5; j=j+1) begin
                        if(BCD_code[20-i+4*j -: 4] > 4)
                            BCD_code[20-i+4*j -: 4] = BCD_code[20-i+4*j -: 4] + 4'd3;
                        else 
                            BCD_code[20-i+4*j -: 4] = BCD_code[20-i+4*j -: 4];
                    end
                end
                else
                begin
                    for (j=0; j<6; j=j+1) begin
                        if(BCD_code[20-i+4*j -: 4] > 4)
                            BCD_code[20-i+4*j -: 4] = BCD_code[20-i+4*j -: 4] + 4'd3;
                        else 
                            BCD_code[20-i+4*j -: 4] = BCD_code[20-i+4*j -: 4];
                    end
                end
            end
        end
    end
    else 
    begin
        always @(*) 
        begin
            BCD_code = {4'b0000,Binary_code};
            if(BCD_code[4:1] > 4)
                BCD_code[4:1] = BCD_code[4:1]+ 4'd3;
            else 
                BCD_code[4:1] = BCD_code[4:1]; 
            
        end
    end
endgenerate
endmodule