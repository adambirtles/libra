# Libra

Libra is a simple 8-bit CPU architecture designed for my BSc dissertation. This repository contains both a [specification][spec] of the Libra ISA and two implementations written in VHDL, one classical and one bit-serial.

## Known issues

### Bit-serial right-shift

The right-shift instructions do not correctly set the zero flag in the bit-serial implementation. A workaround for this problem is to OR the result with 0 to set the flag correctly.

[spec]: specification.md
