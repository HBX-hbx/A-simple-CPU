`timescale 1ns / 1ps
//
// WIDTH: bits in register hdata & vdata
// HSIZE: horizontal size of visible field 
// HFP: horizontal front of pulse
// HSP: horizontal stop of pulse
// HMAX: horizontal max size of value
// VSIZE: vertical size of visible field 
// VFP: vertical front of pulse
// VSP: vertical stop of pulse
// VMAX: vertical max size of value
// HSPP: horizontal synchro pulse polarity (0 - negative, 1 - positive)
// VSPP: vertical synchro pulse polarity (0 - negative, 1 - positive)
//
module vga_driver
#(parameter IMG_W = 0, IMG_H = 0, HSIZE = 0, HFP = 0, HSP = 0, HMAX = 0, VSIZE = 0, VFP = 0, VSP = 0, VMAX = 0, HSPP = 0, VSPP = 0)
(
    input wire clk_i,
    output wire hsync,
    output wire vsync,
    output reg de_o,
    output reg [2:0] red_o,
    output reg [2:0] green_o,
    output reg [1:0] blue_o,

    output reg [15:0] bram_addr_o,
    output reg [7:0] bram_data_i
);

reg [15:0] hdata = 0;
reg [15:0] vdata = 0;

// hdata
always @ (posedge clk_i)
begin
    if (hdata == (HMAX - 1))
        hdata <= 0;
    else
        hdata <= hdata + 1;
end

// vdata
always @ (posedge clk_i)
begin
    if (hdata == (HMAX - 1)) 
    begin
        if (vdata == (VMAX - 1))
            vdata <= 0;
        else
            vdata <= vdata + 1;
    end
end

always @ (posedge clk_i) begin
    if (hdata >= 0 && hdata < IMG_W && vdata >= 0 && vdata < IMG_H) begin
        red_o <= bram_data_i[7:5];
        green_o <= bram_data_i[4:2];
        blue_o <= bram_data_i[1:0];
        if (bram_addr_o == IMG_H * IMG_W - 1) begin
            bram_addr_o <= 0;
        end else begin
            bram_addr_o <= bram_addr_o + 1;
        end
    end else begin
        red_o <= 0;
        green_o <= 0;
        blue_o <= 0;
        bram_addr_o <= bram_addr_o;
    end
end

// hsync & vsync & blank
assign hsync = ((hdata >= HFP) && (hdata < HSP)) ? HSPP : !HSPP;
assign vsync = ((vdata >= VFP) && (vdata < VSP)) ? VSPP : !VSPP;
// when active
assign de_o = ((hdata < HSIZE) & (vdata < VSIZE));

endmodule