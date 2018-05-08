// Mapping the god damn pixels.
// Right now, this is a stub.
module pixmapper
  (
   input wire [11:0] pixel,
   output wire [11:0] ramaddr
   );

   assign ramaddr = pixel;
endmodule // pixmapper
