# Xreal Desktop Mode

Enable developer desktop mode on Xreal One Pro AR glasses with Android phones, providing an extended display instead of the default mirror mode.

Tested with Google Pixel 10 Pro running Android 16.

## Prerequisites

- ADB installed (`android-platform-tools`)
- USB debugging enabled on your phone
- Developer Options enabled

## Quick Start

### First-Time Setup

1. Connect phone via USB
2. Run the one-time persistent settings:
   ```bash
   ./setup.sh init
   ```

### After Phone Reboot

ADB WiFi mode resets on every reboot. To restore:

**Option A: Wireless Debugging (recommended)**

1. Connect Xreal glasses to phone
2. On phone: Settings → Developer options → Wireless debugging → get IP:PORT
3. Connect and set density:
   ```bash
   ./setup.sh connect IP:PORT
   ./setup.sh density
   ```

**Option B: USB Setup**

1. Connect phone via USB (glasses disconnected)
2. Setup ADB over WiFi:
   ```bash
   ./setup.sh usb
   ```
3. Disconnect USB, connect Xreal glasses
4. Set display density:
   ```bash
   ./setup.sh density
   ```

## Usage

```bash
./setup.sh                    # Auto-detect and configure
./setup.sh connect IP:PORT    # Connect via wireless debugging
./setup.sh usb                # Setup ADB WiFi (phone connected via USB)
./setup.sh density            # Set density only (already connected)
./setup.sh init               # One-time initialization of persistent settings
```

## Configuration

Edit `setup.sh` to change settings:

### Display Density (default: 160)

| Density | Description              |
| ------- | ------------------------ |
| `120`   | More content, smaller UI |
| `160`   | Balanced (recommended)   |
| `200`   | Larger UI, less content  |
| `240`   | Very large UI            |

### Pointer Speed (default: 7)

| Value | Description |
| ----- | ----------- |
| `-7`  | Slowest     |
| `0`   | Default     |
| `7`   | Fastest     |

## How It Works

### Persistent Settings (survive reboots)

The `init` command applies these one-time settings:

- `mirror_built_in_display=0` - Disables forced mirroring (key setting)
- `force_desktop_mode_on_external_displays=1` - Enables desktop mode
- `enable_freeform_support=1` - Enables freeform windows
- `development_enable_freeform_windows_on_secondary_displays=1`
- `development_enable_desktop_windowing=1`
- `allow_desktop_on_external_displays=1`
- `pointer_speed=7` - Sets mouse pointer speed to maximum

### Runtime Settings (reset on reboot/reconnect)

- **ADB WiFi** - Must be re-enabled after every phone reboot
- **Display density** - Resets when glasses are reconnected (default 35 dpi is unreadable)

## Developer Options

Enable these in Settings > Developer Options:

- Enable desktop experience features
- Enable non-resizable in multi-window
- Force activities to be resizable

## Troubleshooting

### Desktop mode not activating

1. Verify `mirror_built_in_display` is `0`:
   ```bash
   adb shell settings get secure mirror_built_in_display
   ```
2. Reconnect the glasses
3. If still not working, reboot phone and run `./setup.sh init`

### Display shows as mirror only

Verify `canHostTasks` is `true`:

```bash
adb shell dumpsys display | grep "XREAL" | grep "canHostTasks"
```

### ADB device unauthorized

Accept the USB debugging prompt on your phone. If no prompt appears, revoke USB debugging authorizations in Developer Options and reconnect.

## License

MIT
