// Small bram blob
module bram
  #(
    parameter ADDR_WIDTH = 12,
    parameter DATA_WIDTH = 8
    ) (
       input wire                   clk,
       input wire                   read,
       input wire                   write,
       input wire [ADDR_WIDTH-1:0]  raddr,
       input wire [ADDR_WIDTH-1:0]  waddr,
       output wire [DATA_WIDTH-1:0] data_out,
       input wire [DATA_WIDTH-1:0]  data_in
       );

   reg [DATA_WIDTH-1:0]             mem [0:(2**ADDR_WIDTH)-1];

   always @(posedge clk) begin
      if (write)
        mem[waddr] <= data_in;

      if (read)
        data_out <= mem[raddr];
   end
endmodule // bram

// "Special" BRAM mapper.
// when writing: 14 bit addresses and 8 bit writes.
// when reading: 12 bit addresses and 32 bit reads.
// Why? Science, basically.
module pixram
  (
   input wire        clk,
   input wire        read,
   input wire        write,
   input wire [11:0] raddr,
   input wire [13:0] waddr,
   input wire [31:0] data_out,
   input wire [7:0]  data_in);

   // Write to the banks in order.
   wire              write_a = write && waddr[13:12] == 2'b00 ;
   wire              write_b = write && waddr[13:12] == 2'b01;
   wire              write_c = write && waddr[13:12] == 2'b10 ;
   wire              write_d = write && waddr[13:12] == 2'b11;

   bram #(12, 8) bram_a(clk, read, write_a, raddr, waddr[11:0], data_out[31:24], data_in);
   bram #(12, 8) bram_b(clk, read, write_b, raddr, waddr[11:0], data_out[23:16], data_in);
   bram #(12, 8) bram_c(clk, read, write_c, raddr, waddr[11:0], data_out[15:8], data_in);
   bram #(12, 8) bram_d(clk, read, write_d, raddr, waddr[11:0], data_out[7:0], data_in);
endmodule
