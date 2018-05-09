// Pixsyn - HUB75 signal generator
// To summarize: Attach this to the HUB75 bus
// pin_clk going high triggers hub clock/latch
// OE is inverse of LAT
// LAT is pin_clk AND FC, leading to the effects noted in stage 2
// ABCD are upper address lines
// The stages:
// 0: LA 0. FC 0, TD 0. Clock high -> Hub CLK high, Clock low -> Hub CLK low & address advance
//                              LAT is 0.
// 1: LA 1. FC 0, TD 0. Same as stage 0, but go to stage 2 with FC 1 and TD 1 on clock low.
//                              LAT still 0.
// 2: LA 1, FC 1, TD 1. Clock high -> Hub LAT high, Clock low -> Hub LAT low, go to stage 3 with FC 0.
// 3: LA 1, FC 0, TD 1. Clock high -> Nothing, Clock low -> Address advance, go to stage 0 with TD 0.
module pixsyn(
 input pin_clk,
 output hub_a, output hub_b, output hub_c, output hub_d,
 output hub_clk, output hub_lat, output hub_oe,
 output [11:0] ram_addr, output reg frame_clk
);
 reg [11:0] hub_addr;
 // given D is connected to ground (O.o) on some of Adafruit's other options,
 // I'm taking it to mean "major".
 // ABCD is connected to a 1-of-16 decoder if I'm reading this right.
 // Maths here is:
 // 128x64 : matrix size = 8192
 // msize / 2 : total HUB75 CLKs = 4096
 // 2^4 : abcd divisions = 16
 // tclks / abcddivs : shift register length = 256
 assign hub_a = hub_addr[8];
 assign hub_b = hub_addr[9];
 assign hub_c = hub_addr[10];
 assign hub_d = hub_addr[11];
 assign ram_addr = hub_addr;
 assign hub_clk = pin_clk & ~frame_clk;
 assign hub_lat = pin_clk & frame_clk;
 assign hub_oe = ~hub_lat;
 reg temp_disable = 0;
 wire last_addr = hub_addr[7:0] == 255;

 always @(negedge pin_clk) begin
  if (!last_addr) begin
   hub_addr <= hub_addr + 1;
   frame_clk <= 0;
  end else if (!temp_disable) begin
   frame_clk <= 1;
   temp_disable <= 1;
  end else if (frame_clk) begin
   frame_clk <= 0;
  end else begin
   temp_disable <= 0;
  end
 end
endmodule
