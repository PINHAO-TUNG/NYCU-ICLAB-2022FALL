`include "synchronizer.v"
`include "syn_XOR.v"
module CDC(
           //Input Port
           clk1,
           clk2,
           clk3,
           rst_n,
           in_valid1,
           in_valid2,
           user1,
           user2,

           //Output Port
           out_valid1,
           out_valid2,
           equal,
           exceed,
           winner
       );
//---------------------------------------------------------------------
//   INPUT AND OUTPUT DECLARATION
//---------------------------------------------------------------------
input 		clk1, clk2, clk3, rst_n;
input 		in_valid1, in_valid2;
input [3:0]	user1, user2;

output reg	out_valid1, out_valid2;
output reg	equal, exceed, winner;
//---------------------------------------------------------------------
//   WIRE AND REG DECLARATION
//---------------------------------------------------------------------
//----clk1----
reg [3:0] clk1_cntdelay;
reg [5:0] clk1_cnt50;
reg [3:0] clk1_cnt10;
reg [2:0] poker_table[0:12];
reg [5:0] user1_point;
reg [5:0] user2_point;
reg [6:0] clk1_equal;
reg [6:0] clk1_exceed;
reg [1:0] clk1_winner;
reg [6:0] equalff;
reg [6:0] exceedff;
reg [1:0] winnerff;

reg out_valid_r3;
reg out_valid_r4;
reg out_valid_r8;
reg out_valid_r9;
reg out_valid_r10;
//----clk2----

//----clk3----
wire out_valid_w3;
wire out_valid_w4;
wire out_valid_w8;
wire out_valid_w9;
wire out_valid_w10;
reg flag3;
reg flag4;
reg flag8;
reg flag9;
reg flag10;
reg [6:0] clk3_equal;
reg [6:0] clk3_exceed;
reg [1:0] clk3_winner;
reg [2:0] clk3_cnt7;
reg clk3_cnt2;
//---------------------------------------------------------------------
//   PARAMETER
//---------------------------------------------------------------------
//----clk1----
genvar idx;
//----clk2----

//----clk3----

//---------------------------------------------------------------------
//   DESIGN
//---------------------------------------------------------------------
//============================================
//   clk1 domain
//============================================
// clk1_cntdelay
always@(posedge clk1 or negedge rst_n)
begin
    if(!rst_n)
    begin
        clk1_cntdelay <= 0;
    end
    else if(in_valid1 == 1 || in_valid2 == 1)
    begin
        if(clk1_cntdelay == 3)
        begin
            clk1_cntdelay <= 3;
        end
        else
        begin
            clk1_cntdelay <= clk1_cntdelay + 1;
        end
    end
    else
    begin
        clk1_cntdelay <= clk1_cntdelay;
    end
end
// cnt conrtoler
// clk1_cnt50
always@(posedge clk1 or negedge rst_n)
begin
    if(!rst_n)
    begin
        clk1_cnt50 <= 0;
    end
    else if(in_valid1 == 1 || in_valid2 == 1)
    begin
        if(clk1_cnt50 == 49)
        begin
            clk1_cnt50 <= 0;
        end
        else
        begin
            clk1_cnt50 <= clk1_cnt50 + 1;
        end
    end
    else
        clk1_cnt50 <= clk1_cnt50;
end
// clk1_cnt10
always@(posedge clk1 or negedge rst_n)
begin
    if(!rst_n)
    begin
        clk1_cnt10 <= 0;
    end
    else if(clk1_cntdelay > 1)
    begin
        if(clk1_cnt10 == 9)
        begin
            clk1_cnt10 <= 0;
        end
        else
        begin
            clk1_cnt10 <= clk1_cnt10 + 1;
        end
    end
    else
    begin
        clk1_cnt10 <= clk1_cnt10;
    end
end
// poker_table
generate
    for(idx=0; idx<13; idx=idx+1)
    begin
        always@(posedge clk1 or negedge rst_n)
        begin
            if(!rst_n)
            begin
                poker_table[idx] <= 4;
            end
            else if(in_valid1 == 1)
            begin
                // initial card
                if(clk1_cnt50==0)
                begin
                    if(user1 == (idx+1))
                    begin
                        poker_table[idx] <= 3;
                    end
                    else
                    begin
                        poker_table[idx] <= 4;
                    end
                end
                else
                begin
                    if(user1 == (idx+1))
                    begin
                        poker_table[idx] <= poker_table[idx] - 1;
                    end
                    else
                    begin
                        poker_table[idx] <= poker_table[idx];
                    end
                end
            end
            else if(in_valid2 == 1)
            begin
                if(user2 == (idx+1))
                begin
                    poker_table[idx] <= poker_table[idx] - 1;
                end
                else
                begin
                    poker_table[idx] <= poker_table[idx];
                end
            end
            else
            begin
                poker_table[idx] <= poker_table[idx];
            end
        end
    end
