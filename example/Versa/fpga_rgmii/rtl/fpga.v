/*

Copyright (c) 2014-2018 Alex Forencich

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

*/

// Language: Verilog 2001

`timescale 1ns / 1ps

/*
 * FPGA top-level module
 */
module fpga (
    /*
     * Clock: 125MHz
     * Reset: Push button, active high
     */
    input  wire       clk_125mhz,
    /*
     * GPIO
     */
    output wire [7:0] led,
    /*
     * Ethernet: 1000BASE-T RGMII
     */
    input  wire       phy_rx_clk,
    input  wire [3:0] phy_rxd,
    input  wire       phy_rx_ctl,
    output wire       phy_tx_clk,
    output wire [3:0] phy_txd,
    output wire       phy_tx_ctl,
    output wire       phy_reset_n,
    /*
     * FTDI2232H
     */
    output wire       uart_rxd,
    input  wire       uart_txd
);

wire       ledu;
wire       ledl;
wire       ledd;
wire       ledr;
wire       ledc;

// Internal 125 MHz clock
wire clk_125mhz_mmcm_out;
wire clk_125mhz_int;
wire clk90_125mhz_mmcm_out;
wire clk90_125mhz_int;
wire rst_125mhz_int;

wire mmcm_locked;
wire mmcm_clkfb;

// MMCM instance
// 200 MHz in, 125 MHz out
// PFD range: 10 MHz to 450 MHz
// VCO range: 600 MHz to 1200 MHz
// M = 5, D = 1 sets Fvco = 1000 MHz (in range)
// Divide by 8 to get output frequency of 125 MHz
pll i_pll(
    .clkin(clk_125mhz), // 125 MHz, 0 deg
    .clkout0(clk_125mhz_int), // 125 MHz, 0 deg
    .clkout1(clk90_125mhz_int), // 125 MHz, 90 deg
    .locked(mmcm_locked)
);
// Core held in reset until PLL is locked
sync_reset #(
    .N(4)
)
sync_reset_125mhz_inst (
    .clk(clk_125mhz_int),
    .rst(~mmcm_locked),
    .out(rst_125mhz_int)
);

// GPIO
wire btnu_int;
wire btnl_int;
wire btnd_int;
wire btnr_int;
wire btnc_int;
wire [7:0] sw_int;

wire ledu_int;
wire ledl_int;
wire ledd_int;
wire ledr_int;
wire ledc_int;
wire [7:0] led_int;

wire uart_rxd_int;
wire uart_txd_int;

debounce_switch #(
    .WIDTH(13),
    .N(4),
    .RATE(125000)
)
debounce_switch_inst (
    .clk(clk_125mhz_int),
    .rst(rst_125mhz_int),
    .in({1'b0,
        1'b0,
        1'b0,
        1'b0,
        1'b0,
        8'b0}),
    .out({btnu_int,
        btnl_int,
        btnd_int,
        btnr_int,
        btnc_int,
        sw_int})
);

assign ledu = ledu_int;
assign ledl = ledl_int;
assign ledd = ledd_int;
assign ledr = ledr_int;
assign ledc = ledc_int;
assign led = led_int;

assign uart_rxd = 1'b0;

fpga_core
core_inst (
    /*
     * Clock: 125MHz
     * Synchronous reset
     */
    .clk_125mhz(clk_125mhz_int),
    .clk90_125mhz(clk90_125mhz_int),
    .rst_125mhz(rst_125mhz_int),
    /*
     * GPIO
     */
    .btnu(btnu_int),
    .btnl(btnl_int),
    .btnd(btnd_int),
    .btnr(btnr_int),
    .btnc(btnc_int),
    .sw(sw_int),
    .ledu(ledu_int),
    .ledl(ledl_int),
    .ledd(ledd_int),
    .ledr(ledr_int),
    .ledc(ledc_int),
    .led(led_int),
    /*
     * Ethernet: 1000BASE-T RGMII
     */
    .phy_rx_clk(phy_rx_clk),
    .phy_rxd(phy_rxd),
    .phy_rx_ctl(phy_rx_ctl),
    .phy_tx_clk(phy_tx_clk),
    .phy_txd(phy_txd),
    .phy_tx_ctl(phy_tx_ctl),
    .phy_reset_n(phy_reset_n),
    /*
     * UART: 115200 bps, 8N1
     */
    .uart_rxd(uart_rxd_int),
    .uart_txd(uart_txd_int),
    .uart_rts(1'b1),
    .uart_cts()
);

endmodule
