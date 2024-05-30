
# SPDX-FileCopyrightText: Copyright 2024 Darryl L. Miles
# SPDX-License-Identifier: Apache-2.0

import sys
import random

import cocotb
from cocotb.types import Logic, LogicArray
from cocotb.clock import Clock
from cocotb.binary import BinaryValue
from cocotb.triggers import ClockCycles

from cocotb_stuff.cocotbutil import *

DEBUG_LEVEL = 1

SEL_WIDTH = 4
SEL_COUNT = 2 ** SEL_WIDTH

I_SEL_MASK = 0x0f
I_SEL_EN = 0x10
I_ENABLE = 0x40
I_STROBE = 0x80
O_READY = 0x80

O_READY_BITID = 7


def debug_info(dut, level: int = 1, *args) -> None:
    if DEBUG_LEVEL >= level:
        dut._log.info(*args)


def pad(s, padlen: int = None, padchar: str = ' '):
    assert type(padchar) is str
    if type(padlen) is int and padlen >= 0:
        ss = str(s)
        padcnt = padlen - len(ss)
        if padcnt > 0:
            return ss + (padchar * padcnt)
    return s


# Take a value (of varying type) and create BinaryValue usual just before display output
def resolve_BinaryValue(value, n_bits: int = None) -> BinaryValue:
    if value is None:
        if n_bits is not None:
            return BinaryValue('x' * n_bits, n_bits=n_bits)
        else:
            return BinaryValue('x')

    if type(value) is BinaryValue:
        return value

    if type(value) is int:
        if n_bits is not None:
            return BinaryValue(value, n_bits=n_bits)
        else:
            return BinaryValue(value)

    if type(value) is LogicArray:
        return BinaryValue(str(value))

    raise Exception(f"resolve_BinaryValue(value={value}): invalid type {type(value)}")

def report(dut, ui_in: int, uio_in: int) -> None:
    assert ui_in is None or type(ui_in) is int or type(ui_in) is BinaryValue or type(ui_in) is LogicArray
    assert uio_in is None or type(uio_in) is int or type(uio_in) is BinaryValue or type(uio_in) is LogicArray

    uio_out = dut.uio_out.value
    uo_out = dut.uo_out.value

    o_ready = True if(uo_out.is_resolvable and (uo_out & O_READY) == O_READY) else False

    o_por = dut.oa_por.value
    o_ctrl = dut.oa_ctrl.value
    
    por = f"{str(o_por)}"
    ctrl = f"{str(o_ctrl)}"
    status = "UNKNOWN"

    bv_ui_in = resolve_BinaryValue(ui_in, 8)
    bv_uio_in = resolve_BinaryValue(uio_in, 8)
    dut._log.info(f"ui_in={str(bv_ui_in)} uio_in={str(bv_uio_in)} uo_out={str(uo_out)}  uio_out={str(uio_out)}  ready={pad(o_ready, 5)} por={por}  ctrl={ctrl} {status}")




def uo_out_description(uo_out: int) -> str:
    l = []
    if (uio_in & O_READY) == O_READY:
        l += 'O_READY'
    return ','.join(l)


def ui_in_description(ui_in: int) -> str:
    l = []
    if (ui_in & I_SEL_EN) == I_SEL_EN:
        l += 'I_SEL_EN'
    if (ui_in & I_ENABLE) == I_ENABLE:
        l += 'I_ENABLE'
    if (ui_in & I_STROBE) == I_STROBE:
        l += 'I_STROBE'
    sel = ui_in & I_SEL_MASK
    l = f"SEL={sel}"
    return ','.join(l)


def assert_por(dut, expect, value):
    pass


def assert_por_nominal(dut, start_task: bool):
    if start_task:
        pass	# FIXME setup background job to confirm this signal never changes
    return assert_por(dut, 0x3)


def assert_ready(dut, expect):
    actual = binary_value_bit(dut.uo_out.value, O_READY_BITID)

    if actual is None and expect == LogicArray('X'):
        return
    assert actual is not None

    if expect is None:
        expect_value = 'x'
    elif expect == True or expect == '1' or expect == 1:
        expect_value = '1'
    elif expect == False or expect == '0' or expect == 0:
        expect_value = '0'
    elif type(expect) is Logic:
        expect_value = str(expect)
    else:
        expect_value = '?'
    assert str(actual[2]).casefold() == str(expect_value).casefold(), f"O_READY failure expected={expect_value} actual={actual[2]}"