endgenerate
// user1_point
always@(posedge clk1 or negedge rst_n)
begin
    if(!rst_n)
    begin
        user1_point <= 0;
    end
    else if(in_valid1 == 1)
    begin
        if(clk1_cntdelay == 0)
        begin
            // initial first get
            if(user1 > 10)
                user1_point <= 1;
            else
                user1_point <= user1;
        end
        else
        begin
            if(clk1_cnt10 == 8)
            begin
                // initial first get
                if(user1 > 10)
                    user1_point <= 1;
                else
                    user1_point <= user1;
            end
            else
            begin
                if(user1 > 10)
                    user1_point <= user1_point + 1;
                else
                    user1_point <= user1_point + user1;
            end
        end
    end
    else
    begin
        user1_point <= user1_point;
    end
end
// user2_point
always@(posedge clk1 or negedge rst_n)
begin
    if(!rst_n)
    begin
        user2_point <= 0;
    end
    else if(in_valid2 == 1)
    begin
        if(clk1_cnt10 == 3)
        begin
            // initial first get
            if(user2 > 10)
                user2_point <= 1;
            else
                user2_point <= user2;
        end
        else
        begin
            if(user2 > 10)
                user2_point <= user2_point + 1;
            else
                user2_point <= user2_point + user2;
        end
    end
    else
    begin
        user2_point <= user2_point;
    end
end
// clk1_equal
wire [5:0] down = (52-clk1_cnt50);
wire [5:0] value1 = poker_table[0]+poker_table[10]+poker_table[11]+poker_table[12];
always@(posedge clk1 or negedge rst_n)
begin
    if(!rst_n)
    begin
        clk1_equal <= 0;
    end
    else if(clk1_cnt10 == 4 || clk1_cnt10 == 9)
    begin
        clk1_equal <= 0;
    end
    // user1
    else if(clk1_cnt10 == 1 || clk1_cnt10 == 2)
    begin
        if(user1_point < 11 || user1_point > 20)
        begin
            clk1_equal <= 0;
        end
        else if (user1_point == 20)
        begin
            clk1_equal <= (value1)*100/(down);
        end
        else
        begin // (21 - user1_point)-1  poker_table poker_table[20-user1_point]
            clk1_equal <= poker_table[20-user1_point]*100/(down);
        end
    end
    // user2
    else if(clk1_cnt10 == 6 || clk1_cnt10 == 7)
    begin
        if(user2_point < 11 || user2_point > 20)
            clk1_equal <= 0;
        else if ((20-user2_point) == 0)
            clk1_equal <= (value1)*100/(down);
        else
        begin // (21 - user2_point)-1  poker_table poker_table[20-user2_point]
            clk1_equal <= poker_table[20-user2_point]*100/(down);
        end
    end
    else
    begin
        clk1_equal <= clk1_equal;
    end
