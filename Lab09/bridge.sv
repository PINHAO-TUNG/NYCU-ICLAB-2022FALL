module bridge(input clk, INF.bridge_inf inf);

//================================================================
// logic and parameter
//================================================================
// fsm
parameter s_idle       = 3'd0 ;
parameter s_read_addr  = 3'd1 ;
parameter s_read       = 3'd2 ;
parameter s_write_addr = 3'd3 ;
parameter s_write      = 3'd4 ;
parameter s_out        = 3'd5 ;

logic [2:0]  current_state, next_state;
// get input data
logic [7:0]  addr;
logic [63:0] data;
logic        mode_r_wb;
// preapre output data
logic [63:0] out_data;

//================================================================
// FSM
//================================================================
// current_state
always_ff@(posedge clk or negedge inf.rst_n) 
begin 
	if(!inf.rst_n) 	
		current_state <= s_idle;
	else 				
		current_state <= next_state;
end

// next_state
always_comb 
begin
	case(current_state)
		s_idle: 
		begin
			if(inf.C_in_valid == 1) 
			begin
				if(inf.C_r_wb == 1)	
					next_state = s_read_addr;
				else 						
					next_state = s_write_addr;
			end
			else
				next_state = s_idle;
		end
		s_read_addr:
		begin
			if(inf.AR_READY == 1)	
				next_state = s_read;
			else	
				next_state = s_read_addr;
		end
		s_read:
		begin 
			if(inf.R_VALID == 1)		
				next_state = s_out;
			else
				next_state = s_read;
		end
		s_write_addr:
		begin
			if(inf.AW_READY == 1)	
				next_state = s_write;
			else
				next_state = s_write_addr;
		end
		s_write:
		begin 
			if(inf.B_VALID == 1)
				next_state = s_out;
			else
				next_state = s_write;
		end
		s_out:
		begin	
			next_state = s_idle ;
		end
		default:
		begin
			next_state = s_idle ;
		end
	endcase 
end

//================================================================
// Read Port
//================================================================
// inf.AR_VALID
always_ff@(posedge clk or negedge inf.rst_n) 
begin
	if(!inf.rst_n) 
	begin
		inf.AR_VALID <= 0;
	end 
	else 
	begin
		if(current_state == s_read_addr && inf.AR_READY == 0) 
		begin
			inf.AR_VALID <= 1;
		end 
		else if(current_state == s_read_addr && inf.AR_READY == 1) 
		begin
			inf.AR_VALID <= 0;
		end 
		else
		begin
			inf.AR_VALID <= inf.AR_VALID;
		end
	end
end
// inf.AR_ADDR
always_ff@(posedge clk or negedge inf.rst_n) 
begin
	if(!inf.rst_n) 
	begin
		inf.AR_ADDR <= 0;
	end 
	else 
	begin
		if(current_state == s_read_addr) 
		begin
			inf.AR_ADDR <= 65536+8*addr;
		end
		else
		begin
			inf.AR_ADDR <= inf.AR_ADDR;
		end
	end
end
// inf.R_READY
always_ff@(posedge clk or negedge inf.rst_n) 
begin
	if(!inf.rst_n) 
	begin
		inf.R_READY <= 0;
	end	
	else 
	begin
		if(inf.AR_READY == 1 && inf.AR_VALID == 1) 
		begin
			inf.R_READY <= 1;
		end
		else if(inf.R_VALID == 1 && inf.R_READY == 1) 
		begin
			inf.R_READY <= 0;
		end 
		else
		begin
			inf.R_READY <= inf.R_READY;
		end
	end
end

//================================================================
// Write Port
//================================================================
// inf.AW_VALID
always_ff@(posedge clk or negedge inf.rst_n) 
begin
	if(!inf.rst_n) 
	begin
		inf.AW_VALID <= 0;
	end 
	else 
	begin
		if(current_state == s_write_addr && inf.AW_READY == 0) 
		begin
			inf.AW_VALID <= 1;
		end 
		else if(current_state == s_write_addr && inf.AW_READY == 1) 
		begin
			inf.AW_VALID <= 0;
		end
		else
		begin
			inf.AW_VALID <= inf.AW_VALID;
		end
	end
