module BP(
  clk,
  rst_n,
  in_valid,
  guy,
  in0,
  in1,
  in2,
  in3,
  in4,
  in5,
  in6,
  in7,
  
  out_valid,
  out
);
//==============================================//
//               PORT DECLARATION               //
//==============================================//
input             clk, rst_n;
input             in_valid;
input       [2:0] guy;
input       [1:0] in0, in1, in2, in3, in4, in5, in6, in7;
output reg        out_valid;
output reg  [1:0] out;
//==============================================//
//             Parameter and Integer            //
//==============================================//    
// FSM Parameter
parameter s_idle = 2'd0;
parameter s_input = 2'd1;
parameter s_output = 2'd2;

// Integer and genvar
integer i, j, k;
genvar idx;
//==============================================//
//           WIRE AND REG DECLARATION           //
//==============================================//
// FSM //
// FSM
// state
reg [1:0] current_state, next_state;
// FSM_counter 6bit
reg [5:0] FSM_counter;

// Input Block //
// input table //
// no_obstacles_location 
reg [2:0] no_obstacles_location [0:63];
// obstacles_ornot
reg obstacles_ornot [0:63];
// need_jump 
reg need_jump [0:63];
// guy
// guy_location 
reg [2:0] guy_location;
// walk_cnt 
reg [6:0] walk_cnt;

// output //
// out_table 2*63 arrray
reg [1:0] out_table[0:62];

