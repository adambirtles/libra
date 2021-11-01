# Libra ISA Specification

## Components

![Block diagram of a Libra implementation](block-diagram.png)

### ALU

Libra's arithmetic and logic unit (ALU) supports six operations. Four operations are binary:

- Addition
- Bitwise AND
- Bitwise OR
- Bitwise XOR

The other two are unary:

- Increment
- Bitwise NOT

### Status flags

There are three status flags: halt, carry, and zero.

While the halt flag (`h`) is set, the CPU will not operate.

The carry flag (`c`) stores the carry of the most recent addition/increment.

The zero flag (`z`) is set if the result of the most recent ALU operation is 0.

### General purpose registers

Libra has 16 × 8-bit general purpose registers named `R0` through `R15`. Any two of these registers can be indexed at once (referred to as `RX` and `RY`).

### Special purpose registers

The program counter (`PC`) stores the memory location of the current instruction. It is 12 bits wide.

Load and store instructions are done with the concatenation of the 5-bit page register (`PG`) and a 7-bit index operand.

## Operation

The basic fetch-decode-execute cycle of a Libra CPU is as follows:

1. `IR[15:8] ← M[PC]` then `PC ← PC + 1`
2. `IR[7:0] ← M[PC]` then `PC ← PC + 1`
3. Decode `IR`.
4. Execute the instruction represented by `IR`.
5. If `h` is not set, then return to step 1.

## Instructions

Instructions are 16 bits. The 5 most significant bits are the opcode while the other 11 specify operands. There are four instruction layouts:

<table>
  <tr>
    <th>Type</th>
    <th>15</th>
    <th>14</th>
    <th>13</th>
    <th>12</th>
    <th>11</th>
    <th>10</th>
    <th>9</th>
    <th>8</th>
    <th>7</th>
    <th>6</th>
    <th>5</th>
    <th>4</th>
    <th>3</th>
    <th>2</th>
    <th>1</th>
    <th>0</th>
  </tr>
  <tr>
    <td>No operand</td>
    <td colspan="5">Opcode (5)</td>
    <td colspan="11">N/A</td>
  </tr>
  <tr>
    <td>Register</td>
    <td colspan="5">Opcode (5)</td>
    <td colspan="4">RX (4)</td>
    <td colspan="4">RY (4)</td>
    <td colspan="3">N/A</td>
  </tr>
  <tr>
    <td>Load/Store</td>
    <td colspan="5">Opcode (5)</td>
    <td colspan="4">RX (4)</td>
    <td colspan="7">Index operand (7)</td>
  </tr>
  <tr>
    <td>Immediate</td>
    <td colspan="5">Opcode (5)</td>
    <td colspan="11">Immediate operand (11)</td>
  </tr>
</table>

Some register instructions do not use RY. Load/Store instructions concatenate the index operand with the page to get the memory address to load or store.

The instructions are as follows:

| Name                 | Opcode | Layout     | Description                   |
|:---------------------|:------:|:-----------|:------------------------------|
| No-op                | 00000  | No operand | Do nothing                    |
| Halt                 | 00001  | No operand | Set `h`                       |
| Copy                 | 00010  | Register   | `RX ← RY`                     |
| Load                 | 00011  | Load/Store | `RX ← M[PG . IR[7:0]]`        |
| Store                | 00100  | Load/Store | `M[PG . IR[7:0]] ← RX`        |
| Set page register    | 00101  | Immediate  | `PG ← IR[4:0]`                |
| Jump                 | 00110  | Immediate  | `PC[12:1] ← IR[11:0]`         |
| Jump if zero         | 01000  | Immediate  | Jump if `z` is set            |
| Jump if carry        | 01001  | Immediate  | Jump if `c` is set            |
| Jump if not zero     | 01010  | Immediate  | Jump if `z` is not set        |
| Jump if not carry    | 01011  | Immediate  | Jump if `c` is not set        |
| Left shift           | 01100  | Register   | Clear `c` then `RX ← RX << 1` |
| Right shift          | 01101  | Register   | Clear `c` then `RX ← RX >> 1` |
| Left shift w/ carry  | 01111  | Register   | `RX ← RX << 1`                |
| Right shift w/ carry | 01111  | Register   | `RX ← RX >> 1`                |
| Add                  | 10100  | Register   | Clear `c` then `RX ← RX + RY` |
| Increment            | 10101  | Register   | Clear `c` then `RX ← RX + 1`  |
| Bitwise AND          | 11000  | Register   | `RX ← RX & RY`                |
| Bitwise OR           | 11001  | Register   | `RX ← RX \| RY`               |
| Bitwise XOR          | 11010  | Register   | `RX ← RX ^ RY`                |
| Bitwise NOT          | 11011  | Register   | `RX ← ~RX`                    |
| Add w/ carry         | 11100  | Register   | `RX ← RX + RY`                |
| Increment w/ carry   | 11101  | Register   | `RX ← RX + 1`                 |
