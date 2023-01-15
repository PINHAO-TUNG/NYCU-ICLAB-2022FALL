module FD(input clk, INF.FD_inf inf);
import usertype::*;

//===========================================================================
// logic and parameter 
//===========================================================================
// fsm
fsm_state current_state, next_state;
// current signal
Delivery_man_id current_d_id;
Restaurant_id current_res_id;
Action current_act;
Ctm_Info current_ctm_Info;
food_ID_servings current_food_ID_ser;
// current info
D_man_Info current_D_man_Info;
res_info current_res_info;

// dram input data
logic [63:0] d_id_dram_d, res_id_dram_r;
// out 
logic [63:0] out_value;
// out to bridge
// flag
logic load_dram_d_flag, load_dram_r_flag, write_dram_d_flag, write_dram_r_flag;

// wrong msg //
// wrong_msg
Error_Msg wrong_msg;
// flag
logic wrong_msg_flag;

// comblogic
logic [10:0] food_total;
assign food_total = current_res_info.ser_FOOD1 + current_res_info.ser_FOOD2 + 
                    current_res_info.ser_FOOD3 + current_food_ID_ser.d_ser_food;
//================================================================
// FSM State Declaration
//================================================================
// current_state //
always_ff@(posedge clk or negedge inf.rst_n) 
begin
	if (!inf.rst_n)		
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
			if(inf.act_valid)
            begin
                case(inf.D.d_act[0])
                    // Take
                    4'd1:
                    begin
                        next_state = s_take;
                    end
                    // Deliver
                    4'd2:
                    begin
                        next_state = s_deliver;    
                    end
                    // Order
                    4'd4:
                    begin
                        next_state = s_order;
                    end
                    // Cancel
                    4'd8:
                    begin
                        next_state = s_cancel;
                    end
                    default:
                    begin
                        next_state = s_idle;
                    end
                endcase
            end
            else
                next_state = s_idle;
		end
        s_take: 
        begin
			if(inf.cus_valid)
                next_state = s_load_dram_d;
            else
                next_state = s_take;
		end
        s_deliver: 
        begin
			if(inf.id_valid)
                next_state = s_load_dram_d;
            else
                next_state = s_deliver;
		end
        s_order: 
        begin
			if(inf.food_valid)
                next_state = s_load_dram_r;
            else
                next_state = s_order;
		end
        s_cancel: 
        begin
			if(inf.id_valid)
                next_state = s_load_dram_d;
            else
                next_state = s_cancel;
		end
        s_load_dram_d: 
        begin
			if(inf.C_out_valid)
            begin
                if(current_act == Take)
                begin
                    if(current_d_id == current_ctm_Info.res_ID)
                        next_state = s_cal;
                    else
                        next_state = s_load_dram_r;
                end
                else if(current_act == Cancel)
                begin
                    if(current_d_id == current_res_id)
                        next_state = s_cal;
                    else
                        next_state = s_load_dram_r;
                end
                else
                    next_state = s_cal;
            end
            else
                next_state = s_load_dram_d;
		end
        s_load_dram_r: 
        begin
			if(inf.C_out_valid)
                next_state = s_cal;
            else
                next_state = s_load_dram_r;
		end
        // cal and decide to dram or have wrong
        s_cal:
        begin
            next_state = s_deal;
        end
        s_deal: 
        begin
            if(wrong_msg_flag)
                next_state = s_out;
            else
            begin
                if(current_act == Order)
                    next_state = s_write_dram_r;
                else
			        next_state = s_write_dram_d;
            end
		end
        s_write_dram_d: 
        begin
			if(inf.C_out_valid)
            begin
                if(current_act == Take)
                begin
                    if(current_d_id == current_ctm_Info.res_ID)
                        next_state = s_out;
                    else
                        next_state = s_write_dram_r;
                end
                else if(current_act == Cancel)
                begin
                    if(current_d_id == current_res_id)
                        next_state = s_out;
                    else
                        next_state = s_write_dram_r;
                end
                else
                    next_state = s_out;
            end
            else
                next_state = s_write_dram_d;
		end
        s_write_dram_r: 
        begin
			if(inf.C_out_valid)
                next_state = s_out;
            else
                next_state = s_write_dram_r;
		end
        s_out:
        begin
            next_state = s_idle;
        end
		default:
        begin
			next_state = s_idle;
		end
	endcase
