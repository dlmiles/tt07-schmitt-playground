//
// SKY130 process implementation cell/module mapping
//
// SPDX-FileCopyrightText: Copyright 2024 Darryl Miles
// SPDX-License-Identifier: Apache2.0
//
// This file exist to map the behavioural cell name 'sky130_fd_sc_hd__dfxtp'
//   into a specific cell in the PDK such as 'sky130_fd_sc_hd__dfxtp_1'
//
`default_nettype none

module sky130_fd_sc_hd__dfxtp #(
    parameter integer DRIVE_LEVEL = 2,
    parameter integer DONT_TOUCH = 1
) (
    Q,
    CLK,
    D
);

    // Module ports
    output Q;
    input  CLK;
    input  D;

    generate
        if (DONT_TOUCH == 0) begin
        if (DRIVE_LEVEL == 1) begin
            (* keep , syn_keep *) sky130_fd_sc_hd__dfxtp_1 dfxtp_1 (
`ifdef USE_POWER_PINS
                .VPWR    (1'b1),
                .VGND    (1'b0),
                .VPB     (1'b1),
                .VNB     (1'b0),
`endif
                .Q       (Q),
                .CLK     (CLK),
                .D       (D)
            );
        end else if (DRIVE_LEVEL == 2) begin
            (* keep , syn_keep *) sky130_fd_sc_hd__dfxtp_2 dfxtp_2 (
`ifdef USE_POWER_PINS
                .VPWR    (1'b1),
                .VGND    (1'b0),
                .VPB     (1'b1),
                .VNB     (1'b0),
`endif
                .Q       (Q),
                .CLK     (CLK),
                .D       (D)
            );
        end else if (DRIVE_LEVEL == 4) begin
            (* keep , syn_keep *) sky130_fd_sc_hd__dfxtp_4 dfxtp_4 (
`ifdef USE_POWER_PINS
                .VPWR    (1'b1),
                .VGND    (1'b0),
                .VPB     (1'b1),
                .VNB     (1'b0),
`endif
                .Q       (Q),
                .CLK     (CLK),
                .D       (D)
            );
        end else begin
            // Check sky130 cell library for your requirement and add case
            $error("DRIVE_LEVEL=%d is not implemented for sky130_fd_sc_hd__dfxtp", DRIVE_LEVEL);
        end

        end else begin
        if (DRIVE_LEVEL == 1) begin
            // dont_touch: to force drive level
            (* keep , syn_keep , dont_touch *) sky130_fd_sc_hd__dfxtp_1 dfxtp_1_dont_touch (
`ifdef USE_POWER_PINS
                .VPWR    (1'b1),
                .VGND    (1'b0),
                .VPB     (1'b1),
                .VNB     (1'b0),
`endif
                .Q       (Q),
                .CLK     (CLK),
                .D       (D)
            );
        end else if (DRIVE_LEVEL == 2) begin
            (* keep , syn_keep , dont_touch *) sky130_fd_sc_hd__dfxtp_2 dfxtp_2_dont_touch (
`ifdef USE_POWER_PINS
                .VPWR    (1'b1),
                .VGND    (1'b0),
                .VPB     (1'b1),
                .VNB     (1'b0),
`endif
                .Q       (Q),
                .CLK     (CLK),
                .D       (D)
            );
        end else if (DRIVE_LEVEL == 4) begin
            (* keep , syn_keep , dont_touch *) sky130_fd_sc_hd__dfxtp_4 dfxtp_4_dont_touch (
`ifdef USE_POWER_PINS
                .VPWR    (1'b1),
                .VGND    (1'b0),
                .VPB     (1'b1),
                .VNB     (1'b0),
`endif
                .Q       (Q),
                .CLK     (CLK),
                .D       (D)
            );
        end else begin
            // Check sky130 cell library for your requirement and add case
            $error("DRIVE_LEVEL=%d is not implemented for sky130_fd_sc_hd__dfxtp", DRIVE_LEVEL);
        end
        end
    endgenerate

endmodule
