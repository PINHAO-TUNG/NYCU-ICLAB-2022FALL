module MMSA(
           // input signals
           clk,
           rst_n,
           in_valid,
           in_valid2,
           matrix,
           matrix_size,
           i_mat_idx,
           w_mat_idx,

           // output signals
           out_valid,
           out_value
       );
//---------------------------------------------------------------------
//   INPUT AND OUTPUT DECLARATION
//---------------------------------------------------------------------
input        clk, rst_n, in_valid, in_valid2;
input [15:0] matrix;
input [1:0]  matrix_size;
input [3:0]  i_mat_idx, w_mat_idx;

output reg       	     out_valid;
output reg signed [39:0] out_value;

//---------------------------------------------------------------------
//   PARAMETER
//---------------------------------------------------------------------
// FSM Parameter
parameter s_idle   = 3'd0;
parameter s_matrix = 3'd1;
parameter s_index  = 3'd2;
parameter s_cal    = 3'd3;
parameter s_output = 3'd4;

// genvar
integer i, j;
genvar  idx, jdx;
//---------------------------------------------------------------------
//   WIRE AND REG DECLARATION
//---------------------------------------------------------------------
/// FSM ///
// state
reg [2:0] current_state, next_state;
// counter matrix index cnt
reg [5:0] matrix_cnt;
reg [5:0] index_matrix_cnt;
reg [5:0] fsm_cnt;
// current_matrix_size
reg  in_valid_flag, in_valid2_flag;
reg [1:0] current_matrix_size;

// sram //
// sram x matrix
wire signed [15:0] x_sram_out[0:7];
wire x_sram_cen[0:7];			// always enable
wire x_sram_oen[0:7];			// always enable
reg x_sram_wen[0:7];
reg [7:0] x_sram_a[0:7];
reg signed [15:0] x_sram_in[0:7];

// sram w matrix
wire signed [15:0] w_sram_out[0:7];
wire w_sram_cen[0:7];			// always enable
wire w_sram_oen[0:7];			// always enable
reg w_sram_wen[0:7];
reg [7:0] w_sram_a[0:7];
reg signed [15:0] w_sram_in[0:7];

// sram load data
reg signed [15:0] x_data[0:7][0:14];
reg signed [15:0] w_data[0:7][0:7];

// input //
// input cnt array
reg [3:0] column_cnt;
reg [3:0] row_cnt;

// index //
reg [3:0] current_imat_idx, current_wmat_idx;

// cal //
// PE
reg signed [15:0] ina [0:7][0:7];
reg signed [39:0] inb [0:7][0:7];
reg signed [15:0] inw [0:7][0:7];
wire signed [39:0] outc [0:7][0:7];
wire signed [15:0] outd [0:7][0:7];

// output_value
reg signed [39:0] output_value[0:14];