end
// clk1_exceed
wire [5:0] over9 = poker_table[9];
wire [5:0] over8 = poker_table[8]+poker_table[9];
wire [5:0] over7 = poker_table[7]+poker_table[8]+poker_table[9];
wire [5:0] over6 = poker_table[6]+poker_table[7]+poker_table[8]+poker_table[9];
wire [5:0] over5 = poker_table[5]+poker_table[6]+poker_table[7]+poker_table[8]+poker_table[9];
wire [5:0] over4 = poker_table[4]+poker_table[5]+poker_table[6]+poker_table[7]+poker_table[8]+poker_table[9];
wire [5:0] over3 = poker_table[3]+poker_table[4]+poker_table[5]+poker_table[6]+poker_table[7]+poker_table[8]+poker_table[9];
wire [5:0] over2 = poker_table[2]+poker_table[3]+poker_table[4]+poker_table[5]+poker_table[6]+poker_table[7]+poker_table[8]+poker_table[9];
wire [5:0] over1 = poker_table[1]+poker_table[2]+poker_table[3]+poker_table[4]+poker_table[5]+poker_table[6]+poker_table[7]+poker_table[8]+poker_table[9];
wire [5:0] over0 = poker_table[0]+poker_table[1]+poker_table[2]+poker_table[3]+poker_table[4]+poker_table[5]+poker_table[6]+poker_table[7]+poker_table[8]+poker_table[9]+poker_table[10]+poker_table[11]+poker_table[12];
always@(posedge clk1 or negedge rst_n)
begin
    if(!rst_n)
    begin
        clk1_exceed <= 0;
    end
    else if(clk1_cnt10 == 4 || clk1_cnt10 == 9)
    begin
        clk1_exceed <= 0;
    end
    //user1
    else if(clk1_cnt10 == 1 || clk1_cnt10 == 2)
    begin
        if(user1_point < 12)
        begin
            clk1_exceed <= 0;
        end
        else if(user1_point == 12)
        begin
            clk1_exceed <= over9*100/(down);
        end
        else if(user1_point == 13)
        begin
            clk1_exceed <= over8*100/(down);
        end
        else if(user1_point == 14)
        begin
            clk1_exceed <= over7*100/(down);
        end
        else if(user1_point == 15)
        begin
            clk1_exceed <= over6*100/(down);
        end
        else if(user1_point == 16)
        begin
            clk1_exceed <= over5*100/(down);
        end
        else if(user1_point == 17)
        begin
            clk1_exceed <= over4*100/(down);
        end
        else if(user1_point == 18)
        begin
            clk1_exceed <= over3*100/(down);
        end
        else if(user1_point == 19)
        begin
            clk1_exceed <= over2*100/(down);
        end
        else if(user1_point == 20)
        begin
            clk1_exceed <= over1*100/(down);
        end
        else
        begin
            clk1_exceed <= 100;
        end
    end
    //user2
    else if(clk1_cnt10 == 6 || clk1_cnt10 == 7)
    begin
        if(user2_point < 12)
        begin
            clk1_exceed <= 0;
        end
        else if(user2_point == 12)
        begin
            clk1_exceed <= over9*100/(down);
        end
        else if(user2_point == 13)
        begin
            clk1_exceed <= over8*100/(down);
        end
        else if(user2_point == 14)
        begin
            clk1_exceed <= over7*100/(down);
        end
        else if(user2_point == 15)
        begin
            clk1_exceed <= over6*100/(down);
        end
        else if(user2_point == 16)
        begin
            clk1_exceed <= over5*100/(down);
        end
        else if(user2_point == 17)
        begin
            clk1_exceed <= over4*100/(down);
        end
        else if(user2_point == 18)
        begin
            clk1_exceed <= over3*100/(down);
        end
        else if(user2_point == 19)
        begin
            clk1_exceed <= over2*100/(down);
        end
        else if(user2_point == 20)
        begin
            clk1_exceed <= over1*100/(down);
        end
        else
        begin
            clk1_exceed <= 100;
        end
    end
    else
    begin
        clk1_exceed <= clk1_exceed;
    end
end
//reg trace;
// clk1_winner
always@(posedge clk1 or negedge rst_n)
begin
    if(!rst_n)
    begin
        clk1_winner <= 0;
        //trace <=0;
    end
    else if(clk1_cnt10 == 8)
    begin
        if(user1_point  > 21 && user2_point > 21)
            clk1_winner <= 2'b00;
        else if(user1_point < 22 && user2_point> 21)
            clk1_winner <= 2'b10;
        else if(user1_point > 21 && user2_point < 22)
        begin
            clk1_winner <= 2'b11;
        end
        else
        begin
            if(user1_point == user2_point)
                clk1_winner <= 2'b00;
            else if(user1_point > user2_point )
                clk1_winner <= 2'b10;
            else
            begin
                clk1_winner <= 2'b11;
                //trace <= 1;
            end
        end
    end
    else
    begin
        clk1_winner <= clk1_winner;
    end
end
// equalfff
always@(posedge clk1 or negedge rst_n)
begin
    if(!rst_n)
    begin
        equalff <= 0;
    end
    else
    begin
        equalff <= clk1_equal;
    end
end
// exceedfff
always@(posedge clk1 or negedge rst_n)
begin
    if(!rst_n)
    begin
        exceedff <= 0;
    end
    else
    begin
        exceedff <= clk1_exceed;
    end
