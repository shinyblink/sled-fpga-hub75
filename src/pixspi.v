// PixSPI : Pixel SPI Transferrer
module pixspi(input sysclk, input spi_clk, input spi_ss, input spi_mosi, output [11:0] waddr, output [31:0] wdata, output wclk);
   reg [11:0] address;
   reg [11:0] naddress;
   reg [15:0] working;
   reg [4:0] bitcount;
   reg wclk;
   reg last_spi_ss, last_spi_sc, last_spi_vc;

   wire spi_sc = (~spi_ss) & spi_clk;
   wire spi_vc = spi_sc & (bitcount == 31);
   // spi_sc should rise first, when the bit is submitted.
   // spi_vc should fall second, with spi_sc does, in-between bits

   wire spi_ss_upd = last_spi_ss & ~spi_ss;
   wire spi_sc_upd = spi_sc & ~last_spi_sc;
   wire spi_vc_upd = last_spi_vc & ~spi_vc;

   assign waddr = address;
   assign wdata = working;
   always @(negedge sysclk) begin
      // Verilog hates me. It complains about these lines having multiple drivers,
      // and if I don't listen it starts telling me about how IT SOMEHOW MANAGED TO LOSE TRACK OF RAM WDATA'S DRIVER.
      // So I have to combine them in this mess.
// I GIVE UP!!!! SENDING THIS TO VIF TOMORROW, SAYING "I CANNOT DO VERILOG"
// THIS TOOLCHAIN IS JUST SPAMDELETING THE ENTIRE THING WITH NO REASON GIVEN,
// AND IT'S DRIVING ME UP THE WALL
// SERIOUSLY, WDATA DOES HAVE A DRIVER, YOSYS!
      address <= spi_ss_upd ? 0 : (spi_sc_upd ? naddress : address);
      naddress <= spi_ss_upd ? 0 : (spi_vc_upd ? address + 1 : naddress);
      bitcount <= spi_ss_upd ? 0 : (spi_sc_upd ? bitcount + 1 : bitcount);
      working <= spi_sc_upd ? ((working << 1) | spi_mosi) : working;
      wclk <= spi_vc;
      last_spi_ss <= spi_ss;
      last_spi_sc <= spi_sc;
      last_spi_vc <= spi_vc;
   end
endmodule
