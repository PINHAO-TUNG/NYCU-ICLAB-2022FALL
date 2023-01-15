`include "../00_TESTBED/pseudo_DRAM.sv"
`include "Usertype_FD.sv"

program automatic PATTERN(input clk, INF.PATTERN inf);
import usertype::*;

// Dram
parameter DRAM_p_r = "../00_TESTBED/DRAM/dram.dat";
logic [7:0] golden_DRAM[((65536+256*8)-1):65536];
initial $readmemh(DRAM_p_r, golden_DRAM);


logic [7:0]      golden_id;
Delivery_man_id  golden_d_id;
Restaurant_id    golden_res_id;
Delivery_man_id  before_d_id;
Restaurant_id    before_res_id;
     
Action           golden_act;
Action           before_act;
Ctm_Info         golden_ctm_Info;
food_ID_servings golden_food_ID_ser;

D_man_Info       golden_d_man_Info;
res_info         golden_res_info;

logic [12:0] food_total;

// Dram
// from dram
logic [63:0]     id_dram;
// dram value trans
logic [63:0]     id_dram_trans;

// golden output value
Error_Msg        golden_err_msg;
logic            golden_complete;

logic [63:0]     golden_out_info;

//cnt
integer wait_out_valid_cnt;
integer total_latency;
// signal
integer act, d_id;
integer i;

integer pat_num;

initial begin
    reset_signal_task;

    act             = 0;
    d_id            = 0;
	golden_id       = 0;
	golden_d_id     = 0;
	golden_res_id   = 0;
    before_act      = No_action;
    before_d_id     = 255;
    before_res_id   = 255;

	for(pat_num = 0; pat_num < 20000; pat_num = pat_num +1)
	begin
		@(negedge clk);
        act = $urandom_range(1,4);
		input_task;
        if(act == 3)
        begin
            d_id = d_id;
        end
        else
        begin
            d_id = d_id + 1;
        end
    end	

	pass_pattern;
    $finish;
end


task reset_signal_task; 
    begin 
        #(0.5);  inf.rst_n = 0;

        // rst pattern output
        inf.id_valid       = 0;	
        inf.act_valid      = 0;
        inf.cus_valid      = 0;
        inf.res_valid      = 0;
        inf.food_valid     = 0;
        inf.D              = 0;

        // initial 
        wait_out_valid_cnt = 0;
        total_latency      = 0;

        #(5);
        
        //check all output signals
        if((inf.err_msg!==No_Err)||(inf.complete!== 0)||(inf.out_valid!== 0)||(inf.out_info!==0)) 
        begin
            $finish;
        end

        #(5);  inf.rst_n   = 1;
    end 
endtask

task input_task;
    begin
        // decide act
		act_task;
        // decide id
        if(d_id < 256)
        begin
            golden_d_id   = d_id;
	        golden_res_id = d_id;
        end
        else
        begin
            golden_d_id   = $urandom_range(0,255);
            golden_res_id = golden_d_id;
        end

		if(golden_act==Take)
        begin
            golden_ctm_Info.ctm_status = $urandom_range(0,1);
            golden_ctm_Info.res_ID     = golden_res_id;
            golden_ctm_Info.food_ID    = $urandom_range(1,3);
            golden_ctm_Info.ser_food   = $urandom_range(1,15);
            get_d_id_dram_task;
			op_take_task;
            write_d_id_dram_task;
		end
		else if(golden_act==Deliver)
        begin
            get_d_id_dram_task;
			op_deliver_task;
            write_d_id_dram_task;
		end	
		else if(golden_act==Order)
        begin
            golden_food_ID_ser.d_food_ID  = $urandom_range(1,3);
            golden_food_ID_ser.d_ser_food = $urandom_range(1,15);
            get_res_id_dram_task;
			op_order_task;
            write_res_id_dram_task;
		end	
		else if(golden_act==Cancel)
        begin
            golden_food_ID_ser.d_food_ID  = $urandom_range(1,3);
            golden_food_ID_ser.d_ser_food = 4'd0;
            get_d_id_dram_task;
			op_cancel_task;
            write_d_id_dram_task;
		end	
		wait_out_valid;
		check_output_signals;	
    end 
endtask

task act_task;
    begin
        case(act)
            1:golden_act=Take;
            2:golden_act=Deliver;
            3:golden_act=Order;
            4:golden_act=Cancel;
            default:golden_act=Take;
        endcase	
    end 