end
// inf.AW_ADDR
always_ff@(posedge clk or negedge inf.rst_n) 
begin
	if(!inf.rst_n) 
	begin
		inf.AW_ADDR <= 0;
	end 
	else 
	begin
		if(current_state == s_write_addr) 
		begin
			inf.AW_ADDR <= 65536+8*addr;
		end
		else
		begin
			inf.AW_ADDR <= inf.AW_ADDR;
		end
	end
end
// inf.W_DATA
always_ff@(posedge clk or negedge inf.rst_n) 
begin
	if(!inf.rst_n) 
	begin
		inf.W_DATA <= 0;
	end	
	else 
	begin
		if(inf.AW_READY == 1 && inf.AW_VALID == 1) 
		begin
			inf.W_DATA <= {data[ 7: 0], data[15: 8], data[23:16], data[31:24],
						   data[39:32], data[47:40], data[55:48], data[63:56]};
		end
		else
		begin
			inf.W_DATA <= inf.W_DATA;
		end
	end
end
// inf.W_VALID
always_ff@(posedge clk or negedge inf.rst_n) 
begin
	if(!inf.rst_n) 
	begin
		inf.W_VALID <= 0;
	end	
	else 
	begin
		if(inf.AW_READY == 1 && inf.AW_VALID == 1) 
		begin
			inf.W_VALID <= 1;
		end
		else if(inf.W_VALID == 1 && inf.W_READY == 1) 
		begin
			inf.W_VALID <= 0;
		end 
		else
		begin
			inf.W_VALID <= inf.W_VALID;
		end 	
	end
end
// inf.B_READY
always_ff@(posedge clk or negedge inf.rst_n) 
begin 
	if(!inf.rst_n)	
		inf.B_READY <= 0 ;
	else 			
		inf.B_READY <= 1 ;
end	

//================================================================
// get input data
//================================================================
// inf.C_addr to addr
always_ff@(posedge clk or negedge inf.rst_n) 
begin
	if (!inf.rst_n) 	
		addr <= 0;
	else if(inf.C_in_valid == 1)	
		addr <= inf.C_addr;
	else
		addr <= addr;
end
// inf.C_data_w to data
always_ff@(posedge clk or negedge inf.rst_n) 
begin
	if(!inf.rst_n) 	
		data <= 0;
	else if (inf.C_in_valid == 1 && inf.C_r_wb == 0)	
		data <= inf.C_data_w;
	else
		data <= data;
end
// inf.C_r_wb to mode_r_wb
always_ff@(posedge clk or negedge inf.rst_n) 
begin
	if(!inf.rst_n) 	
		mode_r_wb <= 0;
	else if (inf.C_in_valid == 1)	
		mode_r_wb <= inf.C_r_wb;
	else
		mode_r_wb <= mode_r_wb;
end

//================================================================
// preapre output data
//================================================================
// inf.R_DATA to out_data
always_ff @(posedge clk or negedge inf.rst_n) 
begin
	if(!inf.rst_n) 	
		out_data <= 0;
	else if(inf.R_VALID == 1 && inf.R_READY == 1) 	
	begin
		out_data <= {inf.R_DATA[ 7: 0], inf.R_DATA[15: 8], inf.R_DATA[23:16], inf.R_DATA[31:24],
					 inf.R_DATA[39:32], inf.R_DATA[47:40], inf.R_DATA[55:48], inf.R_DATA[63:56]};
	end
	else 					
		out_data <= out_data;
end

//================================================================
// Output Port
//================================================================
// inf.C_out_valid
always_ff@(posedge clk or negedge inf.rst_n) 
begin 
	if(!inf.rst_n) 	
		inf.C_out_valid <= 0;
	else if(current_state == s_out)	
		inf.C_out_valid <= 1;
	else 							
		inf.C_out_valid <= 0;
end

// inf.C_data_r
always_ff @(posedge clk or negedge inf.rst_n) begin
	if(!inf.rst_n) 	
		inf.C_data_r <= 0 ;
	else if(current_state == s_out) 	
		inf.C_data_r <= out_data;
	else 					
		inf.C_data_r <= 0;
end

endmodule