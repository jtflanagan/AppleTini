# AppleTini
An FPGA-based multifunctional card

Earlier iterations of the design used microcontrollers (a Pico and a Teensy 4.1), but we have moved to an FPGA-based design.  The v4 version of the board works in an Apple IIe as a read-only bus dump card.  It reads events on the Apple II bus, and forwards them over USB to a remote host which can process them (including operating as HDMI video-out, similar to the VidHD card).

The v5 board (just ordered!) is intended to provide the full bus feature set.  The ability to read and write data to the bus, as well as perform full DMA and assert all the control lines available (DMA, RES, RDY, INH, IRQ, NMI, and properly implement DMAIN/OUT and INTIN/OUT.

The boards are designed to connect to a stack of Alchitry boards as sold by SparkFun.  The boards have headers which will mate with the Alchitry Br breakout board.  The high-speed USB needed to do bus dumping is provided by the Alchitry Ft board, which is capable of up to 1.6Gbits/sec data transmit over USB3.  The FPGA, and 256MB of DDR3 SDRAM is provided by the Alchitry Au board.

What can this board ultimately do?  Damn near anything.  Shorter term goals are to provide HDMI out, speaker sound, Mockingboard sound, mouse, Ramworks or Slinky style memory expansion, and solid state HDV storage.  Longer term?  CPU Acceleration.  In-circuit Emulator level debugging.  More flexible expanded memory banking techniques.  There's a lot of potential!  The FPGA on the Alchitry Au is an Artix-7 35T, so there's a lot of room for all kinds of stuff.