endtask

// get dram data from dram array
task get_d_id_dram_task;
    begin
        // get d man info and res info
        golden_d_man_Info = {golden_DRAM[65536+golden_d_id*8+4],golden_DRAM[65536+golden_d_id*8+5],
                             golden_DRAM[65536+golden_d_id*8+6],golden_DRAM[65536+golden_d_id*8+7]};
        golden_res_info   = {golden_DRAM[65536+golden_d_id*8+0],golden_DRAM[65536+golden_d_id*8+1],
                             golden_DRAM[65536+golden_d_id*8+2],golden_DRAM[65536+golden_d_id*8+3]};
    end
endtask

// write dram data to dram array
task write_d_id_dram_task;
    begin
        if(golden_err_msg == No_Err)
        begin
            // write back dram
            golden_DRAM[65536+golden_d_id*8+7] = golden_d_man_Info[ 7: 0];
            golden_DRAM[65536+golden_d_id*8+6] = golden_d_man_Info[15: 8];
            golden_DRAM[65536+golden_d_id*8+5] = golden_d_man_Info[23:16];
            golden_DRAM[65536+golden_d_id*8+4] = golden_d_man_Info[31:24];
            golden_DRAM[65536+golden_d_id*8+3] = golden_res_info[ 7: 0];
            golden_DRAM[65536+golden_d_id*8+2] = golden_res_info[15: 8];
            golden_DRAM[65536+golden_d_id*8+1] = golden_res_info[23:16];
            golden_DRAM[65536+golden_d_id*8+0] = golden_res_info[31:24];
        end
    end
endtask

task get_res_id_dram_task;
    begin
        // get d man info and res info
        golden_d_man_Info = {golden_DRAM[65536+golden_res_id*8+4],golden_DRAM[65536+golden_res_id*8+5],
                             golden_DRAM[65536+golden_res_id*8+6],golden_DRAM[65536+golden_res_id*8+7]};
        golden_res_info   = {golden_DRAM[65536+golden_res_id*8+0],golden_DRAM[65536+golden_res_id*8+1],
                             golden_DRAM[65536+golden_res_id*8+2],golden_DRAM[65536+golden_res_id*8+3]};
    end
endtask

// write dram data to dram array
task write_res_id_dram_task;
    begin
        if(golden_err_msg == No_Err)
        begin
            // write back dram
            golden_DRAM[65536+golden_res_id*8+7] = golden_d_man_Info[ 7: 0];
            golden_DRAM[65536+golden_res_id*8+6] = golden_d_man_Info[15: 8];
            golden_DRAM[65536+golden_res_id*8+5] = golden_d_man_Info[23:16];
            golden_DRAM[65536+golden_res_id*8+4] = golden_d_man_Info[31:24];
            golden_DRAM[65536+golden_res_id*8+3] = golden_res_info[ 7: 0];
            golden_DRAM[65536+golden_res_id*8+2] = golden_res_info[15: 8];
            golden_DRAM[65536+golden_res_id*8+1] = golden_res_info[23:16];
            golden_DRAM[65536+golden_res_id*8+0] = golden_res_info[31:24];
        end
    end
endtask

