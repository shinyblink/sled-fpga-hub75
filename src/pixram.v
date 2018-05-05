// PixRAM
module pixram(
   input sysclk,
   input rclk, input wclk,
   input [11:0] raddr, input [11:0] waddr,
   output [15:0] rdata1, output [15:0] rdata2, input [31:0] wdata
);
   pixsubram ramA(sysclk, rclk, wclk, raddr, waddr, rdata1, wdata[31:16]);
   pixsubram ramB(sysclk, rclk, wclk, raddr, waddr, rdata2, wdata[15:0]);
endmodule

// BRAM mapper bait

module pixsubram(
   input sysclk,
   input rclk, input wclk,
   input [11:0] raddr, input [11:0] waddr,
   output reg [15:0] rdata, input [15:0] wdata);
   reg [15:0] pixels [0:4095];
   always @(posedge sysclk) begin
      if (rclk)
         rdata <= pixels[raddr];
   end
   always @(posedge sysclk) begin
      if (wclk)      
         pixels[waddr] <= wdata;
   end
endmodule
