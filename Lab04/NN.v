module NN(
	// Input signals
	clk,
	rst_n,
	in_valid_u,
	in_valid_w,
	in_valid_v,
	in_valid_x,
	weight_u,
	weight_w,
	weight_v,
	data_x,
	// Output signals
	out_valid,
	out
);
//==============================================//
//             Parameter and Integer            //
//==============================================// 
// IEEE floating point paramenters
parameter inst_sig_width = 23;
parameter inst_exp_width = 8;
parameter inst_ieee_compliance = 0;
parameter inst_arch = 2;

// FSM Parameter
parameter s_idle = 2'd0;
parameter s_input = 2'd1;
parameter s_cal = 2'd2;
parameter s_output = 2'd3;

parameter FP_ZERO = 32'b0_0000_0000_00000000000000000000000;
parameter FP_ONE = 32'b0_0111_1111_00000000000000000000000;

// genvar
genvar idx;
//==============================================//
//         INPUT AND OUTPUT DECLARATION         //
//==============================================//
input  clk, rst_n, in_valid_u, in_valid_w, in_valid_v, in_valid_x;
input [inst_sig_width+inst_exp_width:0] weight_u, weight_w, weight_v;
input [inst_sig_width+inst_exp_width:0] data_x;
output reg	out_valid;
output reg [inst_sig_width+inst_exp_width:0] out;

//==============================================//
//           WIRE AND REG DECLARATION           //
//==============================================//
// FSM //
// state
reg [1:0] current_state, next_state;
// FSM_counter 5bit
reg [4:0] FSM_counter;

// Input //
// u_weight w_weight v_weight x_vector
reg [inst_sig_width+inst_exp_width:0] u_weight[0:8];
reg [inst_sig_width+inst_exp_width:0] w_weight[0:8]; 
reg [inst_sig_width+inst_exp_width:0] v_weight[0:8]; 
reg [inst_sig_width+inst_exp_width:0] x_vector[0:8];

//// cal ////
// ip //
// mult
reg [inst_sig_width+inst_exp_width:0] mult_9_input[0:8];
reg [inst_sig_width+inst_exp_width:0] mult_3_input[0:2];
wire [inst_sig_width+inst_exp_width:0] mult_wire_output[0:8];

// sum3
reg [inst_sig_width+inst_exp_width:0] sum3_9_input[0:8];
wire [inst_sig_width+inst_exp_width:0] sum3_wire_output[0:2];

// exp 
reg [inst_sig_width+inst_exp_width:0] exp_3_input[0:2];
wire [inst_sig_width+inst_exp_width:0] exp_wire_output[0:2];

// add 
reg [inst_sig_width+inst_exp_width:0] add_a3_input[0:2];
reg [inst_sig_width+inst_exp_width:0] add_b3_input[0:2];
wire [inst_sig_width+inst_exp_width:0] add_wire_output[0:2];

// recip 
reg [inst_sig_width+inst_exp_width:0] recip_3_input[0:2];
wire [inst_sig_width+inst_exp_width:0] recip_wire_output[0:2];

// output //
// y_vector
reg [inst_sig_width+inst_exp_width:0] y_vector[0:8];