//==============================================//
//                initial value                 //
//==============================================//
//==============================================//
//            FSM State Declaration             //
//==============================================//
// FSM_counter 6bit //
always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        FSM_counter <= 6'd0;
    else
    case(current_state)
        s_idle:
            FSM_counter <= 6'd0;
        s_input:
            if(FSM_counter == 6'd63)
                FSM_counter <= 6'd0;
            else
                FSM_counter <= FSM_counter + 6'd1;
        s_output:
            if(FSM_counter == 6'd62)
                FSM_counter <= 6'd0;
            else
                FSM_counter <= FSM_counter + 6'd1;
        default:
            FSM_counter <= FSM_counter;
    endcase
end

//==============================================//
//             Current State Block              //
//==============================================//
// current_state //
always@(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        current_state <= s_idle;
    else
    begin
        if(in_valid == 1)
            current_state <= s_input;
        else
            current_state <= next_state;
    end
end

//==============================================//
//              Next State Block                //
//==============================================//
// next_state //
always @(*)
begin
    case(current_state)
        s_input:
            if(FSM_counter == 6'd63)
                next_state = s_output;
            else
                next_state = current_state;
        s_output:
            if(FSM_counter == 6'd62)
                next_state = s_idle;
            else
                next_state = current_state;
        default:
            next_state = current_state;
    endcase
end

//==============================================//
//           FSM state 1 Input Block            //
//==============================================//
//   work   //

// no_obstacles_location 
always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
    begin
        for(i=0; i<64; i=i+1)
        begin
            no_obstacles_location[i] <= 3'd0;
        end
    end
    else
    begin
        if(current_state == s_idle) 
        begin
            for(i=0; i<64; i=i+1)
            begin
                no_obstacles_location[i] <= 3'd0;
            end
        end
        else if(current_state == s_input)
        begin
            if(in0 == 2'b01 || in0 == 2'b10)
            begin
                no_obstacles_location[FSM_counter+1] <= 3'd0;
            end
            else if(in1 == 2'b01 || in1 == 2'b10)
            begin
                no_obstacles_location[FSM_counter+1] <= 3'd1;
            end
            else if(in2 == 2'b01 || in2 == 2'b10)
            begin
                no_obstacles_location[FSM_counter+1] <= 3'd2;
            end
            else if(in3 == 2'b01 || in3 == 2'b10)
            begin
                no_obstacles_location[FSM_counter+1] <= 3'd3;
            end
            else if(in4 == 2'b01 || in4 == 2'b10)
            begin
                no_obstacles_location[FSM_counter+1] <= 3'd4;
            end
            else if(in5 == 2'b01 || in5 == 2'b10)
            begin
                no_obstacles_location[FSM_counter+1] <= 3'd5;
            end
            else if(in6 == 2'b01 || in6 == 2'b10)
            begin
                no_obstacles_location[FSM_counter+1] <= 3'd6;
            end
            else if(in7 == 2'b01 || in7 == 2'b10)
            begin
                no_obstacles_location[FSM_counter+1] <= 3'd7;
            end
            else
            begin
                no_obstacles_location[FSM_counter+1] <= no_obstacles_location[FSM_counter+1];
            end
        end
        else
        begin
            no_obstacles_location[FSM_counter+1] <= no_obstacles_location[FSM_counter+1];
        end
    end
end

// obstacles_ornot
always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
    begin
        for(j=0; j<64; j=j+1)
        begin
            obstacles_ornot[j] <= 1'd0;
        end
    end
    else
    begin
        if(current_state == s_idle)
        begin
            for(j=0; j<64; j=j+1)
            begin
                obstacles_ornot[j] <= 1'd0;
            end
        end
        else if(current_state == s_input)
        begin
            if(in0 != 2'b00)
            begin
                obstacles_ornot[FSM_counter+1] <= 1'd1;
            end
            else
            begin
                obstacles_ornot[FSM_counter+1] <= 1'd0;
            end
        end
        else
        begin
            obstacles_ornot[FSM_counter+1] <= obstacles_ornot[FSM_counter+1];
        end
    end
end

// need_jump
always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
    begin
        for(k=0; k<64; k=k+1)
        begin
            need_jump[k] <= 1'd0;
        end
    end
    else
    begin
        if(current_state == s_idle) 
        begin
            for(k=0; k<64; k=k+1)
            begin
                need_jump[k] <= 1'd0;
            end
        end
        else if(current_state == s_input)
        begin
            if(in0 == 2'b01)
            begin
                need_jump[FSM_counter+1] <= 1'd1;
            end
            else if(in1 == 2'b01)
            begin
                need_jump[FSM_counter+1] <= 1'd1;
            end
            else if(in2 == 2'b01)
            begin
                need_jump[FSM_counter+1] <= 1'd1;
            end
            else if(in3 == 2'b01)
            begin
                need_jump[FSM_counter+1] <= 1'd1;
            end
            else if(in4 == 2'b01)
            begin
                need_jump[FSM_counter+1] <= 1'd1;
            end
            else if(in5 == 2'b01)
            begin
                need_jump[FSM_counter+1] <= 1'd1;
            end
            else if(in6 == 2'b01)
            begin
                need_jump[FSM_counter+1] <= 1'd1;
            end
            else if(in7 == 2'b01)
            begin
                need_jump[FSM_counter+1] <= 1'd1;
            end
            else
            begin
                need_jump[FSM_counter+1] <= need_jump[FSM_counter+1];
            end
        end
        else
        begin
            need_jump[FSM_counter+1] <= need_jump[FSM_counter+1];
        end
    end
end

// walk_cnt
always @(posedge clk or negedge rst_n)
begin 
    if(!rst_n)
    begin
        walk_cnt <= 7'd0;
    end
    else
    begin
        if(current_state == s_idle)
        begin
            walk_cnt <= 7'd0;
        end
        else if(current_state == s_input)
        begin
            if(FSM_counter > 8)
                walk_cnt <= walk_cnt + 1'd1;
            else
                walk_cnt <= walk_cnt;
        end
        else
        begin
            walk_cnt <= walk_cnt + 1'd1;
        end
    end
end

// guy_location
always @(posedge clk or negedge rst_n)
begin 
    if(!rst_n)
    begin
        guy_location <= 3'd0;
    end
    else
    begin
        if(current_state == s_idle)
        begin
            guy_location <= guy;
        end
        else 
        begin               
            if(walk_cnt < 63)
            begin
                if(current_state == s_input && FSM_counter < 9)
                    guy_location <= guy_location;
                else
                begin
                    if(obstacles_ornot[walk_cnt+1] != 0)
                    begin
                        if(no_obstacles_location[walk_cnt+1] == guy_location)
                            guy_location <= guy_location;
                        else if(no_obstacles_location[walk_cnt+1] > guy_location)
                            guy_location <= guy_location + 1'd1;
                        else 
                            guy_location <= guy_location - 1'd1;
                    end
                    else if(obstacles_ornot[walk_cnt+2] != 0)
                    begin
                        if(no_obstacles_location[walk_cnt+2] == guy_location)
                            guy_location <= guy_location;
                        else if(no_obstacles_location[walk_cnt+2] > guy_location)
                            guy_location <= guy_location + 1'd1;
                        else 
                            guy_location <= guy_location - 1'd1;
                    end
                    else if(obstacles_ornot[walk_cnt+3] != 0)
                    begin
                        if(no_obstacles_location[walk_cnt+3] == guy_location)
                            guy_location <= guy_location;
                        else if(no_obstacles_location[walk_cnt+3] > guy_location)
                            guy_location <= guy_location + 1'd1;
                        else 
                            guy_location <= guy_location - 1'd1;
                    end
                    else if(obstacles_ornot[walk_cnt+4] != 0)
                    begin
                        if(no_obstacles_location[walk_cnt+4] == guy_location)
                            guy_location <= guy_location;
                        else if(no_obstacles_location[walk_cnt+4] > guy_location)
                            guy_location <= guy_location + 1'd1;
                        else 
                            guy_location <= guy_location - 1'd1;
                    end
                    else if(obstacles_ornot[walk_cnt+5] != 0)
                    begin
                        if(no_obstacles_location[walk_cnt+5] == guy_location)
                            guy_location <= guy_location;
                        else if(no_obstacles_location[walk_cnt+5] > guy_location)
                            guy_location <= guy_location + 1'd1;
                        else 
                            guy_location <= guy_location - 1'd1;
                    end
                    else if(obstacles_ornot[walk_cnt+6] != 0)
                    begin
                        if(no_obstacles_location[walk_cnt+6] == guy_location)
                            guy_location <= guy_location;
                        else if(no_obstacles_location[walk_cnt+6] > guy_location)
                            guy_location <= guy_location + 1'd1;
                        else 
                            guy_location <= guy_location - 1'd1;
                    end
                    else if(obstacles_ornot[walk_cnt+7] != 0)
                    begin
                        if(no_obstacles_location[walk_cnt+7] == guy_location)
                            guy_location <= guy_location;
                        else if(no_obstacles_location[walk_cnt+7] > guy_location)
                            guy_location <= guy_location + 1'd1;
                        else 
                            guy_location <= guy_location - 1'd1;
                    end
                    else if(obstacles_ornot[walk_cnt+8] != 0)
                    begin
                        if(no_obstacles_location[walk_cnt+8] == guy_location)
                            guy_location <= guy_location;
                        else if(no_obstacles_location[walk_cnt+8] > guy_location)
                            guy_location <= guy_location + 1'd1;
                        else 
                            guy_location <= guy_location - 1'd1;
                    end
                    else
                        guy_location <= guy_location;
                end
            end
            else
                guy_location <= guy_location;
        end
    end
end

// out_table 2*63
always @(posedge clk or negedge rst_n)
begin
    if (!rst_n) /*reset*/
        for(k=0; k<64; k=k+1)
        begin
            out_table[k] <= 2'd0;
        end
    else
    begin
        if(current_state == s_idle)
        begin
            for(k=0; k<64; k=k+1)
            begin
                out_table[k] <= 2'd0;
            end
        end
        else
        begin
            if(walk_cnt < 63)
            begin
                if(obstacles_ornot[walk_cnt+1] != 0)
                begin
                    if(need_jump[walk_cnt+1] == 1)
                    begin
                        out_table[walk_cnt] <= 2'd3;
                    end
                    else
                    begin
                        if(no_obstacles_location[walk_cnt+1] == guy_location)
                            out_table[walk_cnt] <= 2'd0;
                        else if(no_obstacles_location[walk_cnt+1] > guy_location)
                            out_table[walk_cnt] <= 2'd1;
                        else 
                            out_table[walk_cnt] <= 2'd2;
                    end
                end
                else if(obstacles_ornot[walk_cnt+2] != 0)
                begin
                    if(no_obstacles_location[walk_cnt+2] == guy_location)
                        out_table[walk_cnt] <= 2'd0;
                    else if(no_obstacles_location[walk_cnt+2] > guy_location)
                        out_table[walk_cnt] <= 2'd1;
                    else 
                        out_table[walk_cnt] <= 2'd2;
                end
                else if(obstacles_ornot[walk_cnt+3] != 0)
                begin
                    if(no_obstacles_location[walk_cnt+3] == guy_location)
                        out_table[walk_cnt] <= 2'd0;
                    else if(no_obstacles_location[walk_cnt+3] > guy_location)
                        out_table[walk_cnt] <= 2'd1;
                    else 
                        out_table[walk_cnt] <= 2'd2;
                end
                else if(obstacles_ornot[walk_cnt+4] != 0)
                begin
                    if(no_obstacles_location[walk_cnt+4] == guy_location)
                        out_table[walk_cnt] <= 2'd0;
                    else if(no_obstacles_location[walk_cnt+4] > guy_location)
                        out_table[walk_cnt] <= 2'd1;
                    else 
                        out_table[walk_cnt] <= 2'd2;
                end
                else if(obstacles_ornot[walk_cnt+5] != 0)
                begin
                    if(no_obstacles_location[walk_cnt+5] == guy_location)
                        out_table[walk_cnt] <= 2'd0;
                    else if(no_obstacles_location[walk_cnt+5] > guy_location)
                        out_table[walk_cnt] <= 2'd1;
                    else 
                        out_table[walk_cnt] <= 2'd2;
                end
                else if(obstacles_ornot[walk_cnt+6] != 0)
                begin
                    if(no_obstacles_location[walk_cnt+6] == guy_location)
                        out_table[walk_cnt] <= 2'd0;
                    else if(no_obstacles_location[walk_cnt+6] > guy_location)
                        out_table[walk_cnt] <= 2'd1;
                    else 
                        out_table[walk_cnt] <= 2'd2;
                end
                else if(obstacles_ornot[walk_cnt+7] != 0)
                begin
                    if(no_obstacles_location[walk_cnt+7] == guy_location)
                        out_table[walk_cnt] <= 2'd0;
                    else if(no_obstacles_location[walk_cnt+7] > guy_location)
                        out_table[walk_cnt] <= 2'd1;
                    else 
                        out_table[walk_cnt] <= 2'd2;
                end
                else if(obstacles_ornot[walk_cnt+8] != 0)
                begin
                    if(no_obstacles_location[walk_cnt+8] == guy_location)
                        out_table[walk_cnt] <= 2'd0;
                    else if(no_obstacles_location[walk_cnt+8] > guy_location)
                        out_table[walk_cnt] <= 2'd1;
                    else 
                        out_table[walk_cnt] <= 2'd2;
                end
                else
                    out_table[walk_cnt] <= 2'd0;
            end
            else
                out_table[walk_cnt] <= out_table[walk_cnt];
        end
    end
end

//==============================================//
//          FSM state 2 Output Block            //
//==============================================//
//   work   //
// out_valid 
always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
    begin
        out_valid <= 1'b0; /* remember to reset */
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
        out <= 2'd0; /* remember to reset */
    else
    case(current_state)
        s_output:
            out <= out_table[FSM_counter];
        default:
            out <= 2'd0;
    endcase
end

endmodule
