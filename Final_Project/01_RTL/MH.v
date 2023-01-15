module MH (
           clk,
           clk2,
           rst_n,
           in_valid,
           op_valid,
           pic_data,
           se_data,
           op,
           out_valid,
           out_data
       );
//==============================================//
//             I/O PORT DECLARATION             //
//==============================================//
input        clk, clk2, rst_n, in_valid, op_valid;
input [31:0] pic_data;
input [7:0]  se_data;
input [2:0]  op;

output reg        out_valid;
output reg [31:0] out_data;

//==============================================//
//             Parameter and Integer            //
//==============================================//
// FSM Parameter
parameter s_idle       = 3'd0;
parameter s_input      = 3'd1;
parameter s_erodil     = 3'd2;
parameter s_openclose  = 3'd3;
parameter s_his        = 3'd4;
parameter s_output     = 3'd5;

// Integer genvar
genvar idx;
integer i;
//==============================================//
//           WIRE AND REG DECLARATION           //
//==============================================//
// fsm
reg [2:0] current_state, next_state;
// cnt
reg [7:0] cnt_input;
reg [8:0] cnt_erodil, cnt_openclose, cnt_his, cnt_output;
reg [2:0] cnt_padding;
// input data
reg in_valid_reg;
reg [7:0] se_data_reg;
reg [31:0] pic_data_reg;
reg [2:0] op_current;
reg [7:0] se_array [15:0];

/// input buffer ///
// line_buffer1
reg [31:0] line_buffer1_row0 [7:0];
reg [31:0] line_buffer1_row1 [7:0];
reg [31:0] line_buffer1_row2 [7:0];
reg [31:0] line_buffer1_row3 [1:0];
// line_buffer2
reg [31:0] line_buffer2_row0 [7:0];
reg [31:0] line_buffer2_row1 [7:0];
reg [31:0] line_buffer2_row2 [7:0];
reg [31:0] line_buffer2_row3 [1:0];
// ero dil cal
wire [31:0] his_result;
reg [31:0]  ero_dil_value;
reg [31:0]  ero_dil_value2;
wire [31:0] ero_dil_result_lb1;
wire [31:0] ero_dil_result_lb2;
// his
reg [7:0] his_min_value;

/// sram ///
// sram1
wire [31:0] sram1_out;
//wire sram_output_cen // always enable
//wire sram_output_oen // always enable
reg sram1_wen;
reg [7:0] sram1_addr;
reg [31:0] sram1_in;

reg [31:0] sram1_out_reg;