//==============================================//
//            FSM State Declaration             //
//==============================================//
// FSM_counter 5bit //
always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        FSM_counter <= 5'd0;
    else
    case(current_state)
        s_idle:
		begin
            FSM_counter <= 5'd0;
		end
        s_input:
		begin
			if(in_valid_x == 1)
			begin
				if(FSM_counter == 5'd8)
					FSM_counter <= 5'd0;
				else
					FSM_counter <= FSM_counter + 5'd1;
			end
			else
				FSM_counter <= FSM_counter;
		end
	s_cal:
		begin
			if(FSM_counter == 5'd23)
                FSM_counter <= 5'd0;
            else
                FSM_counter <= FSM_counter + 5'd1;
		end
        s_output:
		begin
			if(FSM_counter == 5'd8)
                FSM_counter <= 5'd0;
            else
                FSM_counter <= FSM_counter + 5'd1;
		end    
        default:
            FSM_counter <= FSM_counter;
    endcase
end

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
            if(FSM_counter == 5'd8)
                next_state = s_cal;
            else
                next_state = current_state;
		end
		s_cal:
		begin
			if(FSM_counter == 5'd23)
                next_state = s_output;
            else
                next_state = current_state;
		end
        s_output:
		begin
            if(FSM_counter == 5'd8)
                next_state = s_idle;
            else
                next_state = current_state;
		end
        default:
            next_state = current_state;
    endcase
end

//==============================================//
//           FSM state 1 Input Block            //
//==============================================//
// u_weight
always@(posedge clk or negedge rst_n)
begin
	if(!rst_n)
	begin
		u_weight[0] <= FP_ZERO;
		u_weight[1] <= FP_ZERO;
		u_weight[2] <= FP_ZERO;
		u_weight[3] <= FP_ZERO;
		u_weight[4] <= FP_ZERO;
		u_weight[5] <= FP_ZERO;
		u_weight[6] <= FP_ZERO;
		u_weight[7] <= FP_ZERO;
		u_weight[8] <= FP_ZERO;
	end
	else
	begin
		if(current_state == s_idle)
		begin
			u_weight[0] <= FP_ZERO;
			u_weight[1] <= FP_ZERO;
			u_weight[2] <= FP_ZERO;
			u_weight[3] <= FP_ZERO;
			u_weight[4] <= FP_ZERO;
			u_weight[5] <= FP_ZERO;
			u_weight[6] <= FP_ZERO;
			u_weight[7] <= FP_ZERO;
			u_weight[8] <= FP_ZERO;
		end
		else if(current_state == s_input)
			u_weight[FSM_counter] <= weight_u;
		else
		begin
			u_weight[0] <= u_weight[0];
			u_weight[1] <= u_weight[1];
			u_weight[2] <= u_weight[2];
			u_weight[3] <= u_weight[3];
			u_weight[4] <= u_weight[4];
			u_weight[5] <= u_weight[5];
			u_weight[6] <= u_weight[6];
			u_weight[7] <= u_weight[7];
			u_weight[8] <= u_weight[8];
		end
	end
end

// w_weight
always@(posedge clk or negedge rst_n)
begin
	if(!rst_n)
	begin
		w_weight[0] <= FP_ZERO;
		w_weight[1] <= FP_ZERO;
		w_weight[2] <= FP_ZERO;
		w_weight[3] <= FP_ZERO;
		w_weight[4] <= FP_ZERO;
		w_weight[5] <= FP_ZERO;
		w_weight[6] <= FP_ZERO;
		w_weight[7] <= FP_ZERO;
		w_weight[8] <= FP_ZERO;
	end
	else
	begin
		if(current_state == s_idle)
		begin
			w_weight[0] <= FP_ZERO;
			w_weight[1] <= FP_ZERO;
			w_weight[2] <= FP_ZERO;
			w_weight[3] <= FP_ZERO;
			w_weight[4] <= FP_ZERO;
			w_weight[5] <= FP_ZERO;
			w_weight[6] <= FP_ZERO;
			w_weight[7] <= FP_ZERO;
			w_weight[8] <= FP_ZERO;
		end
		else if(current_state == s_input)
			w_weight[FSM_counter] <= weight_w;
		else
		begin
			w_weight[0] <= w_weight[0];
			w_weight[1] <= w_weight[1];
			w_weight[2] <= w_weight[2];
			w_weight[3] <= w_weight[3];
			w_weight[4] <= w_weight[4];
			w_weight[5] <= w_weight[5];
			w_weight[6] <= w_weight[6];
			w_weight[7] <= w_weight[7];
			w_weight[8] <= w_weight[8];
		end
	end
end

// v_weight
always@(posedge clk or negedge rst_n)
begin
	if(!rst_n)
	begin
		v_weight[0] <= FP_ZERO;
		v_weight[1] <= FP_ZERO;
		v_weight[2] <= FP_ZERO;
		v_weight[3] <= FP_ZERO;
		v_weight[4] <= FP_ZERO;
		v_weight[5] <= FP_ZERO;
		v_weight[6] <= FP_ZERO;
		v_weight[7] <= FP_ZERO;
		v_weight[8] <= FP_ZERO;
	end
	else
	begin
		if(current_state == s_idle)
		begin
			v_weight[0] <= FP_ZERO;
			v_weight[1] <= FP_ZERO;
			v_weight[2] <= FP_ZERO;
			v_weight[3] <= FP_ZERO;
			v_weight[4] <= FP_ZERO;
			v_weight[5] <= FP_ZERO;
			v_weight[6] <= FP_ZERO;
			v_weight[7] <= FP_ZERO;
			v_weight[8] <= FP_ZERO;
		end
		else if(current_state == s_input)
			v_weight[FSM_counter] <= weight_v;
		else
		begin
			v_weight[0] <= v_weight[0];
			v_weight[1] <= v_weight[1];
			v_weight[2] <= v_weight[2];
			v_weight[3] <= v_weight[3];
			v_weight[4] <= v_weight[4];
			v_weight[5] <= v_weight[5];
			v_weight[6] <= v_weight[6];
			v_weight[7] <= v_weight[7];
			v_weight[8] <= v_weight[8];
		end
	end
end

// x_vector
always@(posedge clk or negedge rst_n)
begin
	if(!rst_n)
	begin
		x_vector[0] <= FP_ZERO;
		x_vector[1] <= FP_ZERO;
		x_vector[2] <= FP_ZERO;
		x_vector[3] <= FP_ZERO;
		x_vector[4] <= FP_ZERO;
		x_vector[5] <= FP_ZERO;
		x_vector[6] <= FP_ZERO;
		x_vector[7] <= FP_ZERO;
		x_vector[8] <= FP_ZERO;
	end
	else
	begin
		if(current_state == s_idle)
		begin
			x_vector[0] <= FP_ZERO;
			x_vector[1] <= FP_ZERO;
			x_vector[2] <= FP_ZERO;
			x_vector[3] <= FP_ZERO;
			x_vector[4] <= FP_ZERO;
			x_vector[5] <= FP_ZERO;
			x_vector[6] <= FP_ZERO;
			x_vector[7] <= FP_ZERO;
			x_vector[8] <= FP_ZERO;
		end
		else if(current_state == s_input)
			x_vector[FSM_counter] <= data_x;
		else
		begin
			x_vector[0] <= x_vector[0];
			x_vector[1] <= x_vector[1];
			x_vector[2] <= x_vector[2];
			x_vector[3] <= x_vector[3];
			x_vector[4] <= x_vector[4];
			x_vector[5] <= x_vector[5];
			x_vector[6] <= x_vector[6];
			x_vector[7] <= x_vector[7];
			x_vector[8] <= x_vector[8];
		end
	end
end

//==============================================//
//               FSM state 2 cal                //
//==============================================//
//// ip cal ////
// mult //
// mult_9_input mult_3_input mult_wire_output
generate
	for(idx=0 ; idx<3 ; idx=idx+1)
	begin
		DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
			mult0(.a(mult_9_input[idx]), .b(mult_3_input[idx]), .rnd(3'b000), .z(mult_wire_output[idx]));
		DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
			mult1(.a(mult_9_input[idx+3]), .b(mult_3_input[idx]), .rnd(3'b000), .z(mult_wire_output[idx+3]));
		DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
			mult2(.a(mult_9_input[idx+6]), .b(mult_3_input[idx]), .rnd(3'b000), .z(mult_wire_output[idx+6]));
	end
endgenerate

// sum3 //
// sum3_9_input sum3_wire_output
DW_fp_sum3 #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
	sum0(.a(sum3_9_input[0]), .b(sum3_9_input[1]), .c(sum3_9_input[2]), .rnd(3'b000), .z(sum3_wire_output[0]));
DW_fp_sum3 #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
	sum1(.a(sum3_9_input[3]), .b(sum3_9_input[4]), .c(sum3_9_input[5]), .rnd(3'b000), .z(sum3_wire_output[1]));
DW_fp_sum3 #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
	sum2(.a(sum3_9_input[6]), .b(sum3_9_input[7]), .c(sum3_9_input[8]), .rnd(3'b000), .z(sum3_wire_output[2]));

// exp //
// exp_3_input exp_wire_output
generate
	for(idx=0 ; idx<3 ; idx=idx+1)
	begin
		DW_fp_exp #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
			exp0(.a({~exp_3_input[idx][31], exp_3_input[idx][30:0]}), .z(exp_wire_output[idx]));
	end
endgenerate

// add //
// add_a3_input add_b3_input add_wire_output
generate
	for(idx=0 ; idx<3 ; idx=idx+1)
	begin
		DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
			add0(.a(add_a3_input[idx]), .b(add_b3_input[idx]), .rnd(3'b000), .z(add_wire_output[idx]));
	end
endgenerate

// recip //
// recip_3_input recip_wire_output
generate
	for(idx=0 ; idx<3 ; idx=idx+1)
	begin
		DW_fp_recip #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
			recip0(.a(recip_3_input[idx]), .rnd(3'b000), .z(recip_wire_output[idx]));
	end
endgenerate

//// work and update ////
// mult update //
// u_weight w_weight v_weight to mult_9_input
generate
	for(idx=0; idx<9; idx=idx+1)
	begin
		always@(posedge clk or negedge rst_n)
		begin
			if(!rst_n)
			begin
				mult_9_input[idx] <= FP_ZERO;
			end
			else
			begin
				if(current_state == s_idle)
				begin
					mult_9_input[idx] <= FP_ZERO;
				end
				else if(current_state == s_cal)
				begin
					case(FSM_counter)
						0:
							mult_9_input[idx] <= u_weight[idx];
                        2:
							mult_9_input[idx] <= u_weight[idx];
						5:
							mult_9_input[idx] <= v_weight[idx];
                        7:
							mult_9_input[idx] <= w_weight[idx];
						9:
							mult_9_input[idx] <= u_weight[idx];
						13:
							mult_9_input[idx] <= v_weight[idx];
						15:
							mult_9_input[idx] <= w_weight[idx];
						21:	
							mult_9_input[idx] <= v_weight[idx];
						default:
							mult_9_input[idx] <= mult_9_input[idx];	
					endcase		
				end
				else
					mult_9_input[idx] <= mult_9_input[idx];
			end
		end
	end
endgenerate

// x_vector recip_wire_output to mult_3_input
generate
	for(idx=0; idx<3; idx=idx+1)
	begin
		always@(posedge clk or negedge rst_n)
		begin
			if(!rst_n)
			begin
				mult_3_input[idx] <= FP_ZERO;
			end
			else
			begin
				if(current_state == s_idle)
				begin
					mult_3_input[idx] <= FP_ZERO;
				end
				else if(current_state == s_cal)
				begin
					case(FSM_counter)
						0:
							mult_3_input[idx] <= x_vector[idx];
                        2:
							mult_3_input[idx] <= x_vector[idx+3];
						5:
							mult_3_input[idx] <= recip_wire_output[idx];
                        7:
							mult_3_input[idx] <= recip_wire_output[idx];
						9:
							mult_3_input[idx] <= x_vector[idx+6];
						13:
							mult_3_input[idx] <= recip_wire_output[idx];
						15:
							mult_3_input[idx] <= recip_wire_output[idx];
						21:	
							mult_3_input[idx] <= recip_wire_output[idx];
						default:
							mult_3_input[idx] <= mult_3_input[idx];	
					endcase		
				end
				else
					mult_3_input[idx] <= mult_3_input[idx];
			end
		end
	end
endgenerate

// sum3 update //
// mult_wire_output to sum3_9_input
generate
	for(idx=0; idx<9; idx=idx+1)
	begin
		always@(posedge clk or negedge rst_n)
		begin
			if(!rst_n)
			begin
				sum3_9_input[idx] <= FP_ZERO;
			end
			else
			begin
				if(current_state == s_idle)
				begin
					sum3_9_input[idx] <= FP_ZERO;
				end
				else if(current_state == s_cal)
				begin
					case(FSM_counter)
						1:
							sum3_9_input[idx] <= mult_wire_output[idx];
						3:
							sum3_9_input[idx] <= mult_wire_output[idx];
						6:
							sum3_9_input[idx] <= mult_wire_output[idx];
						8:
							sum3_9_input[idx] <= mult_wire_output[idx];
						10:
							sum3_9_input[idx] <= mult_wire_output[idx];
						14:
							sum3_9_input[idx] <= mult_wire_output[idx];
						16:
							sum3_9_input[idx] <= mult_wire_output[idx];
						22:	
							sum3_9_input[idx] <= mult_wire_output[idx];
						default:
							sum3_9_input[idx] <= sum3_9_input[idx];	
					endcase		
				end
				else
					sum3_9_input[idx] <= sum3_9_input[idx];
			end
		end
	end
endgenerate

// f() //
// exp update //
// sum3_wire_output/add_reg_output to exp_3_input
generate
	for(idx=0; idx<3; idx=idx+1)
	begin
		always@(posedge clk or negedge rst_n)
		begin
			if(!rst_n)
			begin
				exp_3_input[idx] <= FP_ZERO;
			end
			else
			begin
				if(current_state == s_idle)
				begin
					exp_3_input[idx] <= FP_ZERO;
				end
				else if(current_state == s_cal)
				begin
					case(FSM_counter)
						2:
							exp_3_input[idx] <= sum3_wire_output[idx];
						10:
							exp_3_input[idx] <= add_wire_output[idx];
						18:
							exp_3_input[idx] <= add_wire_output[idx];
						default:
							exp_3_input[idx] <= exp_3_input[idx];	
					endcase		
				end
				else
					exp_3_input[idx] <= exp_3_input[idx];
			end
		end
	end
endgenerate

// add update //
// exp_wire_output/ux_sum(sum3_wire_output) to add_a3_input
generate
	for(idx=0; idx<3; idx=idx+1)
	begin
		always@(posedge clk or negedge rst_n)
		begin
			if(!rst_n)
			begin
				add_a3_input[idx] <= FP_ZERO;
			end
			else
			begin
				if(current_state == s_idle)
				begin
					add_a3_input[idx] <= FP_ZERO;
				end
				else if(current_state == s_cal)
				begin
					case(FSM_counter)
						3:
							add_a3_input[idx] <= exp_wire_output[idx];
						4:
							add_a3_input[idx] <= sum3_wire_output[idx];
						11:
							add_a3_input[idx] <= exp_wire_output[idx];
						12:
							add_a3_input[idx] <= sum3_wire_output[idx];
						19:
							add_a3_input[idx] <= exp_wire_output[idx];
						default:
							add_a3_input[idx] <= add_a3_input[idx];	
					endcase		
				end
				else
					add_a3_input[idx] <= add_a3_input[idx];
			end
		end
	end
endgenerate

// FP_ONE/wh_sum(sum3_wire_output) to add_b3_input
generate
	for(idx=0; idx<3; idx=idx+1)
	begin
		always@(posedge clk or negedge rst_n)
		begin
			if(!rst_n)
			begin
				add_b3_input[idx] <= FP_ZERO;
			end
			else
			begin
				if(current_state == s_idle)
				begin
					add_b3_input[idx] <= FP_ZERO;
				end
				else if(current_state == s_cal)
				begin
					case(FSM_counter)
						3:
							add_b3_input[idx] <= FP_ONE;
						9:
							add_b3_input[idx] <= sum3_wire_output[idx];
					    11:
							add_b3_input[idx] <= FP_ONE;
						17:
							add_b3_input[idx] <= sum3_wire_output[idx];
						19:
							add_b3_input[idx] <= FP_ONE;
						default:
							add_b3_input[idx] <= add_b3_input[idx];	
					endcase		
				end
				else
					add_b3_input[idx] <= add_b3_input[idx];
			end
		end
	end
endgenerate

// recip  //
// add_wire_output to recip_3_input
generate
	for(idx=0; idx<3; idx=idx+1)
	begin
		always@(posedge clk or negedge rst_n)
		begin
			if(!rst_n)
			begin
				recip_3_input[idx] <= FP_ZERO;
			end
			else
			begin
				if(current_state == s_idle)
				begin
					recip_3_input[idx] <= FP_ZERO;
				end
				else if(current_state == s_cal)
				begin
					case(FSM_counter)
						4:
							recip_3_input[idx] <= add_wire_output[idx];
						12:
							recip_3_input[idx] <= add_wire_output[idx];
						20:
							recip_3_input[idx] <= add_wire_output[idx];
						default:
							recip_3_input[idx] <= recip_3_input[idx];	
					endcase		
				end
				else
					recip_3_input[idx] <= recip_3_input[idx];
			end
		end
	end
endgenerate

// output data
// sum3_wire_output to y_vector
generate
	for(idx=0; idx<3; idx=idx+1)
	begin
		always@(posedge clk or negedge rst_n)
		begin
			if(!rst_n)
			begin
				y_vector[idx] <= FP_ZERO;
				y_vector[idx+3] <= FP_ZERO;
				y_vector[idx+6] <= FP_ZERO;
			end
			else
			begin
				if(current_state == s_idle)
				begin
					y_vector[idx] <= FP_ZERO;
                    y_vector[idx+3] <= FP_ZERO;
                    y_vector[idx+6] <= FP_ZERO;
				end
				else if(current_state == s_cal)
				begin
					if(FSM_counter == 7)
					begin
						if(sum3_wire_output[idx][31] == 0)
							y_vector[idx] <= sum3_wire_output[idx];	
						else
							y_vector[idx] <= FP_ZERO;
					end
					else if(FSM_counter == 15)
					begin
						if(sum3_wire_output[idx][31] == 0)
							y_vector[idx+3] <= sum3_wire_output[idx];	
						else
							y_vector[idx+3] <= FP_ZERO;
					end
					else if(FSM_counter == 23)
					begin
						if(sum3_wire_output[idx][31] == 0)
							y_vector[idx+6] <= sum3_wire_output[idx];	
						else
							y_vector[idx+6] <= FP_ZERO;
					end
					else
						y_vector[idx] <= y_vector[idx];	
				end
				else
				begin
					y_vector[idx] <= y_vector[idx];
					y_vector[idx+3] <= y_vector[idx+3];
					y_vector[idx+6] <= y_vector[idx+6];
				end
			end
		end
	end
endgenerate

//==============================================//
//          FSM state 3 Output Block            //
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

// out
always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        out <= FP_ZERO; 
    else
    case(current_state)
        s_output:
        begin    
            out <= y_vector[FSM_counter];
        end
        default:
            out <= FP_ZERO;
    endcase
end
endmodule
