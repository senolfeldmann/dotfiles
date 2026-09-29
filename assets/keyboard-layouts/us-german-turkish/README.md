# US German Turkish

Version 1.0.0. Copyright © 2026 Şenol Feldmann. MIT-licensed; the license is also embedded in the bundle. The icon is built from `USGermanTurkish.svg` in this directory. It is a monochrome template icon (`TISIconIsTemplate`) so macOS can tint it for the menu bar. macOS renders custom input-source icons in a square slot; system-generated icons may be wider.

This macOS keyboard layout uses the U.S. input source's key outputs, with only the German and Turkish Option assignments below changed. The U.S. outputs were obtained through `UCKeyTranslate`.

| Option + key | Output | Shift + Option + key |
| --- | --- | --- |
| A | ä | Ä |
| O | ö | Ö |
| U | ü | Ü |
| S | ß | ẞ |
| I | ı | İ |
| G | ğ | Ğ |
| D | ş | Ş |
| C | ç | Ç |

The U.S. Option layer otherwise remains available, including Option+4 = ¢ and Shift+Option+2 = €. Option+E, Option+N, and Option+backtick remain dead keys for acute, tilde, and grave accents. Option+I and Option+U produce letters directly.

`../../../scripts/tweaks/macos-keyboard-layout.sh` installs the bundle. After installation, select `US German Turkish` as an input source in macOS Keyboard settings and log out and back in if an open application still uses the previous layout.
