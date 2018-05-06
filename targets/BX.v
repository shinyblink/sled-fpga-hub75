///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////
///
/// Top-Level Verilog Module
///
/// Only include pins the design is actually using.  Make sure that the pin is
/// given the correct direction: input vs. output vs. inout
///
///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////

`default_nettype none

`include "../src/pll.v"
`include "../src/pixram.v"
`include "../src/spi.v"
`include "../src/pixsyn.v"

module TinyFPGA_BX
	(
	 output pin_usbp,
	 output pin_usbn,
	 input pin_clk,
	 input pin_1,
	 input pin_2,
	 input pin_3,
	 output pin_11,
	 output pin_12,
	 output pin_13,
	 output pin_14,
	 output pin_15,
	 output pin_16,
	 output pin_17,
	 output pin_18,
	 output pin_19,
	 output pin_20,
	 output pin_21,
	 output pin_22,
	 output pin_23
	 );

   assign pin_usbp = 1'b0;
   assign pin_usbn = 1'b0;

   // Clocking. ATTACH PLL HERE!
   // NOTE: ABSOLUTELY MUST be going at least twice as fast as SPI clock!
   //       Blame clock domains
   wire   clock;
   wire   pll_locked;
   pll our_pll(pin_clk, clock, pll_locked);


   // Pins, input
   wire pin_spi_clk = pin_1;
   wire pin_spi_cs = pin_2;
   wire pin_spi_mosi = pin_3;
   // Pins, output
   wire pin_hub_clk;
   wire pin_hub_lat;
   wire pin_hub_oe;
   wire pin_hub_r1;
   wire pin_hub_r2;
   wire pin_hub_g1;
   wire pin_hub_g2;
   wire pin_hub_b1;
   wire pin_hub_b2;
   wire pin_hub_a;
   wire pin_hub_b;
   wire pin_hub_c;
   wire pin_hub_d;
   assign pin_11 = pin_hub_clk;
   assign pin_12 = pin_hub_lat;
   assign pin_13 = pin_hub_oe;
   assign pin_14 = pin_hub_r1;
   assign pin_15 = pin_hub_r2;
   assign pin_16 = pin_hub_g1;
   assign pin_17 = pin_hub_g2;
   assign pin_18 = pin_hub_b1;
   assign pin_19 = pin_hub_b2;
   assign pin_20 = pin_hub_a;
   assign pin_21 = pin_hub_b;
   assign pin_22 = pin_hub_c;
   assign pin_23 = pin_hub_d;

   wire ram_wclk;
   wire [13:0] ram_waddr;
   wire [7:0] ram_wdata;
   wire [11:0] ram_raddr;
   wire [15:0] ram_rdata1;
   wire [15:0] ram_rdata2;

   wire frame_clk;

   // Setup SPI and data transfers.
   wire spi_resetn;
   wire spi_firstbyte;
   wire spi_done;

   spi_slave spi(clock, spi_resetn, pin_spi_clk, pin_spi_mosi, pin_spi_cs, ram_wdata, spi_firstbyte, spi_done);

   reg [13:0] spi_byte_count = 0;
   always @(posedge clock) begin
      if (spi_firstbyte)
        spi_byte_count <= 0;

      if (spi_done)
        spi_byte_count <= spi_byte_count + 1;
   end

   // RAM: Magic.
   /*
   wire ram_rdata [31:0];
   assign ram_rdata[15:0] = ram_rdata1;
   assign ram_rdata[31:16] = ram_rdata2;
   */

   pixram ram(clock, 1, spi_done, ram_raddr, spi_byte_count, {ram_rdata1, ram_rdata2}, ram_wdata);

   // Signal advance happens on clock high
   pixsyn syn_m(clock, pin_hub_a, pin_hub_b, pin_hub_c, pin_hub_d, pin_hub_clk, pin_hub_lat, pin_hub_oe, ram_raddr, frame_clk);

   // 5 bit PWM.
   reg [4:0] frame_count;
   always @(posedge frame_clk) begin
    frame_count <= frame_count + 1;
   end

   assign pin_hub_r1 = ram_rdata1[14:10] < frame_count;
   assign pin_hub_g1 = ram_rdata1[9:5] < frame_count;
   assign pin_hub_b1 = ram_rdata1[4:0] < frame_count;
   assign pin_hub_r2 = ram_rdata2[14:10] < frame_count;
   assign pin_hub_g2 = ram_rdata2[9:5] < frame_count;
   assign pin_hub_b2 = ram_rdata2[4:0] < frame_count;

endmodule
