module Checker(input clk, INF.CHECKER inf);
import usertype::*;

//declare other cover group
covergroup Spec1 @(posedge clk && inf.id_valid);
    option.per_instance = 1;
	coverpoint inf.D.d_id[0]
    {
        option.at_least = 1;
		option.auto_bin_max = 256;
	}
endgroup

covergroup Spec2 @(posedge clk && inf.act_valid);
    option.per_instance = 1;
   	coverpoint inf.D.d_act[0] 
    {
        option.at_least = 10;
   		bins a[] = (Take, Order, Deliver, Cancel => Take, Order, Deliver, Cancel) ;
   	}
endgroup

covergroup Spec3 @(negedge clk && inf.out_valid);
    option.per_instance = 1;
	coverpoint inf.complete
    {
        option.at_least = 200;
		bins c0 = {0};
		bins c1 = {1};
	}
endgroup

covergroup Spec4 @(negedge clk && inf.out_valid);
    option.per_instance = 1;
	coverpoint inf.err_msg
    {
        option.at_least = 20;
		bins e0 = {No_Err};
		bins e1 = {No_food};
		bins e2 = {D_man_busy};
		bins e3 = {No_customers};
		bins e4 = {Res_busy};
		bins e5 = {Wrong_cancel};
		bins e6 = {Wrong_res_ID};
        bins e7 = {Wrong_food_ID};
	}
endgroup

Spec1 cov1 = new();
Spec2 cov2 = new();
Spec3 cov3 = new();
Spec4 cov4 = new();
//************************************ below assertion is to check your pattern ***************************************** 
//                                          Please finish and hand in it
// This is an example assertion given by TA, please write the required assertions below
//  assert_interval : assert property ( @(posedge clk)  inf.out_valid |=> inf.id_valid == 0 [*2])
//  else
//  begin
//  	$display("Assertion X is violated");
//  	$fatal; 
//  end
wire #(0.5) rst_reg = inf.rst_n;
//write other assertions

logic no_invalid;
assign no_invalid = !(inf.id_valid || inf.act_valid || inf.cus_valid || inf.res_valid || inf.food_valid);

Action current_act;

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
//========================================================================================================================================================
// Assertion 1 ( All outputs signals (including FD.sv and bridge.sv) should be zero after reset.)
//========================================================================================================================================================

assert_1 : assert property ( @(negedge rst_reg)  (inf.err_msg === No_Err) && (inf.complete === 0) && (inf.out_valid === 0) && (inf.out_info === 0) && 
                                (inf.C_addr === 0) && (inf.C_r_wb === 0) && (inf.C_in_valid === 0) && (inf.C_data_w === 0) && 
                                (inf.C_out_valid === 0) && (inf.C_data_r === 0) && (inf.AR_VALID===0) && (inf.AR_ADDR===0) &&
								(inf.R_READY===0) && (inf.AW_VALID===0) && (inf.AW_ADDR===0) && (inf.W_VALID===0) && 
								(inf.W_DATA===0) && (inf.B_READY===0))
else
begin
	$display("Assertion 1 is violated");
	$fatal; 
end

assert_2 : assert property ( @(posedge clk)  (inf.complete === 1 && inf.out_valid === 1) |-> inf.err_msg===No_Err)
else
begin
	$display("Assertion 2 is violated");
	$fatal; 
end

assert_3 : assert property ( @(posedge clk)  (inf.complete === 0 && inf.out_valid === 1) |-> inf.out_info===0)
else
begin
	$display("Assertion 3 is violated");
	$fatal; 
end

assert_4_1 : assert property ( @(posedge clk)  inf.act_valid === 1 |->  ##[2:6] (inf.id_valid === 1 || inf.res_valid === 1 || inf.food_valid === 1 || inf.cus_valid === 1))
else
begin
	$display("Assertion 4 is violated");
	$fatal; 
end

assert_4_2 : assert property ( @(posedge clk)  ((current_act === Order || current_act === Cancel) && inf.res_valid === 1) |->  ##[2:6] (inf.food_valid === 1))
else
begin
	$display("Assertion 4 is violated");
	$fatal; 
end

assert_4_3 : assert property ( @(posedge clk)  (current_act === Take && inf.id_valid === 1) |->  ##[2:6] (inf.cus_valid === 1))
else
begin
	$display("Assertion 4 is violated");
	$fatal; 
end

assert_4_4 : assert property ( @(posedge clk)  (current_act === Cancel && inf.food_valid === 1) |->  ##[2:6] (inf.id_valid === 1))
else
begin
	$display("Assertion 4 is violated");
	$fatal; 
end

assert_5 : assert property ( @(posedge clk)  $onehot({ inf.id_valid, inf.act_valid, inf.cus_valid, inf.res_valid, inf.food_valid, no_invalid}))  
else
begin
 	$display("Assertion 5 is violated");
 	$fatal; 
end

assert_6 : assert property ( @(posedge clk)  inf.out_valid === 1 |-> ##1 inf.out_valid === 0)
else
begin
	$display("Assertion 6 is violated");
	$fatal; 
end

assert_7 : assert property ( @(posedge clk)  inf.out_valid === 1 |-> ##[2:10] inf.act_valid === 1)
else
begin
	$display("Assertion 7 is violated");
	$fatal; 
end

assert_8_1 : assert property ( @(posedge clk)  (current_act === Take && inf.cus_valid === 1) |-> ##[1:1200] inf.out_valid === 1)
else
begin
	$display("Assertion 8 is violated");
	$fatal; 
end

assert_8_2 : assert property ( @(posedge clk)  ((current_act === Deliver || current_act === Cancel) && inf.id_valid === 1) |-> ##[1:1200] inf.out_valid === 1)
else
begin
	$display("Assertion 8 is violated");
	$fatal; 
end

assert_8_3 : assert property ( @(posedge clk)  (current_act === Order && inf.food_valid === 1) |-> ##[1:1200] inf.out_valid === 1)
else
begin
	$display("Assertion 8 is violated");
	$fatal; 
end

endmodule