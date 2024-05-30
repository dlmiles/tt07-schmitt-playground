/*
 * Copyright (c) 2024 Darryl L. Miles
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

`include "config.vh"
`include "tt_um.vh"

`define SEL_COUNT 16
`define SEL_WIDTH  4

module tt_um_dlmiles_schmitt_playground (
`ifdef TT_ANALOG_POWER
    input  wire       VGND,
    input  wire       VPWR,
`endif
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    // This is ifdef otherwise when I use OL1 to generate digital block, it will add
    //  placeholder metal for ports, even if they are not connected.
`ifdef TT_ANALOG_EXTERNAL_SIGNAL_PORTS
    inout  wire [7:0] ua,       // Analog pins, only ua[5:0] can be used
`endif
    input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset

`ifdef TT_ANALOG_INTERNAL_SIGNAL_PORTS
    ,
    // These are the ports facing the internal analogue components of this mixed-signal project
    output wire [SEL_COUNT-1:0]  oa_ctrl,
    output wire [1:0]            oa_por,
    output wire                  oa_ena
`endif
);

`ifndef TT_ANALOG_POWER
    wire VGND;
    assign VGND = 1'b0;
    wire VPWR;
    assign VPWR = 1'b1;
`endif

    localparam SEL_COUNT = `SEL_COUNT;
    localparam SEL_WIDTH = `SEL_WIDTH;	// $log2Up(SEL_COUNT)

    localparam UI_IN_0_SEL = 0;
    localparam UI_IN_4_SEL_EN = 4;
    localparam UI_IN_6_ENABLE = 6;
    localparam UI_IN_7_STROBE = 7;

    localparam UO_OUT_7_READY = 7;

    wire i_enable;
    assign i_enable = ui_in[UI_IN_6_ENABLE];
    wire i_strobe;
    assign i_strobe = ui_in[UI_IN_7_STROBE];

    wire i_sel_en;
    assign i_sel_en = ui_in[UI_IN_4_SEL_EN];
    wire [SEL_WIDTH-1:0] i_sel;
    assign i_sel[SEL_WIDTH-1:0] = ui_in[UI_IN_0_SEL+:SEL_WIDTH];

    // This is put here as it is expected to be provided to tt_um_amux_controller
    reg rst_n_sync;
    always @(posedge clk)
        rst_n_sync <= rst_n;

`ifndef TT_ANALOG_INTERNAL_SIGNAL_PORTS
    wire oa_ena;
    wire [1:0] oa_por;
    wire [SEL_COUNT-1:0] oa_ctrl;
`endif

    // Pull through digital block to make available to analog on south side, via a buffer.
`ifdef SYNTHESIS
    wire oa_ena_dont_touch;
    (* keep , syn_keep *) sky130_fd_sc_hd__buf #(
        .DRIVE_LEVEL(4),
        .DONT_TOUCH(1)
    ) buf_oa_ena (
        .X      (oa_ena_dont_touch),
        .A      (ena)
    );
    assign oa_ena = oa_ena_dont_touch;
`else
    assign oa_ena = ena; // simulation
`endif

    wire o_ready;
    wire [SEL_COUNT-1:0] o_ctrl;

    assign uo_out[UO_OUT_7_READY] = o_ready;
    assign uo_out[6:0] = o_ctrl[15:8];

    assign uio_oe = {8{`UIO_OE_OUTPUT}};
    assign uio_out = o_ctrl[7:0];

    tt_um_amux_controller #(
        .SEL_WIDTH  (SEL_WIDTH)
        //,.SEL_COUNT  (SEL_COUNT)
    ) amux_ctrl (
        .VGND       (VGND),
        .VPWR       (VPWR),

        .i_enable   (i_enable),         // i: enable
        .i_strobe   (i_strobe),		// i: strobe
        .i_sel_en   (i_sel_en),         // i: sel_en
        .i_sel      (i_sel),		// i: mux selection
        
        .o_ready    (o_ready),		// o: ready
        .o_ctrl     (o_ctrl),           // o: ctrl

        .oa_ctrl    (oa_ctrl),		// o: to-analogue
        .oa_por     (oa_por),		// o: to-analogue

        .rst_n_sync (rst_n_sync),	// i: sync reset
        .rst_n      (rst_n),		// i: async reset
        .clk        (clk)               // i: clock
    );

endmodule
