---
name: embedded-protocol-analysis
description: Use for CAN, SPI, UART, I2C, RF modem interfaces, binary packets, logic analyzer traces, and hardware communication debugging.
---

# Embedded protocol analysis

## Procedure

- Separate observations, hypotheses and protocol assumptions; retain raw captures and exact byte order.
- Identify physical layer, framing, clock, polarity, bit order, sample rate, arbitration and timeout behavior.
- First produce a minimal reproducible capture/decoder; do not design production architecture prematurely.
- For SocketCAN diagnostics prefer small Python standard-library scripts when feasible.
- Validate CRC, counters, timestamps, endian interpretation and edge cases with known frames.
- Avoid transmitting potentially unsafe commands or changing device state without explicit authorization.
- Report confidence and what further measurement would falsify the hypothesis.

## Completion report

Summarize reused code, files changed, validation performed, unverified assumptions, and any remaining risks.