//==============================================//
//            FSM State Declaration             //
//==============================================//
// current_state
always@(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        current_state <= s_idle;
    else
        current_state <= next_state;
end
// next_state
always @(*)
begin
    case(current_state)
        s_idle:
        begin
            if(in_valid == 1)
            begin
                next_state = s_input;
            end
            else
            begin
                next_state = s_idle;
            end
        end
        s_input:
        begin
            if(op_current == 0)
            begin
                if(cnt_input == 255)
                begin
                    next_state = s_his;
                end
                else
                begin
                    next_state = s_input;
                end
            end
            else if(op_current == 2 || op_current == 3)
            begin
                if(cnt_input == 24)
                begin
                    next_state = s_erodil;
                end
                else
                begin
                    next_state = s_input;
                end
            end
            else if(op_current == 6 || op_current == 7)
            begin
                if(cnt_input == 50)
                begin
                    next_state = s_openclose;
                end
                else
                begin
                    next_state = s_input;
                end
            end
            else
            begin
                next_state = s_input;
            end
        end
        s_erodil:
        begin
            if(cnt_erodil == 257)
            begin
                next_state = s_output;
            end
            else
            begin
                next_state = s_erodil;
            end
        end
        s_openclose:
        begin
            if(cnt_openclose == 257)
            begin
                next_state = s_output;
            end
            else
            begin
                next_state = s_openclose;
            end
        end
        s_his:
        begin
            if(cnt_his == 3)
            begin
                next_state = s_output;
            end
            else
            begin
                next_state = s_his;
            end
        end
        s_output:
        begin
            if(cnt_output == 256)
            begin
                next_state = s_idle;
            end
            else
            begin
                next_state = s_output;
            end
        end
        default:
        begin
            next_state = s_idle;
        end
    endcase
end

//==============================================//
//                 cnt controler                //
//==============================================//
// cnt_input
always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        cnt_input <= 0;
    else if(current_state == s_idle)
        cnt_input <= 0;
    else if(current_state == s_input)
    begin
        cnt_input <= cnt_input + 1;
    end
    else
        cnt_input <= 0;
end
// cnt_output
always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        cnt_output <= 0;
    else if(current_state == s_idle)
        cnt_output <= 0;
    else if(current_state == s_output)
    begin
        if(cnt_output == 256)
            cnt_output <= 0;
        else
            cnt_output <= cnt_output + 1;
    end
    else
        cnt_output <= cnt_output;
end
// cnt_erodil
always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        cnt_erodil <= 0;
    else if(current_state == s_idle)
        cnt_erodil <= 0;
    else if(current_state == s_erodil)
    begin
        if(cnt_erodil == 257)
            cnt_erodil <= 0;
        else
            cnt_erodil <= cnt_erodil + 1;
    end
    else
        cnt_erodil <= cnt_erodil;
end
// cnt_openclose
always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        cnt_openclose <= 0;
    else if(current_state == s_idle)
        cnt_openclose <= 0;
    else if(current_state == s_openclose)
    begin
        if(cnt_openclose == 257)
            cnt_openclose <= 0;
        else
            cnt_openclose <= cnt_openclose + 1;
    end
    else
        cnt_openclose <= cnt_openclose;
end
// cnt_padding
always@(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        cnt_padding <= 0;
    else if(current_state == s_idle)
        cnt_padding <= 0;
    else if(current_state == s_input && cnt_input > 24)
        cnt_padding <= cnt_padding + 1;
    else if(current_state == s_erodil || current_state == s_openclose)
        cnt_padding <= cnt_padding + 1;
    else
        cnt_padding <= 0;
end
// cnt_his
always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        cnt_his <= 0;
    else if(current_state == s_idle)
        cnt_his <= 0;
    else if(current_state == s_his)
    begin
        if(cnt_his == 3)
            cnt_his <= 0;
        else
            cnt_his <= cnt_his + 1;
    end
    else
        cnt_his <= cnt_his;
end
//==============================================//
//              SRAM control Design             //
//==============================================//
RA1SH sram1(.Q(sram1_out), .CLK(clk), .CEN(1'b0), .WEN(sram1_wen), .A(sram1_addr), .D(sram1_in), .OEN(1'b0));

// sram1_wen
always@(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        sram1_wen <= 0;
    else if(current_state == s_idle)/*initial value write data*/
        sram1_wen <= 0;
    else if(current_state == s_input)/*write data*/
    begin
        if(cnt_input < 255)
            sram1_wen <= 0;
        else
            sram1_wen <= 1;
    end
    else if(current_state == s_erodil && cnt_erodil < 256)/*write data*/
        sram1_wen <= 0;
    else if(current_state == s_openclose && cnt_openclose < 256)/*write data*/
        sram1_wen <= 0;
    else if(current_state == s_erodil && cnt_erodil > 255)/*read data*/
        sram1_wen <= 1;
    else if(current_state == s_openclose && cnt_openclose > 255)/*read data*/
        sram1_wen <= 1;
    else if(current_state == s_his)/*read data*/
        sram1_wen <= 1;
    else if(current_state == s_output)/*read data*/
        sram1_wen <= 1;
    else
        sram1_wen <= sram1_wen;
end

// sram1_addr
always@(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        sram1_addr <= 0;
    else if(current_state == s_idle)/*initial value*/
        sram1_addr <= 0;
    else if(in_valid_reg == 1)
    begin
        if(cnt_input == 24)
        begin
            if(op_current == 2 || op_current == 3)
                sram1_addr <= 0;
            else
                sram1_addr <= sram1_addr + 1;
        end
        else if(cnt_input == 50)
        begin
            if(op_current == 6 || op_current == 7)
                sram1_addr <= 0;
            else
                sram1_addr <= sram1_addr + 1;
        end
        else
        begin
            if(cnt_input == 255)
                sram1_addr <= 0;
            else
                sram1_addr <= sram1_addr + 1;
        end
    end
    else if(current_state == s_erodil)
    begin
        if(cnt_erodil == 255)
            sram1_addr <= 0;
        else
            sram1_addr <= sram1_addr + 1;
    end
    else if(current_state == s_openclose)
    begin
        if(cnt_openclose == 255)
            sram1_addr <= 0;
        else
            sram1_addr <= sram1_addr + 1;
    end
    else if(current_state == s_his)
    begin
        sram1_addr <= sram1_addr + 1;
    end
    else if(current_state == s_output)
    begin
        sram1_addr <= sram1_addr + 1;
    end
    else
        sram1_addr <= sram1_addr;
end

// sram1_in
always@(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        sram1_in <= 0;
    else if(current_state == s_erodil)
        sram1_in <= ero_dil_result_lb1;
    else if(current_state == s_openclose)
        sram1_in <= ero_dil_result_lb2;
    else if(in_valid == 1)
        sram1_in <= pic_data;
    else if(current_state == s_idle)
        sram1_in <= 0;
    else
        sram1_in <= sram1_in;
end

// sram1_out_reg
always@(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        sram1_out_reg <= 0;
    else if(current_state == s_idle)/*initial value*/
        sram1_out_reg <= 0;
    else
        sram1_out_reg <= sram1_out;
end

//==============================================//
//                Get Input Data                //
//==============================================//
// op 0 histogram 2 erosion 3 dilation 6 opening 7 closing
// op_current
always@(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        op_current <= 0;
    // get current input op
    else if(op_valid == 1)
        op_current <= op;
    else if(current_state == s_idle)
        op_current <= 0;
    else
        op_current <= op_current;
end

// se_data_reg
always@(posedge clk or negedge rst_n)
begin
    if(!rst_n)
    begin
        se_data_reg <= 0;
    end
    else if(in_valid == 1 && cnt_input < 15)
    begin
        se_data_reg <= se_data;
    end
    else
    begin
        se_data_reg <= 0;
    end
end
// se_array
always@(posedge clk or negedge rst_n)
begin
    if(!rst_n)
    begin
        for (i=0; i<16; i=i+1)
        begin
            se_array[i] <= 0;
        end
    end
    else if(current_state == s_input && cnt_input < 16)
    begin
        se_array[cnt_input] <= se_data_reg;
    end
    else
    begin
        for (i=0; i<16; i=i+1)
        begin
            se_array[i] <= se_array[i];
        end
    end
end

//==============================================//
//               Shift Line Buffer              //
//==============================================//
/// line buffer1 ///
// line_buffer1_row0 //
// line_buffer1_row0[7]
always@(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        line_buffer1_row0[7] <= 0;
    else
        line_buffer1_row0[7] <= line_buffer1_row1[0];
end
// line_buffer1_row0[0:6]
generate
    for(idx=0 ; idx<7; idx=idx+1)
    begin
        always@(posedge clk or negedge rst_n)
        begin
            if(!rst_n)
                line_buffer1_row0[idx] <= 0;
            else
                line_buffer1_row0[idx] <= line_buffer1_row0[idx+1];
        end
    end
endgenerate
// line_buffer1_row1 //
// line_buffer1_row1[7]
always@(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        line_buffer1_row1[7] <= 0;
    else
        line_buffer1_row1[7] <= line_buffer1_row2[0];
end
// line_buffer1_row1[0:6]
generate
    for(idx=0 ; idx<7; idx=idx+1)
    begin
        always@(posedge clk or negedge rst_n)
        begin
            if(!rst_n)
                line_buffer1_row1[idx] <= 0;
            else
                line_buffer1_row1[idx] <= line_buffer1_row1[idx+1];
        end
    end
endgenerate
// line_buffer1_row2 //
// line_buffer1_row2[7]
always@(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        line_buffer1_row2[7] <= 0;
    else
        line_buffer1_row2[7] <= line_buffer1_row3[0];
end
// line_buffer1_row2[0:6]
generate
    for(idx=0 ; idx<7; idx=idx+1)
    begin
        always@(posedge clk or negedge rst_n)
        begin
            if(!rst_n)
                line_buffer1_row2[idx] <= 0;
            else
                line_buffer1_row2[idx] <= line_buffer1_row2[idx+1];
        end
    end
endgenerate
// line_buffer1_row3 //
// line_buffer1_row3[1]
always@(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        line_buffer1_row3[1] <= 0;
    else if(in_valid == 1)
        line_buffer1_row3[1] <= pic_data;
    else
        line_buffer1_row3[1] <= 0;
end
// line_buffer1_row3[0]
always@(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        line_buffer1_row3[0] <= 0;
    else
        line_buffer1_row3[0] <= line_buffer1_row3[1];
end


/// line buffer2 ///
// line_buffer2_row0 //
// line_buffer2_row0[7]
always@(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        line_buffer2_row0[7] <= 0;
    else
        line_buffer2_row0[7] <= line_buffer2_row1[0];
end
// line_buffer2_row0[0:6]
generate
    for(idx=0 ; idx<7; idx=idx+1)
    begin
        always@(posedge clk or negedge rst_n)
        begin
            if(!rst_n)
                line_buffer2_row0[idx] <= 0;
            else
                line_buffer2_row0[idx] <= line_buffer2_row0[idx+1];
        end
    end
endgenerate
// line_buffer2_row1 //
// line_buffer2_row1[7]
always@(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        line_buffer2_row1[7] <= 0;
    else
        line_buffer2_row1[7] <= line_buffer2_row2[0];
end
// line_buffer2_row1[0:6]
generate
    for(idx=0 ; idx<7; idx=idx+1)
    begin
        always@(posedge clk or negedge rst_n)
        begin
            if(!rst_n)
                line_buffer2_row1[idx] <= 0;
            else
                line_buffer2_row1[idx] <= line_buffer2_row1[idx+1];
        end
    end
endgenerate
// line_buffer2_row2 //
// line_buffer2_row2[7]
always@(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        line_buffer2_row2[7] <= 0;
    else
        line_buffer2_row2[7] <= line_buffer2_row3[0];
end
// line_buffer2_row2[0:6]
generate
    for(idx=0 ; idx<7; idx=idx+1)
    begin
        always@(posedge clk or negedge rst_n)
        begin
            if(!rst_n)
                line_buffer2_row2[idx] <= 0;
            else
                line_buffer2_row2[idx] <= line_buffer2_row2[idx+1];
        end
    end
endgenerate
// line_buffer2_row3 //
// line_buffer2_row3[1]
always@(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        line_buffer2_row3[1] <= 0;
    else if(in_valid == 1)
        line_buffer2_row3[1] <= ero_dil_result_lb1;
    else if(current_state == 3 && cnt_openclose < 230)
        line_buffer2_row3[1] <= ero_dil_result_lb1;
    else
        line_buffer2_row3[1] <= 0;
end
// line_buffer2_row3[0]
always@(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        line_buffer2_row3[0] <= 0;
    else
        line_buffer2_row3[0] <= line_buffer2_row3[1];
end

//==============================================//
//         Erosion & Dilation Calculation       //
//==============================================//
// lb1
wire [55:0] lb1_row0 = (cnt_padding == 7) ? {24'b0,line_buffer1_row0[0]}:{line_buffer1_row0[1][23:0],line_buffer1_row0[0]};
wire [55:0] lb1_row1 = (cnt_padding == 7) ? {24'b0,line_buffer1_row1[0]}:{line_buffer1_row1[1][23:0],line_buffer1_row1[0]};
wire [55:0] lb1_row2 = (cnt_padding == 7) ? {24'b0,line_buffer1_row2[0]}:{line_buffer1_row2[1][23:0],line_buffer1_row2[0]};
wire [55:0] lb1_row3 = (cnt_padding == 7) ? {24'b0,line_buffer1_row3[0]}:{line_buffer1_row3[1][23:0],line_buffer1_row3[0]};

// ero dil array
wire [7:0] ero_pic_array[3:0];
wire [7:0] dil_pic_array[3:0];
wire [31:0] ero_result;
wire [31:0] dil_result;

// ero_result
assign ero_result ={ero_pic_array[3],  ero_pic_array[2],  ero_pic_array[1],  ero_pic_array[0]};
// dil_result
assign dil_result ={dil_pic_array[3],  dil_pic_array[2],  dil_pic_array[1],  dil_pic_array[0]};
// ero_dil_result_lb1
assign ero_dil_result_lb1 = (op_current == 2 || op_current == 6) ? ero_result : dil_result;

// erosion //
generate
    for(idx=0; idx<4; idx=idx+1)
    begin
        wire [7:0] elm0  = (lb1_row0[idx*8+7:idx*8+0]   < se_array[0])?  8'd0:(lb1_row0[idx*8+7:idx*8+0]   - se_array[0]);
        wire [7:0] elm1  = (lb1_row0[idx*8+15:idx*8+8]  < se_array[1])?  8'd0:(lb1_row0[idx*8+15:idx*8+8]  - se_array[1]);
        wire [7:0] elm2  = (lb1_row0[idx*8+23:idx*8+16] < se_array[2])?  8'd0:(lb1_row0[idx*8+23:idx*8+16] - se_array[2]);
        wire [7:0] elm3  = (lb1_row0[idx*8+31:idx*8+24] < se_array[3])?  8'd0:(lb1_row0[idx*8+31:idx*8+24] - se_array[3]);
        wire [7:0] elm4  = (lb1_row1[idx*8+7:idx*8+0]   < se_array[4])?  8'd0:(lb1_row1[idx*8+7:idx*8+0]   - se_array[4]);
        wire [7:0] elm5  = (lb1_row1[idx*8+15:idx*8+8]  < se_array[5])?  8'd0:(lb1_row1[idx*8+15:idx*8+8]  - se_array[5]);
        wire [7:0] elm6  = (lb1_row1[idx*8+23:idx*8+16] < se_array[6])?  8'd0:(lb1_row1[idx*8+23:idx*8+16] - se_array[6]);
        wire [7:0] elm7  = (lb1_row1[idx*8+31:idx*8+24] < se_array[7])?  8'd0:(lb1_row1[idx*8+31:idx*8+24] - se_array[7]);
        wire [7:0] elm8  = (lb1_row2[idx*8+7:idx*8+0]   < se_array[8])?  8'd0:(lb1_row2[idx*8+7:idx*8+0]   - se_array[8]);
        wire [7:0] elm9  = (lb1_row2[idx*8+15:idx*8+8]  < se_array[9])?  8'd0:(lb1_row2[idx*8+15:idx*8+8]  - se_array[9]);
        wire [7:0] elm10 = (lb1_row2[idx*8+23:idx*8+16] < se_array[10])? 8'd0:(lb1_row2[idx*8+23:idx*8+16] - se_array[10]);
        wire [7:0] elm11 = (lb1_row2[idx*8+31:idx*8+24] < se_array[11])? 8'd0:(lb1_row2[idx*8+31:idx*8+24] - se_array[11]);
        wire [7:0] elm12 = (lb1_row3[idx*8+7:idx*8+0]   < se_array[12])? 8'd0:(lb1_row3[idx*8+7:idx*8+0]   - se_array[12]);
        wire [7:0] elm13 = (lb1_row3[idx*8+15:idx*8+8]  < se_array[13])? 8'd0:(lb1_row3[idx*8+15:idx*8+8]  - se_array[13]);
        wire [7:0] elm14 = (lb1_row3[idx*8+23:idx*8+16] < se_array[14])? 8'd0:(lb1_row3[idx*8+23:idx*8+16] - se_array[14]);
        wire [7:0] elm15 = (lb1_row3[idx*8+31:idx*8+24] < se_array[15])? 8'd0:(lb1_row3[idx*8+31:idx*8+24] - se_array[15]);
        wire [127:0] tmp_in = {elm0,elm1,elm2,elm3,elm4,elm5,elm6,elm7,elm8,elm9,elm10,elm11,elm12,elm13,elm14,elm15};
        wire [7:0] tmp_out;
        Min_16to1 u_Min_16to1(tmp_in,tmp_out);
        assign ero_pic_array[idx] = tmp_out;
    end
endgenerate

// Dilation //
generate
    for(idx=0; idx<4; idx=idx+1)
    begin : lb1_Dilation1
        wire [8:0] eelm0  = lb1_row0[idx*8+7:idx*8+0]   + se_array[15];
        wire [8:0] eelm1  = lb1_row0[idx*8+15:idx*8+8]  + se_array[14];
        wire [8:0] eelm2  = lb1_row0[idx*8+23:idx*8+16] + se_array[13];
        wire [8:0] eelm3  = lb1_row0[idx*8+31:idx*8+24] + se_array[12];
        wire [8:0] eelm4  = lb1_row1[idx*8+7:idx*8+0]   + se_array[11];
        wire [8:0] eelm5  = lb1_row1[idx*8+15:idx*8+8]  + se_array[10];
        wire [8:0] eelm6  = lb1_row1[idx*8+23:idx*8+16] + se_array[9];
        wire [8:0] eelm7  = lb1_row1[idx*8+31:idx*8+24] + se_array[8];
        wire [8:0] eelm8  = lb1_row2[idx*8+7:idx*8+0]   + se_array[7];
        wire [8:0] eelm9  = lb1_row2[idx*8+15:idx*8+8]  + se_array[6];
        wire [8:0] eelm10 = lb1_row2[idx*8+23:idx*8+16] + se_array[5];
        wire [8:0] eelm11 = lb1_row2[idx*8+31:idx*8+24] + se_array[4];
        wire [8:0] eelm12 = lb1_row3[idx*8+7:idx*8+0]   + se_array[3];
        wire [8:0] eelm13 = lb1_row3[idx*8+15:idx*8+8]  + se_array[2];
        wire [8:0] eelm14 = lb1_row3[idx*8+23:idx*8+16] + se_array[1];
        wire [8:0] eelm15 = lb1_row3[idx*8+31:idx*8+24] + se_array[0];
        wire [143:0] etmp_in = {eelm0,eelm1,eelm2,eelm3,eelm4,eelm5,eelm6,eelm7,eelm8,eelm9,eelm10,eelm11,eelm12,eelm13,eelm14,eelm15};
        wire [7:0] etmp_out;
        Max_16to1 u_Max_16to1(etmp_in,etmp_out);
        assign dil_pic_array[idx] = etmp_out;
    end
endgenerate

// ero_dil_value
always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        ero_dil_value <= 0;
    else if(current_state == s_idle)
        ero_dil_value <= 0;
    else
    begin
        if(op_current == 2 || op_current == 6)
            ero_dil_value <= ero_result;
        else
            ero_dil_value <= dil_result;
    end
end

// lb2
wire [55:0] lb2_row0 = (cnt_padding == 1) ? {24'b0,line_buffer2_row0[0]}:{line_buffer2_row0[1][23:0],line_buffer2_row0[0]};
wire [55:0] lb2_row1 = (cnt_padding == 1) ? {24'b0,line_buffer2_row1[0]}:{line_buffer2_row1[1][23:0],line_buffer2_row1[0]};
wire [55:0] lb2_row2 = (cnt_padding == 1) ? {24'b0,line_buffer2_row2[0]}:{line_buffer2_row2[1][23:0],line_buffer2_row2[0]};
wire [55:0] lb2_row3 = (cnt_padding == 1) ? {24'b0,line_buffer2_row3[0]}:{line_buffer2_row3[1][23:0],line_buffer2_row3[0]};

// ero dil array
wire [7:0] ero_pic_array2[3:0];
wire [7:0] dil_pic_array2[3:0];
wire [31:0] ero_result2;
wire [31:0] dil_result2;
// ero_result2
assign ero_result2 ={ero_pic_array2[3],  ero_pic_array2[2],  ero_pic_array2[1],  ero_pic_array2[0]};
// dil_result2
assign dil_result2 ={dil_pic_array2[3],  dil_pic_array2[2],  dil_pic_array2[1],  dil_pic_array2[0]};
// ero_dil_result_lb2
assign ero_dil_result_lb2 = (op_current == 7) ? ero_result2 : dil_result2;

// erosion //
generate
    for(idx=0; idx<4; idx=idx+1)
    begin
        wire [7:0] elm02  = (lb2_row0[idx*8+7:idx*8+0]   < se_array[0])?  8'd0:(lb2_row0[idx*8+7:idx*8+0]   - se_array[0]);
        wire [7:0] elm12  = (lb2_row0[idx*8+15:idx*8+8]  < se_array[1])?  8'd0:(lb2_row0[idx*8+15:idx*8+8]  - se_array[1]);
        wire [7:0] elm22  = (lb2_row0[idx*8+23:idx*8+16] < se_array[2])?  8'd0:(lb2_row0[idx*8+23:idx*8+16] - se_array[2]);
        wire [7:0] elm32  = (lb2_row0[idx*8+31:idx*8+24] < se_array[3])?  8'd0:(lb2_row0[idx*8+31:idx*8+24] - se_array[3]);
        wire [7:0] elm42  = (lb2_row1[idx*8+7:idx*8+0]   < se_array[4])?  8'd0:(lb2_row1[idx*8+7:idx*8+0]   - se_array[4]);
        wire [7:0] elm52  = (lb2_row1[idx*8+15:idx*8+8]  < se_array[5])?  8'd0:(lb2_row1[idx*8+15:idx*8+8]  - se_array[5]);
        wire [7:0] elm62  = (lb2_row1[idx*8+23:idx*8+16] < se_array[6])?  8'd0:(lb2_row1[idx*8+23:idx*8+16] - se_array[6]);
        wire [7:0] elm72  = (lb2_row1[idx*8+31:idx*8+24] < se_array[7])?  8'd0:(lb2_row1[idx*8+31:idx*8+24] - se_array[7]);
        wire [7:0] elm82  = (lb2_row2[idx*8+7:idx*8+0]   < se_array[8])?  8'd0:(lb2_row2[idx*8+7:idx*8+0]   - se_array[8]);
        wire [7:0] elm92  = (lb2_row2[idx*8+15:idx*8+8]  < se_array[9])?  8'd0:(lb2_row2[idx*8+15:idx*8+8]  - se_array[9]);
        wire [7:0] elm102 = (lb2_row2[idx*8+23:idx*8+16] < se_array[10])? 8'd0:(lb2_row2[idx*8+23:idx*8+16] - se_array[10]);
        wire [7:0] elm112 = (lb2_row2[idx*8+31:idx*8+24] < se_array[11])? 8'd0:(lb2_row2[idx*8+31:idx*8+24] - se_array[11]);
        wire [7:0] elm122 = (lb2_row3[idx*8+7:idx*8+0]   < se_array[12])? 8'd0:(lb2_row3[idx*8+7:idx*8+0]   - se_array[12]);
        wire [7:0] elm132 = (lb2_row3[idx*8+15:idx*8+8]  < se_array[13])? 8'd0:(lb2_row3[idx*8+15:idx*8+8]  - se_array[13]);
        wire [7:0] elm142 = (lb2_row3[idx*8+23:idx*8+16] < se_array[14])? 8'd0:(lb2_row3[idx*8+23:idx*8+16] - se_array[14]);
        wire [7:0] elm152 = (lb2_row3[idx*8+31:idx*8+24] < se_array[15])? 8'd0:(lb2_row3[idx*8+31:idx*8+24] - se_array[15]);
        wire [127:0] tmp_in2 = {elm02,elm12,elm22,elm32,elm42,elm52,elm62,elm72,elm82,elm92,elm102,elm112,elm122,elm132,elm142,elm152};
        wire [7:0] tmp_out2;
        Min_16to1 u_Min_16to1(tmp_in2,tmp_out2);
        assign ero_pic_array2[idx] = tmp_out2;
    end
endgenerate

// Dilation //
generate
    for(idx=0; idx<4; idx=idx+1)
    begin
        wire [8:0] eelm02  = lb2_row0[idx*8+7:idx*8+0]   + se_array[15];
        wire [8:0] eelm12  = lb2_row0[idx*8+15:idx*8+8]  + se_array[14];
        wire [8:0] eelm22  = lb2_row0[idx*8+23:idx*8+16] + se_array[13];
        wire [8:0] eelm32  = lb2_row0[idx*8+31:idx*8+24] + se_array[12];
        wire [8:0] eelm42  = lb2_row1[idx*8+7:idx*8+0]   + se_array[11];
        wire [8:0] eelm52  = lb2_row1[idx*8+15:idx*8+8]  + se_array[10];
        wire [8:0] eelm62  = lb2_row1[idx*8+23:idx*8+16] + se_array[9];
        wire [8:0] eelm72  = lb2_row1[idx*8+31:idx*8+24] + se_array[8];
        wire [8:0] eelm82  = lb2_row2[idx*8+7:idx*8+0]   + se_array[7];
        wire [8:0] eelm92  = lb2_row2[idx*8+15:idx*8+8]  + se_array[6];
        wire [8:0] eelm102 = lb2_row2[idx*8+23:idx*8+16] + se_array[5];
        wire [8:0] eelm112 = lb2_row2[idx*8+31:idx*8+24] + se_array[4];
        wire [8:0] eelm122 = lb2_row3[idx*8+7:idx*8+0]   + se_array[3];
        wire [8:0] eelm132 = lb2_row3[idx*8+15:idx*8+8]  + se_array[2];
        wire [8:0] eelm142 = lb2_row3[idx*8+23:idx*8+16] + se_array[1];
        wire [8:0] eelm152 = lb2_row3[idx*8+31:idx*8+24] + se_array[0];
        wire [143:0] etmp_in2 = {eelm02,eelm12,eelm22,eelm32,eelm42,eelm52,eelm62,eelm72,eelm82,eelm92,eelm102,eelm112,eelm122,eelm132,eelm142,eelm152};
        wire [7:0] etmp_out2;
        Max_16to1 u_Max_16to1(etmp_in2,etmp_out2);
        assign dil_pic_array2[idx] = etmp_out2;
    end
endgenerate

// ero_dil_value2
always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        ero_dil_value2 <= 0;
    else if(current_state == s_idle)
        ero_dil_value2 <= 0;
    else
    begin
        if(op_current == 7)
            ero_dil_value2 <= ero_result2;
        else
            ero_dil_value2 <= dil_result2;
    end
end

//==============================================//
//              Histogram Calculation           //
//==============================================//
// in state = s_input //
// pic_data to pic_data_reg
// pic_data_reg
always@(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        pic_data_reg <= 0;
    else if(in_valid == 1)
        pic_data_reg <= pic_data;
    else
        pic_data_reg <= 0;
end

// find min vale of input value(store in input reg pic_data_reg)
wire [7:0] out_in4min;
Min_4to1 u_Min_4to1_f (pic_data_reg[7:0],   pic_data_reg[15:8],  pic_data_reg[23:16],   pic_data_reg[31:24], out_in4min);

// his_min_value
always@(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        his_min_value <= 255;
    else if(in_valid_reg == 1)
    begin
        if(his_min_value < out_in4min)
            his_min_value <= his_min_value;
        else
            his_min_value <= out_in4min;
    end
    else if(current_state == s_idle)
        his_min_value <= 255;
    else
        his_min_value <= his_min_value;
end

// build cdf table //
reg [10:0] cdf_table[255:0];
wire [2:0] cdf_add[255:0];
generate
    for(idx=0; idx<256; idx=idx+1)
    begin
        wire [2:0] tmp_cal;
        assign tmp_cal = (pic_data_reg[7:0]<=idx)+(pic_data_reg[15:8]<=idx)+(pic_data_reg[23:16]<=idx)+(pic_data_reg[31:24]<=idx);
        assign cdf_add[idx] = tmp_cal;
    end
endgenerate

// in_valid_reg
always@(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        in_valid_reg <= 0;
    else if(in_valid == 1)
        in_valid_reg <= 1;
    else
        in_valid_reg <= 0;
end

// cdf_table use cdf_add update
generate
    for(idx=0; idx<256; idx=idx+1)
    begin
        always@(posedge clk or negedge rst_n)
        begin
            if(!rst_n)
                cdf_table[idx] <= 0;
            else if(current_state == s_idle)
                cdf_table[idx] <= 0;
            else if(in_valid_reg == 1)
            begin
                cdf_table[idx] <= cdf_table[idx] + cdf_add[idx];
            end
            else
                cdf_table[idx] <= cdf_table[idx];
        end
    end
endgenerate

// in state == s_his //
reg [10:0] min;
// min
always@(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        min <= 0;
    else if(current_state == s_idle)
        min <= 0;
    else if(current_state == s_his && cnt_his == 0)
        min <= cdf_table[his_min_value];
    else
        min <= min;
end

// output prepare
reg [17:0] cdv_dividend[3:0];
// cdv_dividend
generate
    for(idx=0; idx<4; idx=idx+1)
    begin
        always@(posedge clk or negedge rst_n)
        begin
            if(!rst_n)
            begin
                cdv_dividend[idx] <= 0;
            end
            else if(current_state == s_idle)
            begin
                cdv_dividend[idx] <= 0;
            end
            else if(current_state == s_his && cnt_his > 1)
            begin
                cdv_dividend[idx] <= (cdf_table[sram1_out_reg[idx*8+7:idx*8+0]] - min) * 255;
            end
            else if(current_state == s_output)
            begin
                cdv_dividend[idx] <= (cdf_table[sram1_out_reg[idx*8+7:idx*8+0]] - min) * 255;
            end
            else
            begin
                cdv_dividend[idx] <= cdv_dividend[i];
            end
        end
    end
endgenerate


// divisor
reg [9:0] divisor;
always@(posedge clk or negedge rst_n)
begin
    if(!rst_n)
    begin
        divisor <= 0;
    end
    else if(current_state == s_idle)
        divisor <= 0;
    else if(current_state == s_his && cnt_his == 2)
        divisor <= (1024 - min);
    else
    begin
        divisor <= divisor;
    end
end

reg [7:0] cdv_value[3:0];
// cdv_value
generate
    for(idx=0; idx<4; idx=idx+1)
    begin
        always@(posedge clk or negedge rst_n)
        begin
            if(!rst_n)
            begin
                cdv_value[idx] <= 0;
            end
            //initial
            else if(current_state == s_idle)
            begin
                cdv_value[idx] <= 0;
            end
            else if(current_state == s_his && cnt_his > 2)
            begin
                cdv_value[idx] <= cdv_dividend[idx]/divisor;
            end
            else if(current_state == s_output)
            begin
                cdv_value[idx] <= cdv_dividend[idx]/divisor;
            end
            else
            begin
                cdv_value[idx] <= cdv_value[i];
            end
        end
    end
endgenerate

//==============================================//
//                    Output                    //
//==============================================//
// out_valid
always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        out_valid <= 0;
    else if(current_state == s_output)
    begin
        if(cnt_output == 256)
            out_valid <= 0;
        else
            out_valid <= 1;
    end
    else
        out_valid <= 0;
end
// out_data
always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        out_data <= 0;
    else if(current_state == s_output && cnt_output < 256)
    begin
        if(op_current == 0)
            out_data <= {cdv_value[3],cdv_value[2],cdv_value[1],cdv_value[0]};
        else
            out_data <= sram1_out;
    end
    else
        out_data <= 0;
end
endmodule

    module Min_16to1(
        // input
        in,
        // output
        out
    );
// input
input [127:0] in;
// output
output  [7:0] out;
// WIRE AND REG DECLARATION
wire    [7:0] out0, out1;
Min_8to1 u_Min_8to1_0 (in[7:0],    in[15:8],    in[23:16],   in[31:24],
                       in[39:32],  in[47:40],   in[55:48],   in[63:56],   out0);
Min_8to1 u_Min_8to1_1 (in[71:64],  in[79:72],   in[87:80],   in[95:88],
                       in[103:96], in[111:104], in[119:112], in[127:120],  out1);
wire    [7:0] final_out  = (out0 < out1) ? out0 : out1;
// out
assign out = final_out;
endmodule


    module Min_8to1(
        // input
        in1,in2,in3,in4,in5,in6,in7,in8,
        // output
        out
    );
// input
input  [7:0] in1, in2, in3, in4, in5, in6, in7, in8;
// output
output [7:0] out;
// WIRE AND REG DECLARATION
wire   [7:0] min2to1_0  = (in1 < in2) ? in1 : in2;
wire   [7:0] min2to1_1  = (in3 < in4) ? in3 : in4;
wire   [7:0] min2to1_2  = (in5 < in6) ? in5 : in6;
wire   [7:0] min2to1_3  = (in7 < in8) ? in7 : in8;
wire   [7:0] min_4to1_0 = (min2to1_0 < min2to1_1) ? min2to1_0 : min2to1_1;
wire   [7:0] min_4to1_1 = (min2to1_2 < min2to1_3) ? min2to1_2 : min2to1_3;
wire   [7:0] min_final  = (min_4to1_0 < min_4to1_1) ? min_4to1_0 : min_4to1_1;
// out
assign             out  = min_final;
endmodule

    module Max_16to1(
        // input
        in,
        // output
        out
    );
// input
input [143:0] in;
// output
output  [7:0] out;
// WIRE AND REG DECLARATION
wire    [7:0] out0, out1;
Max_8to1 u_Max_8to1_0 (in[8:0],     in[17:9],    in[26:18],   in[35:27],
                       in[44:36],   in[53:45],   in[62:54],   in[71:63],   out0);
Max_8to1 u_Max_8to1_1 (in[80:72],   in[89:81],   in[98:90],   in[107:99],
                       in[116:108], in[125:117], in[134:126], in[143:135], out1);
wire   [7:0] final_out  = (out0 > out1) ? out0 : out1;
// out
assign out = final_out;
endmodule


    module Max_8to1(
        // input
        in1,in2,in3,in4,in5,in6,in7,in8,
        // output
        out
    );
// input
input  [8:0] in1, in2, in3, in4, in5, in6, in7, in8;
// output
output [7:0] out;
// WIRE AND REG DECLARATION
wire   [7:0] in_tmp1   = (in1 > 255) ? 255 : in1[7:0];
wire   [7:0] in_tmp2   = (in2 > 255) ? 255 : in2[7:0];
wire   [7:0] in_tmp3   = (in3 > 255) ? 255 : in3[7:0];
wire   [7:0] in_tmp4   = (in4 > 255) ? 255 : in4[7:0];
wire   [7:0] in_tmp5   = (in5 > 255) ? 255 : in5[7:0];
wire   [7:0] in_tmp6   = (in6 > 255) ? 255 : in6[7:0];
wire   [7:0] in_tmp7   = (in7 > 255) ? 255 : in7[7:0];
wire   [7:0] in_tmp8   = (in8 > 255) ? 255 : in8[7:0];
wire   [7:0] max2to1_1 = (in_tmp1 > in_tmp2) ? in_tmp1 : in_tmp2;
wire   [7:0] max2to1_2 = (in_tmp3 > in_tmp4) ? in_tmp3 : in_tmp4;
wire   [7:0] max2to1_3 = (in_tmp5 > in_tmp6) ? in_tmp5 : in_tmp6;
wire   [7:0] max2to1_4 = (in_tmp7 > in_tmp8) ? in_tmp7 : in_tmp8;
wire   [7:0] max_0     = (max2to1_1 > max2to1_2) ? max2to1_1 : max2to1_2;
wire   [7:0] max_1     = (max2to1_3 > max2to1_4) ? max2to1_3 : max2to1_4;
wire   [7:0] max_final = (max_0 > max_1) ? max_0 : max_1;
// out
assign             out = max_final;
endmodule

    module Min_4to1(
        // input
        in1,in2,in3,in4,
        // output
        out
    );
// input
input  [7:0] in1, in2, in3, in4;
// output
output [7:0] out;
// WIRE AND REG DECLARATION
wire   [7:0] min2to1_0 = (in1 < in2) ? in1 : in2;
wire   [7:0] min2to1_1 = (in3 < in4) ? in3 : in4;
wire   [7:0] min_4to1  = (min2to1_0 < min2to1_1) ? min2to1_0 : min2to1_1;
// out
assign             out = min_4to1;
endmodule
