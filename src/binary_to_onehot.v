/*
 * Copyright (c) 2024 Darryl L. Miles
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none


module binary_to_onehot #(
    parameter SEL_WIDTH = -1,
    parameter SEL_COUNT = 2 ** SEL_WIDTH
) (
    input  wire [SEL_WIDTH-1:0]  sel,
    output reg  [SEL_COUNT-1:0]  oh
);

    // no supported: assertions with elaboration time constants should work
//    assert (SEL_WIDTH > 0) else $error("SEL_WIDTH <= 0");
    // 2nd best is manually read
    initial begin
        $display("binary_to_onehot.SEL_WIDTH=%d", SEL_WIDTH);
        $display("binary_to_onehot.SEL_COUNT=%d", SEL_COUNT);
    end

`ifdef DISABLE
    // Manually spelled out, not useful with parameterization of verilog modules
    always_comb begin
      case (sel)
        4'b0000: oh = 16'b0000000000000001;
        4'b0001: oh = 16'b0000000000000010;
        4'b0010: oh = 16'b0000000000000100;
        4'b0011: oh = 16'b0000000000001000;
        4'b0100: oh = 16'b0000000000010000;
        4'b0101: oh = 16'b0000000000100000;
        4'b0110: oh = 16'b0000000001000000;
        4'b0111: oh = 16'b0000000010000000;
        4'b1000: oh = 16'b0000000100000000;
        4'b1001: oh = 16'b0000001000000000;
        4'b1010: oh = 16'b0000010000000000;
        4'b1011: oh = 16'b0000100000000000;
        4'b1100: oh = 16'b0001000000000000;
        4'b1101: oh = 16'b0010000000000000;
        4'b1110: oh = 16'b0100000000000000;
        4'b1111: oh = 16'b1000000000000000;
      endcase
    end
`endif

    always_comb begin
      oh = {SEL_COUNT{1'b0}};
      oh[sel] = 1'b1;	// decoder
    end

`ifdef DISABLE
    wire [SEL_WIDTH-1:0] selinv;
  
    genvar s;
    genvar d;
    generate
        for(s = 0; s < SEL_WIDTH; s = s + 1) begin : si
            assign selinv = ~sel[s];
        end
        for(d = 0; d < SEL_COUNT; d = d + 1) begin : d
            wire [SEL_WIDTH-1:0] inp;
            for(s = 0; s < SEL_WIDTH; s = s + 1) begin : i
                if (d == (1'b1 << s)) begin
                    assign inp[s] = sel[s];
                end else begin
                    assign inp[s] = selinv[s];
                end
            end
            assign oh[d] = &inp;
        end
    endgenerate
`endif

`ifdef FOO_DISABLE
    always @(*) begin
        case (sel)
        4'b0000: oh = 16'b0000000000000001;
        4'b0001: oh = 16'b0000000000000010;
        4'b0010: oh = 16'b0000000000000100;
        4'b0011: oh = 16'b0000000000001000;
        4'b0100: oh = 16'b0000000000010000;
        4'b0101: oh = 16'b0000000000100000;
        4'b0110: oh = 16'b0000000001000000;
        4'b0111: oh = 16'b0000000010000000;
        4'b1000: oh = 16'b0000000100000000;
        4'b1001: oh = 16'b0000001000000000;
        4'b1010: oh = 16'b0000010000000000;
        4'b1011: oh = 16'b0000100000000000;
        4'b1100: oh = 16'b0001000000000000;
        4'b1101: oh = 16'b0010000000000000;
        4'b1110: oh = 16'b0100000000000000;
        4'b1111: oh = 16'b1000000000000000;
        default: oh = {SEL_COUNT{1'b0}};
        endcase
    end
`endif

endmodule