end

//================================================================
// Current signal
//================================================================
// current_d_id
always_ff@(posedge clk or negedge inf.rst_n) 
begin
    if(!inf.rst_n)		
        current_d_id <= 0;
	else if(inf.id_valid) 				
        current_d_id <= inf.D.d_id[0];
    else
        current_d_id <= current_d_id;
end
// current_act
always_ff@(posedge clk or negedge inf.rst_n) 
begin
    if(!inf.rst_n)		
        current_act <= No_action;
	else if(inf.act_valid) 				
        current_act <= inf.D.d_act[0];
    else
        current_act <= current_act;
end
// current_ctm_Info
always_ff@(posedge clk or negedge inf.rst_n) 
begin
    if(!inf.rst_n)		
        current_ctm_Info <= 0;
	else if(inf.cus_valid) 				
        current_ctm_Info <= inf.D.d_ctm_info[0];
    else
        current_ctm_Info <= current_ctm_Info;
end
// current_res_id
always_ff@(posedge clk or negedge inf.rst_n) 
begin
    if(!inf.rst_n)		
        current_res_id <= 0;
	else if(inf.res_valid) 				
        current_res_id <= inf.D.d_res_id[0];
    else
        current_res_id <= current_res_id;
end
// current_food_ID_ser
always_ff@(posedge clk or negedge inf.rst_n) 
begin
    if(!inf.rst_n)		
        current_food_ID_ser <= 0;
	else if(inf.food_valid) 				
        current_food_ID_ser <= inf.D.d_food_ID_ser[0];
    else
        current_food_ID_ser <= current_food_ID_ser;
end

