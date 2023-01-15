
// synopsys translate_off
`include "/usr/synthesis/dw/sim_ver/DW_div.v"
`include "/usr/synthesis/dw/sim_ver/DW_div_pipe.v"
// synopsys translate_on


module EDH(
           clk,
           rst_n,
           op,
           in_valid,
           pic_no,
           se_no,
           busy,

           //AXI
           arid_m_inf,
           araddr_m_inf,
           arlen_m_inf,
           arsize_m_inf,
           arburst_m_inf,
           arvalid_m_inf,
           arready_m_inf,

           rid_m_inf,
           rdata_m_inf,
           rresp_m_inf,
           rlast_m_inf,
           rvalid_m_inf,
           rready_m_inf,

           awid_m_inf,
           awaddr_m_inf,
           awsize_m_inf,
           awburst_m_inf,
           awlen_m_inf,
           awvalid_m_inf,
           awready_m_inf,

           wdata_m_inf,
           wlast_m_inf,
           wvalid_m_inf,
           wready_m_inf,

           bid_m_inf,
           bresp_m_inf,
           bvalid_m_inf,
           bready_m_inf
       );
//==============================================//
//               PORT DECLARATION               //
//==============================================//
// PORT Parameter
parameter width_id      = 4;
parameter data_width    = 128;
parameter address_width = 32;

/// IN OUT SIGNAL ///
input  wire   clk, rst_n, in_valid;
input [3:0]   pic_no;
input [1:0]   op;
input [5:0]   se_no;

output reg    busy;
/// AXI ///
//==================Write Output================//
// AXI Write Address Channel //
// master
output wire [width_id-1:0]      awid_m_inf;    //fix 'b0
output reg  [address_width-1:0] awaddr_m_inf;  //each time 32'h00040000 + pic_no*32'h00001000
output wire [2:0]               awsize_m_inf;  //fix 3'b100
output wire [1:0]               awburst_m_inf; //fix 2'b01
output reg  [7:0]               awlen_m_inf;   //each time 8'd255
output reg                      awvalid_m_inf; //awready_m_inf == 1 turn to 0
// slave
input  wire                     awready_m_inf; //awready_m_inf == 1 awvalid_m_inf turn to 0

// AXI Write Data Channel //
// master
output reg [data_width-1:0]  wdata_m_inf;   //sram out value
output reg                   wlast_m_inf;   //cnt256_out == 254 turn to 1 else 0
output reg                   wvalid_m_inf;  //awready_m_inf == 1 turn to 1 cnt256_out == 255 turn to 0
// slave
input  wire                  wready_m_inf;  //sram_addr_r ++

/// None Need to Use ///
// AXI Write Response Channel //
// slave
input  wire  [width_id-1:0]  bid_m_inf;    //none use
input  wire  [1:0]           bresp_m_inf;  //none use
input  wire                  bvalid_m_inf; //no need to use
// master
output reg                   bready_m_inf; //no need to use
//==================Read Input==================//
// AXI Read Addresss Channel //
// master
output wire [width_id-1:0]      arid_m_inf;    //fix 'b0
output reg  [address_width-1:0] araddr_m_inf;  //SE & PIC 2way
output reg  [7:0]               arlen_m_inf;   //SE & PIC 2way
output wire [2:0]               arsize_m_inf;  //fix 3'b100
output wire [1:0]               arburst_m_inf; //fix 2'b01
output reg                      arvalid_m_inf; //arready_m_inf == 1 turn to 0
// slave
input  wire                     arready_m_inf; //arready_m_inf == 1 arvalid_m_inf turn to 0

// AXI Read Data Channel //
// slave
input  wire [width_id-1:0]    rid_m_inf;   //no use
input  wire [data_width-1:0]  rdata_m_inf; //rvalid_m_inf == 1 receive data
input  wire [1:0]             rresp_m_inf; //no use
input  wire                   rlast_m_inf; //rlast_m_inf == 1 rready_m_inf turn to 0
input  wire                   rvalid_m_inf;//rvalid_m_inf == 1 rdata_m_inf get data
// master
output reg                    rready_m_inf;//arready_m_inf == 1 turn to 1 rlast_m_inf == 1 turn to 0

//==============================================//
//             Parameter and Integer            //
//==============================================//
// FSM Parameter
parameter s_idle    = 3'd0;
parameter s_se      = 3'd1;
parameter s_pic     = 3'd2;
parameter s_cal     = 3'd3;
parameter s_waddr   = 3'd4;
parameter s_out     = 3'd5;
parameter s_his_pic = 3'd6;
parameter s_his_cdf = 3'd7;

// Integer genvar
genvar idx;
//==============================================//
//           WIRE AND REG DECLARATION           //
//==============================================//
// get input data
reg [3:0] pic_no_current;
reg [1:0] op_current;
reg [5:0] se_no_current;

/// controler ///
// fsm
reg [2:0] current_state, next_state;
// cnt
reg [8:0] cnt256_input;
reg [8:0] cnt256_out;
reg [8:0] cnt256_cal;
reg [8:0] cnt256_cdf;
reg [2:0] cnt_waddr;
reg [1:0] cnt_padding;

