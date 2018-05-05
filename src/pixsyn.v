// Pixsyn - HUB75 signal generator
// To summarize: Attach this to the HUB75 bus
// pin_clk going high triggers hub clock/latch
// NOTE: THIS MODULE IS PROBABLY ENTIRELY WRONG AT PRESENT.
// CAN SOMEONE CONTACT ADAFRUIT? AND FAST? ...HELP?
module pixsyn(input pin_clk, output hub_a, output hub_b, output hub_c, output hub_d, output hub_clk, output hub_lat, output hub_oe, output [11:0] ram_addr, output frame_clk);
 reg [11:0] hub_addr;
 assign hub_a = hub_addr[11];
 assign hub_b = hub_addr[10];
 assign hub_c = hub_addr[9];
 assign hub_d = hub_addr[8];
 assign ram_addr = hub_addr;
 assign hub_clk = pin_clk;
 // I'm going to *assume* that they took the simplest solution, and kept the control lines constant
 //  across all modules (of which there are 128x64's worth, so 4) and just kept on chaining
 // thus 8 modules multiplied by 16 bit shift registers is 128
 assign hub_lat = pin_clk & (hub_addr[6:0] == 127);
 assign hub_oe = ~hub_lat;
 assign frame_clk = pin_clk & (hub_addr == 4095);
 always @(negedge pin_clk) begin
  hub_addr <= hub_addr + 1;
 end
endmodule