end
//winnerff
always@(posedge clk1 or negedge rst_n)
begin
    if(!rst_n)
    begin
        winnerff <= 0;
    end
    else
    begin
        winnerff <= clk1_winner;
    end
end
// out_valid_r3
always@(posedge clk1 or negedge rst_n)
begin
    if(!rst_n)
    begin
        out_valid_r3 <= 0;
    end
    else if(clk1_cnt10 == 1)
    begin
        out_valid_r3 <= 1;
    end
    else
    begin
        out_valid_r3 <= 0;
    end
end
// out_valid_r4
always@(posedge clk1 or negedge rst_n)
begin
    if(!rst_n)
    begin
        out_valid_r4 <= 0;
    end
    else if(clk1_cnt10 == 2)
    begin
        out_valid_r4 <= 1;
    end
    else
    begin
        out_valid_r4 <= 0;
    end
end
// out_valid_r8
always@(posedge clk1 or negedge rst_n)
begin
    if(!rst_n)
    begin
        out_valid_r8 <= 0;
    end
    else if(clk1_cnt10 == 6)
    begin
        out_valid_r8 <= 1;
    end
    else
    begin
        out_valid_r8 <= 0;
    end
end
// out_valid_r9
always@(posedge clk1 or negedge rst_n)
begin
    if(!rst_n)
    begin
        out_valid_r9 <= 0;
    end
    else if(clk1_cnt10 == 7)
    begin
        out_valid_r9 <= 1;
    end
    else
    begin
        out_valid_r9 <= 0;
    end
end
// out_valid_r10
always@(posedge clk1 or negedge rst_n)
begin
    if(!rst_n)
    begin
        out_valid_r10 <= 0;
    end
    else if(clk1_cnt10 == 8)
    begin
        out_valid_r10 <= 1;
    end
    else
    begin
        out_valid_r10 <= 0;
    end
end
//============================================
//   clk3 domain
//============================================
//flag3
always@(posedge clk3 or negedge rst_n)
begin
    if(!rst_n)
    begin
        flag3 <= 0;
    end
    else
    begin
        flag3 <= out_valid_w3;
    end
end
//flag4
always@(posedge clk3 or negedge rst_n)
begin
    if(!rst_n)
    begin
        flag4 <= 0;
    end
    else
    begin
        flag4 <= out_valid_w4;
    end
end
//flag8
always@(posedge clk3 or negedge rst_n)
begin
    if(!rst_n)
    begin
        flag8 <= 0;
    end
    else
    begin
        flag8 <= out_valid_w8;
    end
end
//flag9
always@(posedge clk3 or negedge rst_n)
begin
    if(!rst_n)
    begin
        flag9 <= 0;
    end
    else
    begin
        flag9 <= out_valid_w9;
    end
end
//flag10
always@(posedge clk3 or negedge rst_n)
begin
    if(!rst_n)
    begin
        flag10 <= 0;
    end
    else
    begin
        flag10 <= out_valid_w10;
    end
end
/// out ///
reg out_valid11;
// out_valid11 clk3_cnt7 7cycle
always@(posedge clk3 or negedge rst_n)
begin
    if(!rst_n)
    begin
        out_valid11 <= 0;
    end
    else if(flag3 == 1 || flag4 == 1 || flag8 == 1 || flag9 == 1)
    begin
        out_valid11 <= 1;
    end
    else if(clk3_cnt7== 6)
    begin
        out_valid11 <= 0;
    end
    else
    begin
        out_valid11 <= out_valid11;
    end
end
// out_valid1 delay 1 cycle
always@(posedge clk3 or negedge rst_n)
begin
    if(!rst_n)
    begin
        out_valid1 <= 0;
    end
    else if(out_valid11 == 1)
    begin
        out_valid1 <= 1;
    end
    else
        out_valid1 <= 0;
end
// clk3_cnt7 7cycle
always@(posedge clk3 or negedge rst_n)
begin
    if(!rst_n)
    begin
        clk3_cnt7 <= 0;
    end
    else if(flag3 == 1 || flag4 == 1 || flag8 == 1 || flag9 == 1)
    begin
        clk3_cnt7 <= 0;
    end
    else
    begin
        if(clk3_cnt7 == 6)
            clk3_cnt7 <= 0;
        else
            clk3_cnt7 <= clk3_cnt7 + 1;
    end
