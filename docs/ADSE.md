# Advanced Digital Sound Engine

Core is aarch64, specifically designed for integration with automotive application

## Wants

* Automotive Range (-20C to 70C)
* Must have BT, multiple devices preferred
* WiFi (both as client and AP?)
* LTE radio capability??
* Ample GPIO for iPod, digital sound, etc
* MOST??? https://en.wikipedia.org/wiki/MOST_Bus
* OBD-II connection? (probably not)
* CANbus? (ugh, no, only for tightly integrated designs)

Large battery is probably unnecessary, but should have enough to shut down cleanly. Should be able to hop on home WiFi for software updates, or connect to phone WiFi, or provide WiFi if equipped with an LTE radio. (That part's very iffy.)

## Software Flow

iPod Stack:
* A2DP -> iPod Emulation
* Spotify Native (snapd) -> iPod Emulation
* Pandora Native? -> iPod Emulation
* Local Storage -> iPod Emulation
... somehow need to do 30-pin and lightning

Android Auto??

Standalone/Behind-Dash Integration:
* A2DP -> 2-wire (multiple?)
* A2DP Data -> RDS/Track Info?? (may need to be CANbus)

Maybe sense connection, or hardware switch, or software switch?

## VAG Interface
VAG (AKA MMI/UMI) comes in multiple flavors because of course it does

Porsche is DIN9 or DIN9+USB; 996 (DIN9) will probably need 12V-5V and FW pullup. 997.1+ is USB+DIN9 with 5V (1.8A? 3.6A?) and 12V (1A?) available. 991.2+ is USB.
