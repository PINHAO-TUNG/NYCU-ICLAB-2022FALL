module RCL(
    clk,
    rst_n,
    in_valid,
    coef_Q,
    coef_L,
    out_valid,
    out
);
// ===============================================================
// Input & Output Declaration
// ===============================================================
input            clk, rst_n, in_valid;
input      [4:0] coef_Q, coef_L;
output reg       out_valid;
output reg [1:0] out;

//==============================================//
//             Parameter and Integer            //
//==============================================//
parameter s_idle   = 2'd0;
parameter s_input  = 2'd1;
parameter s_cal    = 2'd2;
parameter s_output = 2'd3;

//==============================================//
//           WIRE AND REG DECLARATION           //
//==============================================//
/// FSM ///
// state
reg [1:0] current_state, next_state;
// counter matrix index cnt
reg [4:0] fsm_cnt;

//input
reg signed [4:0] a, b, c, m, n;
reg        [4:0] k;

//cal
reg signed [20:0] dividend;
reg signed [12:0] divsor;
reg signed [20:0] d_eql_r_det;
reg 	   [1:0]  out_value;

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
            if(fsm_cnt == 5'd2)
                next_state = s_cal;
            else
                next_state = current_state;
        end
	s_cal:
	begin
	    if(fsm_cnt == 5'd5)
                next_state = s_output;
            else
                next_state = current_state;
	end
        s_output:
        begin
            next_state = s_idle;
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
    begin
	case(current_state)
	    s_idle:
	    begin
		fsm_cnt <= 5'd0;
	    end
	    s_input:
	    begin
		if(in_valid == 1)
		begin
		    if(fsm_cnt == 5'd2)
			fsm_cnt <= 5'd0;
		    else 
		        fsm_cnt <= fsm_cnt + 5'd1;
		end
		else
		    fsm_cnt <= fsm_cnt;
	    end
	    s_cal:
	    begin
		if(fsm_cnt == 5'd5)
		    fsm_cnt <= 5'd0;
		else
		    fsm_cnt <= fsm_cnt + 5'd1;
	    end
	    s_output:
	    begin
		fsm_cnt <= 5'd0;
	    end
	    default:
		fsm_cnt <= fsm_cnt;
	endcase
    end
end

//==============================================//
//            FSM state 1 input Block           //
//==============================================//
// coef_Q m, n unsigned k 
// coef_L a, b, c, 

// coef_L to a  
always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        a <= 5'd0;
    else if(current_state == s_idle)
	a <= 5'd0;
    else if(current_state == s_input && fsm_cnt == 0)
	a <= coef_L;
    else 
	a <= a;
end
// coef_L to b 
always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        b <= 5'd0;
    else if(current_state == s_idle)
	b <= 5'd0;
    else if(current_state == s_input && fsm_cnt == 1)
	b <= coef_L;
    else 
	b <= b;
end
// coef_L to c 
always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        c <= 5'd0;
    else if(current_state == s_idle)
	c <= 5'd0;
    else if(current_state == s_input && fsm_cnt == 2)
	c <= coef_L;
    else 
	c <= c;
end

// coef_Q to m 
always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        m <= 5'd0;
    else if(current_state == s_idle)
	m <= 5'd0;
    else if(current_state == s_input && fsm_cnt == 0)
	m <= coef_Q;
    else 
	m <= m;
end
// coef_Q to n 
always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        n <= 5'd0;
    else if(current_state == s_idle)
	n <= 5'd0;
    else if(current_state == s_input && fsm_cnt == 1)
	n <= coef_Q;
    else 
	n <= n;
end
// coef_Q to k 
always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        k <= 5'd0;
    else if(current_state == s_idle)
	k <= 5'd0;
    else if(current_state == s_input && fsm_cnt == 2)
	k <= coef_Q;
    else 
	k <= k;
end

//==============================================//
//             FSM state 2 cal Block            //
//==============================================//
// dividend divsor 13bit
// dividend
always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        dividend <= 21'd0;
    else if(current_state == s_idle)
	dividend <= 21'd0;
    else if(current_state == s_cal && fsm_cnt == 0)
	dividend <= a*m + b*n + c;
    else if(current_state == s_cal && fsm_cnt == 1)
	dividend <= dividend*dividend;
    else 
	dividend <= dividend;
end
// divsor
always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        divsor <= 13'd0;
    else if(current_state == s_idle)
	divsor <= 13'd0;
    else if(current_state == s_cal && fsm_cnt == 0)
	divsor <= a*a + b*b;
    else 
	divsor <= divsor;
end

// d_eql_r_det 21bit
always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        d_eql_r_det <= 21'd0;
    else if(current_state == s_idle)
	d_eql_r_det <= 21'd0;
    else if(current_state == s_cal && fsm_cnt == 2)
	d_eql_r_det <= k*divsor;
    else 
	d_eql_r_det <= d_eql_r_det;
end

// out_value
always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        out_value <= 2'd0;
    else if(current_state == s_idle)
	out_value <= 2'd0;
    else if(current_state == s_cal && fsm_cnt == 4)
    begin
	if(dividend > d_eql_r_det)
	    out_value <= 2'd0;
	else if(dividend == d_eql_r_det)
	    out_value <= 2'd1;
	else
	    out_value <= 2'd2;
    end
    else 
	out_value <= out_value;
end

//==============================================//
//            FSM state 3 output Block          //
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
        out <= 2'd0; 
    else
    case(current_state)
        s_output:
        begin    
            out <= out_value;
        end
        default:
            out <= 2'd0; 
    endcase
end

endmodule