// op take  
// send d_id ctm_info
// need take d_man_info and res_info_data
// check d_man_info and res_info
task op_take_task;
    begin
        /// send input signal ///
        // take if needed
        if(before_act == golden_act && before_d_id == golden_d_id)
        begin
            // send input value        action
            @(negedge clk);
            inf.act_valid = 1;
            inf.D         = {12'd0,golden_act};
            // end of send input value
            @(negedge clk);	
            inf.act_valid = 0;
            inf.D         = 12'bx;
            // send input value        ctm info
            @(negedge clk);
            inf.cus_valid = 1;
            inf.D         = {golden_ctm_Info};
            // end of send input value
            @(negedge clk);	
            inf.cus_valid = 0;
            inf.D         = 12'bx;
        end
        // take
        else
        begin
            // send input value        action
            @(negedge clk);
            inf.act_valid = 1;
            inf.D         = {12'd0,golden_act};
            // end of send input value
            @(negedge clk);	
            inf.act_valid = 0;
            inf.D         = 12'bx;
            // send input value        d id
            @(negedge clk);
            inf.id_valid = 1;
            inf.D        = {8'd0,golden_d_id};
            // end of send input value
            @(negedge clk);		
            inf.id_valid = 0;
            inf.D        = 12'bx;
            // send input value        ctm info
			@(negedge clk);
            inf.cus_valid = 1;
            inf.D         = {golden_ctm_Info};
            // end of send input value
            @(negedge clk);	
            inf.cus_valid = 0;
            inf.D         = 12'bx;
        end
        /// end of send input signal ///

        /// cal ///
        if(golden_d_man_Info.ctm_info1 == 0 && golden_d_man_Info.ctm_info2 == 0)
        begin
            if(golden_ctm_Info.food_ID == FOOD1)
            begin
                // No food
                if(golden_res_info.ser_FOOD1 < golden_ctm_Info.ser_food)
                begin
                    // output signal
                    golden_err_msg  = No_Food;
                    golden_complete = 0;
                    golden_out_info = 0;
                end
                else
                begin
                    golden_d_man_Info.ctm_info1 = golden_ctm_Info;
                    golden_res_info.ser_FOOD1 = golden_res_info.ser_FOOD1 - golden_ctm_Info.ser_food;
                    // output signal
                    golden_err_msg  = No_Err;
                    golden_complete = 1;
                    golden_out_info = {golden_d_man_Info,golden_res_info};
                end
            end
            else if(golden_ctm_Info.food_ID == FOOD2)
            begin
                // No food
                if(golden_res_info.ser_FOOD2 < golden_ctm_Info.ser_food)
                begin
                    // output signal
                    golden_err_msg  = No_Food;
                    golden_complete = 0;
                    golden_out_info = 0;
                end
                else
                begin
                    golden_d_man_Info.ctm_info1 = golden_ctm_Info;
                    golden_res_info.ser_FOOD2 = golden_res_info.ser_FOOD2 - golden_ctm_Info.ser_food;
                    // output signal
                    golden_err_msg  = No_Err;
                    golden_complete = 1;
                    golden_out_info = {golden_d_man_Info,golden_res_info};
                end
            end
            else if(golden_ctm_Info.food_ID == FOOD3)
            begin
                // No food
                if(golden_res_info.ser_FOOD3 < golden_ctm_Info.ser_food)
                begin
                    // output signal
                    golden_err_msg  = No_Food;
                    golden_complete = 0;
                    golden_out_info = 0;
                end
                else
                begin
                    golden_d_man_Info.ctm_info1 = golden_ctm_Info;
                    golden_res_info.ser_FOOD3 = golden_res_info.ser_FOOD3 - golden_ctm_Info.ser_food;
                    // output signal
                    golden_err_msg  = No_Err;
                    golden_complete = 1;
                    golden_out_info = {golden_d_man_Info,golden_res_info};
                end
            end
        end
        else if(golden_d_man_Info.ctm_info1 != 0 && golden_d_man_Info.ctm_info2 == 0)
        begin
            if(golden_d_man_Info.ctm_info1.ctm_status == VIP)
            begin
                if(golden_ctm_Info.food_ID == FOOD1)
                begin
                    // No food
                    if(golden_res_info.ser_FOOD1 < golden_ctm_Info.ser_food)
                    begin
                        // output signal
                        golden_err_msg  = No_Food;
                        golden_complete = 0;
                        golden_out_info = 0;
                    end
                    else
                    begin
                        golden_d_man_Info.ctm_info2 = golden_ctm_Info;
                        golden_res_info.ser_FOOD1 = golden_res_info.ser_FOOD1 - golden_ctm_Info.ser_food;
                        // output signal
                        golden_err_msg  = No_Err;
                        golden_complete = 1;
                        golden_out_info = {golden_d_man_Info,golden_res_info};
                    end
                end
                else if(golden_ctm_Info.food_ID == FOOD2)
                begin
                    // No food
                    if(golden_res_info.ser_FOOD2 < golden_ctm_Info.ser_food)
                    begin
                        // output signal
                        golden_err_msg  = No_Food;
                        golden_complete = 0;
                        golden_out_info = 0;
                    end
                    else
                    begin
                        golden_d_man_Info.ctm_info2 = golden_ctm_Info;
                        golden_res_info.ser_FOOD2 = golden_res_info.ser_FOOD2 - golden_ctm_Info.ser_food;
                        // output signal
                        golden_err_msg  = No_Err;
                        golden_complete = 1;
                        golden_out_info = {golden_d_man_Info,golden_res_info};
                    end
                end
                else if(golden_ctm_Info.food_ID == FOOD3)
                begin
                    // No food
                    if(golden_res_info.ser_FOOD3 < golden_ctm_Info.ser_food)
                    begin
                        // output signal
                        golden_err_msg  = No_Food;
                        golden_complete = 0;
                        golden_out_info = 0;
                    end
                    else
                    begin
                        golden_d_man_Info.ctm_info2 = golden_ctm_Info;
                        golden_res_info.ser_FOOD3 = golden_res_info.ser_FOOD3 - golden_ctm_Info.ser_food;
                        // output signal
                        golden_err_msg  = No_Err;
                        golden_complete = 1;
                        golden_out_info = {golden_d_man_Info,golden_res_info};
                    end
                end
            end
            else
            begin
                if(golden_ctm_Info.food_ID == FOOD1)
                begin
                    // No food
                    if(golden_res_info.ser_FOOD1 < golden_ctm_Info.ser_food)
                    begin
                        // output signal
                        golden_err_msg  = No_Food;
                        golden_complete = 0;
                        golden_out_info = 0;
                    end
                    else
                    begin
                        if(golden_ctm_Info.ctm_status == VIP)
                        begin
                            golden_d_man_Info.ctm_info2 = golden_d_man_Info.ctm_info1;
                            golden_d_man_Info.ctm_info1 = golden_ctm_Info;
                        end
                        else
                        begin
                            golden_d_man_Info.ctm_info2 = golden_ctm_Info;
                        end
                        golden_res_info.ser_FOOD1 = golden_res_info.ser_FOOD1 - golden_ctm_Info.ser_food;
                        // output signal
                        golden_err_msg  = No_Err;
                        golden_complete = 1;
                        golden_out_info = {golden_d_man_Info,golden_res_info};
                    end
                end
                else if(golden_ctm_Info.food_ID == FOOD2)
                begin
                    // No food
                    if(golden_res_info.ser_FOOD2 < golden_ctm_Info.ser_food)
                    begin
                        // output signal
                        golden_err_msg  = No_Food;
                        golden_complete = 0;
                        golden_out_info = 0;
                    end
                    else
                    begin
                        if(golden_ctm_Info.ctm_status == VIP)
                        begin
                            golden_d_man_Info.ctm_info2 = golden_d_man_Info.ctm_info1;
                            golden_d_man_Info.ctm_info1 = golden_ctm_Info;
                        end
                        else
                        begin
                            golden_d_man_Info.ctm_info2 = golden_ctm_Info;
                        end
                        golden_res_info.ser_FOOD2 = golden_res_info.ser_FOOD2 - golden_ctm_Info.ser_food;
                        // output signal
                        golden_err_msg  = No_Err;
                        golden_complete = 1;
                        golden_out_info = {golden_d_man_Info,golden_res_info};
                    end
                end
                else if(golden_ctm_Info.food_ID == FOOD3)
                begin
                    // No food
                    if(golden_res_info.ser_FOOD3 < golden_ctm_Info.ser_food)
                    begin
                        // output signal
                        golden_err_msg  = No_Food;
                        golden_complete = 0;
                        golden_out_info = 0;
                    end
                    else
                    begin
                        if(golden_ctm_Info.ctm_status == VIP)
                        begin
                            golden_d_man_Info.ctm_info2 = golden_d_man_Info.ctm_info1;
                            golden_d_man_Info.ctm_info1 = golden_ctm_Info;
                        end
                        else
                        begin
                            golden_d_man_Info.ctm_info2 = golden_ctm_Info;
                        end
                        golden_res_info.ser_FOOD3 = golden_res_info.ser_FOOD3 - golden_ctm_Info.ser_food;
                        // output signal
                        golden_err_msg  = No_Err;
                        golden_complete = 1;
                        golden_out_info = {golden_d_man_Info,golden_res_info};
                    end
                end
            end
        end
        else if(golden_d_man_Info.ctm_info1 == 0 && golden_d_man_Info.ctm_info2 != 0)
        begin
            if(golden_d_man_Info.ctm_info1.ctm_status == VIP)
            begin
                if(golden_ctm_Info.food_ID == FOOD1)
                begin
                    // No food
                    if(golden_res_info.ser_FOOD1 < golden_ctm_Info.ser_food)
                    begin
                        // output signal
                        golden_err_msg  = No_Food;
                        golden_complete = 0;
                        golden_out_info = 0;
                    end
                    else
                    begin
                        golden_d_man_Info.ctm_info2 = golden_ctm_Info;
                        golden_res_info.ser_FOOD1 = golden_res_info.ser_FOOD1 - golden_ctm_Info.ser_food;
                        // output signal
                        golden_err_msg  = No_Err;
                        golden_complete = 1;
                        golden_out_info = {golden_d_man_Info,golden_res_info};
                    end
                end
                else if(golden_ctm_Info.food_ID == FOOD2)
                begin
                    // No food
                    if(golden_res_info.ser_FOOD2 < golden_ctm_Info.ser_food)
                    begin
                        // output signal
                        golden_err_msg  = No_Food;
                        golden_complete = 0;
                        golden_out_info = 0;
                    end
                    else
                    begin
                        golden_d_man_Info.ctm_info2 = golden_ctm_Info;
                        golden_res_info.ser_FOOD2 = golden_res_info.ser_FOOD2 - golden_ctm_Info.ser_food;
                        // output signal
                        golden_err_msg  = No_Err;
                        golden_complete = 1;
                        golden_out_info = {golden_d_man_Info,golden_res_info};
                    end
                end
                else if(golden_ctm_Info.food_ID == FOOD3)
                begin
                    // No food
                    if(golden_res_info.ser_FOOD3 < golden_ctm_Info.ser_food)
                    begin
                        // output signal
                        golden_err_msg  = No_Food;
                        golden_complete = 0;
                        golden_out_info = 0;
                    end
                    else
                    begin
                        golden_d_man_Info.ctm_info2 = golden_ctm_Info;
                        golden_res_info.ser_FOOD3 = golden_res_info.ser_FOOD3 - golden_ctm_Info.ser_food;
                        // output signal
                        golden_err_msg  = No_Err;
                        golden_complete = 1;
                        golden_out_info = {golden_d_man_Info,golden_res_info};
                    end
                end
            end
            else
            begin
                if(golden_ctm_Info.food_ID == FOOD1)
                begin
                    // No food
                    if(golden_res_info.ser_FOOD1 < golden_ctm_Info.ser_food)
                    begin
                        // output signal
                        golden_err_msg  = No_Food;
                        golden_complete = 0;
                        golden_out_info = 0;
                    end
                    else
                    begin
                        if(golden_ctm_Info.ctm_status == VIP)
                        begin
                            golden_d_man_Info.ctm_info2 = golden_d_man_Info.ctm_info1;
                            golden_d_man_Info.ctm_info1 = golden_ctm_Info;
                        end
                        else
                        begin
                            golden_d_man_Info.ctm_info2 = golden_ctm_Info;
                        end
                        golden_res_info.ser_FOOD1 = golden_res_info.ser_FOOD1 - golden_ctm_Info.ser_food;
                        // output signal
                        golden_err_msg  = No_Err;
                        golden_complete = 1;
                        golden_out_info = {golden_d_man_Info,golden_res_info};
                    end
                end
                else if(golden_ctm_Info.food_ID == FOOD2)
                begin
                    // No food
                    if(golden_res_info.ser_FOOD2 < golden_ctm_Info.ser_food)
                    begin
                        // output signal
                        golden_err_msg  = No_Food;
                        golden_complete = 0;
                        golden_out_info = 0;
                    end
                    else
                    begin
                        if(golden_ctm_Info.ctm_status == VIP)
                        begin
                            golden_d_man_Info.ctm_info2 = golden_d_man_Info.ctm_info1;
                            golden_d_man_Info.ctm_info1 = golden_ctm_Info;
                        end
                        else
                        begin
                            golden_d_man_Info.ctm_info2 = golden_ctm_Info;
                        end
                        golden_res_info.ser_FOOD2 = golden_res_info.ser_FOOD2 - golden_ctm_Info.ser_food;
                        // output signal
                        golden_err_msg  = No_Err;
                        golden_complete = 1;
                        golden_out_info = {golden_d_man_Info,golden_res_info};
                    end
                end
                else if(golden_ctm_Info.food_ID == FOOD3)
                begin
                    // No food
                    if(golden_res_info.ser_FOOD3 < golden_ctm_Info.ser_food)
                    begin
                        // output signal
                        golden_err_msg  = No_Food;
                        golden_complete = 0;
                        golden_out_info = 0;
                    end
                    else
                    begin
                        if(golden_ctm_Info.ctm_status == VIP)
                        begin
                            golden_d_man_Info.ctm_info2 = golden_d_man_Info.ctm_info1;
                            golden_d_man_Info.ctm_info1 = golden_ctm_Info;
                        end
                        else
                        begin
                            golden_d_man_Info.ctm_info2 = golden_ctm_Info;
                        end
                        golden_res_info.ser_FOOD3 = golden_res_info.ser_FOOD3 - golden_ctm_Info.ser_food;
                        // output signal
                        golden_err_msg  = No_Err;
                        golden_complete = 1;
                        golden_out_info = {golden_d_man_Info,golden_res_info};
                    end
                end
            end
        end
        // Delivery man busy
        else 
        begin
            // output signal
            golden_err_msg  = D_man_busy;
            golden_complete = 0;
            golden_out_info = 0;
        end

        before_d_id   = golden_d_id;
        before_res_id = golden_res_id;
        before_act    = golden_act;
    end 
endtask

// op deliver 
// send d_id
// need take d_info_data
// check d_info
task op_deliver_task;
    begin
        /// send input signal ///
        // send input value        action
        @(negedge clk);
        inf.act_valid = 1;
        inf.D         = {12'd0,golden_act};
        // end of send input value
        @(negedge clk);	
        inf.act_valid = 0;
        inf.D         = 12'bx;
        // send input value        d_id
        @(negedge clk);
        inf.id_valid = 1;
        inf.D        = {8'd0,golden_d_id};
        // end of send input value
        @(negedge clk);		
        inf.id_valid = 0;
        inf.D        = 12'bx;
        /// end of send input signal ///

        /// cal ///
        if(golden_d_man_Info.ctm_info1 !== 0 && golden_d_man_Info.ctm_info2 === 0)
        begin
            golden_d_man_Info.ctm_info1 = 0;
            // output signal
            golden_err_msg  = No_Err;
            golden_complete = 1;
            golden_out_info = {golden_d_man_Info,32'd0};
        end
        else if(golden_d_man_Info.ctm_info1 === 0 && golden_d_man_Info.ctm_info2  !== 0)
        begin
            golden_d_man_Info.ctm_info1 = golden_d_man_Info.ctm_info2;
            golden_d_man_Info.ctm_info2 = 0;
            // output signal
            golden_err_msg  = No_Err;
            golden_complete = 1;
            golden_out_info = {golden_d_man_Info,32'd0};
        end
        else if(golden_d_man_Info.ctm_info1  !== 0 && golden_d_man_Info.ctm_info2  !== 0)
        begin
            golden_d_man_Info.ctm_info1 = golden_d_man_Info.ctm_info2;
            golden_d_man_Info.ctm_info2 = 0;
            // output signal
            golden_err_msg  = No_Err;
            golden_complete = 1;
            golden_out_info = {golden_d_man_Info,32'd0};
        end
        else 
        begin
            golden_d_man_Info = golden_d_man_Info;
            // output signal
            golden_err_msg  = No_customers;
            golden_complete = 0;
            golden_out_info = 0;
        end
        before_d_id   = golden_d_id;
        before_res_id = golden_res_id;
        before_act    = golden_act;
    end 
endtask

// op order 
// send res_id food_id_ser
// need take res_info_data
// check res_info
task op_order_task;
    begin
        /// send input signal ///
        // oeder if needed
        if(before_act == golden_act && before_res_id == golden_res_id)
        begin
            // send input value        action
            @(negedge clk);
            inf.act_valid = 1;
            inf.D         = {12'd0,golden_act};
            // end of send input value
            @(negedge clk);	
            inf.act_valid = 0;
            inf.D         = 12'bx;
            // send input value        food id ser
            @(negedge clk);
            inf.food_valid = 1;
            inf.D          = {10'd0,golden_food_ID_ser};
            // end of send input value
            @(negedge clk);	
            inf.food_valid = 0;
            inf.D          = 12'bx;
        end
        // order
        else
        begin
            // send input value        action
            @(negedge clk);
            inf.act_valid = 1;
            inf.D         = {12'd0,golden_act};
            // end of send input value
            @(negedge clk);	
            inf.act_valid = 0;
            inf.D         = 12'bx;
            // send input value        res id
            @(negedge clk);
            inf.res_valid = 1;
            inf.D        = {8'd0,golden_res_id};
            // end of send input value
            @(negedge clk);		
            inf.res_valid = 0;
            inf.D         = 12'bx;
            // send input value        food id ser
            @(negedge clk);
            inf.food_valid = 1;
            inf.D          = {10'd0,golden_food_ID_ser};
            // end of send input value
            @(negedge clk);	
            inf.food_valid = 0;
            inf.D          = 12'bx;
        end
        /// end of send input signal ///

        
        food_total = golden_res_info.ser_FOOD1 + golden_res_info.ser_FOOD2 + 
                    golden_res_info.ser_FOOD3 + golden_food_ID_ser.d_ser_food;
        /// cal ///
        if(food_total > golden_res_info.limit_num_orders)
        begin
            // output signal
            golden_err_msg  = Res_busy;
            golden_complete = 0;
            golden_out_info = 0;
        end
        else
        begin
            if(golden_food_ID_ser.d_food_ID == FOOD1)
            begin
                golden_res_info.ser_FOOD1 = golden_res_info.ser_FOOD1 + golden_food_ID_ser.d_ser_food;
                // output signal
                golden_err_msg  = No_Err;
                golden_complete = 1;
                golden_out_info = {32'd0,golden_res_info};
            end
            else if(golden_food_ID_ser.d_food_ID == FOOD2)
            begin
                golden_res_info.ser_FOOD2 = golden_res_info.ser_FOOD2 + golden_food_ID_ser.d_ser_food;
                // output signal
                golden_err_msg  = No_Err;
                golden_complete = 1;
                golden_out_info = {32'd0,golden_res_info};
            end
            else if(golden_food_ID_ser.d_food_ID == FOOD3)
            begin
                golden_res_info.ser_FOOD3 = golden_res_info.ser_FOOD3 + golden_food_ID_ser.d_ser_food;
                // output signal
                golden_err_msg  = No_Err;
                golden_complete = 1;
                golden_out_info = {32'd0,golden_res_info};
            end
            else
            begin
                // output signal
                golden_err_msg  = Res_busy;
                golden_complete = 0;
                golden_out_info = 0;
            end
        end

        before_d_id   = golden_d_id;
        before_res_id = golden_res_id;
        before_act    = golden_act;
    end 
endtask

// op cancel  
// send res_id food_id_ser d_id
// need take d_man_info and res_info_data
// check d_man_info
task op_cancel_task;
    begin
        /// send input signal ///
        // send input value        action
        @(negedge clk);
        inf.act_valid = 1;
        inf.D         = {12'd0,golden_act};
        // end of send input value
        @(negedge clk);	
        inf.act_valid = 0;
        inf.D         = 12'bx;
        // send input value        res id
        @(negedge clk);
        inf.res_valid = 1;
        inf.D         = {8'd0,golden_res_id};
        // end of send input value
        @(negedge clk);		
        inf.res_valid = 0;
        inf.D         = 12'bx;
        // send input value        food id ser
        @(negedge clk);
        inf.food_valid = 1;
        inf.D          = {10'd0,golden_food_ID_ser};
        // end of send input value
        @(negedge clk);	
        inf.food_valid = 0;
        inf.D          = 12'bx;
        // send input value        d id
        @(negedge clk);
        inf.id_valid = 1;
        inf.D        = {8'd0,golden_d_id};
        // end of send input value
        @(negedge clk);		
        inf.id_valid = 0;
        inf.D        = 12'bx;
        /// end of send input signal ///

        /// cal ///
        // Wrong cancel
        if(golden_d_man_Info.ctm_info1 == 0 && golden_d_man_Info.ctm_info2 == 0)
        begin
            // output signal
            golden_err_msg  = Wrong_cancel;
            golden_complete = 0;
            golden_out_info = 0;
        end
        else
        begin
            // Wrong Restaurant ID     ctm_info1.res_ID and ctm_info2.res_ID none equal to golden_res_id
            if(golden_d_man_Info.ctm_info1.res_ID != golden_res_id && golden_d_man_Info.ctm_info2.res_ID != golden_res_id)
            begin
                // output signal
                golden_err_msg  = Wrong_res_ID;
                golden_complete = 0;
                golden_out_info = 0;
            end
            else
            begin
                // golden_res_id equal to ctm_info1.res_ID 
                if(golden_d_man_Info.ctm_info1.res_ID == golden_res_id && golden_d_man_Info.ctm_info2.res_ID == golden_res_id)
                begin
                    // Wrong food ID ctm_info1
                    if(golden_d_man_Info.ctm_info1.food_ID != golden_food_ID_ser.d_food_ID && golden_d_man_Info.ctm_info2.food_ID != golden_food_ID_ser.d_food_ID)
                    begin
                        // output signal
                        golden_err_msg  = Wrong_food_ID;
                        golden_complete = 0;
                        golden_out_info = 0;
                    end
                    // no wrong ctm_info1 change
                    else
                    begin
                        if(golden_d_man_Info.ctm_info1.food_ID == golden_food_ID_ser.d_food_ID && golden_d_man_Info.ctm_info2.food_ID == golden_food_ID_ser.d_food_ID)
                        begin
                            golden_d_man_Info.ctm_info1 = 0;
                            golden_d_man_Info.ctm_info2 = 0;
                        end
                        else if(golden_d_man_Info.ctm_info1.food_ID == golden_food_ID_ser.d_food_ID && golden_d_man_Info.ctm_info2.food_ID != golden_food_ID_ser.d_food_ID)
                        begin
                            golden_d_man_Info.ctm_info1 = golden_d_man_Info.ctm_info2;
                            golden_d_man_Info.ctm_info2 = 0;
                        end 
                        else if(golden_d_man_Info.ctm_info1.food_ID != golden_food_ID_ser.d_food_ID && golden_d_man_Info.ctm_info2.food_ID == golden_food_ID_ser.d_food_ID)
                        begin
                            golden_d_man_Info.ctm_info2 = 0;
                        end
                        // output signal
                        golden_err_msg  = No_Err;
                        golden_complete = 1;
                        golden_out_info = {golden_d_man_Info,32'd0};
                    end
                end
                // golden_res_id equal to ctm_info1.res_ID 
                else if(golden_d_man_Info.ctm_info1.res_ID == golden_res_id && golden_d_man_Info.ctm_info2.res_ID != golden_res_id)
                begin
                    // Wrong food ID ctm_info1
                    if(golden_d_man_Info.ctm_info1.food_ID != golden_food_ID_ser.d_food_ID)
                    begin
                        // output signal
                        golden_err_msg  = Wrong_food_ID;
                        golden_complete = 0;
                        golden_out_info = 0;
                    end
                    // no wrong ctm_info1 change
                    else
                    begin
                        golden_d_man_Info.ctm_info1 = golden_d_man_Info.ctm_info2;
                        golden_d_man_Info.ctm_info2 = 0;
                        // output signal
                        golden_err_msg  = No_Err;
                        golden_complete = 1;
                        golden_out_info = {golden_d_man_Info,32'd0};
                    end 
                end
                // golden_res_id equal to ctm_info2.res_ID 
                else
                begin
                    // Wrong food ID ctm_info2
                    if(golden_d_man_Info.ctm_info2.food_ID != golden_food_ID_ser.d_food_ID)
                    begin
                        // output signal
                        golden_err_msg  = Wrong_food_ID;
                        golden_complete = 0;
                        golden_out_info = 0;
                    end
                    // no wrong
                    else
                    begin
                        // ctm_info2
                        if(golden_d_man_Info.ctm_info2.res_ID == golden_res_id && golden_d_man_Info.ctm_info2.food_ID == golden_food_ID_ser.d_food_ID)
                            golden_d_man_Info.ctm_info2 = 0;
                        // output signal
                        golden_err_msg  = No_Err;
                        golden_complete = 1;
                        golden_out_info = {golden_d_man_Info,32'd0};
                    end 
                end   
            end
        end 
        before_d_id   = golden_d_id;
        before_res_id = golden_res_id;  
        before_act    = golden_act; 
    end 
endtask

task wait_out_valid;
    begin
        wait_out_valid_cnt = 1;
        while(inf.out_valid === 1'b0)
        begin
            @(negedge clk);
            wait_out_valid_cnt = wait_out_valid_cnt + 1;
            if(wait_out_valid_cnt > 1200)
            begin	
                $display("Wrong Answer");
                $finish;
            end
        end
        total_latency = total_latency + wait_out_valid_cnt;
    end 
endtask

task check_output_signals;
    begin
        if((inf.complete!==golden_complete)||(inf.err_msg!==golden_err_msg)||(inf.out_info!==golden_out_info))
        begin
            $display("Wrong Answer");
            $finish;
        end
        else 
        begin
            @(negedge clk);
            if(inf.out_valid==1)
            begin
                $display("Wrong Answer");	
                $finish;
            end
            @(negedge clk);
        end	
    end 
endtask

task pass_pattern; 
    begin
        $finish;
    end
endtask

endprogram