module TT(
           //Input Port
           clk,
           rst_n,
           in_valid,
           source,
           destination,

           //Output Port
           out_valid,
           cost
       );
//==============================================//
//               PORT DECLARATION               //
//==============================================//
input               clk, rst_n, in_valid;
input       [3:0]   source;
input       [3:0]   destination;

output reg          out_valid;
output reg  [3:0]   cost;
//==============================================//
//             Parameter and Integer            //
//==============================================//
// FSM Parameter
parameter s_idle = 2'd0;
parameter s_input = 2'd1;
parameter s_calculation = 2'd2;
parameter s_output = 2'd3;

// Integer and genvar
integer i, j;
genvar idx, jdx;
//==============================================//
//           WIRE AND REG DECLARATION           //
//==============================================//
// FSM
reg [1:0] current_state, next_state;

// Input Block //
// input counter
reg get_input_counter = 1'b0;
// start and terminal
reg [3:0] start_stations, terminal_stations;
// stations_table
reg stations_table [0:15][0:15];

// Calculation Block //
// table
reg [3:0]cost_logger[0:15];
reg [0:15] been_index_table;
// index pointer
reg [3:0] index_point;

// counter array
/*
reg [3:0] FSM2_counter_row;
reg [3:0] FSM2_counter_column;
*/
reg [4:0] FSM2_counter_row;
reg [4:0] FSM2_counter_column;

// output
reg find_output = 1'b0;
reg [3:0] cost_value;