//---------------------------------------------------------------------
//   DESIGN
//---------------------------------------------------------------------
//==============================================//
//            FSM State Declaration             //
//==============================================//
// current_state //
always@(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        current_state <= s_idle;
    else
    begin
        current_state <= next_state;
    end
end

// next_state //
always @(*)
begin
    case(current_state)
        s_idle:
        begin
            next_state = s_matrix;
        end
        s_matrix:
        begin
            // in_valid == 0 && matrix_cnt > 31 in_valid == 0 && in_valid_flag == 1 
            if(in_valid == 0 && matrix_cnt > 31)
                next_state = s_index;
            else
                next_state = current_state;
        end
        s_index:
        begin
            //in_valid2 == 1 in_valid2 == 0 && in_valid2_flag == 1
            if(in_valid2 == 0 && in_valid2_flag == 1)
                next_state = s_cal;
            else
                next_state = current_state;
        end
        s_cal:
        begin
            case(current_matrix_size)
                0:
                begin
                    if(fsm_cnt == 6'd8)
                        next_state = s_output;
                    else
                        next_state = current_state;
                end
                1:
                begin
                    if(fsm_cnt == 6'd14)
                        next_state = s_output;
                    else
                        next_state = current_state;
                end
                2:
                begin
                    if(fsm_cnt == 6'd26)
                        next_state = s_output;
                    else
                        next_state = current_state;
                end
                default:
                    next_state = current_state;
            endcase
        end
        s_output:
        begin
            if(index_matrix_cnt == 6'd16)
            begin
                case(current_matrix_size)
                    0:
                    begin
                        if(fsm_cnt == 6'd2)
                            next_state = s_idle;
                        else
                            next_state = current_state;
                    end
                    1:
                    begin
                        if(fsm_cnt == 6'd6)
                            next_state = s_idle;
                        else
                            next_state = current_state;
                    end
                    2:
                    begin
                        if(fsm_cnt == 6'd14)
                            next_state = s_idle;
                        else
                            next_state = current_state;
                    end
                    default:
                        next_state = current_state;
                endcase
            end
            else
            begin
                case(current_matrix_size)
                    0:
                    begin
                        if(fsm_cnt == 6'd2)
                            next_state = s_index;
                        else
                            next_state = current_state;
                    end
                    1:
                    begin
                        if(fsm_cnt == 6'd6)
                            next_state = s_index;
                        else
                            next_state = current_state;
                    end
                    2:
                    begin
                        if(fsm_cnt == 6'd14)
                            next_state = s_index;
                        else
                            next_state = current_state;
                    end
                    default:
                        next_state = current_state;
                endcase
            end
        end
        default:
            next_state = current_state;
    endcase
end

// matrix_cnt
always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        matrix_cnt <= 6'd0;
    else
    begin
        case(current_state)
            s_idle:
            begin
                matrix_cnt <= 6'd0;
            end
            s_matrix:
            begin
                case(current_matrix_size)
                    0:
                    begin
                        if(column_cnt == 1 && row_cnt == 1)
                            matrix_cnt <= matrix_cnt + 6'd1;
                        else
                            matrix_cnt <= matrix_cnt;
                    end
                    1:
                    begin
                        if(column_cnt == 3 && row_cnt == 3)
                            matrix_cnt <= matrix_cnt + 6'd1;
                        else
                            matrix_cnt <= matrix_cnt;
                    end
                    2:
                    begin
                        if(column_cnt == 7 && row_cnt == 7)
                            matrix_cnt <= matrix_cnt + 6'd1;
                        else
                            matrix_cnt <= matrix_cnt;
                    end
                    default:
                    begin
                        if(column_cnt == 1 && row_cnt == 1)
                            matrix_cnt <= matrix_cnt + 6'd1;
                        else
                            matrix_cnt <= matrix_cnt;
                    end
                endcase
            end
            s_index:
            begin
                matrix_cnt <= 6'd0;
            end
            default:
                matrix_cnt <= matrix_cnt;
        endcase
    end
end

// index_matrix_cnt
always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        index_matrix_cnt <= 6'd0;
    else if(current_state == s_idle)
        index_matrix_cnt <= 6'd0;
    else if(in_valid2 == 1)
    begin
        if(index_matrix_cnt == 6'd16)
            index_matrix_cnt <= 6'd0;
        else
            index_matrix_cnt <= index_matrix_cnt + 6'd1;
    end
    else
        index_matrix_cnt <= index_matrix_cnt;
end

// fsm_cnt
always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        fsm_cnt <= 6'd0;
    else
    case(current_state)
        s_idle:
        begin
            fsm_cnt <= 6'd0;
        end
        s_index:
        begin
            fsm_cnt <= 6'd0;
        end
        s_cal:
        begin
            case(current_matrix_size)
                0:
                begin
                    if(fsm_cnt == 6'd8)
                        fsm_cnt <= 6'd0;
                    else
                        fsm_cnt <= fsm_cnt + 6'd1;
                end
                1:
                begin
                    if(fsm_cnt == 6'd14)
                        fsm_cnt <= 6'd0;
                    else
                        fsm_cnt <= fsm_cnt + 6'd1;
                end
                2:
                begin
                    if(fsm_cnt == 6'd26)
                        fsm_cnt <= 6'd0;
                    else
                        fsm_cnt <= fsm_cnt + 6'd1;
                end
                default:
                    fsm_cnt <= fsm_cnt;
            endcase
        end
        s_output:
        begin
            case(current_matrix_size)
                0:
                begin
                    if(fsm_cnt == 6'd2)
                        fsm_cnt <= 6'd0;
                    else
                        fsm_cnt <= fsm_cnt + 6'd1;
                end
                1:
                begin
                    if(fsm_cnt == 6'd6)
                        fsm_cnt <= 6'd0;
                    else
                        fsm_cnt <= fsm_cnt + 6'd1;
                end
                2:
                begin
                    if(fsm_cnt == 6'd14)
                        fsm_cnt <= 6'd0;
                    else
                        fsm_cnt <= fsm_cnt + 6'd1;
                end
                default:
                    fsm_cnt <= fsm_cnt;
            endcase
        end
        default:
            fsm_cnt <= fsm_cnt;
    endcase
end

//==============================================//
//             over any state Design            //
//==============================================//
// in_valid_flag //
always @(posedge clk or negedge rst_n)
begin
    if (!rst_n)
        in_valid_flag = 1'd0;
    else
    begin
        if(in_valid)
            in_valid_flag = 1'd1;
        else
            in_valid_flag = 1'd0;
    end
end

// in_valid2_flag //
always @(posedge clk or negedge rst_n)
begin
    if (!rst_n)
        in_valid2_flag = 1'd0;
    else
    begin
        if(in_valid2)
            in_valid2_flag = 1'd1;
        else
            in_valid2_flag = 1'd0;
    end
end

// current_matrix_size //
always @(posedge clk or negedge rst_n)
begin
    if (!rst_n)
        current_matrix_size <= 2'd0;
    else if (current_state == s_idle)
        current_matrix_size <= 2'd0;
    else if(in_valid == 1 && in_valid_flag == 0)
    begin
        current_matrix_size <= matrix_size;
    end
    else
        current_matrix_size <= current_matrix_size;
end

//==============================================//
//              SRAM control Design             //
//==============================================//
// xsram
generate
    for(idx=0 ; idx<8 ; idx=idx+1)
    begin
        sram256 xsram(.Q(x_sram_out[idx]), .CLK(clk), .CEN(x_sram_cen[idx]), .WEN(x_sram_wen[idx]), .A(x_sram_a[idx]), .D(x_sram_in[idx]), .OEN(x_sram_oen[idx]));
    end
endgenerate

// wsram
generate
    for(idx=0 ; idx<8 ; idx=idx+1)
    begin
        sram256 xsram(.Q(w_sram_out[idx]), .CLK(clk), .CEN(w_sram_cen[idx]), .WEN(w_sram_wen[idx]), .A(w_sram_a[idx]), .D(w_sram_in[idx]), .OEN(w_sram_oen[idx]));
    end
endgenerate

// x_sram_cen x_sram_oen w_sram_cen w_sram_oen
generate
    for(idx=0 ; idx<8 ; idx=idx+1)
    begin
        assign x_sram_cen[idx] = 0;
        assign x_sram_oen[idx] = 0;
        assign w_sram_cen[idx] = 0;
        assign w_sram_oen[idx] = 0;
    end
endgenerate

// x_sram_a
always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
    begin
        for(i=0; i<16; i=i+1)
        begin
            x_sram_a[i] <= 8'd0;
        end
    end
    else if(current_state == s_matrix && matrix_cnt < 16)
    begin
        x_sram_a[column_cnt] <= row_cnt + 16*matrix_cnt;
    end
    else if(current_state == s_cal)
    begin
        for(i=0; i<16; i=i+1)
        begin
            x_sram_a[i] <= fsm_cnt + 16*current_imat_idx;
        end
    end
    else
    begin
        for(i=0; i<16; i=i+1)
        begin
            x_sram_a[i] <= x_sram_a[i];
        end
    end
end

// w_sram_a
always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
    begin
        for(i=0; i<16; i=i+1)
        begin
            w_sram_a[i] <= 8'd0;
        end
    end
    else if(current_state == s_matrix && matrix_cnt > 15 && matrix_cnt < 32)
    begin
        w_sram_a[column_cnt] <= row_cnt + 16*(matrix_cnt-16);
    end
    else if (current_state == s_cal)
    begin
        for(i=0; i<16; i=i+1)
        begin
            w_sram_a[i] <= fsm_cnt + 16*current_wmat_idx;
        end
    end
    else
    begin
        for(i=0; i<16; i=i+1)
        begin
            w_sram_a[i] <= w_sram_a[i];
        end
    end
end

// x_sram_wen
generate
    for (idx=0 ; idx<8 ; idx=idx+1)
    begin
        always @(posedge clk or negedge rst_n)
        begin
            if (!rst_n)
            begin
                x_sram_wen[idx] <= 1'd0;
            end
            else if(current_state == s_matrix)
            begin
                x_sram_wen[idx] <= 1'd0;
            end
            else if(current_state == s_cal)
            begin
                x_sram_wen[idx] <= 1'd1;
            end
            else
            begin
                x_sram_wen[idx] <= x_sram_wen[idx];
            end
        end
    end
endgenerate

// w_sram_wen
generate
    for (idx=0 ; idx<8 ; idx=idx+1)
    begin
        always @(posedge clk or negedge rst_n)
        begin
            if (!rst_n)
            begin
                w_sram_wen[idx] <= 1'd0;
            end
            else if(current_state == s_matrix)
            begin
                w_sram_wen[idx] <= 1'd0;
            end
            else if(current_state == s_cal)
            begin
                w_sram_wen[idx] <= 1'd1;
            end
            else
            begin
                w_sram_wen[idx] <= w_sram_wen[idx];
            end
        end
    end
endgenerate

//==============================================//
//           FSM state 1 matrix Block           //
//==============================================//
// input cnt array //
// row_cnt
always @(posedge clk or negedge rst_n)
begin
    if (!rst_n)
        row_cnt <= 4'd0;
    else
    begin
        if(current_state == s_matrix && in_valid == 1)/*new add && in_valid == 1*/
        begin
            case(current_matrix_size)
                0:
                begin
                    if(column_cnt == 4'd1)
                        if(row_cnt == 4'd1)
                            row_cnt <= 4'd0;
                        else
                            row_cnt <= row_cnt + 4'd1;
                    else
                    begin
                        row_cnt <= row_cnt;
                    end
                end
                1:
                begin
                    if(column_cnt == 4'd3)
                        if(row_cnt == 4'd3)
                            row_cnt <= 4'd0;
                        else
                            row_cnt <= row_cnt + 4'd1;
                    else
                    begin
                        row_cnt <= row_cnt;
                    end
                end
                2:
                begin
                    if(column_cnt == 4'd7)
                        if(row_cnt == 4'd7)
                            row_cnt <= 4'd0;
                        else
                            row_cnt <= row_cnt + 4'd1;
                    else
                    begin
                        row_cnt <= row_cnt;
                    end
                end
                default:
                    row_cnt <= row_cnt;
            endcase
        end
        else
            row_cnt <= 4'd0;
    end
end

// column_cnt
always @(posedge clk or negedge rst_n)
begin
    if (!rst_n)
        column_cnt <= 4'd0;
    else
    begin
        if(current_state == s_matrix && in_valid == 1)/*new add && in_valid == 1*/
        begin
            case(current_matrix_size)
                0:
                begin
                    if(column_cnt == 4'd1)
                        column_cnt <= 4'd0;
                    else
                        column_cnt <= column_cnt + 4'd1;
                end
                1:
                begin
                    if(column_cnt == 4'd3)
                        column_cnt <= 4'd0;
                    else
                        column_cnt <= column_cnt + 4'd1;
                end
                2:
                begin
                    if(column_cnt == 4'd7)
                        column_cnt <= 4'd0;
                    else
                        column_cnt <= column_cnt + 4'd1;
                end
                default:
                    column_cnt <= column_cnt;
            endcase
        end
        else
            column_cnt <= 4'd0;
    end
end

// x_sram_in
always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
    begin
        for(i=0; i<16; i=i+1)
        begin
            x_sram_in[i] <= 16'd0;
        end
    end
    else if(current_state == s_matrix && matrix_cnt < 16)
    begin
        x_sram_in[column_cnt] <= matrix;
    end
    else
    begin
        for(i=0; i<16; i=i+1)
        begin
            x_sram_in[i] <= x_sram_in[i];
        end
    end
end

// w_sram_in
always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
    begin
        for(i=0; i<16; i=i+1)
        begin
            w_sram_in[i] <= 16'd0;
        end
    end
    else if(current_state == s_matrix && matrix_cnt > 15 && matrix_cnt < 32)
    begin
        w_sram_in[column_cnt] <= matrix;
    end
    else
    begin
        for(i=0; i<16; i=i+1)
        begin
            w_sram_in[i] <= w_sram_in[i];
        end
    end
end

//==============================================//
//            FSM state 2 index Block           //
//==============================================//
// current_imat_idx
always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        current_imat_idx <= 4'd0;
    else if(current_state == s_idle)
        current_imat_idx <= 4'd0;
    else if(in_valid2 == 1) /*i_mat_idx != 4'dx*/
    begin
        current_imat_idx <= i_mat_idx;
    end
    else
        current_imat_idx <= current_imat_idx;
end

// current_wmat_idx
always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        current_wmat_idx <= 4'd0;
    else if(current_state == s_idle)
        current_wmat_idx <= 4'd0;
    else if(in_valid2 == 1)/*w_mat_idx != 4'dx*/
    begin
        current_wmat_idx <= w_mat_idx;
    end
    else
        current_wmat_idx <= current_wmat_idx;
end

//==============================================//
//             FSM state 3 cal Block            //
//==============================================//
// SA
generate
    for(idx=0 ;idx<8 ;idx=idx+1)
    begin
        for(jdx=0 ;jdx<8 ;jdx=jdx+1)
        begin
            SAPE sa_pe(.input_a(ina[idx][jdx]), .input_b(inb[idx][jdx]), .input_w(inw[idx][jdx]), .output_c(outc[idx][jdx]), .output_d(outd[idx][jdx]));
        end
    end
endgenerate

// outd/x_data to ina // delay 3 cycle 0 1 2  in 3 change value
generate
    for(idx=0 ;idx<8 ;idx=idx+1)
    begin
        for(jdx=0 ;jdx<8 ;jdx=jdx+1)
        begin
            always@(posedge clk or negedge rst_n)
            begin
                if(!rst_n)
                    ina[idx][jdx] <= 16'd0;
                else if(current_state == s_idle || current_state == s_index)
                    ina[idx][jdx] <= 16'd0;
                else if(current_state == s_cal && fsm_cnt > 2)/*&& fsm_cnt < 34*/
                begin
                    //fsm_cnt < 34
                    if(fsm_cnt < 18)
                    begin
                        if(jdx == 0)
                            ina[idx][0] <= x_data[idx][fsm_cnt-3];
                        else
                            ina[idx][jdx] <= outd[idx][jdx-1];
                    end
                    else
                        if(jdx == 0)
                            ina[idx][0] <= 16'd0;
                        else
                            ina[idx][jdx] <= outd[idx][jdx-1];
                end
                else
                    ina[idx][jdx] <= ina[idx][jdx];
            end
        end
    end
endgenerate

// inw // delay 3 cycle 0 1 2  in 3 change value
generate
    for(idx=0 ;idx<8 ;idx=idx+1)
    begin
        for(jdx=0 ;jdx<8 ;jdx=jdx+1)
        begin
            always@(posedge clk or negedge rst_n)
            begin
                if(!rst_n)
                    inw[idx][jdx] <= 16'd0;
                else if(current_state == s_idle || current_state == s_index)
                    inw[idx][jdx] <= 16'd0;
                else if(current_state == s_cal && fsm_cnt > 2 && fsm_cnt < 11)
                begin
                    inw[idx][jdx] <= w_data[idx][jdx];
                end
                else
                    inw[idx][jdx] <= inw[idx][jdx];
            end
        end
    end
endgenerate

// outc/0 to inb // delay 3 cycle 0 1 2  in 3 change value
generate
    for(idx=0 ;idx<8 ;idx=idx+1)
    begin
        for(jdx=0 ;jdx<8 ;jdx=jdx+1)
        begin
            always@(posedge clk or negedge rst_n)
            begin
                if(!rst_n)
                    inb[idx][jdx] <= 16'd0;
                else if(current_state == s_idle || current_state == s_index)
                    inb[idx][jdx] <= 16'd0;
                else if(current_state == s_cal && fsm_cnt > 2)
                begin
                    if(idx == 0)
                        inb[0][jdx] <= 40'd0;
                    else
                        inb[idx][jdx] <= outc[idx-1][jdx];
                end
                else
                    inb[idx][jdx] <= inb[idx][jdx];
            end
        end
    end
endgenerate

// x_sram_out to x_data // delay 2 cycle 0 1  in 2 change value
always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
    begin
        for(i=0; i<8; i=i+1)
        begin
            for(j=0; j<15; j=j+1)
            begin
                x_data[i][j] <= 16'd0;
            end
        end
    end
    else if(current_state == s_idle || current_state == s_index)
    begin
        for(i=0; i<8; i=i+1)
        begin
            for(j=0; j<15; j=j+1)
            begin
                x_data[i][j] <= 16'd0;
            end
        end
    end
    else if(current_state == s_cal && fsm_cnt > 1)
    begin
        if(current_matrix_size == 0 && fsm_cnt < 4)
        begin
            x_data[0][fsm_cnt-2] <= x_sram_out[0];
            x_data[1][fsm_cnt-1] <= x_sram_out[1];
        end
        else if(current_matrix_size == 1 && fsm_cnt < 6)
        begin
            x_data[0][fsm_cnt-2] <= x_sram_out[0];
            x_data[1][fsm_cnt-1] <= x_sram_out[1];
            x_data[2][fsm_cnt] <= x_sram_out[2];
            x_data[3][fsm_cnt+1] <= x_sram_out[3];
        end
        else if(current_matrix_size == 2 && fsm_cnt < 10)
        begin
            x_data[0][fsm_cnt-2] <= x_sram_out[0];
            x_data[1][fsm_cnt-1] <= x_sram_out[1];
            x_data[2][fsm_cnt] <= x_sram_out[2];
            x_data[3][fsm_cnt+1] <= x_sram_out[3];
            x_data[4][fsm_cnt+2] <= x_sram_out[4];
            x_data[5][fsm_cnt+3] <= x_sram_out[5];
            x_data[6][fsm_cnt+4] <= x_sram_out[6];
            x_data[7][fsm_cnt+5] <= x_sram_out[7];
        end
        else
        begin
            for(i=0; i<8; i=i+1)
            begin
                for(j=0; j<15; j=j+1)
                begin
                    x_data[i][j] <= x_data[i][j];
                end
            end
        end
    end
    else
    begin
        for(i=0; i<8; i=i+1)
        begin
            for(j=0; j<15; j=j+1)
            begin
                x_data[i][j] <= x_data[i][j];
            end
        end
    end
end

// w_sram_out to w_data // delay 2 cycle 0 1  in 2 change value
always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
    begin
        for(i=0; i<8; i=i+1)
        begin
            for(j=0; j<8; j=j+1)
            begin
                w_data[i][j] <= 16'd0;
            end
        end
    end
    else if(current_state == s_idle || current_state == s_index)
    begin
        for(i=0; i<8; i=i+1)
        begin
            for(j=0; j<8; j=j+1)
            begin
                w_data[i][j] <= 16'd0;
            end
        end
    end
    else if(current_state == s_cal && fsm_cnt > 1)
    begin
        if (current_matrix_size == 0 && fsm_cnt < 4)
        begin
            w_data[fsm_cnt-2][0] <= w_sram_out[0];
            w_data[fsm_cnt-2][1] <= w_sram_out[1];
        end
        else if (current_matrix_size == 1 && fsm_cnt < 6)
        begin
            w_data[fsm_cnt-2][0] <= w_sram_out[0];
            w_data[fsm_cnt-2][1] <= w_sram_out[1];
            w_data[fsm_cnt-2][2] <= w_sram_out[2];
            w_data[fsm_cnt-2][3] <= w_sram_out[3];
        end
        else if (current_matrix_size == 2 && fsm_cnt < 10)
        begin
            w_data[fsm_cnt-2][0] <= w_sram_out[0];
            w_data[fsm_cnt-2][1] <= w_sram_out[1];
            w_data[fsm_cnt-2][2] <= w_sram_out[2];
            w_data[fsm_cnt-2][3] <= w_sram_out[3];
            w_data[fsm_cnt-2][4] <= w_sram_out[4];
            w_data[fsm_cnt-2][5] <= w_sram_out[5];
            w_data[fsm_cnt-2][6] <= w_sram_out[6];
            w_data[fsm_cnt-2][7] <= w_sram_out[7];
        end
        else
        begin
            for(i=0; i<8; i=i+1)
            begin
                for(j=0; j<8; j=j+1)
                begin
                    w_data[i][j] <= w_data[i][j];
                end
            end
        end
    end
    else
    begin
        for(i=0; i<8; i=i+1)
        begin
            for(j=0; j<8; j=j+1)
            begin
                w_data[i][j] <= w_data[i][j];
            end
        end
    end
end

// output_value
always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
    begin
        for(i=0; i<15; i=i+1)
        begin
            output_value[i] <= 40'd0;
        end
    end
    else if(current_state == s_idle || current_state == s_index)
    begin
        for(i=0; i<15; i=i+1)
        begin
            output_value[i] <= 40'd0;
        end
    end
    else if (current_state == s_cal)
    begin
        case(current_matrix_size)
            0:
            begin
                if(fsm_cnt > 4)
                    output_value[fsm_cnt-5] <= outc[1][0] + outc[1][1];
                else
                    output_value[fsm_cnt] <= output_value[fsm_cnt];
            end
            1:
            begin
                if(fsm_cnt > 6)
                    output_value[fsm_cnt-7] <= outc[3][0] + outc[3][1] + outc[3][2] + outc[3][3];
                else
                    output_value[fsm_cnt] <= output_value[fsm_cnt];
            end
            2:
            begin
                if(fsm_cnt > 10)
                    output_value[fsm_cnt-11] <= outc[7][0] + outc[7][1] + outc[7][2] + outc[7][3] + outc[7][4] + outc[7][5] + outc[7][6] + outc[7][7];
                else
                    output_value[fsm_cnt] <= output_value[fsm_cnt];
            end
            default:
                output_value[fsm_cnt] <= output_value[fsm_cnt];
        endcase
    end
    else
    begin
        for(i=0; i<15; i=i+1)
        begin
            output_value[i] <= output_value[i];
        end
    end
end

//==============================================//
//            FSM state 4 output Block          //
//==============================================//
// out_valid
always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
    begin
        out_valid <= 1'b0;
    end
    else
    begin
        case(current_state)
            s_output:
                out_valid <= 1'b1;
            default:
                out_valid <= 1'b0;
        endcase
    end
end

// out_value
always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        out_value <= 40'd0;
    else
    case(current_state)
        s_output:
        begin
            out_value <= output_value[fsm_cnt];
        end
        default:
            out_value <= 40'd0;
    endcase
end

endmodule

    module SAPE(
        input_a,
        input_b,
        input_w,
        output_c,
        output_d);
// INPUT AND OUTPUT DECLARATION //
input signed [15:0] input_a, input_w;
input signed [39:0] input_b;
output signed [39:0] output_c;
output signed [15:0] output_d;
// cal //
assign output_c = input_a*input_w + input_b;
assign output_d = input_a;
endmodule