//================================================================
// Current info
//================================================================
// current_D_man_Info
always_ff@(posedge clk or negedge inf.rst_n) 
begin
    if (!inf.rst_n)		
        current_D_man_Info <= 0;
    // load D_man_Info
    else if(current_state == s_load_dram_d && inf.C_out_valid)
        current_D_man_Info <= inf.C_data_r[31:0];
    // change D_man_Info
    else if(current_state == s_cal)
    begin
        // current_ctm_Info to current_D_man_Info
        if(current_act == Take)
        begin
            if(current_D_man_Info.ctm_info1 == 0 && current_D_man_Info.ctm_info2 == 0)
                current_D_man_Info.ctm_info1 <= current_ctm_Info;
            else if(current_D_man_Info.ctm_info1 != 0 && current_D_man_Info.ctm_info2 == 0)
            begin
                if(current_D_man_Info.ctm_info1.ctm_status == VIP)
                    current_D_man_Info.ctm_info2 <= current_ctm_Info;
                else
                begin
                    if(current_ctm_Info.ctm_status == VIP)
                    begin
                        current_D_man_Info.ctm_info1 <= current_ctm_Info;
                        current_D_man_Info.ctm_info2 <= current_D_man_Info.ctm_info1;
                    end
                    else
                        current_D_man_Info.ctm_info2 <= current_ctm_Info;
                end
            end
            // Delivery man busy
            else 
                current_D_man_Info <= current_D_man_Info;
        end
        // current_D_man_Info to current_ctm_Info
        else if(current_act == Deliver)
        begin
            if(current_D_man_Info.ctm_info1 != 0 && current_D_man_Info.ctm_info2 == 0)
            begin
                current_D_man_Info.ctm_info1 <= 0;
            end
            else if(current_D_man_Info.ctm_info1 != 0 && current_D_man_Info.ctm_info2 != 0)
            begin
                current_D_man_Info.ctm_info1 <= current_D_man_Info.ctm_info2;
                current_D_man_Info.ctm_info2 <= 0;
            end
            else 
                current_D_man_Info <= current_D_man_Info;
        end
        // Cancel current_D_man_Info ctm_Info 
        else if(current_act == Cancel)
        begin
            // Wrong cancel
            if(current_D_man_Info.ctm_info1 == 0 && current_D_man_Info.ctm_info2 == 0)
                current_D_man_Info <= current_D_man_Info;
            else if(current_D_man_Info.ctm_info1 != 0 && current_D_man_Info.ctm_info2 == 0)
            begin
                // Wrong Restaurant ID
                if(current_D_man_Info.ctm_info1.res_ID != current_res_id)
                    current_D_man_Info <= current_D_man_Info;
                else
                begin
                    // Wrong food ID
                    if(current_D_man_Info.ctm_info1.food_ID != current_food_ID_ser.d_food_ID)
                        current_D_man_Info <= current_D_man_Info;
                    // no wrong
                    else
                    begin
                        // ctm_info1
                        if(current_D_man_Info.ctm_info1.res_ID == current_res_id && current_D_man_Info.ctm_info1.food_ID == current_food_ID_ser.d_food_ID)
                            current_D_man_Info.ctm_info1 <= 0;
                        else
                            current_D_man_Info <= current_D_man_Info;
                    end    
                end
            end
            else 
            begin
                // Wrong Restaurant ID     ctm_info1.res_ID and ctm_info2.res_ID none equal to current_res_id
                if(current_D_man_Info.ctm_info1.res_ID != current_res_id && current_D_man_Info.ctm_info2.res_ID != current_res_id)
                    current_D_man_Info <= current_D_man_Info;
                else
                begin
                    // current_res_id equal to ctm_info1.res_ID 
                    if(current_D_man_Info.ctm_info1.res_ID == current_res_id && current_D_man_Info.ctm_info2.res_ID == current_res_id)
                    begin
                        // Wrong food ID ctm_info1
                        if(current_D_man_Info.ctm_info1.food_ID != current_food_ID_ser.d_food_ID && current_D_man_Info.ctm_info2.food_ID != current_food_ID_ser.d_food_ID)
                            current_D_man_Info <= current_D_man_Info;
                        // no wrong ctm_info1 change
                        else if(current_D_man_Info.ctm_info1.food_ID == current_food_ID_ser.d_food_ID && current_D_man_Info.ctm_info2.food_ID == current_food_ID_ser.d_food_ID)
                        begin
                            current_D_man_Info.ctm_info1 <= 0;
                            current_D_man_Info.ctm_info2 <= 0;
                        end
                        else if(current_D_man_Info.ctm_info1.food_ID == current_food_ID_ser.d_food_ID && current_D_man_Info.ctm_info2.food_ID != current_food_ID_ser.d_food_ID)
                        begin
                            current_D_man_Info.ctm_info1 <= current_D_man_Info.ctm_info2;
                            current_D_man_Info.ctm_info2 <= 0;
                        end 
                        else if(current_D_man_Info.ctm_info1.food_ID != current_food_ID_ser.d_food_ID && current_D_man_Info.ctm_info2.food_ID == current_food_ID_ser.d_food_ID)
                        begin
                            current_D_man_Info.ctm_info2 <= 0;
                        end
                        else
                            current_D_man_Info <= current_D_man_Info;
                    end
                    // current_res_id equal to ctm_info1.res_ID 
                    else if(current_D_man_Info.ctm_info1.res_ID == current_res_id && current_D_man_Info.ctm_info2.res_ID != current_res_id)
                    begin
                        // Wrong food ID ctm_info1
                        if(current_D_man_Info.ctm_info1.food_ID != current_food_ID_ser.d_food_ID)
                            current_D_man_Info <= current_D_man_Info;
                        // no wrong ctm_info1 change
                        else
                        begin
                            current_D_man_Info.ctm_info1 <= current_D_man_Info.ctm_info2;
                            current_D_man_Info.ctm_info2 <= 0;
                        end 
                    end
                    // current_res_id equal to ctm_info2.res_ID 
                    else
                    begin
                        // Wrong food ID ctm_info2
                        if(current_D_man_Info.ctm_info2.food_ID != current_food_ID_ser.d_food_ID)
                            current_D_man_Info <= current_D_man_Info;
                        // no wrong
                        else
                        begin
                            // ctm_info2
                            if(current_D_man_Info.ctm_info2.res_ID == current_res_id && current_D_man_Info.ctm_info2.food_ID == current_food_ID_ser.d_food_ID)
                                current_D_man_Info.ctm_info2 <= 0;
                            else
                                current_D_man_Info <= current_D_man_Info;
                        end 
                    end   
                end
            end
        end
        // Order
        else
            current_D_man_Info <= current_D_man_Info;
    end
    else
        current_D_man_Info <= current_D_man_Info;