// sram_output
wire [127:0] sram_output_out;
//wire sram_output_cen // always enable
//wire sram_output_oen // always enable
reg sram_output_wen;
reg [7:0] sram_output_addr;
reg [127:0] sram_output_in;

// input data
reg [127:0] se_data;
// pic input buffer
reg [127:0]pic_row0[3:0];
reg [127:0]pic_row1[3:0];
reg [127:0]pic_row2[3:0];
reg [127:0]pic_row3[3:0];

// Erosion Dilation result
wire [127:0] ero_result;
wire [127:0] dil_result;
wire [127:0] his_result;

reg  [12:0] cdf_value_table[255:0];
reg  busy_flag;

reg wready_flag;
reg [127:0] ero_dil_value;
//==============================================//
//            FSM State Declaration             //
//==============================================//
// current_state //
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
            if(in_valid == 1)
            begin
                if(op == 2)
                begin
                    next_state = s_his_pic;
                end
                else
                begin
                    next_state = s_se;
                end
            end
            else
            begin
                next_state = s_idle;
            end
        end
        s_se:
        begin
            if(rlast_m_inf == 1)
            begin
                next_state = s_pic;
            end
            else
            begin
                next_state = s_se;
            end
        end
        s_pic:
        begin
            if(cnt256_input == 9'd15)
            begin
                next_state = s_cal;
            end
            else
            begin
                next_state = s_pic;
            end
        end
        s_cal:
        begin
            if(cnt256_cal == 9'd256)
            begin
                next_state = s_waddr;
            end
            else
            begin
                next_state = s_cal;
            end
        end
        s_waddr:
        begin
            if(awready_m_inf == 1)
            begin
                next_state = s_out;
            end
            else
            begin
                next_state = s_waddr;
            end
        end
        s_out:
        begin
            if(cnt256_out == 9'd256)
            begin
                next_state = s_idle;
            end
            else
            begin
                next_state = s_out;
            end
        end
        s_his_pic:
        begin
            if(cnt256_input == 9'd256)
            begin
                next_state = s_his_cdf;
            end
            else
            begin
                next_state = s_his_pic;
            end
        end
        s_his_cdf:
        begin
            if(cnt256_cdf == 9'd259)
            begin
                next_state = s_waddr;
            end
            else
            begin
                next_state = s_his_cdf;
            end
        end
        default:
        begin
            next_state = s_idle;
        end
    endcase
end

//==============================================//
//                 cnt controler                //
//==============================================//
// cnt256_input
always@(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        cnt256_input <= 9'd0;
    else if(current_state == s_idle)
        cnt256_input <= 9'd0;
    else if(current_state == s_pic && cnt256_input < 9'd256 && rvalid_m_inf == 1'd1)
        cnt256_input <= cnt256_input + 1;
    else if(current_state == s_cal && cnt256_input < 9'd256 && rvalid_m_inf == 1'd1)
        cnt256_input <= cnt256_input + 1;
    else if(current_state == s_his_pic && cnt256_input < 9'd256 && rvalid_m_inf == 1'd1)
        cnt256_input <= cnt256_input + 1;
    else
        cnt256_input <= 9'd0;
end
// cnt256_out
always@(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        cnt256_out <= 9'd0;
    else if(current_state == s_idle)
        cnt256_out <= 9'd0;
    else if(current_state == s_out && wready_m_inf == 1)
        cnt256_out <= cnt256_out + 1;
    else
        cnt256_out <= 9'd0;
end
// cnt256_cal
always@(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        cnt256_cal <= 9'd0;
    else if(current_state == s_idle)
        cnt256_cal <= 9'd0;
    else if(current_state == s_cal)
        cnt256_cal <= cnt256_cal + 1;
    else
        cnt256_cal <= 9'd0;
end
// cnt256_cdf
always@(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        cnt256_cdf <= 9'd0;
    else if(current_state == s_idle)
        cnt256_cdf <= 9'd0;
    else if(current_state == s_his_cdf)
        cnt256_cdf <= cnt256_cdf + 1;
    else
        cnt256_cdf <= 9'd0;
end
// cnt_padding
always@(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        cnt_padding <= 2'd0;
    else if(current_state == s_idle)
        cnt_padding <= 2'd0;
    else if(current_state == s_pic && rvalid_m_inf == 1)
        cnt_padding <= cnt_padding + 1;
    else if(current_state == s_cal )/*rvalid_m_inf*/
        cnt_padding <= cnt_padding + 1;
    else if(current_state == s_his_pic)
        cnt_padding <= cnt_padding + 1;
    else
        cnt_padding <= 2'd0;
end
// cnt_waddr
always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        cnt_waddr <= 0;
    else if(current_state == s_idle)
        cnt_waddr <= 0;
    else if(current_state == s_waddr)
    begin
        if(cnt_waddr < 6)
            cnt_waddr <= cnt_waddr + 1;
        else
            cnt_waddr <= cnt_waddr;
    end
    else
        cnt_waddr <= 0;
end

//==============================================//
//                   AXI port                   //
//==============================================//
/// fix signal ///
// axi write address channel //
assign awid_m_inf    =  'b0;
assign awsize_m_inf  = 3'b100;
assign awburst_m_inf = 2'b01;
// axi read addr channel //
assign arid_m_inf    =  'b0;
assign arsize_m_inf  = 3'b100;
assign arburst_m_inf = 2'b01;

/// Write Address Channel ///
// awaddr_m_inf each time same value
always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        awaddr_m_inf <= 32'h00040000;
    else
        awaddr_m_inf <= 32'h00040000 + pic_no_current * 32'h00001000;
end
// awlen_m_inf each time same value
always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        awlen_m_inf = 8'd255;
    else
        awlen_m_inf = 8'd255;
end
// awvalid_m_inf
always@(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        awvalid_m_inf <= 0;
    else if(current_state == s_waddr && cnt_waddr == 4)/*need 5 cycle to read 3 data to output buffer*/
        awvalid_m_inf <= 1;
    else if(awready_m_inf == 1)
        awvalid_m_inf <= 0;
    else
        awvalid_m_inf <= awvalid_m_inf;
end
/// Write Data Channel ///
// wdata_m_inf output buffer to dram
// wlast_m_inf
always@(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        wlast_m_inf <= 0;
    else if(cnt256_out == 9'd254)
        wlast_m_inf <= 1;
    else
        wlast_m_inf <= 0;
end
// wvalid_m_inf
always@(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        wvalid_m_inf <= 0;
    else if(awready_m_inf == 1)
        wvalid_m_inf <= 1;
    else if(cnt256_out == 9'd255)
        wvalid_m_inf <= 0;
    else
        wvalid_m_inf <= wvalid_m_inf;
end
/// Write Response Channel ///
// nont need use

/// Read Address Channel ///
// araddr_m_inf SE & PIC 2way
always@(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        araddr_m_inf <= 0;
    else if(next_state == s_pic)
        araddr_m_inf <= 32'h00040000 + pic_no_current * 32'h00001000;
    else if(in_valid == 1)
    begin
        if(op == 2)
            araddr_m_inf <= 32'h00040000 + pic_no * 32'h00001000;
        else
            araddr_m_inf <= 32'h00030000 + se_no  * 32'h00000010;
    end
    else
        araddr_m_inf <= araddr_m_inf;
end
// arlen_m_inf SE & PIC 2way pic 255 se 0
always@(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        arlen_m_inf <= 8'd0;
    else if(in_valid == 1)
    begin
        if(op == 2)
            arlen_m_inf <= 8'd255;
        else
            arlen_m_inf <= 8'd0;
    end
    else if(current_state == s_se && rlast_m_inf == 1)
        arlen_m_inf <= 8'd255;
    else
        arlen_m_inf <= arlen_m_inf;
end
// arvalid_m_inf put address handshake
always@(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        arvalid_m_inf <= 0;
    else if(in_valid == 1)
        arvalid_m_inf <= 1;
    else if(arready_m_inf == 1'd1)
        arvalid_m_inf <= 0;
    else if(current_state == s_se && rlast_m_inf == 1)
        arvalid_m_inf <= 1;
    else
        arvalid_m_inf <= arvalid_m_inf;
end
/// Read Data Channel ///
// out rready_m_inf get data handshake
always@(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        rready_m_inf <= 0;
    else if(arready_m_inf == 1'd1)
        rready_m_inf <= 1;
    else if(rlast_m_inf == 1'd1)
        rready_m_inf <= 0;
    else
        rready_m_inf <= rready_m_inf;
end

//==============================================//
//              SRAM control Design             //
//==============================================//
// sram output data need delay 2 cycle  sram_input_out & sram_output_out
RA1SH outputdata_sram(.Q(sram_output_out), .CLK(clk), .CEN(1'b0), .WEN(sram_output_wen), .A(sram_output_addr), .D(sram_output_in), .OEN(1'b0));

/// outputdata_sram ///
// sram_output_wen
always@(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        sram_output_wen <= 1'd0;
    else if(current_state == s_idle)/*initial value*/
        sram_output_wen <= 1'd0;
    else if(current_state == s_cal)/*cal & write  data*/
        sram_output_wen <= 1'd0;
    else if(current_state == s_waddr)/*read data*/
        sram_output_wen <= 1'd1;
    else if(current_state == s_out)/*read data*/
        sram_output_wen <= 1'd1;
    //his//
    else if(current_state == s_his_pic)/*write data wen control*/
        sram_output_wen <= 1'd0;
    else if(current_state == s_his_cdf)/*cal read data wen control*/
        sram_output_wen <= 1'd1;
    else
        sram_output_wen <= sram_output_wen;
end
// sram_output_addr
always@(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        sram_output_addr <= 8'd0;
    else if(current_state == s_idle)/*initial value*/
        sram_output_addr <= 8'd0;
    else if(current_state == s_cal && cnt256_cal > 0)/*write data address*/
    begin
        if(cnt256_cal == 9'd256)
            sram_output_addr <= 0;
        else
            sram_output_addr <= sram_output_addr + 8'd1;
    end
    /*read data address*/
    else if(current_state == s_waddr)
        if(cnt_waddr > 3)
        begin
            sram_output_addr <= sram_output_addr;
        end
        else
            sram_output_addr <= sram_output_addr + 8'd1;
    /*read data address*/
    else if(current_state == s_out && wready_m_inf == 1)
        sram_output_addr <= sram_output_addr + 8'd1;
    //his//
    else if(current_state == s_his_pic && rvalid_m_inf == 1'd1 && cnt256_input < 256)/*write data address*/
    begin
        sram_output_addr <= sram_output_addr + 8'd1;
    end
    //new add
    else if(current_state == s_his_cdf)
        sram_output_addr <= 0;
    else
        sram_output_addr <= sram_output_addr;
end

// sram_input_out to sram_output_in
wire [7:0] pic_data_array[15:0];
generate
    for(idx=0; idx<16; idx=idx+1)
    begin
        wire [7:0] pixel_data = sram_output_out[idx*8+7:idx*8];
        wire [7:0] cdf_output_value  = cdf_value_table[pixel_data];
        assign pic_data_array[idx] = cdf_output_value;
    end
endgenerate
assign his_result = {pic_data_array[15], pic_data_array[14], pic_data_array[13], pic_data_array[12],
                     pic_data_array[11], pic_data_array[10], pic_data_array[9],  pic_data_array[8],
                     pic_data_array[7],  pic_data_array[6],  pic_data_array[5],  pic_data_array[4],
                     pic_data_array[3],  pic_data_array[2],  pic_data_array[1],  pic_data_array[0]
                    };
// sram_output_in
always@(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        sram_output_in <= 128'd0;
    else if(current_state == s_idle)/*initial value*/
        sram_output_in <= 128'd0;
    else if(current_state == s_cal)/*write data*/
    begin
        sram_output_in <= ero_dil_value;
    end
    //his//
    else if(current_state == s_his_pic && rvalid_m_inf == 1'd1 && cnt256_input < 256)/*write data*/
        sram_output_in <= rdata_m_inf;
    else
        sram_output_in <= sram_output_in;
end

//==============================================//
//             SRAM to Output Buffer            //
//==============================================//
reg [127:0] output_buffer [3:0];
wire [127:0] data_out_w = (op_current == 2)? his_result:sram_output_out;
reg [127:0] data_out_r;
always@(posedge clk or negedge rst_n)
begin
    if(!rst_n)
    begin
        data_out_r <= 0;
    end
    else if(wready_m_inf==1)
    begin
        data_out_r <= data_out_w;
    end
end
// output_buffer[3]
always@(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        output_buffer[3] <= 0;
    else if(current_state == s_idle)
        output_buffer[3] <= 0;
    else if(current_state == s_waddr && cnt_waddr == 5)
        output_buffer[3] <= data_out_w;
    else
        output_buffer[3] <= output_buffer[3];
end
// output_buffer[2]
always@(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        output_buffer[2] <= 0;
    else if(current_state == s_idle)
        output_buffer[2] <= 0;
    else if(current_state == s_waddr && cnt_waddr == 4)
        output_buffer[2] <= data_out_w;
    else
        output_buffer[2] <= output_buffer[2];
end
// output_buffer[1]
always@(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        output_buffer[1] <= 0;
    else if(current_state == s_idle)
        output_buffer[1] <= 0;
    else if(current_state == s_waddr && cnt_waddr == 3)
        output_buffer[1] <= data_out_w;
    else
        output_buffer[1] <= output_buffer[1];
end
// output_buffer[0]
always@(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        output_buffer[0] <= 0;
    else if(current_state == s_idle)
        output_buffer[0] <= 0;
    else if(current_state == s_waddr && cnt_waddr == 2)
        output_buffer[0] <= data_out_w;
    else
        output_buffer[0] <= output_buffer[0];
end

always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        wready_flag <= 0;
    else if(current_state == s_idle)
        wready_flag <= 0;
    else if(current_state == s_out && wready_m_inf == 1)
        wready_flag <= 1;
    else
        wready_flag <= 0;
end
// wdata_m_inf
always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        wdata_m_inf <= 0;
    else if(current_state == s_idle)
        wdata_m_inf <= 0;
    else if(awready_m_inf == 1)
        wdata_m_inf <= output_buffer[0];
    else if(current_state == s_out && wready_flag == 0 && wready_m_inf == 1)
        wdata_m_inf <= output_buffer[1];
    else if(current_state == s_out && cnt256_out == 1)
        wdata_m_inf <= output_buffer[2];
    else if(current_state == s_out && cnt256_out == 2)
        wdata_m_inf <= output_buffer[3];
    else if(current_state == s_out && cnt256_out > 1)
        wdata_m_inf <= data_out_r;
    else
        wdata_m_inf <= wdata_m_inf;
end

//==============================================//
//                get input data                //
//==============================================//
// op_current
always@(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        op_current <= 0;
    else if(in_valid == 1)
        op_current <= op;
    else
        op_current <= op_current;
end
// pic_no_current
always@(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        pic_no_current <= 0;
    else if(in_valid == 1)
        pic_no_current <= pic_no;
    else
        pic_no_current <= pic_no_current;
end
// se_no_current
always@(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        se_no_current <= 0;
    else if(in_valid == 1)
        se_no_current <= se_no;
    else
        se_no_current <= se_no_current;
end

//==============================================//
//                   Main Code                  //
//==============================================//
/// global output ///
// busy flag
always@(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        busy_flag <= 0;
    else
        busy_flag <= in_valid;
end
// busy
always@(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        busy <= 0;
    else if(busy_flag == 1)
        busy <= 1;
    else if(current_state == s_out && cnt256_out == 256)
        busy <= 0;
    else
        busy <= busy;
end

/// input data ///
// se_no to se_data
always@(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        se_data <= 128'd0;
    else if(current_state == s_se && rvalid_m_inf == 1)
        se_data <= rdata_m_inf;
    else
        se_data <= se_data;
end

//==============================================//
//         Erosion & Dilation Calculation       //
//==============================================//
/// se ///
wire [7:0] se_array[15:0];
generate
    for(idx=0; idx<16 ; idx=idx+1)
    begin
        wire [7:0] ero_tmp = se_data[idx*8+7:0+idx*8];
        wire [7:0] dil_tmp = se_data[(15-idx)*8+7:0+(15-idx)*8];
        assign se_array[idx] = (op_current == 0) ? ero_tmp : dil_tmp;
    end
endgenerate

/// pic input shift buffer ///
// pic_row0 //
// pic_row0[3]
always@(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        pic_row0[3] <= 0;
    else
        pic_row0[3] <= pic_row1[0];
end
// pic_row0[0 1 2]
generate
    for(idx=0 ; idx<3; idx=idx+1)
    begin
        always@(posedge clk or negedge rst_n)
        begin
            if(!rst_n)
                pic_row0[idx] <= 0;
            else
                pic_row0[idx] <= pic_row0[idx+1];
        end
    end
endgenerate
// pic_row1 //
// pic_row1[3]
always@(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        pic_row1[3] <= 0;
    else
        pic_row1[3] <= pic_row2[0];
end
// pic_row1[0 1 2]
generate
    for(idx=0 ; idx<3; idx=idx+1)
    begin
        always@(posedge clk or negedge rst_n)
        begin
            if(!rst_n)
                pic_row1[idx] <= 0;
            else
                pic_row1[idx] <= pic_row1[idx+1];
        end
    end
endgenerate
// pic_row2 //
// pic_row2[3]
always@(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        pic_row2[3] <= 0;
    else
        pic_row2[3] <= pic_row3[0];
end
// pic_row2[0 1 2]
generate
    for(idx=0 ; idx<3; idx=idx+1)
    begin
        always@(posedge clk or negedge rst_n)
        begin
            if(!rst_n)
                pic_row2[idx] <= 0;
            else
                pic_row2[idx] <= pic_row2[idx+1];
        end
    end
endgenerate
// pic_row3 //
// pic_row3[3]
always@(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        pic_row3[3] <= 0;
    else if(current_state == s_pic && rvalid_m_inf == 1)
        pic_row3[3] <= rdata_m_inf;
    else if(current_state == s_cal && rvalid_m_inf == 1)
        pic_row3[3] <= rdata_m_inf;
    else
        pic_row3[3] <= 0;
end

// pic_row3[0 1 2]
generate
    for(idx=0 ; idx<3; idx=idx+1)
    begin
        always@(posedge clk or negedge rst_n)
        begin
            if(!rst_n)
                pic_row3[idx] <= 0;
            else
                pic_row3[idx] <= pic_row3[idx+1];
        end
    end
endgenerate

/// Erosion & Dilation Calculation ///
// common item
wire [151:0] pic_dataow0 = (cnt_padding == 3) ? {24'b0,pic_row0[0]}:{pic_row0[1][23:0],pic_row0[0]};
wire [151:0] pic_dataow1 = (cnt_padding == 3) ? {24'b0,pic_row1[0]}:{pic_row1[1][23:0],pic_row1[0]};
wire [151:0] pic_dataow2 = (cnt_padding == 3) ? {24'b0,pic_row2[0]}:{pic_row2[1][23:0],pic_row2[0]};
wire [151:0] pic_dataow3 = (cnt_padding == 3) ? {24'b0,pic_row3[0]}:{pic_row3[1][23:0],pic_row3[0]};

wire [7:0] ero_pic_array[15:0];
wire [7:0] dil_pic_array[15:0];

// ero_result
assign ero_result ={ero_pic_array[15], ero_pic_array[14], ero_pic_array[13], ero_pic_array[12],
                    ero_pic_array[11], ero_pic_array[10], ero_pic_array[9],  ero_pic_array[8],
                    ero_pic_array[7],  ero_pic_array[6],  ero_pic_array[5],  ero_pic_array[4],
                    ero_pic_array[3],  ero_pic_array[2],  ero_pic_array[1],  ero_pic_array[0]};
// dil_result
assign dil_result ={dil_pic_array[15], dil_pic_array[14], dil_pic_array[13], dil_pic_array[12],
                    dil_pic_array[11], dil_pic_array[10], dil_pic_array[9],  dil_pic_array[8],
                    dil_pic_array[7],  dil_pic_array[6],  dil_pic_array[5],  dil_pic_array[4],
                    dil_pic_array[3],  dil_pic_array[2],  dil_pic_array[1],  dil_pic_array[0]};

// erosion //
generate
    for(idx=0; idx<16; idx=idx+1)
    begin
        wire [7:0] elm0  = (pic_dataow0[idx*8+7:idx*8+0]   < se_array[0])?  8'd0:(pic_dataow0[idx*8+7:idx*8+0]   - se_array[0]);
        wire [7:0] elm1  = (pic_dataow0[idx*8+15:idx*8+8]  < se_array[1])?  8'd0:(pic_dataow0[idx*8+15:idx*8+8]  - se_array[1]);
        wire [7:0] elm2  = (pic_dataow0[idx*8+23:idx*8+16] < se_array[2])?  8'd0:(pic_dataow0[idx*8+23:idx*8+16] - se_array[2]);
        wire [7:0] elm3  = (pic_dataow0[idx*8+31:idx*8+24] < se_array[3])?  8'd0:(pic_dataow0[idx*8+31:idx*8+24] - se_array[3]);
        wire [7:0] elm4  = (pic_dataow1[idx*8+7:idx*8+0]   < se_array[4])?  8'd0:(pic_dataow1[idx*8+7:idx*8+0]   - se_array[4]);
        wire [7:0] elm5  = (pic_dataow1[idx*8+15:idx*8+8]  < se_array[5])?  8'd0:(pic_dataow1[idx*8+15:idx*8+8]  - se_array[5]);
        wire [7:0] elm6  = (pic_dataow1[idx*8+23:idx*8+16] < se_array[6])?  8'd0:(pic_dataow1[idx*8+23:idx*8+16] - se_array[6]);
        wire [7:0] elm7  = (pic_dataow1[idx*8+31:idx*8+24] < se_array[7])?  8'd0:(pic_dataow1[idx*8+31:idx*8+24] - se_array[7]);
        wire [7:0] elm8  = (pic_dataow2[idx*8+7:idx*8+0]   < se_array[8])?  8'd0:(pic_dataow2[idx*8+7:idx*8+0]   - se_array[8]);
        wire [7:0] elm9  = (pic_dataow2[idx*8+15:idx*8+8]  < se_array[9])?  8'd0:(pic_dataow2[idx*8+15:idx*8+8]  - se_array[9]);
        wire [7:0] elm10 = (pic_dataow2[idx*8+23:idx*8+16] < se_array[10])? 8'd0:(pic_dataow2[idx*8+23:idx*8+16] - se_array[10]);
        wire [7:0] elm11 = (pic_dataow2[idx*8+31:idx*8+24] < se_array[11])? 8'd0:(pic_dataow2[idx*8+31:idx*8+24] - se_array[11]);
        wire [7:0] elm12 = (pic_dataow3[idx*8+7:idx*8+0]   < se_array[12])? 8'd0:(pic_dataow3[idx*8+7:idx*8+0]   - se_array[12]);
        wire [7:0] elm13 = (pic_dataow3[idx*8+15:idx*8+8]  < se_array[13])? 8'd0:(pic_dataow3[idx*8+15:idx*8+8]  - se_array[13]);
        wire [7:0] elm14 = (pic_dataow3[idx*8+23:idx*8+16] < se_array[14])? 8'd0:(pic_dataow3[idx*8+23:idx*8+16] - se_array[14]);
        wire [7:0] elm15 = (pic_dataow3[idx*8+31:idx*8+24] < se_array[15])? 8'd0:(pic_dataow3[idx*8+31:idx*8+24] - se_array[15]);
        wire [127:0] tmp_in = {elm0,elm1,elm2,elm3,elm4,elm5,elm6,elm7,elm8,elm9,elm10,elm11,elm12,elm13,elm14,elm15};
        wire [7:0] tmp_out;
        Min_16to1 u_Min_16to1(tmp_in,tmp_out);
        assign ero_pic_array[idx] = tmp_out;
    end
endgenerate

// Dilation //
generate
    for(idx=0; idx<16; idx=idx+1)
    begin
        wire [8:0] eelm0  = pic_dataow0[idx*8+7:idx*8+0]   + se_array[0];
        wire [8:0] eelm1  = pic_dataow0[idx*8+15:idx*8+8]  + se_array[1];
        wire [8:0] eelm2  = pic_dataow0[idx*8+23:idx*8+16] + se_array[2];
        wire [8:0] eelm3  = pic_dataow0[idx*8+31:idx*8+24] + se_array[3];
        wire [8:0] eelm4  = pic_dataow1[idx*8+7:idx*8+0]   + se_array[4];
        wire [8:0] eelm5  = pic_dataow1[idx*8+15:idx*8+8]  + se_array[5];
        wire [8:0] eelm6  = pic_dataow1[idx*8+23:idx*8+16] + se_array[6];
        wire [8:0] eelm7  = pic_dataow1[idx*8+31:idx*8+24] + se_array[7];
        wire [8:0] eelm8  = pic_dataow2[idx*8+7:idx*8+0]   + se_array[8];
        wire [8:0] eelm9  = pic_dataow2[idx*8+15:idx*8+8]  + se_array[9];
        wire [8:0] eelm10 = pic_dataow2[idx*8+23:idx*8+16] + se_array[10];
        wire [8:0] eelm11 = pic_dataow2[idx*8+31:idx*8+24] + se_array[11];
        wire [8:0] eelm12 = pic_dataow3[idx*8+7:idx*8+0]   + se_array[12];
        wire [8:0] eelm13 = pic_dataow3[idx*8+15:idx*8+8]  + se_array[13];
        wire [8:0] eelm14 = pic_dataow3[idx*8+23:idx*8+16] + se_array[14];
        wire [8:0] eelm15 = pic_dataow3[idx*8+31:idx*8+24] + se_array[15];
        wire [143:0] etmp_in = {eelm0,eelm1,eelm2,eelm3,eelm4,eelm5,eelm6,eelm7,eelm8,eelm9,eelm10,eelm11,eelm12,eelm13,eelm14,eelm15};
        wire [7:0] etmp_out;
        Max_16to1 u_Max_16to1(etmp_in,etmp_out);
        assign dil_pic_array[idx] = etmp_out;
    end
endgenerate

// ero_dil_value
always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        ero_dil_value <= 0;
    else if(current_state == s_pic && rvalid_m_inf == 1)
    begin
        if(op_current == 0)
            ero_dil_value <= ero_result;
        else
            ero_dil_value <= dil_result;
    end
    else if(current_state == s_cal)
    begin
        if(op_current == 0)
            ero_dil_value <= ero_result;
        else
            ero_dil_value <= dil_result;
    end
    else
        ero_dil_value <= ero_dil_value;

end

//==============================================//
//              Histogram Calculation           //
//==============================================//
/// cdf ///
// in current_state == s_his_pic //
reg [127:0] his_pic_data;
// his_pic_data
always@(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        his_pic_data <= 0;
    else if(current_state == s_idle)/*initial value*/
        his_pic_data <= 0;
    else if(current_state == s_his_pic && rvalid_m_inf == 1 && cnt256_input < 256)/*write data data*/
        his_pic_data <= rdata_m_inf;
    else
        his_pic_data <= his_pic_data;
end

// build cdf table //
reg [12:0] cdf_table[255:0];
wire [4:0] cdf_add[255:0];
generate
    for(idx=0; idx<256; idx=idx+1)
    begin
        wire [4:0] tmp_cal;
        assign tmp_cal = (his_pic_data[7:0]==idx)+(his_pic_data[15:8]==idx)+(his_pic_data[23:16]==idx)+(his_pic_data[31:24]==idx) +
               (his_pic_data[39:32]==idx)+(his_pic_data[47:40]==idx)+(his_pic_data[55:48]==idx)+(his_pic_data[63:56]==idx) +
               (his_pic_data[71:64]==idx)+(his_pic_data[79:72]==idx)+(his_pic_data[87:80]==idx)+(his_pic_data[95:88]==idx) +
               (his_pic_data[103:96]==idx)+(his_pic_data[111:104]==idx)+(his_pic_data[119:112]==idx)+(his_pic_data[127:120]==idx);
        assign cdf_add[idx] = tmp_cal;
    end
endgenerate
reg delay_buffer;
always@(posedge clk or negedge rst_n)
begin
    if(!rst_n)
    begin
        delay_buffer <= 0;
    end
    else if(current_state == s_his_pic)
    begin
        delay_buffer <= rvalid_m_inf;
    end
    else
    begin
        delay_buffer <= 0;
    end
end
// cdf_table use cdf_add update
generate
    for(idx=0; idx<256; idx=idx+1)
    begin
        always@(posedge clk or negedge rst_n)
        begin
            if(!rst_n)
                cdf_table[idx] <= 0;
            else if(current_state == s_idle)
                cdf_table[idx] <= 0;
            else if(current_state == s_his_pic && delay_buffer == 1)
            begin
                cdf_table[idx] <= cdf_table[idx] + cdf_add[idx];
            end
            else
                cdf_table[idx] <= cdf_table[idx];
        end
    end
endgenerate

// in current_state == s_his_cdf //
reg  [12:0] cdf_accumulator;
reg  [12:0] min;
// cdf_accumulator
always@(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        cdf_accumulator <= 0;
    else if(current_state == s_idle)
        cdf_accumulator <= 0;
    else if(current_state == s_his_cdf && cnt256_cdf < 256)
        cdf_accumulator <= cdf_accumulator + cdf_table[cnt256_cdf];
    else
        cdf_accumulator <= cdf_accumulator;
end
// min
always@(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        min <= 0;
    else if(current_state == s_idle)
        min <= 0;
    else if(current_state == s_his_cdf)
    begin
        if(min == 0 && cdf_table[cnt256_cdf]!=0 )
            min <= cdf_table[cnt256_cdf];
        else
            min <= min;
    end
    else
        min <= 0;
end
integer i;
reg [19:0] cdv_dividend;
// cdv_dividend
always@(posedge clk or negedge rst_n)
begin
    if(!rst_n)
    begin
        cdv_dividend <= 0;
    end
    //initial
    else if(current_state == s_idle)
        cdv_dividend <= 0;
    else if(current_state == s_his_cdf && cnt256_cdf > 0 && cnt256_cdf < 257)
        cdv_dividend <= (cdf_accumulator - min) * 255;
    else
    begin
        cdv_dividend <= cdv_dividend;
    end
end
// divisor
reg [11:0] divisor;
always@(posedge clk or negedge rst_n)
begin
    if(!rst_n)
    begin
        divisor <= 0;
    end
    //initial
    else if(current_state == s_idle)
        divisor <= 0;
    else if(current_state == s_his_cdf && cnt256_cdf > 0 && cnt256_cdf < 257)
        divisor <= (4096 - min);
    else
    begin
        divisor <= divisor;
    end
end
wire [19:0] div_pipe_output;
wire [11:0] remnd;
wire db0;
DW_div_pipe #(20,12,0,0,2,0,0)
            div_pipe(.clk(clk), .rst_n(rst_n), .en(1'b1), .a(cdv_dividend), .b(divisor), .quotient(div_pipe_output),.remainder(remnd), .divide_by_0(db0));
// cdf_value_table
always@(posedge clk or negedge rst_n)
begin
    if(!rst_n)
    begin
        for (i=0; i<256; i=i+1)
        begin
            cdf_value_table[i] <= 0;
        end
    end
    //initial
    else if(current_state == s_his_pic && cnt256_input < 256)
        cdf_value_table[cnt256_input] <= 0;
    /* //none pipe use
    else if(current_state == s_his_cdf && cnt256_cdf > 1 && cnt256_cdf < 258)
        cdf_value_table[cnt256_cdf-2] <= cdv_dividend/divisor;
    */
    else if(current_state == s_his_cdf && cnt256_cdf > 2 && cnt256_cdf < 259)
        cdf_value_table[cnt256_cdf-3] <= div_pipe_output;
    else
    begin
        for (i=0; i<256; i=i+1)
        begin
            cdf_value_table[i] <= cdf_value_table[i];
        end
    end
end
endmodule

    module Min_16to1(
        // input
        in,
        // output
        out
    );
// input
input [127:0] in;
// output
output  [7:0] out;
// WIRE AND REG DECLARATION
wire    [7:0] out0, out1, out2, out3, final_out;
Min_4to1 u_Min_4to1_0 (in[7:0],    in[15:8],    in[23:16],   in[31:24],   out0);
Min_4to1 u_Min_4to1_1 (in[39:32],  in[47:40],   in[55:48],   in[63:56],   out1);
Min_4to1 u_Min_4to1_2 (in[71:64],  in[79:72],   in[87:80],   in[95:88],   out2);
Min_4to1 u_Min_4to1_3 (in[103:96], in[111:104], in[119:112], in[127:120], out3);
Min_4to1 u_Min_4to1_4 (out0,       out1,        out2,        out3,        final_out);
// out
assign out = final_out;
endmodule


    module Min_4to1(
        // input
        in1,in2,in3,in4,
        // output
        out
    );
// input
input  [7:0] in1, in2, in3, in4;
// output
output [7:0] out;
// WIRE AND REG DECLARATION
wire   [7:0] min2to1_0 = (in1 < in2) ? in1 : in2;
wire   [7:0] min2to1_1 = (in3 < in4) ? in3 : in4;
wire   [7:0] min_4to1  = (min2to1_0 < min2to1_1) ? min2to1_0 : min2to1_1;
// out
assign             out = min_4to1;
endmodule

    module Max_16to1(
        // input
        in,
        // output
        out
    );
// input
input [143:0] in;
// output
output  [7:0] out;
// WIRE AND REG DECLARATION
wire    [7:0] out0, out1, out2, out3;
Max_4to1 u_Max_4to1_0 (in[8:0],    in[17:9],    in[26:18],   in[35:27],   out0);
Max_4to1 u_Max_4to1_1 (in[44:36],  in[53:45],   in[62:54],   in[71:63],   out1);
Max_4to1 u_Max_4to1_2 (in[80:72],  in[89:81],   in[98:90],   in[107:99],  out2);
Max_4to1 u_Max_4to1_3 (in[116:108], in[125:117], in[134:126], in[143:135], out3);
wire   [7:0] max2to1_0 = (out0 > out1) ? out0 : out1;
wire   [7:0] max2to1_1 = (out2 > out3) ? out2 : out3;
wire   [7:0] final_out  = (max2to1_0 > max2to1_1) ? max2to1_0 : max2to1_1;
// out
assign out = final_out;
endmodule


    module Max_4to1(
        // input
        in1,in2,in3,in4,
        // output
        out
    );
// input
input  [8:0] in1, in2, in3, in4;
// output
output [7:0] out;
// WIRE AND REG DECLARATION
wire   [7:0] in_tmp1   = (in1 > 255) ? 255 : in1[7:0];
wire   [7:0] in_tmp2   = (in2 > 255) ? 255 : in2[7:0];
wire   [7:0] in_tmp3   = (in3 > 255) ? 255 : in3[7:0];
wire   [7:0] in_tmp4   = (in4 > 255) ? 255 : in4[7:0];
wire   [7:0] max2to1_0 = (in_tmp1 > in_tmp2) ? in_tmp1 : in_tmp2;
wire   [7:0] max2to1_1 = (in_tmp3 > in_tmp4) ? in_tmp3 : in_tmp4;
wire   [7:0] max_4to1  = (max2to1_0 > max2to1_1) ? max2to1_0 : max2to1_1;
// out
assign             out = max_4to1;
endmodule


