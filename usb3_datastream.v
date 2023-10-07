`define write_only

module usb3_datastream (
//外部时钟
    input clk125m,
    input [31:0]dataIN,
//SLAVE FIFO模式接口
    input flaga,
    input flagb,
    input flagc,
    input flagd,

    output slcs_n,
    output slwr_n,
    output slrd_n,
    output sloe_n,
    output pktend_n,
    output [1:0]a,
    output pclk,

`ifndef write_only
    inout [31:0] data
`else
    output [31:0] data
`endif 
);
    wire clk_out1;               //PLL_out
    wire res_n;                 //复位,由PLL模块输出
//根据输入时钟与芯片匹配时钟，调用 PLL IP核生成时钟↓
  clk_wiz_0 instance_name
   (
    // Clock out ports
    .clk_out1(clk_out1),     // output clk_out1
    // Status and control signals
    .res_n(res_n),       // output res_n
   // Clock in ports
    .clk125m(clk125m));      // input clk125m
//PLL↑
//调用USB只写控制模块
usb_ctrl_wrOnly wronly(
    /*.clk(clk_out1),*/.clk(clk125m), //先不使用分频时钟
    .res_n(res_n),
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
    .data(data),
    .pclk(pclk)
);
endmodule