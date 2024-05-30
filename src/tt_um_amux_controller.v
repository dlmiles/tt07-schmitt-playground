/*
 * Copyright (c) 2024 Darryl L. Miles
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none


// The interface of this module looks very similar to the TT_UM interface to allow
// it to be used directly at the top level, or
module tt_um_amux_controller #(
    parameter SEL_WIDTH = 3,
    parameter SEL_COUNT = 2 ** SEL_WIDTH
) (
    input  wire                 VGND,
    input  wire                 VPWR,

    input  wire                 i_enable,
    input  wire                 i_strobe,
    input  wire                 i_sel_en,
    input  wire [SEL_WIDTH-1:0] i_sel,
    output wire                 o_ready,
    output wire [SEL_COUNT-1:0] o_ctrl,

    // OA prefix for internal to project digital-to-analog output signals
    output wire [SEL_COUNT-1:0] oa_ctrl,
    output wire [1:0]           oa_por,

    input  wire                 rst_n,       // reset_n - async activate
    input  wire                 rst_n_sync,  // reset_n - sync release
    input  wire                 clk          // clock
);

    // These can be a parameter in version 2
    wire [SEL_WIDTH-1:0] DEFAULT_SEL_ON_RESET;
    assign DEFAULT_SEL_ON_RESET = {SEL_WIDTH{1'b1}};     // make the last one the default as it may not be any
    wire SET_SEL_ON_RESET;
    assign SET_SEL_ON_RESET = 1'b1;

    // What is this control circuit trying to do.
    //
    // Allow it to be a module inside a more complex mixed signal project that needs to share TT input wires.
    // So i_enable is provided to inhibit this module from interpreting any command.
    // The parent instanciating module will need to manage the o_ready signal and multiplex it if necessary
    // on the outputs.
    //
    // Manage reset conditions, it does this always (even when i_enable==0) to achieve a consistent internal
    // state ASAP.
    // It enters reset asynchronously (causing immediate DUT disconnection) but only leaves reset synchronously.
    //
    // There is a 2 to 2.5 clock cycle quisecent period where no DUT is active, during the reselect process.
    // The disconnection occurs asynchronously on the i_strobe posedge.  Reconnection occurs synchronously
    // after another 2 to 2.5 clock cycles.  The control circuit timing is designed to minimize any aparent
    // glitching over the oa_ctrl and o_ready control lines.
    //
    // Provide a power-on-reset that attempts to ensure the project must complete a reset cycle
    //  on power-on before any DUT is connected.

    // Reset control (this assumes a rst_n_sync is provided by parent, and rst_n is async)
    reg reset;
    always @(posedge clk)
        reset <= rst_n_sync;

    wire rst_posedge;
    assign rst_posedge = rst_n_sync & !reset;

    reg rst_done;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rst_done <= 1'b0;
        end else begin
            rst_done <= rst_done | rst_posedge; // or_rst_done
        end
    end


    // Power-On-Reset (also has analogue oa_por resistive net drain, ~220k Ohm @ 1.8v)
    // The goal is to remove the potential randomnesson startup and make is more deterministic (always off)
    // A bit of an experiment, maybe por[0] also needs a resistive net drain also.
`ifdef SYNTHESIS
    wire [2:0] por;
    wire [2:0] por_dly;
    // DFF: critical to not optimize away (synthesis wanted to die output to logic ONE)
    // also critical to not get an additional buffer inserted at Q output to OA_POR[?] port.
    (* keep , syn_keep *) sky130_fd_sc_hd__dfxtp #(
        .DRIVE_LEVEL(1),	// this can be DL=1 as it only drives to por[1]
        .DONT_TOUCH(0)		// can resize
    ) por_2_dfxtp_1 (
        .Q      (por[2]),
        .CLK    (clk),
        .D      (1'b1)
    );
    (* keep , syn_keep *) sky130_fd_sc_hd__dlygate4sd3 #(
        .DONT_TOUCH(0)		// can resize
    ) por_2_dlygate4sd3_1 (
        .X      (por_dly[2]),
        .A      (por[2])
    );
    (* keep , syn_keep *) sky130_fd_sc_hd__dfxtp #(
        .DRIVE_LEVEL(2),	// this is routed to por[0] as well as resistor out oa_por[1]
        .DONT_TOUCH(1)		// enable, no resizing, due to resistor
    ) por_1_dfxtp_2 (
        .Q      (por[1]),
        .CLK    (clk),
        .D      (por_dly[2])
    );
    (* keep , syn_keep *) sky130_fd_sc_hd__dlygate4sd3 #(
        .DONT_TOUCH(0)		// can resize
    ) por_1_dlygate4sd3_1 (
        .X      (por_dly[1]),
        .A      (por[1])
    );
    (* keep , syn_keep *) sky130_fd_sc_hd__dfxtp #(
        .DRIVE_LEVEL(2),	// this is routed to and_rst_n_disconnect as well as resistor out oa_por[0]
        .DONT_TOUCH(1)		// enable, no resizing, due to resistor
    ) por_0_dfxtp_2 (
        .Q      (por[0]),
        .CLK    (clk),
        .D      (por_dly[1]) // (por[1]) //_dont_touch[1])
    );
    (* keep , syn_keep *) sky130_fd_sc_hd__dlygate4sd3 #(
        .DONT_TOUCH(0)		// can resize
    ) por_0_dlygate4sd3_1 (
        .X      (por_dly[0]),	// this is neeed to make and3 meet timing!  LOL but its an async signal! oh well...
        .A      (por[0])
    );
`else
    reg [2:0] por;
    always @(posedge clk) begin
        por[0] <= por[1];
        por[1] <= por[2];
        por[2] <= 1'b1;
    end
`endif

    // Strobe input signal management
    reg [1:0] stb_next;  // stb_next[0] is capture, stb_next[1] is 1 cycle delayed
    always @(posedge clk) begin
        if (!rst_n_sync) begin
            stb_next[0] <= 1'b0;
        end if (i_enable) begin
            stb_next[0] <= i_strobe;
        end else begin
            stb_next[0] <= 1'b0;
        end
    end
    always @(posedge clk) begin
        stb_next[1] <= stb_next[0];
    end

    wire stb_posedge_async;
    assign stb_posedge_async = i_strobe & !stb_next[0];
    wire stb_posedge_sync;
    assign stb_posedge_sync = stb_next[0] & !stb_next[1];

    reg reg_stb_posedge_extend;
    always @(posedge clk) begin
        reg_stb_posedge_extend <= stb_posedge_sync;
    end

    reg reg_delay_en;
    always @(negedge clk) begin
        reg_delay_en <= stb_posedge_sync;
    end

    wire or_stb_active;
    assign or_stb_active = |{reg_delay_en, reg_stb_posedge_extend, stb_posedge_sync};


    // SEL
    wire and_can_sel_capture;
    assign and_can_sel_capture = i_sel_en & !or_stb_active;

    reg [SEL_WIDTH-1:0] sel_front;
    always @(posedge clk) begin
        if(and_can_sel_capture) begin
            sel_front <= i_sel;
        end
    end
    
    reg [SEL_WIDTH-1:0] sel;
    always @(negedge clk) begin
        if (!rst_n_sync && SET_SEL_ON_RESET) begin
            sel <= DEFAULT_SEL_ON_RESET;
        end else if(stb_posedge_sync) begin
            sel <= sel_front;
        end
    end


    // This is not critical due to use of DFF between
    wire stb_posedge_disconnect;
    assign stb_posedge_disconnect = stb_posedge_sync && !reg_delay_en;


    // Why am I using sky130 cells directly here ?
    //   Well I have not worked thorugh the possibilities on if the synthesiser can techmap a
    //   cell function coalesce that results in the intended AND and OR (as written in verilog)
    //   into a different cell that might facilitate an unwanted glitch to occur at the output
    //   which feed an async-reset.  Maybe Yosys knows and detects this is an async signal and
    //   the remapping rules are more limited.
    // But just in case the intention here was for a NOR2 and AND3 to exists as described in
    //   the verlog.

   // Pull through digital block to make available to analog on south side, via a buffer.
    wire nor_stb_disconnect;
`ifdef SYNTHESIS
    // NOR2: critical async signal line
    (* keep , syn_keep *) sky130_fd_sc_hd__nor2 #(
        .DONT_TOUCH(1)		// enable, no resizing, due to preference (no reason)
    ) async_nor2 (
        .Y      (nor_stb_disconnect),
        .A      (stb_posedge_async),
        .B      (stb_posedge_disconnect)
    );
`else
    assign nor_stb_disconnect = !(stb_posedge_async | stb_posedge_disconnect);  // simulation
`endif

    wire and_rst_n_disconnect;
`ifdef SYNTHESIS
    // AND3: critical async signal line
    (* keep , syn_keep *) sky130_fd_sc_hd__and3 #(
        .DONT_TOUCH(1)		// enable, no resizing, due to preference (no reason)
    ) async_and3 (
        .X      (and_rst_n_disconnect),
        .A      (nor_stb_disconnect),
        .B      (rst_n),
        .C      (por_dly[0])	// por[0] was here, but + dlygate4sd3 is needed to meet timing
    );
`else
    assign and_rst_n_disconnect = nor_stb_disconnect & rst_n & por[0];	// simulation
`endif

    // Output Enable
    wire and_state_good;
    assign and_state_good = rst_done & or_stb_active;	// ???

    reg reg_sel_oe;
    always @(posedge clk or negedge and_rst_n_disconnect) begin
        if (!and_rst_n_disconnect) begin
            reg_sel_oe <= 0;
        end else if(reg_delay_en) begin
            reg_sel_oe <= and_state_good;
        end
    end

    // Decoder (binary to one-hot)
    wire [SEL_COUNT-1:0] ctrl;

    binary_to_onehot #(
        .SEL_WIDTH  (SEL_WIDTH)
    ) decoder (
        .sel        (sel[SEL_WIDTH-1:0]),		// i
        .oh         (ctrl[SEL_COUNT-1:0])		// o
    );

    genvar d;
    generate
        for(d = 0; d < SEL_COUNT; d = d + 1) begin : c
            // FIXME Should we force this is to be sky130_and2 cells, this prevents optimization with composite
            // logic cells that may cause glitching.  But looking at the upstream data path I think we are ok.
            // The goal is to ensure that when the and_dec_en toggle in any direction, it is the only input pin
            // that is allowed to toggle around that clock edge.
            assign oa_ctrl[d] = ctrl[d] & reg_sel_oe; // output-enable
        end
    endgenerate

    assign o_ready = reg_sel_oe;
    assign o_ctrl[SEL_COUNT-1:0] = ctrl[SEL_COUNT-1:0];

    assign oa_por[1:0] = por[1:0];	// analog ~220kR resistive drain

endmodule
