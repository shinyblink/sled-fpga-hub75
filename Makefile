# Makefile for sled's FPGA HUB75 backend, based on a TinyFPGA BX,
# which got proudly sponsored by the creator, Luke Valenty!
# Many thanks!

PROJ := sled-hub75

FILES := 

all: BX
# Device specific rules.
BX: PIN_DEF := pins/BX.pcf
BX: DEVICE := lp8k
BX: ENTRY := targets/BX
BX: TOP := TinyFPGA_BX
BX: targets/BX.rpt targets/BX.bin
	cp targets/BX.bin $(PROJ).bin

# Programming rules
prog-tinyprog: $(PROJ).bin
	tinyprog --program $<

prog-ice: $(PROJ).bin
	iceprog $<

# Shared targets.
%.blif: %.v
	yosys -p 'synth_ice40 -top $(TOP) -blif $@' $< $(FILES)

%.asc: %.blif $(PIN_DEF)
	arachne-pnr -d 8k -P cm81 -o $@ -p $(PIN_DEF) $<

%.bin: %.asc
	icepack $< $@

# Generative targets
src/pll.v:
	icepll -i 16 -o 64 -m -f $@

# Timing analysis.
%.rpt: %.asc
	icetime -d $(DEVICE) -mtr $@ $<

# Clean
clean:
	rm -f $(PROJ).bin $(PROJ).asc $(PROJ).rpt $(PROJ).blif
	rm -f targets/BX.bin