end
//clk3_equal
always@(posedge clk3 or negedge rst_n)
begin
    if(!rst_n)
    begin
        clk3_equal <= 0;
    end
    else if(flag3 == 1 || flag4 == 1 || flag8 == 1 || flag9 == 1)
    begin
        clk3_equal <= equalff;
    end
    else
    begin
        clk3_equal <= clk3_equal;
    end
end
//clk3_exceed
always@(posedge clk3 or negedge rst_n)
begin
    if(!rst_n)
    begin
        clk3_exceed <= 0;
    end
    else if(flag3 == 1 || flag4 == 1 || flag8 == 1 || flag9 == 1)
    begin
        clk3_exceed <= exceedff;
    end
    else
    begin
        clk3_exceed <= clk3_exceed;
    end
end
//clk3_winner
always@(posedge clk3 or negedge rst_n)
begin
    if(!rst_n)
    begin
        clk3_winner <= 0;
    end
    else if(flag10 == 1)
    begin
        clk3_winner <= winnerff;
    end
    else
    begin
        clk3_winner <= clk3_winner;
    end
end
// valid1 equal & exceed //
// equal
always@(posedge clk3 or negedge rst_n)
begin
    if(!rst_n)
    begin
        equal <= 0;
    end
    else if(out_valid11 == 1)
    begin
        equal <= clk3_equal[6-clk3_cnt7];
    end
    else
    begin
        equal <= 0;
    end
end
// exceed
always@(posedge clk3 or negedge rst_n)
begin
    if(!rst_n)
    begin
        exceed <= 0;
    end
    else if(out_valid11 == 1)
    begin
        exceed <= clk3_exceed[6-clk3_cnt7];
    end
    else
    begin
        exceed <= 0;
    end
end
reg out_valid22;
// out_valid22 clk3_cnt2 1 or 2cycle
always@(posedge clk3 or negedge rst_n)
begin
    if(!rst_n)
    begin
        out_valid22 <= 0;
    end
    else if(flag10 == 1)
    begin
        out_valid22 <= 1;
    end
    else if(clk1_winner == 0 && clk3_cnt2 == 0)
    begin
        out_valid22 <= 0;
    end
    else if(clk1_winner > 0 && clk3_cnt2 == 1)
    begin
        out_valid22 <= 0;
    end
    else
    begin
        out_valid22 <= out_valid22;
    end
end
// out_valid1 delay 1 cycle
always@(posedge clk3 or negedge rst_n)
begin
    if(!rst_n)
    begin
        out_valid2 <= 0;
    end
    else if(out_valid22 == 1)
    begin
        out_valid2 <= 1;
    end
    else
        out_valid2 <= 0;
end
// clk3_cnt2 2cycle
always@(posedge clk3 or negedge rst_n)
begin
    if(!rst_n)
    begin
        clk3_cnt2 <= 0;
    end
    else if(flag10 == 1)
    begin
        clk3_cnt2 <= 0;
    end
    else
    begin
        clk3_cnt2 <= clk3_cnt2 + 1;
    end
end
// winner
always@(posedge clk3 or negedge rst_n)
begin
    if(!rst_n)
    begin
        winner <= 0;
    end
    else if(out_valid22 == 1)
    begin
        winner <= clk3_winner[1-clk3_cnt2];
    end
    else
    begin
        winner <= 0;
    end
end
//---------------------------------------------------------------------
//   syn_XOR
//---------------------------------------------------------------------
//clk_1 to clk_3
syn_XOR u_syn_XOR3(.IN(out_valid_r3),.OUT(out_valid_w3),.TX_CLK(clk1),.RX_CLK(clk3),.RST_N(rst_n));
syn_XOR u_syn_XOR4(.IN(out_valid_r4),.OUT(out_valid_w4),.TX_CLK(clk1),.RX_CLK(clk3),.RST_N(rst_n));
syn_XOR u_syn_XOR8(.IN(out_valid_r8),.OUT(out_valid_w8),.TX_CLK(clk1),.RX_CLK(clk3),.RST_N(rst_n));
syn_XOR u_syn_XOR9(.IN(out_valid_r9),.OUT(out_valid_w9),.TX_CLK(clk1),.RX_CLK(clk3),.RST_N(rst_n));
syn_XOR u_syn_XOR10(.IN(out_valid_r10),.OUT(out_valid_w10),.TX_CLK(clk1),.RX_CLK(clk3),.RST_N(rst_n));

endmodule
