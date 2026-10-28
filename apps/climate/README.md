# Climate

The temperature (°C) and humidity from the sensor inside your unidex. **B** reads it again, and it updates by itself
once a minute while it's open. No permissions.

The sensor sits on the board, next to the chip, so it reads a few degrees warmer than the room, more while charging
or using WiFi, and takes a while to catch up when you move somewhere new.

Needs firmware with API level 6 (`unidex.climate`). First written by [candour](https://github.com/candour).