end
// current_res_info
always_ff@(posedge clk or negedge inf.rst_n) 
begin
    if (!inf.rst_n)		
        current_res_info <= 0;
    else if(current_state == s_load_dram_d && inf.C_out_valid)
    begin 				
        if(current_act == Take)
        begin
            if(current_d_id == current_ctm_Info.res_ID)
                current_res_info <= inf.C_data_r[63:32];
            else
                current_res_info <= current_res_info;
        end
        else if(current_act == Cancel)
        begin
            if(current_d_id == current_res_id)
                current_res_info <= inf.C_data_r[63:32];
            else
                current_res_info <= current_res_info;
        end
        else
            current_res_info <= current_res_info;
    end
	else if(current_state == s_load_dram_r && inf.C_out_valid) 				
        current_res_info <= inf.C_data_r[63:32];
    else if(current_state == s_cal)
    begin
        // take current_res_info.ser_FOODs - current_ctm_Info.ser_food
        if(current_act == Take)
        begin
            // Delivery man busy
            if(current_D_man_Info.ctm_info1 != 0 && current_D_man_Info.ctm_info2 != 0)
                current_res_info <= current_res_info;
            else
            begin
                if(current_ctm_Info.food_ID == FOOD1)
                begin
                    // No food
                    if(current_res_info.ser_FOOD1 < current_ctm_Info.ser_food)
                        current_res_info <= current_res_info;
                    else
                        current_res_info.ser_FOOD1 <= current_res_info.ser_FOOD1 - current_ctm_Info.ser_food;
                end
                else if(current_ctm_Info.food_ID == FOOD2)
                begin
                    // No food
                    if(current_res_info.ser_FOOD2 < current_ctm_Info.ser_food)
                        current_res_info <= current_res_info;
                    else
                        current_res_info.ser_FOOD2 <= current_res_info.ser_FOOD2 - current_ctm_Info.ser_food;
                end
                else if(current_ctm_Info.food_ID == FOOD3)
                begin
                    // No food
                    if(current_res_info.ser_FOOD3 < current_ctm_Info.ser_food)
                        current_res_info <= current_res_info;
                    else
                        current_res_info.ser_FOOD3 <= current_res_info.ser_FOOD3 - current_ctm_Info.ser_food;
                end
                else
                    current_res_info <= current_res_info;
            end
        end
        else if(current_act == Order)
        begin
            // Restaurant busy
            if(food_total > current_res_info.limit_num_orders)
                current_res_info <= current_res_info;
            else
            begin
                if(current_food_ID_ser.d_food_ID == FOOD1)
                    current_res_info.ser_FOOD1 <= current_res_info.ser_FOOD1 + current_food_ID_ser.d_ser_food;
                else if(current_food_ID_ser.d_food_ID == FOOD2)
                    current_res_info.ser_FOOD2 <= current_res_info.ser_FOOD2 + current_food_ID_ser.d_ser_food;
                else if(current_food_ID_ser.d_food_ID == FOOD3)
                    current_res_info.ser_FOOD3 <= current_res_info.ser_FOOD3 + current_food_ID_ser.d_ser_food;
                else
                    current_res_info <= current_res_info;
            end    
        end
        // cancel Deliver
        else
            current_res_info <= current_res_info;
    end
    else
        current_res_info <= current_res_info;
end

//================================================================
// dram input data
//================================================================
// d_id_dram_d
always_ff@(posedge clk or negedge inf.rst_n) 
begin
    if(!inf.rst_n)		
        d_id_dram_d <= 0;
    else if(current_state == s_load_dram_d && inf.C_out_valid == 1)
        d_id_dram_d <= inf.C_data_r;
    else
        d_id_dram_d <= d_id_dram_d;
