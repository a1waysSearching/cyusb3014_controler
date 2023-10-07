`define write_only

module usb_ctrl_wrOnly (
    input              clk,
    input              res_n,
    input      [31:0]  dataIN,          //串行数据输入
//FIFO空满信号
    input              flaga,           //FIFO写状态  1未写满     0满
    input              flagb,           //FIFO写快满  1未快写满   0余6Byte位置写满
    input              flagc,           //FIFO读状态  1读空       0未读空
    input              flagd,           //FIFO读状态  1读快空     0余6Byte位置读空
//输出标志
    output reg         slcs_n,          //片选
    output reg         slwr_n,          //写使能
    output reg         slrd_n,          //读使能
    output reg         sloe_n,          //输出使能
    output reg         pktend_n,        //空包
    output reg [1:0]   a,               //读写使能选通地址

`ifndef write_only
    inout      [31:0]  data,            //双向数据
`else 
    output     [31:0]  data,            //只写数据
`endif 

    output             pclk             //输出芯片匹配时钟

);
    localparam         pack_len = 256;  //数据包长度

    assign pclk = clk;                  //芯片匹配时钟

    reg        [8:0]  data_num;        //数据包个数计数器
    reg        [3:0]   delay_cnt;       //延时计数器
    reg        [31:0]  hanging;         //用于等待FIFO信号拉高
    reg        [31:0]  wrreg;           //写入寄存器
    reg        [3:0]   state;           
//FSM状态
    parameter          Rest = 4'd0;
    parameter          Idle = 4'd1;
    parameter          Write = 4'd2;
    parameter          Write_stop = 4'd3;
//控制信号开关状态
    parameter          sl_on  = 1'b0;
    parameter          sl_off = 1'b1;
/* 
    parameter          Read = 4'd4;
    parameter          Rdelay = 4'd5;
    parameter          Read_stop = 4'd6;
*/
//  reg                W_or_D;          //选择写或读
//  reg        [31:0]  rdreg;           //读取寄存器
/*
//判断读写方向    0为Write  1为read
always @(posedge clk or negedge res_n) begin
    if (!res_n) begin
        W_or_D <= 1'b1;         //读数据 
    end
    else if(state == Read_stop) begin
        W_or_D <=  1'b0;        //写数据       
    end
    else begin
        W_or_D <= 1'b1;         //读数据
    end
end
*/

//FSM
always @(posedge clk or negedge res_n) begin
    if (!res_n) begin
        state <= Rest;
    end
    else begin
        if (!flaga) begin
            hanging <= hanging + 1'b1;
        end
        else begin
            hanging <= 32'b0;
        case (state)
            Rest:begin
                state <= Idle;
            end 
            Idle:begin
                if (flaga) begin //读数据且FIFO未满
                    state <= Write;
                end
                else begin
                    state <= Idle;
                end
            end
            Write:begin
                if (data_num >= pack_len) begin
                    state <= Write_stop;
                end
                else begin
                    state <= Write;
                end
            end
            Write_stop:begin
                if (delay_cnt >= 4'd4) begin
                    state <= Idle;
                end
                else begin
                    state <= Write_stop;
                end
            end
            default:begin 
                state <= Idle;
            end 
        endcase
        end
    end
end
//写入数据包计数器
always @(posedge clk or negedge res_n ) begin
    if(!res_n)begin
        data_num <= 9'b0;
    end
    else if (state == Write) begin
        data_num <= data_num + 1'b1;
    end
    else begin
        data_num <= 9'b0;
    end
end
//延时计数器
always @(posedge clk or negedge res_n) begin
    if (!res_n) begin
        delay_cnt <= 4'b0;
    end
    else if (state == Write_stop) begin
        delay_cnt <= delay_cnt + 1'b1;
    end
    else begin
        delay_cnt <= 4'b0;
    end
end
//控制信号
always @(posedge clk or negedge res_n) begin
    if (!res_n) begin
        slcs_n   <= sl_off;
        slwr_n   <= sl_off;
        slrd_n   <= sl_off;
        sloe_n   <= sl_off;
        pktend_n <= sl_off;
        a        <= 2'b00;
    end
    else if (state == Idle) begin          //IDLE
        slcs_n   <= sl_off;
        slwr_n   <= sl_off;
        slrd_n   <= sl_off;
        sloe_n   <= sl_off;
        pktend_n <= sl_off;
        a        <= 2'b00;
    end
    else if (state == Write) begin          //Write
        if (data_num == 9'd0) begin        //Write开始
            slcs_n   <= sl_on;
            slwr_n   <= sl_on;
            slrd_n   <= sl_off;
            sloe_n   <= sl_off;
            pktend_n <= sl_off;
            a        <= 2'b00;
        end
        else if (data_num == 9'd255) begin //Write结尾空包
            slcs_n   <= sl_on;
            slwr_n   <= sl_on;
            slrd_n   <= sl_off;
            sloe_n   <= sl_off;
            pktend_n <= sl_on;
            a        <= 2'b00;
        end
        else if (data_num == 9'd256) begin //Write停止使能
            slcs_n   <= sl_off;
            slwr_n   <= sl_off;
            slrd_n   <= sl_off;
            sloe_n   <= sl_off;
            pktend_n <= sl_off;
            a        <= 2'b00;
        end
    end
    else if (state == Write_stop) begin     //等待
        slcs_n   <= sl_off;
        slwr_n   <= sl_off;
        slrd_n   <= sl_off;
        sloe_n   <= sl_off;
        pktend_n <= sl_off;
        a        <= 2'b00;
    end
    else begin
        slcs_n   <= sl_off;
        slwr_n   <= sl_off;
        slrd_n   <= sl_off;
        sloe_n   <= sl_off;
        pktend_n <= sl_off;
    end
end
//写入单个32bit信号
always @(posedge clk or negedge res_n) begin
    if (!res_n) begin
        wrreg <= 32'b0;
    end
    else if ((state == Write) && (data_num < pack_len )) begin //pack_len = 256且第256个数据包为空数据包
        wrreg <= dataIN;                                       //输入数据存入寄存器
    end
    else begin
        wrreg <= 32'b0;
    end
end

assign data = wrreg;                                           //输出寄存器值

/*
// 赋值总线
`ifndef write_only
    assign data = (W_or_D?rdreg:wrreg);            //三态门选择数据方向
`else 
    assign data = wrreg;                           //只写数据
`endif 
*/
endmodule
