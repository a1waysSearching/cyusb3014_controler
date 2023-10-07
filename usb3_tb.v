`timescale 1ns/1ns
module usb3_tb ();
    reg clk_in;         //125M
    reg [31:0]dataIN;
    reg flaga;          
    reg flagb;
    reg flagc;
    reg flagd;

    wire slcs_n;
    wire slwr_n;
    wire slrd_n;
    wire sloe_n;
    wire pktend_n;
    wire [1:0]a;
    wire pclk;
    wire [31:0]data;
//例化
usb3_datastream top(
    .clk125m(clk_in),
    .dataIN(dataIN),
    .flaga(flaga),
    .flagb(flagb),
    .flagc(flagc),
    .flagd(flagd),

    .slcs_n(slcs_n),
    .slwr_n(slwr_n),
    .slrd_n(slrd_n),
    .sloe_n(sloe_n),
    .pktend_n(pktend_n),
    .a(a),
    .pclk(pclk),
    .data(data)
);
//产生时钟
    initial begin
        clk_in = 0;
        forever #4 clk_in = ~clk_in;//ClockPeriod = 8ns , 1s/8ns = 0.125*10^9 = 125*10^6 → 125M
    end
//初始化数据后输入数据
    initial begin
        dataIN = 32'b0;
        flaga = 0;      //FIFO满
        flagb = 0;
        flagc = 0;
        flagd = 0;
        #100
        flaga = 1'b1;
        //forever #2 dataIN = dataIN + 1'b1;
        repeat (512) @(posedge clk_in)
		dataIN = dataIN + 1'b1;
        #1000 flaga = 0;
        #500 $finish;
    end
endmodule
//未分频的125M，发送一次256个数据包用时2104ns，为263个周期
