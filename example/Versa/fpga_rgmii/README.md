# Verilog Ethernet Versa Example Design

## Introduction

This example design targets the ECP5 Versa FPGA board.

The design by default listens to UDP port 1234 at IP address 192.168.1.128 and
will echo back any packets received.  The design will also respond correctly
to ARP requests.  

Configure the PHY for RGMII by placing J66 across pins 1 and 2, opening J67,
and shorting J68.

FPGA: LFE5UM5G-45F-8CABGA381
PHY: Marvell M88E1512

## How to build

Run make to build.  Ensure that the Yosys/nextpnr/prjtrellis toolchain components are
in PATH.  

## How to test

Run make program to program the Versa board with the OpenOCD software.
Then run netcat -u 192.168.1.128 1234 to open a UDP connection to port 1234.
Any text entered into netcat will be echoed back after pressing enter.  