//==============================================//
//                initial value                 //
//==============================================//
//==============================================//
//            FSM State Declaration             //
//==============================================//
always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        FSM2_counter_row <= 5'd0;
    else
    case(current_state)
        s_idle:
            FSM2_counter_row <= 5'd0;
        s_input:
            FSM2_counter_row <= 5'd0;
        s_calculation:
            if(FSM2_counter_row == 5'd17)
                FSM2_counter_row <= 5'd0;
            else if(find_output == 1)
                FSM2_counter_row <= 5'd0;
            else
                FSM2_counter_row <= FSM2_counter_row + 1'b1;
        s_output:
            if(FSM2_counter_row == 5'd1)
                FSM2_counter_row <= 5'd0;
            else
                FSM2_counter_row <= FSM2_counter_row + 5'b1;
        default:
            FSM2_counter_row <= FSM2_counter_row;
    endcase
end

//==============================================//
//             Current State Block              //
//==============================================//
always@(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        current_state <= s_idle;
    else
        current_state <= next_state;
end

//==============================================//
//              Next State Block                //
//==============================================//
always @(*)
begin
    case(current_state)
        s_idle:
            if(in_valid == 1)
                next_state = s_input;
            else
                next_state = current_state;
        s_input:
            if(in_valid == 0)
                next_state = s_calculation;
            else
                next_state = current_state;
        s_calculation:
            if(find_output == 1 || FSM2_counter_column == 5'd17)
                next_state = s_output;
            else
                next_state = current_state;
        s_output:
            if(FSM2_counter_row == 5'd1)
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
// get_input_counter //
// get_input_counter = 0 get start and terminal stations
// get_input_counter = 1 get track graph
always @(posedge clk or negedge rst_n)
begin
    if(!rst_n) /*initial*/
        get_input_counter <= 1'b0;
    else
    begin
        if(in_valid == 1 && get_input_counter == 0)
            get_input_counter <= 1'b1;
        else if(current_state == s_output) /*initial*/
            get_input_counter <= 1'b0;
        else
            get_input_counter  <= get_input_counter;
    end
end

// start and terminal stations //
// start_stations
always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        start_stations <= 4'd0;
    else
    begin
        if(get_input_counter == 0)
            start_stations <= source;
        else if(current_state == s_output) /*initial*/
            start_stations <= 4'd0;
        else
            start_stations <= start_stations;
    end
end
// terminal_stations
always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        terminal_stations <= 4'd0;
    else
    begin
        if(get_input_counter == 0)
            terminal_stations <= destination;
        else if(current_state == s_output) /*initial*/
            terminal_stations <= 4'd0;
        else
            terminal_stations <= terminal_stations;
    end
end

// get track graph //
// stations_table initial
always @(posedge clk or negedge rst_n)
begin
    if (!rst_n) /* when reset initial */
    begin
        for(i=0; i<16; i=i+1)
        begin
            for(j=0; j<16; j=j+1)
            begin
                stations_table[i][j] <= 1'd0;
            end
        end
    end
    else
        if(get_input_counter)
        begin
            if(current_state == s_input && in_valid == 1)
            begin
                stations_table[source][destination] <=  1'd1;
                stations_table[destination][source] <=  1'd1;
            end
            else
                stations_table[i][j] <= stations_table[i][j];
        end
        else if(current_state == s_output) /* when find output initial */
            for(i=0; i<16; i=i+1)
            begin
                for(j=0; j<16; j=j+1)
                begin
                    stations_table[i][j] <= 1'd0;
                end
            end
        else
            for(i=0; i<16; i=i+1)
            begin
                for(j=0; j<16; j=j+1)
                begin
                    stations_table[i][j] <= stations_table[i][j];
                end
            end
end

//==============================================//
//        FSM state 2 Calculation Block         //
//==============================================//
// find now index contain
// first find container and get them cost
// cost_logger
generate
    for( idx=0 ; idx<16 ; idx=idx+1 )
    begin
        always @(posedge clk or negedge rst_n)
        begin
            if (!rst_n) /*initial*/
                cost_logger[idx] <= 4'd0 ;
            else
                if(current_state == s_calculation)
                begin
                    if(stations_table[index_point][idx] == 1)
                        if(cost_logger[idx] == 0)
                            cost_logger[idx] <= cost_logger[index_point] + 1'd1;
                        else
                            cost_logger[idx] <= cost_logger[idx];
                    else
                        cost_logger[idx] <= cost_logger[idx];
                end
                else /*initial*/
                    cost_logger[idx] <= 4'd0;
        end
    end
endgenerate

// second note now index
// index_point
always @(posedge clk or negedge rst_n)
begin
    if (!rst_n) /*initial*/
        index_point <= 4'd0;
    else
    begin
        if(current_state == s_input)
            index_point <= start_stations;
        else if(current_state == s_calculation)
        begin
            if(FSM2_counter_column == 0)
                index_point <= start_stations;
            else
            begin
                if(cost_logger[FSM2_counter_row] == FSM2_counter_column && been_index_table[FSM2_counter_row] == 0)
                    index_point <= FSM2_counter_row;
                else
                    index_point <= index_point;
            end
        end
        else /*initial*/
            index_point <= 4'd0;
    end
end

// been_index_table
generate
    for( idx=0 ; idx<16 ; idx=idx+1 )
    begin
        always @(posedge clk or negedge rst_n)
        begin
            if (!rst_n)
                been_index_table[idx] <= 1'b0;
            else
            begin
                if(current_state == s_calculation)
                begin
                    if(idx == index_point)
                        been_index_table[idx] <= 1'b1;
                    else
                        been_index_table[idx] <= been_index_table[idx];
                end
                else
                    been_index_table[idx] <= 1'b0;
            end
        end
    end
endgenerate

// output //
// find_output
always @(posedge clk or negedge rst_n)
begin
    if (!rst_n)
        find_output <= 1'b0;
    else
    begin
        if(current_state == s_calculation)
        begin
            if(cost_logger[terminal_stations] != 0)
                find_output <= 1'b1;
            else
                if(been_index_table[terminal_stations] != 0)
                    find_output <= 1'b1;
                else if(FSM2_counter_column == 5'd16 && FSM2_counter_row == 5'd17)
                    find_output <= 1'b1;
                else
                    find_output <= find_output;
        end
        else
            find_output <= 1'b0;
    end
end

// cost_value
always @(posedge clk or negedge rst_n)
begin
    if (!rst_n)
        cost_value <= 4'd0;
    else
    begin
        if(current_state == s_calculation)
        begin
            if(cost_logger[terminal_stations] != 0)
                cost_value <= cost_logger[terminal_stations];
            else
                if(been_index_table[terminal_stations] != 0)
                    cost_value <= cost_logger[terminal_stations];
                else if(FSM2_counter_column == 5'd16 && FSM2_counter_row == 5'd17)
                    cost_value <= 4'd0; /*output*/
                else
                    cost_value <= cost_value;
        end
        else
            cost_value <= 4'd0;
    end
end

// counter array //
// FSM2_counter_row
// in line 85
// FSM2_counter_column
always @(posedge clk or negedge rst_n)
begin
    if (!rst_n)
        FSM2_counter_column <= 4'd0;
    else
    begin
        if(current_state == s_calculation)
        begin
            if(FSM2_counter_row == 5'd17)
                FSM2_counter_column <= FSM2_counter_column + 1'd1;
            else
                FSM2_counter_column <= FSM2_counter_column;
        end
        else
            FSM2_counter_column <= 4'd0;
    end
end

//==============================================//
//          FSM state 3 Output Block            //
//==============================================//
//   work   //
// out_valid //correct//
always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        out_valid <= 1'b0; /* remember to reset */
    else
    case(current_state)
        s_output:
            if (FSM2_counter_row == 0)
                out_valid <= 1'b1;
            else
                out_valid <= 1'b0;
        default:
            out_valid <= 1'b0;
    endcase
end

// cost //correct//
always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        cost <= 4'b0; /* remember to reset */
    else
    case(current_state)
        s_output:
            cost <= cost_value;
        default:
            cost <= 4'b0;
    endcase
end

endmodule