def assert_ctrl(dut, expect):
    assert type(expect) is int, f"expect={expect} expected type {type(expect)}"
    assert expect >= 0 and expect <= 15, f"expect={expect} is out of range 0..15"
    bit = 1 << expect

    ctrl = dut.oa_ctrl.value.integer
    
    if expect >= 0 and expect <= 14: # only 15 bits
        if expect <= 7:
            tmp = dut.uio_out.value.integer
        else:
            tmp = (dut.uo_out.value.integer & 0x7f) << 8
        assert tmp == bit, f"uo_in/uio_in indicator is {tmp:04x} but expected={bit:04x} for bit={bit:04x}"

    if expect is not None:
        assert ctrl == bit, f"ctrl={ctrl} expected value expected={expect:04x} for bit={bit:04x}"


def compute(ui_in: int, value: int = None, sel: int = None) -> int:
    assert value is None or type(value) is int, f"value is unexpected type={type(stb)}"
    assert sel is None or type(sel) is int, f"sel is unexpected type={type(sel)}"

    CTLMASK = I_SEL_EN|I_STROBE|I_ENABLE	#!I_SEL_MASK
    ALLMASK = I_SEL_MASK|CTLMASK

    if value is not None:
        assert (value & ~ALLMASK) == 0, f"value={value} is out of range I_SEL_MASK|I_SEL_EN|I_STROBE|I_ENABLE"
        new_value = value & CTLMASK	# only CTLMASK we do I_SEL_MASK below
    else:
        new_value = ui_in & CTLMASK	# no change

    if sel is not None:
        assert (sel & ~I_SEL_MASK) == 0, f"sel={sel} is out of range 0..{I_SEL_MASK}"
        new_value |= sel & I_SEL_MASK
    else:
        new_value |= ui_in & I_SEL_MASK

    return (ui_in & ~ALLMASK) | new_value


