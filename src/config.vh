//
//
//
`ifdef SYNTHESIS

// TT_ANALOG_POWER
//   declare external VGND and VPWR ports
`define TT_ANALOG_POWER 1


// TT_ANALOG_INTERNAL_SIGNAL_PORTS
//   declare internal oa_* ports
`define TT_ANALOG_INTERNAL_SIGNAL_PORTS 1


// TT_ANALOG_EXTERNAL_SIGNAL_PORTS:
//   declare external analog ports ua[0-7]
//   see note near usage
//`define TT_ANALOG_EXTERNAL_SIGNAL_PORTS 1

`endif
