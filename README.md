# ZMK Layer Monitor

**[Website](https://apps.filipp.tech/zmk-layer-monitor)** | **[Download](https://github.com/pfilipp/zmk-layer/releases/latest)**

A macOS menu bar app that displays your active ZMK keyboard layer in real time via HID, with a full keyboard overlay showing keybindings for the current layer.

## Features

- **Real-time HID layer tracking** — monitors your ZMK keyboard's active layer via a custom HID report
- **Keyboard overlay** — toggle a full keyboard layout display showing keybindings for the active layer (default hotkey: `⌘⌃K`)
- **Layer pill indicator** — floating indicator in the top-right corner shows current layer name and lock state
- **Color-coded keys** — tap, hold, modifier-wrapped, and sticky keys are visually distinguished using a colorblind-safe palette
- **Customizable layer names** — rename layers, add emoji, configure visibility (show only when locked, show momentary from locked)
- **Configurable hotkey** — set any keyboard shortcut to toggle the overlay
- **ZMK keymap parser** — import your `.keymap` file to display your actual keybindings (physical layout is inferred automatically)

## Requirements

- macOS
- A ZMK keyboard running firmware built from [pfilipp/zmk](https://github.com/pfilipp/zmk) (a fork that adds HID layer state reporting)

## Installation

Download the latest `.dmg` from [GitHub Releases](https://github.com/pfilipp/zmk-layer/releases/latest).

## ZMK Firmware Setup

ZMK Layer Monitor requires a custom HID report (Report ID `0x04`) that is not part of stock ZMK. You need to build your firmware from the [pfilipp/zmk](https://github.com/pfilipp/zmk) fork.

### Recommended: Use zmk-workspace

The easiest way to build is with [pfilipp/zmk-workspace](https://github.com/pfilipp/zmk-workspace) (a fork of [urob's zmk-workspace](https://github.com/urob/zmk-workspace)):

1. Fork or clone [pfilipp/zmk-workspace](https://github.com/pfilipp/zmk-workspace)
2. Add to your board's `.conf` file:
   ```
   CONFIG_ZMK_HID_LAYER_STATE_REPORT=y
   ```
3. Build and flash as usual

### Manual setup

If you maintain your own ZMK config:

1. Point your `west.yml` manifest to `https://github.com/pfilipp/zmk` instead of the upstream ZMK repo
2. Add `CONFIG_ZMK_HID_LAYER_STATE_REPORT=y` to your `.conf`
3. Build and flash

## Importing Keymaps

To display your actual keybindings in the keyboard overlay:

1. Open ZMK Layer Monitor from the menu bar
2. Click **Import Keyboard Layout**
3. Select your `.keymap` file (e.g., `splitkb_aurora_sweep.keymap`)

The physical key layout is inferred from the line structure of your `bindings` arrays — each line of bindings corresponds to one row of keys.

## Supported Keymap Formats

ZMK Layer Monitor supports the **standard (vanilla) ZMK devicetree format** — keymaps with an explicit `keymap {}` block containing layers with `bindings = < ... >` arrays.

**Not supported:** macro-based keymap configs such as those using [urob's zmk-helpers](https://github.com/urob/zmk-helpers) (e.g., `ZMK_LAYER()` macros). These require C preprocessor expansion before the keymap can be parsed.

If your config uses macros, you can:
- Preprocess your keymap with `gcc -E` or `cpp` to expand macros, then import the result
- Convert your keymap to the vanilla devicetree format manually

## Supported Behaviors

The keymap parser recognizes these ZMK behaviors:

| Behavior | Description |
|----------|-------------|
| `&kp` | Key press |
| `&hml` / `&hmr` | Home row mods (left/right) |
| `&lt` | Layer-tap |
| `&mo` | Momentary layer |
| `&tog` | Toggle layer |
| `&sk` | Sticky key |
| `&mt` | Mod-tap |
| `&trans` | Transparent (inherits from lower layer) |
| `&none` | No action |

Modifier wrappers like `LG()`, `LS()`, `LC()`, `LA()`, `LCS()`, etc. are also supported and displayed with distinct colors.

## Configuring Layers

In the menu bar popover, you can:

- **Add/remove layers** — manage up to 8 layers
- **Rename layers** — give each layer a custom name and emoji
- **Show only when locked** — hide the overlay pill when no layer lock is active
- **Show momentary from locked** — show momentary layer activation when a lock is active

Default layer names: Base, Lower, Raise, Adjust, Nav, Num, Sym, Fun.

## Building from Source

1. Clone the repository:
   ```bash
   git clone https://github.com/pfilipp/zmk-layer.git
   ```
2. Open `zmk-layer.xcodeproj` in Xcode
3. Build and run (⌘R)

## License

MIT License — see [LICENSE](LICENSE) for details.
