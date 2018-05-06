// SPI slave, made by dd2, dachdecker2 on GitHub.
// Slightly tweaked, mainly commenting out stuff I don't need.
// Many thanks, used with explicit permission!
module spi_slave
(
 input        clk,
 input        resetn,
 input        spi_clk,
 input        spi_mosi,
 input        spi_cs,
 //input [7:0]  write_value,
 output [7:0] read_value,
 output [0:0] first_byte,
 //output [0:0] timeout_expired,
 output [0:0] done,
 //output [7:0] debug_info
 );

   // CPOL == 0: clock state while idle is low  ("inactive")
   // CPOL == 1: clock state while idle is high ("inactive")
   parameter CPOL = 0;
   // CPHA == 0: write on clock deactivation, sample on clock activation
   // CPHA == 1: write on clock activation, sample on clock deactivation
   parameter CPHA = 0;
   parameter LSBFIRST = 0;
   // TIMEOUT__NOT_CS: 0 - use ship select
   //                  1 - don't use chip select, use timeout instead
   parameter TIMEOUT__NOT_CS = 0;
   parameter TIMEOUT_CYCLES  = 2;

   reg [3:0]                   state = 0;      // idle, start condition, d0, d1, ..., d7
   reg [7:0]                   value_int = 0;
   reg [7:0]                   read_value = 0;
   reg [0:0]                   done = 0;
   reg [0:0]                   first_byte = 0; // inform caller that this is a new transmission
   wire [0:0]                  sample;         // used as name for the "sample" condition is True
   wire [0:0]                  write;          // used as name for the "write" condition is True
   reg [0:0]                   spi_clk_reg;    // registered value of spi_clk
   reg [0:0]                   spi_clk_pre;    // previous value of spi_clk
   reg [0:0]                   spi_cs_reg;     // registered value of spi_cs
   reg [0:0]                   spi_cs_pre;     // previous value of spi_cs
   reg [0:0]                   spi_mosi_reg;   // registered value of spi_mosi
   reg [0:0]                   spi_mosi_pre;   // previous value of spi_mosi
   reg [0:0]                   reset_timeout;  // timeout signal, used in timeout mode
   reg [0:0]                   first_byte_int; // internal signal which is high until the first byte is done

   assign sample =    (CPOL ^  (CPHA ^ spi_clk_reg))
     && (CPOL ^ !(CPHA ^ spi_clk_pre));

   assign write  =    (CPOL ^ !(CPHA ^ spi_clk_reg))
     && (CPOL ^  (CPHA ^ spi_clk_pre));

   localparam TIMEOUT_CYCLE_BITS = TIMEOUT__NOT_CS * ($clog2(TIMEOUT_CYCLES)-1);
   reg [TIMEOUT_CYCLE_BITS:0]  timeout_counter = 0;
   reg [0:0]                   timeout_expired = 1;

   // actual implementation
   always @(posedge clk) begin
      if (!resetn) begin
         state           <= 0;
         reset_timeout   <= 1;
         done            <= 0;
         timeout_counter <= 0;
         timeout_expired <= 1;
         first_byte      <= 0;
         spi_clk_reg     <= 0;
         spi_clk_pre     <= 0;
      end else begin
         timeout_counter <= reset_timeout ? TIMEOUT_CYCLES :
                            (timeout_counter ? timeout_counter - 1 : 0);
         if (!TIMEOUT__NOT_CS) begin
            timeout_expired <= spi_cs_reg;
         end else begin
            timeout_expired <= !timeout_counter;
         end

         // obtain actual and recent values of cs and clk
         spi_cs_reg <= spi_cs;
         spi_cs_pre <= spi_cs_reg;

         spi_clk_reg  <= spi_clk;
         spi_clk_pre  <= spi_clk_reg;

         spi_mosi_reg <= spi_mosi;
         spi_mosi_pre <= spi_mosi_reg;

         // default values
         reset_timeout <= 0;
         read_value <= 0;
         first_byte <= 0;
         done <= 0;

         // detect falling edge of CS
         if (!spi_cs_reg && spi_cs_pre) first_byte_int <= 1;

         if (timeout_expired) begin
            state <= 0;
            reset_timeout <= 1;
         end else if (sample) begin
            reset_timeout <= 1; // reset timeout in every bit
            value_int <= LSBFIRST ? {spi_mosi, value_int[7:1]}
                         : {value_int[6:0], spi_mosi};
            if (state < 8) begin
               // starting reception while idle
               state <= state + 1;
            end
         end else if (state == 8) begin
            first_byte     <= first_byte_int;
            first_byte_int <= 0;
            read_value     <= value_int;
            done           <= 1;
            state          <= 0;
         end
      end
   end

   /*    always @(clk) begin
    `ifdef FORMAL
    clk_cnt_spiclk = (clk ^ clk_pre) ? clk_cnt_spiclk + 1 : 0;
    `endif
    end // */
/*
`ifdef FORMAL
   //        reg  [0:0] clk_pre;        // previus clk state
   reg  [7:0] clk_cnt_spiclk; // signal for counting cycles (for verification)
   reg [3:0]  state_pre;      // previous value of state
   reg [3:0]  done_since_CS = 0;  // previous value of state

   initial done_since_CS <= 0;
   initial spi_cs <= 1;

   always @(posedge clk) begin
      state_pre <= state;

      if (spi_clk_reg == spi_clk_pre) clk_cnt_spiclk <= clk_cnt_spiclk + 1;
      else                            clk_cnt_spiclk <= 0;

      if (!spi_cs_reg && spi_cs_pre) done_since_CS <= 0;
      else                           done_since_CS <= done_since_CS + done;


      // first_byte must be high only for the first byte after pulling CS
      assert (!first_byte || first_byte && done_since_CS == 0);

      // assume spiclk to change every 2 clks or less often
      restrict ((spi_clk_reg == spi_clk_pre)
                ||(spi_clk_reg ^  spi_clk_pre) && (clk_cnt_spiclk > 3));

      // assume MOSI to not change during read edge of clock
      assume (!sample || sample && (spi_mosi_reg == spi_mosi_pre));
      // assert that done never gets high
      // while CS is not pulled
      // (done is allowed to get high within 2 cycles)
      assert (!done || done && (!spi_cs_reg || (clk_cnt_spiclk < 2)));
      // assert the done is only high after
      // receiving multiples of 8 bits
      assert (!done || done && (state_pre == 8));
   end
`endif

   assign debug_info[7:4] = state[3:0];
   //    assign debug_info[7:4] = {timeout_expired, timeout_expired, TIMEOUT__NOT_CS, reset_timeout};
   assign debug_info[3:0] = value_int[3:0];
   //    assign debug_info[3:0] = {value_int[2:0], first_byte};
*/
endmodule