end
// res_id_dram_r
always_ff@(posedge clk or negedge inf.rst_n) 
begin
    if(!inf.rst_n)		
        res_id_dram_r <= 0;
	else if(current_state == s_load_dram_r && inf.C_out_valid == 1) 				
        res_id_dram_r <= inf.C_data_r;
    else
        res_id_dram_r <= res_id_dram_r;
end

//================================================================
// fsm s_deal
//================================================================
// out_value
always_ff@(posedge clk or negedge inf.rst_n) 
begin
    if(!inf.rst_n)		
        out_value <= 0;
	else if(current_state == s_deal) 		
    begin
        if(wrong_msg_flag == 0)
        begin
            if(current_act == Take)
                out_value <= {current_D_man_Info,current_res_info};
            else if(current_act == Deliver)
                out_value <= {current_D_man_Info,32'd0};
            else if(current_act == Order)
                out_value <= {32'd0,current_res_info};
            else if(current_act == Cancel)
                out_value <= {current_D_man_Info,32'd0};
            else
                out_value <= out_value;
        end
        else
            out_value <= 0;
    end	
    else
        out_value <= out_value;
end

//================================================================
// WRONG MESSAGE
//================================================================
// wrong_msg
always_ff @(posedge clk or negedge inf.rst_n) 
begin
    if(!inf.rst_n)		
        wrong_msg <= No_Err;
	else if(current_state == s_cal) 				
    begin
        if(current_act == Take)
        begin
            // Delivery man busy
            if(current_D_man_Info.ctm_info1 != 0 && current_D_man_Info.ctm_info2 != 0)
                wrong_msg <= D_man_busy;
            else
            begin
                if(current_ctm_Info.food_ID == FOOD1)
                begin
                    // No food
                    if(current_res_info.ser_FOOD1 < current_ctm_Info.ser_food)
                        wrong_msg <= No_Food;
                    else
                        wrong_msg <= No_Err;
                end
                else if(current_ctm_Info.food_ID == FOOD2)
                begin
                    // No food
                    if(current_res_info.ser_FOOD2 < current_ctm_Info.ser_food)
                        wrong_msg <= No_Food;
                    else
                        wrong_msg <= No_Err;
                end
                else if(current_ctm_Info.food_ID == FOOD3)
                begin
                    // No food
                    if(current_res_info.ser_FOOD3 < current_ctm_Info.ser_food)
                        wrong_msg <= No_Food;
                    else
                        wrong_msg <= No_Err;
                end
                else
                    wrong_msg <= No_Err;
            end
        end
        else if(current_act == Deliver)
        begin
            // No customers
            if(current_D_man_Info.ctm_info1 == 0 && current_D_man_Info.ctm_info2 == 0)
                wrong_msg <= No_customers;
            else
                wrong_msg <= No_Err;
        end
        else if(current_act == Order)
        begin
            // Restaurant is busy
            if(food_total >current_res_info.limit_num_orders)
                wrong_msg <= Res_busy;
            else
                wrong_msg <= No_Err;
        end
        else if(current_act == Cancel)
        begin
            // Wrong cancel
            if(current_D_man_Info.ctm_info1 == 0 && current_D_man_Info.ctm_info2 == 0)
                wrong_msg <= Wrong_cancel;
            else if(current_D_man_Info.ctm_info1 != 0 && current_D_man_Info.ctm_info2 == 0)
            begin
                // Wrong Restaurant ID
                if(current_D_man_Info.ctm_info1.res_ID != current_res_id)
                    wrong_msg <= Wrong_res_ID;
                else
                begin
                    // Wrong food ID
                    if(current_D_man_Info.ctm_info1.food_ID != current_food_ID_ser.d_food_ID)
                        wrong_msg <= Wrong_food_ID;
                    // no wrong
                    else
                        wrong_msg <= No_Err;
                end
            end
            else 
            begin
                // Wrong Restaurant ID
                if(current_D_man_Info.ctm_info1.res_ID != current_res_id && current_D_man_Info.ctm_info2.res_ID != current_res_id)
                    wrong_msg <= Wrong_res_ID;
                else
                begin
                    if(current_D_man_Info.ctm_info1.res_ID == current_res_id && current_D_man_Info.ctm_info2.res_ID == current_res_id)
                    begin
                        // Wrong food ID
                        if(current_D_man_Info.ctm_info1.food_ID != current_food_ID_ser.d_food_ID && current_D_man_Info.ctm_info2.food_ID != current_food_ID_ser.d_food_ID)
                            wrong_msg <= Wrong_food_ID;
                        // no wrong
                        else
                            wrong_msg <= No_Err;
                    end
                    // current_res_id equal to ctm_info1.res_ID 
                    else if(current_D_man_Info.ctm_info1.res_ID == current_res_id)
                    begin
                        // Wrong food ID
                        if(current_D_man_Info.ctm_info1.food_ID != current_food_ID_ser.d_food_ID)
                            wrong_msg <= Wrong_food_ID;
                        // no wrong
                        else
                            wrong_msg <= No_Err;
                    end
                    // current_res_id equal to ctm_info2.res_ID 
                    else
                    begin
                        // Wrong food ID
                        if(current_D_man_Info.ctm_info2.food_ID != current_food_ID_ser.d_food_ID)
                            wrong_msg <= Wrong_food_ID;
                        // no wrong
                        else
                            wrong_msg <= No_Err;
                    end
                end
            end
        end
        else
            wrong_msg <= No_Err;
    end
    else if(current_state == s_idle)
        wrong_msg <= No_Err;
    else
        wrong_msg <= wrong_msg;
end
// wrong_msg_flag
always_ff @(posedge clk or negedge inf.rst_n) 
begin
    if(!inf.rst_n)		
        wrong_msg_flag <= 0;
	else if(current_state == s_cal) 				
    begin
        if(current_act == Take)
        begin
            // Delivery man busy
            if(current_D_man_Info.ctm_info1 != 0 && current_D_man_Info.ctm_info2 != 0)
                wrong_msg_flag <= 1;
            else
            begin
                if(current_ctm_Info.food_ID == FOOD1)
                begin
                    // No food
                    if(current_res_info.ser_FOOD1 < current_ctm_Info.ser_food)
                        wrong_msg_flag <= 1;
                    else
                        wrong_msg_flag <= 0;
                end
                else if(current_ctm_Info.food_ID == FOOD2)
                begin
                    // No food
                    if(current_res_info.ser_FOOD2 < current_ctm_Info.ser_food)
                        wrong_msg_flag <= 1;
                    else
                        wrong_msg_flag <= 0;
                end
                else if(current_ctm_Info.food_ID == FOOD3)
                begin
                    // No food
                    if(current_res_info.ser_FOOD3 < current_ctm_Info.ser_food)
                        wrong_msg_flag <= 1;
                    else
                        wrong_msg_flag <= 0;
                end
                else
                    wrong_msg_flag <= 0;
            end
        end
        else if(current_act == Deliver)
        begin
            // No customers
            if(current_D_man_Info.ctm_info1 == 0 && current_D_man_Info.ctm_info2 == 0)
                wrong_msg_flag <= 1;
            else
                wrong_msg_flag <= 0;
        end
        else if(current_act == Order)
        begin
            // Restaurant is busy
            if(food_total >current_res_info.limit_num_orders)
                wrong_msg_flag <= 1;
            else
                wrong_msg_flag <= 0;
        end
        else if(current_act == Cancel)
        begin
            // Wrong cancel
            if(current_D_man_Info.ctm_info1 == 0 && current_D_man_Info.ctm_info2 == 0)
                wrong_msg_flag <= 1;
            else if(current_D_man_Info.ctm_info1 != 0 && current_D_man_Info.ctm_info2 == 0)
            begin
                // Wrong Restaurant ID
                if(current_D_man_Info.ctm_info1.res_ID != current_res_id)
                    wrong_msg_flag <= 1;
                else
                begin
                    // Wrong food ID
                    if(current_D_man_Info.ctm_info1.food_ID != current_food_ID_ser.d_food_ID)
                        wrong_msg_flag <= 1;
                    // no wrong
                    else
                        wrong_msg_flag <= 0;
                end
            end
            else 
            begin
                // Wrong Restaurant ID
                if(current_D_man_Info.ctm_info1.res_ID != current_res_id && current_D_man_Info.ctm_info2.res_ID != current_res_id)
                    wrong_msg_flag <= 1;
                else
                begin
                    // current_res_id equal to ctm_info1.res_ID 
                    if(current_D_man_Info.ctm_info1.res_ID == current_res_id && current_D_man_Info.ctm_info2.res_ID == current_res_id)
                    begin
                        // Wrong food ID
                        if(current_D_man_Info.ctm_info1.food_ID != current_food_ID_ser.d_food_ID && current_D_man_Info.ctm_info2.food_ID != current_food_ID_ser.d_food_ID)
                            wrong_msg_flag <= 1;
                        // no wrong
                        else
                            wrong_msg_flag <= 0;
                    end
                    // current_res_id equal to ctm_info1.res_ID 
                    else if(current_D_man_Info.ctm_info1.res_ID == current_res_id)
                    begin
                        // Wrong food ID
                        if(current_D_man_Info.ctm_info1.food_ID != current_food_ID_ser.d_food_ID)
                            wrong_msg_flag <= 1;
                        // no wrong
                        else
                            wrong_msg_flag <= 0;
                    end
                    // current_res_id equal to ctm_info2.res_ID 
                    else
                    begin
                        // Wrong food ID
                        if(current_D_man_Info.ctm_info2.food_ID != current_food_ID_ser.d_food_ID)
                            wrong_msg_flag <= 1;
                        // no wrong
                        else
                            wrong_msg_flag <= 0;
                    end
                end
            end
        end
        else
            wrong_msg_flag <= 0;
    end
    else if(current_state == s_out)
        wrong_msg_flag <= 0;
    else
        wrong_msg_flag <= wrong_msg_flag;
end

//================================================================
// OUTPUT PORT to bridge
//================================================================
/// load_dram_d_flag load_dram_r_flag write_dram_d_flag write_dram_r_flag ///
// load_dram_d_flag
always_ff@(posedge clk or negedge inf.rst_n) 
begin
    if(!inf.rst_n)		
        load_dram_d_flag <= 0;
	else if(current_state == s_load_dram_d) 				
        load_dram_d_flag <= 1;
    else
        load_dram_d_flag <= 0;
end
// load_dram_r_flag
always_ff@(posedge clk or negedge inf.rst_n) 
begin
    if(!inf.rst_n)		
        load_dram_r_flag <= 0;
	else if(current_state == s_load_dram_r) 				
        load_dram_r_flag <= 1;
    else
        load_dram_r_flag <= 0;
end
// write_dram_d_flag
always_ff@(posedge clk or negedge inf.rst_n) 
begin
    if(!inf.rst_n)		
        write_dram_d_flag <= 0;
	else if(current_state == s_write_dram_d) 				
        write_dram_d_flag <= 1;
    else
        write_dram_d_flag <= 0;
end
// write_dram_r_flag
always_ff@(posedge clk or negedge inf.rst_n) 
begin
    if(!inf.rst_n)		
        write_dram_r_flag <= 0;
	else if(current_state == s_write_dram_r) 				
        write_dram_r_flag <= 1;
    else
        write_dram_r_flag <= 0;
end

/// output port ///
// inf.C_addr
always_ff@(posedge clk or negedge inf.rst_n) 
begin
    if(!inf.rst_n)		
        inf.C_addr <= 0;
	else if(current_state == s_load_dram_d) 				
        inf.C_addr <= current_d_id;
    else if(current_state == s_load_dram_r) 
    begin			
        if(current_act == Take)
            inf.C_addr <= current_ctm_Info.res_ID;	
        else
            inf.C_addr <= current_res_id;
    end
    else if(current_state == s_write_dram_d) 				
        inf.C_addr <= current_d_id;
    else if(current_state == s_write_dram_r) 				
    begin	
        if(current_act == Take)
            inf.C_addr <= current_ctm_Info.res_ID;	
        else			
            inf.C_addr <= current_res_id;
    end
    else
        inf.C_addr <= inf.C_addr;
end
// inf.C_r_wb
always_ff@(posedge clk or negedge inf.rst_n) 
begin
    if(!inf.rst_n)		
        inf.C_r_wb <= 0;
	else if(current_state == s_load_dram_d) 				
        inf.C_r_wb <= 1;
    else if(current_state == s_load_dram_r) 				
        inf.C_r_wb <= 1;
    else if(current_state == s_write_dram_d) 				
        inf.C_r_wb <= 0;
    else if(current_state == s_write_dram_r) 				
        inf.C_r_wb <= 0;
    else
        inf.C_r_wb <= inf.C_r_wb;
end
// inf.C_in_valid
always_ff@(posedge clk or negedge inf.rst_n) 
begin
    if(!inf.rst_n)		
        inf.C_in_valid <= 0;
	else if(current_state == s_load_dram_d && load_dram_d_flag == 0) 				
        inf.C_in_valid <= 1;
    else if(current_state == s_load_dram_r && load_dram_r_flag == 0) 				
        inf.C_in_valid <= 1;
    else if(current_state == s_write_dram_d && write_dram_d_flag == 0) 				
        inf.C_in_valid <= 1;
    else if(current_state == s_write_dram_r && write_dram_r_flag == 0) 				
        inf.C_in_valid <= 1;
    else
        inf.C_in_valid <= 0;
end
// inf.C_data_w
always_ff@(posedge clk or negedge inf.rst_n) 
begin
    if(!inf.rst_n)		
        inf.C_data_w <= 0;				
    else if(current_state == s_write_dram_d)
    begin 		
        if(current_act == Take)
        begin
            if(current_d_id == current_ctm_Info.res_ID)
                inf.C_data_w <= {current_res_info,current_D_man_Info};
            else
                inf.C_data_w <= {d_id_dram_d[63:32],current_D_man_Info};
        end
        else if(current_act == Cancel)
        begin
            if(current_d_id == current_res_id)
                inf.C_data_w <= {current_res_info,current_D_man_Info};
            else
                inf.C_data_w <= {d_id_dram_d[63:32],current_D_man_Info};
        end	
        else	
            inf.C_data_w <= {d_id_dram_d[63:32],current_D_man_Info};
    end
    else if(current_state == s_write_dram_r) 	
    begin			
        inf.C_data_w <= {current_res_info,res_id_dram_r[31:0]};
    end
    else
        inf.C_data_w <= inf.C_data_w;
end

//================================================================
// OUTPUT PORT to pattern
//================================================================
// inf.out_valid
always_ff@(posedge clk or negedge inf.rst_n) 
begin
    if(!inf.rst_n)		
        inf.out_valid <= 0;
	else if(current_state == s_out) 				
        inf.out_valid <= 1;
    else
        inf.out_valid <= 0;
end
// inf.out_info
always_ff@(posedge clk or negedge inf.rst_n) 
begin
    if(!inf.rst_n)		
        inf.out_info <= 0;
	else if(current_state == s_out)
    begin 			
        if(inf.complete == 0)	
            inf.out_info <= 0;
        else
            inf.out_info <= out_value;
    end
    else
        inf.out_info <= 0;
end
// inf.err_msg
always_ff @(posedge clk or negedge inf.rst_n) 
begin
    if(!inf.rst_n)		
        inf.err_msg <= No_Err;
    else if(wrong_msg_flag == 1)
        inf.err_msg <= wrong_msg;
    else
        inf.err_msg <= No_Err;
end
// inf.complete
always_ff @(posedge clk or negedge inf.rst_n) 
begin
    if(!inf.rst_n)		
        inf.complete <= 0;
    else if(wrong_msg_flag == 1)
        inf.complete <= 0;
    else
        inf.complete <= 1;
end


endmodule