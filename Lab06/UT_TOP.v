//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   File Name   : UT_TOP.v
//   Module Name : UT_TOP
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

//synopsys translate_off
`include "B2BCD_IP.v"
//synopsys translate_on

module UT_TOP (
           // Input signals
           clk, rst_n, in_valid, in_time,
           // Output signals
           out_valid, out_display, out_day
       );

// ===============================================================
// Input & Output Declaration
// ===============================================================
input clk, rst_n, in_valid;
input [30:0] in_time;
output reg out_valid;
output reg [3:0] out_display;
output reg [2:0] out_day;

// ===============================================================
// Parameter & Integer Declaration
// ===============================================================
// FSM Parameter
parameter s_idle    = 2'd0;
parameter s_input   = 2'd1;
parameter s_output  = 2'd2;

// div
parameter div_width = 5'd24;

// B2BCD
parameter B2BCD_WIDTH_8 = 4'd8;
parameter B2BCD_DIGIT_3 = 4'd3;
parameter B2BCD_WIDTH_4 = 4'd4;
parameter B2BCD_DIGIT_2 = 4'd2;

integer i;
//================================================================
// Wire & Reg Declaration
//================================================================
/// FSM ///
// state
reg [1:0] current_state, next_state;
// counter matrix index cnt
reg [4:0] fsm_cnt;

// input
// unixtime
reg [30:0] unixtime;

//reg [div_width-1:0] reg_quot;
reg [15:0] four_year_cyc;

// year first sec
reg [6:0] year_1sthalf, year_2ndhalf;

// daliy_second
reg [23:0] daliy_second;
// year_remaind
reg [8:0] year_remaind;

// ans
reg [10:0] year;
reg  [3:0] mounth;
reg  [4:0] day;
reg  [4:0] hour;
reg  [5:0] minute;
reg  [5:0] second;
reg  [2:0] week;
reg  [2:0] week_bcd;

// div mod
reg  [div_width-1:0] dividend;
reg  [div_width-1:0] mod;

// B2BCD 
reg  [7:0] Binary_code_8;
wire [11:0] BCD_code_3;
reg  [3:0] Binary_code_4;
wire [7:0] BCD_code_2;

// out_display_list
reg [3:0] out_display_list[0:13];
//================================================================
// DESIGN
//================================================================
// opertator
B2BCD_IP #(.WIDTH(B2BCD_WIDTH_8), .DIGIT(B2BCD_DIGIT_3)) 
        B2BCD_IP_8to3 ( .Binary_code(Binary_code_8), .BCD_code(BCD_code_3));
B2BCD_IP #(.WIDTH(B2BCD_WIDTH_4), .DIGIT(B2BCD_DIGIT_2)) 
        B2BCD_IP_4to2 ( .Binary_code(Binary_code_4), .BCD_code(BCD_code_2));
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
            next_state = s_input;
        end
        s_input:
        begin
            if(in_valid == 1'd1)
                next_state = s_output;
            else
                next_state = current_state;
        end
        s_output:
        begin
            if(fsm_cnt == 5'd18)
                next_state = s_idle;
            else
                next_state = current_state;
        end
        default:
            next_state = current_state;
    endcase
end

// fsm_cnt
always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        fsm_cnt <= 5'd0;
    else
    case(current_state)
        s_idle:
        begin
            fsm_cnt <= 5'd0;
        end
        s_input:
        begin
            fsm_cnt <= 5'd0;
        end
        s_output:
        begin
            if(fsm_cnt == 5'd18)
                fsm_cnt <= 5'd0;
            else
                fsm_cnt <= fsm_cnt + 5'd1;
        end
        default:
            fsm_cnt <= fsm_cnt;
    endcase
end

//==============================================//
//            FSM state 1 input Block           //
//==============================================//
// unixtime
always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        unixtime <= 31'd0;
    else if(current_state == s_idle)
        unixtime <= 31'd0;
    else if (current_state == s_input && in_valid == 1)
        unixtime <= in_time;
    else
        unixtime <= unixtime;
end

//==============================================//
//           FSM state 2 output Block           //
//==============================================//
// div opertator //
// dividend
always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        dividend <= 24'd1;
    else if(current_state == s_idle)
        dividend <= 24'd1;
    else if (current_state == s_output)
    begin
        if(fsm_cnt == 0)
            dividend <= unixtime[30:7] / 675;
        else if(fsm_cnt == 1)
            dividend <= dividend / 1461;
        else if(fsm_cnt == 2)
            dividend <= daliy_second / 60;
        else if(fsm_cnt == 3)
            dividend <= dividend / 60;
        else
            dividend <= dividend;
    end
    else
        dividend <= dividend;
end

// mod
always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        mod <= 24'd1;
    else if(current_state == s_idle)
        mod <= 24'd1;
    else if (current_state == s_output)
    begin
        if(fsm_cnt == 0)
            mod <= unixtime[30:7] % 675;
        else if(fsm_cnt == 1)
            mod <= dividend % 7;
        else if(fsm_cnt == 2)
            mod <= daliy_second % 60;
        else if(fsm_cnt == 3)
            mod <= dividend % 60;
        else
            mod <= mod;
    end
    else
        mod <= mod;
end


// four_year_cyc 
always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        four_year_cyc <= 16'd0;
    else if(current_state == s_idle)
        four_year_cyc <= 16'd0;
    else if (current_state == s_output && fsm_cnt == 1)
        four_year_cyc <= dividend[15:0];
    else if (current_state == s_output && fsm_cnt == 2)
        four_year_cyc <= four_year_cyc - 1461*dividend;
    else
        four_year_cyc <= four_year_cyc;
end

//daliy_second
always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        daliy_second <= 24'd0;
    else if(current_state == s_idle)
        daliy_second <= 24'd0;
    else if (current_state == s_output)
    begin
        if(fsm_cnt == 1)
            daliy_second <= unixtime - dividend*86400;
        else
            daliy_second <= daliy_second;
    end
    else
        daliy_second <= daliy_second;
end

// year_remaind
always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        year_remaind <= 9'd0;
    else if(current_state == s_idle)
        year_remaind <= 9'd0;
    else if (current_state == s_output && fsm_cnt == 4)
    begin
        if(four_year_cyc < 365)
        begin
            year_remaind <= four_year_cyc;
        end
        else if(four_year_cyc > 364 && four_year_cyc < 730) 
        begin
            year_remaind <= four_year_cyc - 365;
        end
        else if(four_year_cyc > 729 && four_year_cyc < 1096) 
        begin
            year_remaind <= four_year_cyc - 730;
        end
        else if (four_year_cyc > 1095 && four_year_cyc < 1461) 
        begin
            year_remaind <= four_year_cyc - 1096;
        end
        else
            year_remaind <= year_remaind;
    end
    else
        year_remaind <= year_remaind;
end

// output_value binary//
// year
always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        year <= 11'd0;
    else if(current_state == s_idle)
        year <= 11'd0;
    else if (current_state == s_output && fsm_cnt == 2)
        year <= dividend[10:0];
    else if (current_state == s_output && fsm_cnt == 3)
    begin
        if(four_year_cyc < 365)
        begin
            year <= 11'd1970 + 4*year;
        end
        else if(four_year_cyc > 364 && four_year_cyc < 730) 
        begin
            year <= 11'd1971 + 4*year;
        end
        else if(four_year_cyc > 729 && four_year_cyc < 1096) 
        begin
            year <= 11'd1972 + 4*year;
        end
        else if (four_year_cyc > 1095 && four_year_cyc < 1461) 
        begin
            year <= 11'd1973 + 4*year;
        end
        else
            year <= year;
    end
    else
        year <= year;
end

// year_1sthalf
always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        year_1sthalf <= 7'd0;
    else if(current_state == s_idle)
        year_1sthalf <= 7'd0;
    else if (current_state == s_output && fsm_cnt == 0)
    begin
        if(unixtime >= 946684800)
            year_1sthalf <= 7'd20;
        else
            year_1sthalf <= 7'd19;
    end
    else
        year_1sthalf <= year_1sthalf;
end

// year_2ndhalf
always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        year_2ndhalf <= 7'd0;
    else if(current_state == s_idle)
        year_2ndhalf <= 7'd0;
    else if (current_state == s_output && fsm_cnt == 4)
    begin
        if(unixtime >= 946684800)
            year_2ndhalf <= year - 2000;
        else
            year_2ndhalf <= year - 1900;
    end
    else
        year_2ndhalf <= year_2ndhalf;
end

// mounth
always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        mounth <= 4'd0;
    else if(current_state == s_idle)
        mounth <= 4'd0;
    else if (current_state == s_output && fsm_cnt == 5)
    begin
        if(four_year_cyc > 729 && four_year_cyc < 1096)
        begin
            if(year_remaind < 31)
            begin
                mounth <= 4'd1;
            end
            else if(year_remaind > 30 && year_remaind < 60) 
            begin
                mounth <= 4'd2;
            end
            else if(year_remaind > 59 && year_remaind < 91) 
            begin
                mounth <= 4'd3;
            end
            else if (year_remaind > 90 && year_remaind < 121) 
            begin
                mounth <= 4'd4;
            end
            else if(year_remaind > 120 && year_remaind < 152)
            begin
                mounth <= 4'd5;
            end
            else if(year_remaind > 151 && year_remaind < 182) 
            begin
                mounth <= 4'd6;
            end
            else if(year_remaind > 181 && year_remaind < 213) 
            begin
                mounth <= 4'd7;
            end
            else if (year_remaind > 212 && year_remaind < 244) 
            begin
                mounth <= 4'd8;
            end
            else if (year_remaind > 243 && year_remaind < 274) 
            begin
                mounth <= 4'd9;
            end
            else if (year_remaind > 273 && year_remaind < 305) 
            begin
                mounth <= 4'd10;
            end
            else if (year_remaind > 304 && year_remaind < 335) 
            begin
                mounth <= 4'd11;
            end
            else if (year_remaind > 334 && year_remaind < 366) 
            begin
                mounth <= 4'd12;
            end
            else
                mounth <= mounth;
        end
        else
        begin
            if(year_remaind < 31)
            begin
                mounth <= 4'd1;
            end
            else if(year_remaind > 30 && year_remaind < 59) 
            begin
                mounth <= 4'd2;
            end
            else if(year_remaind > 58 && year_remaind < 90) 
            begin
                mounth <= 4'd3;
            end
            else if (year_remaind > 89 && year_remaind < 120) 
            begin
                mounth <= 4'd4;
            end
            else if(year_remaind > 119 && year_remaind < 151)
            begin
                mounth <= 4'd5;
            end
            else if(year_remaind > 150 && year_remaind < 181) 
            begin
                mounth <= 4'd6;
            end
            else if(year_remaind > 180 && year_remaind < 212) 
            begin
                mounth <= 4'd7;
            end
            else if (year_remaind > 211 && year_remaind < 243) 
            begin
                mounth <= 4'd8;
            end
            else if (year_remaind > 242 && year_remaind < 273) 
            begin
                mounth <= 4'd9;
            end
            else if (year_remaind > 272 && year_remaind < 304) 
            begin
                mounth <= 4'd10;
            end
            else if (year_remaind > 303 && year_remaind < 334) 
            begin
                mounth <= 4'd11;
            end
            else if (year_remaind > 333 && year_remaind < 365) 
            begin
                mounth <= 4'd12;
            end
            else
                mounth <= mounth;
        end
    end
    else
        mounth <= mounth;
end

// day;
always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        day <= 5'd0;
    else if(current_state == s_idle)
        day <= 5'd0;
    else if (current_state == s_output && fsm_cnt == 6)
    begin
        if(four_year_cyc > 729 && four_year_cyc < 1096)
        begin
            if(year_remaind < 31)
            begin
                day <= year_remaind + 1;
            end
            else if(year_remaind > 30 && year_remaind < 60) 
            begin
                day <= year_remaind - 30;
            end
            else if(year_remaind > 59 && year_remaind < 91) 
            begin
                day <= year_remaind - 59;
            end
            else if (year_remaind > 90 && year_remaind < 121) 
            begin
                day <= year_remaind - 90;
            end
            else if(year_remaind > 120 && year_remaind < 152)
            begin
                day <= year_remaind - 120;
            end
            else if(year_remaind > 151 && year_remaind < 182) 
            begin
                day <= year_remaind - 151;
            end
            else if(year_remaind > 181 && year_remaind < 213) 
            begin
                day <= year_remaind - 181;
            end
            else if (year_remaind > 212 && year_remaind < 244) 
            begin
                day <= year_remaind - 212;
            end
            else if (year_remaind > 243 && year_remaind < 274) 
            begin
                day <= year_remaind - 243;
            end
            else if (year_remaind > 273 && year_remaind < 305) 
            begin
                day <= year_remaind - 273;
            end
            else if (year_remaind > 304 && year_remaind < 335) 
            begin
                day <= year_remaind - 304;
            end
            else if (year_remaind > 334 && year_remaind < 366) 
            begin
                day <= year_remaind - 334;
            end
            else
                day <= day;
        end
        else
        begin
            if(year_remaind < 31)
            begin
                day <= year_remaind + 1;
            end
            else if(year_remaind > 30 && year_remaind < 59) 
            begin
                day <= year_remaind - 30;
            end
            else if(year_remaind > 58 && year_remaind < 90) 
            begin
                day <= year_remaind - 58;
            end
            else if (year_remaind > 89 && year_remaind < 120) 
            begin
                day <= year_remaind - 89;
            end
            else if(year_remaind > 119 && year_remaind < 151)
            begin
                day <= year_remaind - 119;
            end
            else if(year_remaind > 150 && year_remaind < 181) 
            begin
                day <= year_remaind - 150;
            end
            else if(year_remaind > 180 && year_remaind < 212) 
            begin
                day <= year_remaind - 180;
            end
            else if (year_remaind > 211 && year_remaind < 243) 
            begin
                day <= year_remaind - 211;
            end
            else if (year_remaind > 242 && year_remaind < 273) 
            begin
                day <= year_remaind - 242;
            end
            else if (year_remaind > 272 && year_remaind < 304) 
            begin
                day <= year_remaind - 272;
            end
            else if (year_remaind > 303 && year_remaind < 334) 
            begin
                day <= year_remaind - 303;
            end
            else if (year_remaind > 333 && year_remaind < 365) 
            begin
                day <= year_remaind - 333;
            end
            else
                day <= day;
        end
    end
    else
        day <= day;
end

// hour;
always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        hour <= 5'd0;
    else if(current_state == s_idle)
        hour <= 5'd0;
    else if (current_state == s_output && fsm_cnt == 4)
        hour <= dividend[4:0];
    else
        hour <= hour;
end

// minute;
always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        minute <= 6'd0;
    else if(current_state == s_idle)
        minute <= 6'd0;
    else if (current_state == s_output && fsm_cnt == 4)
        minute <= mod[5:0];
    else
        minute <= minute;
end

// second;
always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        second <= 6'd0;
    else if(current_state == s_idle)
        second <= 6'd0;
    else if (current_state == s_output && fsm_cnt == 3)
        second <= mod[5:0];
    else
        second <= second;
end

// week
always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        week <= 3'd0;
    else if(current_state == s_idle)
        week <= 3'd0;
    else if(current_state == s_output && fsm_cnt == 2)
    begin
        if(mod[2:0] < 3'd3)
            week <= mod[2:0] + 3'd4;
        else
            week <= mod[2:0] - 3'd3;
    end
    else
        week <= week;
end

// b2bcd //
// Binary_code_8
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        Binary_code_8 <= 8'd0;
    else if(current_state == s_idle)
        Binary_code_8 <= 8'd0;
    else if(current_state == s_output)
    begin
        if(fsm_cnt == 1)
            Binary_code_8 <= {1'b0,year_1sthalf};
        else if(fsm_cnt == 5)
            Binary_code_8 <= {1'b0,year_2ndhalf};
        else if(fsm_cnt == 6)
            Binary_code_8 <= {2'b00,second};
        else if(fsm_cnt == 7)
            Binary_code_8 <= {4'b0000,mounth};
        else if(fsm_cnt == 8)
            Binary_code_8 <= {3'b000,day};
        else if(fsm_cnt == 9)
            Binary_code_8 <= {3'b000,hour};
        else if(fsm_cnt == 10)
            Binary_code_8 <= {2'b00,minute};
        else
            Binary_code_8 <= Binary_code_8;
    end
    else
        Binary_code_8 <= Binary_code_8;
end

// Binary_code_4
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        Binary_code_4 <= 4'd0;
    else if(current_state == s_idle)
        Binary_code_4 <= 4'd0;
    else if(current_state == s_output && fsm_cnt == 3)
        Binary_code_4 <= {1'b0,week};
    else
        Binary_code_4 <= Binary_code_4;
end

// BCD_code_3 to out_display_list
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
    begin
        for(i=0; i<14; i=i+1)
        begin
            out_display_list[i] <= 4'd0;
        end
    end
    else if(current_state == s_idle)
    begin
        for(i=0; i<14; i=i+1)
        begin
            out_display_list[i] <= 4'd0;
        end
    end
    else if(current_state == s_output)
    begin
        if(fsm_cnt == 2)
        begin
            out_display_list[0] <= BCD_code_3[7:4];
            out_display_list[1] <= BCD_code_3[3:0];
        end
        else if(fsm_cnt == 6)
        begin
            out_display_list[2] <= BCD_code_3[7:4];
            out_display_list[3] <= BCD_code_3[3:0]; 
        end
        else if(fsm_cnt == 7)
        begin
            out_display_list[12] <= BCD_code_3[7:4];
            out_display_list[13] <= BCD_code_3[3:0];
        end
        else if(fsm_cnt == 8)
        begin
            out_display_list[4] <= BCD_code_3[7:4];
            out_display_list[5] <= BCD_code_3[3:0];
        end
        else if(fsm_cnt == 9)
        begin
            out_display_list[6] <= BCD_code_3[7:4];
            out_display_list[7] <= BCD_code_3[3:0];
        end
        else if(fsm_cnt == 10)
        begin
            out_display_list[8] <= BCD_code_3[7:4];
            out_display_list[9] <= BCD_code_3[3:0];
        end
        else if(fsm_cnt == 11)
        begin
            out_display_list[10] <= BCD_code_3[7:4];
            out_display_list[11] <= BCD_code_3[3:0];
        end
        else
        begin
        for(i=0; i<14; i=i+1)
        begin
            out_display_list[i] <= out_display_list[i];
        end
    end
    end
    else
    begin
        for(i=0; i<14; i=i+1)
        begin
            out_display_list[i] <= out_display_list[i];
        end
    end
end

// week_bcd 
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        week_bcd <= 3'd0;
    else if(current_state == s_idle)
        week_bcd <= 3'd0;
    else if(current_state == s_output && fsm_cnt == 4)
        week_bcd <= BCD_code_2[3:0];
    else
        week_bcd <= week_bcd;
end

/// out ///
// out_valid
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        out_valid <= 1'b0; 
    else
    begin
        if(current_state == s_output && fsm_cnt > 4)
            out_valid <= 1'b1; 
        else
            out_valid <= 1'b0;
    end
end

// out_display
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        out_display <= 4'b0; 
    else
    begin
        if(current_state == s_output && fsm_cnt > 4)
            out_display <= out_display_list[fsm_cnt-5]; 
        else
            out_display <= 4'b0;
    end
end

// out_day
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        out_day <= 3'b0; 
    else
    begin
        if(current_state == s_output && fsm_cnt > 4)
            out_day <= week_bcd; 
        else
            out_day <= 3'b0;
    end
end

endmodule
