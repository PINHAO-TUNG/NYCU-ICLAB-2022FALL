module SP(
	// Input signals
	clk,
	rst_n,
	cg_en,
	in_valid,
	in_data,
	in_mode,
	// Output signals
	out_valid,
	out_data
);

// INPUT AND OUTPUT DECLARATION // 
input		clk;
input		rst_n;
input		in_valid;
input		cg_en;
input [8:0] in_data;
input [2:0] in_mode;

output reg 		  out_valid;
output reg signed[9:0] out_data;

// PARAMETER //
// FSM Parameter
parameter s_idle    = 3'd0;
parameter s_input   = 3'd1;
parameter s_add_sub = 3'd2;
parameter s_sma     = 3'd3;
parameter s_mmm     = 3'd4;
parameter s_out     = 3'd5;

integer i;
genvar idx;
// WIRE AND REG DECLARATION //
/// controler ///
// fsm
reg [2:0] current_state, next_state;
reg [3:0] fsm_cnt;

// global
reg [2:0] current_in_mode;
reg flag;

// s_idle
reg        [8:0] input_value;
reg signed [8:0] sig_input_value;
reg signed [9:0] data_s0[0:8];
// s_add_sub
reg signed [8:0] state1_max;
reg signed [8:0] state1_min;
reg signed [8:0] half_of_difference;
reg signed [8:0] midpoint;
reg signed [9:0] data_s1[0:8];
// s_sma
reg signed [9:0] data_s2[0:8];
// s_mmm
reg signed [8:0] state3_max;
reg signed [8:0] state3_mid;
reg signed [8:0] state3_min;
reg signed [9:0] data_s3[0:8];
// s_out

