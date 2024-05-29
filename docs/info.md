<!---

This file is used to generate your project datasheet. Please fill in the information below and delete any unused
sections.

You can also include images in this folder and reference them in the markdown. Each image must be less than
512 kb in size, and the combined size of all images must be less than 1 MB.
-->

## How it works

This is a number of different DUTs (Device Under Test) in the analog design area of the
Schmitt Inverter circuit.

Only one DUT can be active at a time.  The digital interface can be used to select which DUT is active.

There is an attempt at a control circuit that tries to ensure that on power
up no DUT can be active.  This is an output enable control on the binary
decoder that generates a one-hot control signal to enable a DUT.

## How to test

Select the TT project ID via the standard TT project selection sequence
documented on TinyTypeout.com.

Apply a digital reset sequence to this project.

Wait for READY signal asserted indication.

Setup SEL signal (3 bits) to the DUT ID you wish to select and make the STROBE
signal active, then apply CLK posedge.  The STROBE is edge triggered, so you
must return the STROBE signal to zero and apply CLK, before another selection
can be made.  This is to ratelimit and reduce chance of damage if you were
able to rapidly cycle the selected DUT.

Wait for READY signal asserted indication.

Use analogue pins as per the selected Device Under Test.

In this state the following:
 * RST_N must remain inactive at all times.  The negedge of this signal will
   perform an immediate async reset, causing no DUT to be selected.
   NOTE: the reset sequence requires a synchronous sequence to complete and
   leave reset state.
 * It is not necessary to continue to provide a CLK signal to the project at
   this point.
 * STROBE can be left high or brought back low after the active clock cycle
   to activate a DUT.

## External hardware

The control system is expected to be managed by the standard TinyTapeout
firmware.  More details and snippets will be provided in this documentation to
follow later.

## Signals

+--------+-----+-------------------------------------------------------------------+
| Name   | i/o | Description                                                       |
+--------|-----|-------------------------------------------------------------------|
| CLK    |  i  | Non specific clock frequency, STA uses CLOCK_PERIOD=15ns (66MHz)  |
| RST_N  |  i  | Async active.   Synchronous release.                              |
| ENABLE |  i  | Active high, digital interface enable command pin.                |
|        |     | This is provided to help modularize the digital control interface |
|        |     | behind this enable signal, to allow more complicated future       |
|        |     | mixed-signal projects to easily multiplex TinyTapeout tt_um pin   |
|        |     | usage with other mixed-signal requirements.                       |
| SEL_EN |  i  | Active high, needs to be active to change SEL value.              |
|        |     |                                                                   |
| STROBE |  i  | Active high, Posedge triggered.                                   |
| SEL    |  i  | Ensure SEL bits are setup before STROBE goes active.              |
| READY  |  o  | Active high.                                                      |
|        |     | After reset, confirms sync reset sequence complete.               |
|        |     | After strobe, confirms analog pins ready.                         |

## TODO

Provide standard copy-and-paste snippets for the TT MicroPython interface to
perform the RESET and DUT selection sequences.
