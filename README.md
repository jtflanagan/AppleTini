# AppleTini
Teensy 4.1-based multifunctional Apple II peripheral card

The design uses a non-wireless Pico, flashed with the AppleTini_pico sketch, and a Teensy 4.1 with Ethernet, flashed with the AppleTini_teensy sketch.  The Teensy should be clocked at 812MHz in order to meet timing.  You may need to set that manually in the sketch before flashing the board.

The bus_controller.pio.h file was generated from the bus_controller.pio file using https://wokwi.com/tools/pioasm, but any other pioasm method would work just as well.  The Arduino IDE does not support pioasm itself, but is happy to let you include the generated header file if you provide it.

It is VERY important to leave the power jumper off of the board if you choose to keep the Teensy USB plugged in during use- unlike the Pico, the Teensy does not have circuitry to safely use the USB at the same time as externally sourced power.  This is not an issue under conventional use- normally you will just have the jumper in, and no USB connected.  You would only put in the USB and pull the jumper if you were doing heavy development on the Teensy code and needing to reflash it frequently.