// DESIGN //
/// FSM /// 
// current_state 
always@(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        current_state <= s_idle;
    else
        current_state <= next_state;
end
// next_state
always@(*)
begin
    case(current_state)
		s_idle:
		begin
			if(in_valid == 1 && flag == 0)
				next_state = s_input;
			else
				next_state = current_state;
		end
		s_input:
		begin
			if(fsm_cnt == 9)
			begin
				if(current_in_mode[1]==1)
					next_state = s_add_sub;
				else
				begin
					if(current_in_mode[2]==1)
						next_state = s_sma;
					else
						next_state = s_mmm;
				end
			end
			else
				next_state = current_state;
		end
		s_add_sub:
		begin
			if(fsm_cnt == 2)
			begin
				if(current_in_mode[2]==1)
					next_state = s_sma;
				else
					next_state = s_mmm;
			end
			else
				next_state = current_state;
		end
		s_sma:
		begin
			next_state = s_mmm;
		end
		s_mmm:
		begin
			if(fsm_cnt == 4)
				next_state = s_out;
			else
				next_state = current_state;
		end
		s_out:
		begin
			if(fsm_cnt == 2)
				next_state = s_idle;
			else
				next_state = current_state;
		end
		default:
		begin
			next_state = current_state;
		end
	endcase
end
// fsm_cnt
always@(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        fsm_cnt <= 0;
	else if(current_state == s_idle)
		fsm_cnt <= 0;
	else if(current_state == s_input)
	begin
		if(fsm_cnt == 9)
			fsm_cnt <= 0;
		else
			fsm_cnt <= fsm_cnt + 1;
	end
	else if(current_state == s_add_sub)
	begin
		if(fsm_cnt == 2)
			fsm_cnt <= 0;
		else
			fsm_cnt <= fsm_cnt + 1;
	end
	else if(current_state == s_mmm)
	begin
		if(fsm_cnt == 4)
			fsm_cnt <= 0;
		else
			fsm_cnt <= fsm_cnt + 1;
	end
	else if(current_state == s_out)
	begin
		if(fsm_cnt == 2)
			fsm_cnt <= 0;
		else
			fsm_cnt <= fsm_cnt + 1;
	end
    else
        fsm_cnt <= fsm_cnt;
end

// global //
// flag
always@(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        flag <= 0;
	else if(in_valid == 1)
		flag <= 1;
    else
        flag <= 0;
end
// current_in_mode
always@(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        current_in_mode <= 0;
	else if(in_valid == 1 && flag == 0)
		current_in_mode <= in_mode;
    else
        current_in_mode <= current_in_mode;
end

// fsm state 0 s_idle and fsm state 1 s_input //
// input_value
always@(posedge clk or negedge rst_n)
begin
	if(!rst_n)
        input_value <= 0;
	else if(in_valid == 1)
		input_value <= in_data;
	else
		input_value <= 0;
end
// comb logic
reg [8:0] signedsignal;
generate
	// Gray2Decimal
	wire in8 = input_value[8];
	wire in7 = input_value[7];
	wire in6 = in7^input_value[6];
	wire in5 = in6^input_value[5];
	wire in4 = in5^input_value[4];
	wire in3 = in4^input_value[3];
	wire in2 = in3^input_value[2];
	wire in1 = in2^input_value[1];
	wire in0 = in1^input_value[0];
	wire [8:0] Gray2Decimal= {in8,in7,in6,in5,in4,in3,in2,in1,in0};
endgenerate
// Decimal2signedsignal
always @(*)
begin
	if(Gray2Decimal[8] == 1)
	begin
		signedsignal = {Gray2Decimal[8],~Gray2Decimal[7:0]}+1;
	end
	else
	begin
		signedsignal = Gray2Decimal;
	end
end
// sig_input_value
always@(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        sig_input_value <= 0;
	else if(current_state == s_input)
	begin
		if(current_in_mode[0] == 1)
			sig_input_value <= signedsignal;
		else 
			sig_input_value <= input_value;
	end
    else
        sig_input_value <= 0;
end
// data_s0
always@(posedge clk or negedge rst_n)
begin
	if(!rst_n)
	begin
		for (i=0; i<9; i=i+1) 
		begin
			data_s0[i] <= 0;
		end
	end
	else if(current_state == s_input && fsm_cnt > 0)
		data_s0[fsm_cnt-1] <= sig_input_value;
	else
	begin
		for (i=0; i<9; i=i+1) 
		begin
			data_s0[i] <= data_s0[i];
		end
	end
end
// fin max min 
// need in s_add_sb and s_mmm
wire signed [9:0] data[0:8];
wire signed [9:0] max_tmp, min_tmp;
generate
	for(idx=0; idx<9; idx=idx+1)
    begin
		assign data[idx] = (current_state == s_add_sub)? data_s0[idx]:data_s3[idx];
	end
endgenerate

Min_9to1 s1_Min_9to1 (data[0], data[1], data[2], data[3], data[4],
					  data[5], data[6], data[7], data[8], min_tmp);
Max_9to1 s1_Max_9to1 (data[0], data[1], data[2], data[3], data[4],
					  data[5], data[6], data[7], data[8], max_tmp);

// fsm state 1 s_add_sub //

// state1_max
always@(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        state1_max <= 0;
    else if(current_state == s_add_sub && fsm_cnt == 0)
        state1_max <= max_tmp;
	else
		state1_max <= state1_max;
end
// state1_min
always@(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        state1_min <= 0;
    else if(current_state == s_add_sub && fsm_cnt == 0)
        state1_min <= min_tmp;
	else
		state1_min <= state1_min;
end
// half_of_difference
always@(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        half_of_difference <= 0;
    else if(current_state == s_add_sub && fsm_cnt == 1)
        half_of_difference <= (state1_max - state1_min)/2;
	else
		half_of_difference <= half_of_difference;
end
// midpoint
always@(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        midpoint <= 0;
    else if(current_state == s_add_sub && fsm_cnt == 1)
        midpoint <= (state1_max + state1_min)/2;
	else
		midpoint <= midpoint;
end
// data_s1
generate
	for(idx=0; idx<9; idx=idx+1)
    begin
		always@(posedge clk or negedge rst_n)
		begin
			if(!rst_n)
				data_s1[idx] <= 0;
			else if(current_state == s_add_sub && fsm_cnt == 2)
			begin
				if(data_s0[idx] > midpoint)
					data_s1[idx] <= data_s0[idx] - half_of_difference;
				else if(data_s0[idx] < midpoint)
					data_s1[idx] <= data_s0[idx] + half_of_difference;
				else
					data_s1[idx] <= data_s0[idx];
			end
			else
				data_s1[idx] <= data_s1[idx];
		end
	end
endgenerate

// fsm state 2 s_sma //
generate
	for(idx=0; idx<9; idx=idx+1)
    begin
		always@(posedge clk or negedge rst_n)
		begin
			if(!rst_n)
				data_s2[idx] <= 0;
			else if(current_state == s_sma && current_in_mode[1] == 1)
			begin
				if(idx==0)
					data_s2[0] <= (data_s1[8] + data_s1[0] + data_s1[1])/3;
				else if(idx==8)
					data_s2[8] <= (data_s1[7] + data_s1[8] + data_s1[0])/3;
				else
					data_s2[idx] <= (data_s1[idx-1] + data_s1[idx] + data_s1[idx+1])/3;
			end
			else if(current_state == s_sma && current_in_mode[1] == 0)
			begin
				if(idx==0)
					data_s2[0] <= (data_s0[8] + data_s0[0] + data_s0[1])/3;
				else if(idx==8)
					data_s2[8] <= (data_s0[7] + data_s0[8] + data_s0[0])/3;
				else
					data_s2[idx] <= (data_s0[idx-1] + data_s0[idx] + data_s0[idx+1])/3;
			end
			else
				data_s2[idx] <= data_s2[idx];
		end
	end
endgenerate

// fsm state 3 s_mmm
// state3_max
always@(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        state3_max <= 0;
    else if(current_state == s_mmm && fsm_cnt == 1)
        state3_max <= max_tmp;
	else
		state3_max <= state3_max;
end
// state3_min
always@(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        state3_min <= 0;
    else if(current_state == s_mmm && fsm_cnt == 1)
        state3_min <= min_tmp;
	else
		state3_min <= state3_min;
end

wire signed [9:0] sort_in[0:8];
wire signed [9:0] sort_out[0:8];

Sort3 Sort3_0(sort_in[0],sort_in[1],sort_in[2],sort_out[0],sort_out[1],sort_out[2]);
Sort3 Sort3_1(sort_in[3],sort_in[4],sort_in[5],sort_out[3],sort_out[4],sort_out[5]);
Sort3 Sort3_2(sort_in[6],sort_in[7],sort_in[8],sort_out[6],sort_out[7],sort_out[8]);

generate
	assign sort_in[0] = data_s3[0];
	assign sort_in[1] = (fsm_cnt == 2)? data_s3[3]:data_s3[1];
	assign sort_in[2] = (fsm_cnt == 2)? data_s3[6]:data_s3[2];
	assign sort_in[3] = (fsm_cnt == 2)? data_s3[1]:(fsm_cnt == 3)?data_s3[2]:data_s3[3];
	assign sort_in[4] = data_s3[4];
	assign sort_in[5] = (fsm_cnt == 2)? data_s3[7]:(fsm_cnt == 3)?data_s3[6]:data_s3[5];
	assign sort_in[6] = (fsm_cnt == 2)? data_s3[2]:data_s3[6];
	assign sort_in[7] = (fsm_cnt == 2)? data_s3[5]:data_s3[7];
	assign sort_in[8] = data_s3[8];
endgenerate
// data_s3
generate
	for(idx=0; idx<9; idx=idx+1)
    begin
		always@(posedge clk or negedge rst_n)
		begin
			if(!rst_n)
				data_s3[idx] <= 0;
			else if(current_state == s_mmm && fsm_cnt == 0)
			begin
				if(current_in_mode[2] == 1)
					data_s3[idx] <= data_s2[idx];
				else
				begin
					if(current_in_mode[1] == 1)
						data_s3[idx] <= data_s1[idx];
					else
					begin
						data_s3[idx] <= data_s0[idx];
					end
				end
			end
			else if(current_state == s_mmm && fsm_cnt > 0)
				data_s3[idx] <= sort_out[idx];
			else
				data_s3[idx] <= data_s3[idx];
		end
	end
endgenerate

// state3_mid
always@(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        state3_mid <= 0;
    else if(current_state == s_mmm && fsm_cnt == 4)
        state3_mid <= sort_out[4];
	else
		state3_mid <= state3_mid;
end

// fsm state  s_out
// out_valid
always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        out_valid <= 0; 
    else if(current_state == s_out)
		out_valid <= 1;
    else
		out_valid <= 0;
end
// out_data
always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        out_data <= 0; 
    else if(current_state == s_out)
	begin
		if(fsm_cnt == 0)
			out_data <= state3_max;
		else if(fsm_cnt == 1)
			out_data <= state3_mid;
		else 
			out_data <= state3_min;
	end
    else
		out_data <= 0;
end
endmodule

module Min_9to1(
    // input
    in1,in2,in3,in4,in5,in6,in7,in8,in9,
    // output
    out
);
// input
input  signed [9:0] in1, in2, in3, in4, in5, in6, in7, in8, in9;
// output
output signed [9:0] out;
// WIRE AND REG DECLARATION
wire signed  [9:0] min_0  = (in1 < in2) ? in1 : in2;
wire signed  [9:0] min_1  = (in3 < in4) ? in3 : in4;
wire signed  [9:0] min_2  = (in5 < in6) ? in5 : in6;
wire signed  [9:0] min_3  = (in7 < in8) ? in7 : in8;
wire signed  [9:0] min_4to1_0 = (min_0 < min_1) ? min_0 : min_1;
wire signed  [9:0] min_4to1_1 = (min_2 < min_3) ? min_2 : min_3;
wire signed  [9:0] min_5to1_0 = (min_4to1_1 < in9) ? min_4to1_1 : in9;
wire signed  [9:0] min_final  = (min_4to1_0 < min_5to1_0) ? min_4to1_0 : min_5to1_0;
// out
assign             out  = min_final;
endmodule

module Max_9to1(
    // input
    in1,in2,in3,in4,in5,in6,in7,in8,in9,
    // output
    out
);
// input
input  signed [9:0] in1, in2, in3, in4, in5, in6, in7, in8, in9;
// output
output signed [9:0] out;
// WIRE AND REG DECLARATION
wire  signed [9:0] max1  = (in1   > in2)   ? in1   : in2;
wire  signed [9:0] max2  = (in3   > in4)   ? in3   : in4;
wire  signed [9:0] max3  = (in5   > in6)   ? in5   : in6;
wire  signed [9:0] max4  = (in7   > in8)   ? in7   : in8;
wire  signed [9:0] max_0 = (max1  > max2)  ? max1  : max2;
wire  signed [9:0] max_1 = (max3  > max4)  ? max3  : max4;
wire  signed [9:0] max_2 = (max_0 > max_1) ? max_0 : max_1;
wire  signed [9:0] max_f = (max_2 > in9)   ? max_2 : in9;
// out
assign         out = max_f;
endmodule

module Sort3 (
	// input
    in1,in2,in3,
    // output
    min,mid,max
);
// input
input  signed [9:0] in1, in2, in3;
// output
output signed [9:0] min, mid, max;	
wire signed [9:0] max2to1 = (in1     > in2)? in1     : in2;
wire signed [9:0] max_out = (max2to1 > in3)? max2to1 : in3;
wire signed [9:0] min2to1 = (in1     < in2)? in1     : in2;
wire signed [9:0] mid_out = (max2to1 < in3)? max2to1 : (in3 > min2to1)? in3 : min2to1;
wire signed [9:0] min_out = (min2to1 < in3)? min2to1 : in3;
assign     min     = min_out;
assign     mid     = mid_out;
assign     max     = max_out;
endmodule  