@cocotb.test()
async def test_schmitt_playground(dut):
    dut._log.info("Start")
    clock = Clock(dut.clk, 10, units="us")
    cocotb.start_soon(clock.start())

    # FIXME this is a param in VCD (how to access from cocotb?)
    #foo = dut._id("SEL_WIDTH", extended=False)
    #assert SEL_WIDTH == dut.SEL_WIDTH.value, f"SEL_WIDTH mismatch, {SEL_WIDTH} != {str(dut.SEL_WIDTH.value.integer)}  [test != vcd]"
    #assert SEL_COUNT == dut.SEL_COUNT.value.integer, f"SEL_COUNT mismatch, {SEL_COUNT} != {str(dut.SEL_COUNT.value.integer)}  [test != vcd]"

    ui_in = None
    uio_in = None
    report(dut, ui_in, uio_in)

    # Power-On-Reset signals should start working immediately
    assert_por(dut, 0, LogicArray('XX'))
    assert_ready(dut, Logic('X'))
    await ClockCycles(dut.clk, 1)       # show X
    report(dut, ui_in, uio_in)
    assert_por(dut, 0, LogicArray('XX'))

    assert_ready(dut, Logic('X'))	# init after first clock
    # FIXME setup expectation of ready=False (until further notice)
    #assert_ctrl(dut, None)
    # FIXME setup expectation of ctrl=None (until further notice)
    await ClockCycles(dut.clk, 1)       # show X
    report(dut, ui_in, uio_in)
    assert_por(dut, 0x2, LogicArray('1X'))

    debug(dut, 'RESET')

    # ena=0 state
    dut.ena.value = 0
    dut.rst_n.value = 0
    dut.clk.value = 0
    dut.ui_in.value = 0
    dut.uio_in.value = 0

    ui_in = 0
    uio_in = 0

    await ClockCycles(dut.clk, 2)       # show muted inputs ena=0
    report(dut, ui_in, uio_in)
    assert_por(dut, 0x2, LogicArray('11'))

    dut._log.info("ena (active)")
    dut.ena.value = 1                   # ena=1
    await ClockCycles(dut.clk, 2)
    report(dut, ui_in, uio_in)

    dut._log.info("reset (inactive)")
    dut.rst_n.value = 1                 # leave reset
    await ClockCycles(dut.clk, 2)
    report(dut, ui_in, uio_in)


    debug(dut, 'START')
    
    ui_in = 0
    uio_in = 0
    
    report(dut, ui_in, uio_in)

    await ClockCycles(dut.clk, 1)
    report(dut, ui_in, uio_in)

    # FIXME setup rst_done monitor
    # FIXME setup state_good monitor
    # FIXME stb_posedge_sync monitor
    # FIXME setup delay_en monitor

    # Try input combintation without I_ENABLE to confirm no change of outputs
    ui_in = compute(ui_in, I_SEL_EN|I_STROBE|I_ENABLE, sel=0)
    dut.ui_in.value = ui_in
    await ClockCycles(dut.clk, 1)
    report(dut, ui_in, uio_in)

    # Try all combinations of input ui_in uio_in (expect no change in outputs)

    ui_in = compute(ui_in, 0)
    dut.ui_in.value = ui_in
    await ClockCycles(dut.clk, 1)
    report(dut, ui_in, uio_in)

    ui_in = compute(ui_in, I_ENABLE)
    dut.ui_in.value = ui_in
    await ClockCycles(dut.clk, 1)
    report(dut, ui_in, uio_in)

    # Try all combinations of input ui_in uio_in (expect no change in outputs)


    # Now try sel=0
    # expect O_READY
    # expect O_CTRL0
    
    await ClockCycles(dut.clk, 7)
    report(dut, ui_in, uio_in)

    # deassert I_ENABLE (and try all inputs)
    ui_in = compute(ui_in, I_ENABLE)
    dut.ui_in.value = ui_in
    await ClockCycles(dut.clk, 1)
    report(dut, ui_in, uio_in)

    # deassert I_STROBE (and try all inputs)
    ui_in = compute(ui_in, I_ENABLE)
    dut.ui_in.value = ui_in
    await ClockCycles(dut.clk, 1)
    report(dut, ui_in, uio_in)

    # deassert I_ENABLE (again, and try all inputs)
    ui_in = compute(ui_in, I_ENABLE)
    dut.ui_in.value = ui_in
    await ClockCycles(dut.clk, 1)
    report(dut, ui_in, uio_in)

    # assert I_STROBE (and try all inputs)
    ui_in = compute(ui_in, I_STROBE)
    dut.ui_in.value = ui_in
    await ClockCycles(dut.clk, 1)
    report(dut, ui_in, uio_in)

    # assert I_STROBE and I_ENABLE (and try all inputs, as the I_STROBE edge was lost expect no change)
    ui_in = compute(ui_in, I_STROBE)
    dut.ui_in.value = ui_in
    await ClockCycles(dut.clk, 1)
    report(dut, ui_in, uio_in)

    # deassert I_STROBE
    ui_in = compute(ui_in, I_ENABLE)
    dut.ui_in.value = ui_in
    await ClockCycles(dut.clk, 1)
    report(dut, ui_in, uio_in)

    # FIXME optional wind on half a clock cycle


    for x_sel in range(16):
        dut._log.info(f"x_sel={x_sel}")

        # assert I_STROBE and I_ENABLE (select another)
        ui_in = compute(ui_in, I_SEL_EN|I_STROBE|I_ENABLE, sel=x_sel)
        dut.ui_in.value = ui_in
        # FIXME pass control to sim, but don't step clock, looking for async change of O_READY/O_CTRL
        # FIXME use half clock cycle instead here
        await ClockCycles(dut.clk, 1)
        report(dut, ui_in, uio_in)

        assert_ready(dut, False) # confirm OE disconnects

        await ClockCycles(dut.clk, 1)
        report(dut, ui_in, uio_in)
        # FIXME confirm !O_READY and disconnected O_CTRL 

        assert_ready(dut, False) # confirm OE connects

        await ClockCycles(dut.clk, 1)
        report(dut, ui_in, uio_in)

        assert_ready(dut, True) # confirm OE connects
        assert_ctrl(dut, x_sel)

        # deassert I_STROBE
        ui_in = compute(ui_in, 0)
        dut.ui_in.value = ui_in

        # FIXME use half clock cycles to count cycles until O_READY and O_CTRL1 appears

        for i in range(7):
            await ClockCycles(dut.clk, 1)
            report(dut, ui_in, uio_in)

            assert_ready(dut, True) # confirm OE connects
            assert_ctrl(dut, x_sel)


    assert_ready(dut, True) # confirm it is connected before

    # assert ISTROBE confirm OE disconnects
    ui_in = compute(ui_in, I_STROBE)
    dut.ui_in.value = ui_in
    await ClockCycles(dut.clk, 1)
    assert_ready(dut, False) # confirm OE disconnects
    report(dut, ui_in, uio_in)


    # deassert I_STROBE
    # FIXME optional wind on half a clock cycle
    # assert I_STROBE, sel=1
    

    debug(dut, 'DONE')

    await ClockCycles(dut.clk, 10)
    report(dut, ui_in, uio_in)
