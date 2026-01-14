#!/bin/bash
#
# Xreal One Pro Desktop Mode Setup Script
# For Google Pixel 10 Pro
#
# Usage:
#   ./xreal-setup.sh              # Auto-detect and configure
#   ./xreal-setup.sh usb          # Setup ADB WiFi (phone connected via USB)
#   ./xreal-setup.sh density      # Set density only (already connected via WiFi)
#   ./xreal-setup.sh init         # One-time initialization of persistent settings
#

set -e

# Configuration
WIFI_PORT=5555
DENSITY=160 # Adjust this value if needed (120=small, 160=balanced, 200=large)
PHONE_IP=""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
  echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
  echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
  echo -e "${RED}[ERROR]${NC} $1"
}

# Check if adb is available
check_adb() {
  if ! command -v adb &>/dev/null; then
    log_error "ADB not found. Please install Android SDK platform-tools."
    exit 1
  fi
}

# Get connected device (USB or WiFi)
get_device() {
  local devices=$(adb devices | grep -v "List" | grep -E "device$" | head -1)
  if [ -z "$devices" ]; then
    return 1
  fi
  echo "$devices" | awk '{print $1}'
}

# Get phone's WiFi IP address
get_phone_ip() {
  local device=$1
  adb -s "$device" shell ip route | grep wlan0 | awk '{print $9}'
}

# Setup ADB over WiFi
setup_wifi_adb() {
  log_info "Setting up ADB over WiFi..."

  local usb_device=$(adb devices | grep -v "List" | grep -v ":" | grep -E "device$" | awk '{print $1}')

  if [ -z "$usb_device" ]; then
    log_error "No USB device found. Connect your phone via USB first."
    exit 1
  fi

  log_info "Found USB device: $usb_device"

  # Get IP before switching to TCP mode
  PHONE_IP=$(get_phone_ip "$usb_device")

  if [ -z "$PHONE_IP" ]; then
    log_error "Could not get phone's WiFi IP. Make sure WiFi is connected."
    exit 1
  fi

  log_info "Phone IP: $PHONE_IP"

  # Enable TCP/IP mode
  adb -s "$usb_device" tcpip $WIFI_PORT
  sleep 2

  # Connect via WiFi
  log_info "Connecting to $PHONE_IP:$WIFI_PORT..."
  adb connect "$PHONE_IP:$WIFI_PORT"

  log_info "ADB WiFi setup complete!"
  echo ""
  log_info "You can now disconnect the USB cable and connect your Xreal glasses."
  echo ""

  # Save IP for later use
  echo "$PHONE_IP" >/tmp/xreal_phone_ip
}

# Find Xreal display ID
find_xreal_display_id() {
  local device=$1
  # Look for EXTERNAL display in viewport (the Xreal glasses)
  adb -s "$device" shell dumpsys display 2>/dev/null |
    grep -oP "type=EXTERNAL[^}]*displayId=\K[0-9]+" | head -1
}

# Set density on Xreal display
set_xreal_density() {
  local device=$1

  log_info "Finding Xreal display..."

  local display_id=$(find_xreal_display_id "$device")

  if [ -z "$display_id" ]; then
    log_error "Xreal display not found. Make sure glasses are connected."
    exit 1
  fi

  log_info "Found Xreal display ID: $display_id"
  log_info "Setting density to $DENSITY..."

  adb -s "$device" shell wm density $DENSITY -d "$display_id"

  log_info "Density set successfully!"
}

# One-time initialization of persistent settings
init_persistent_settings() {
  local device=$1

  log_info "Applying one-time persistent settings..."

  # Disable forced mirroring
  adb -s "$device" shell settings put secure mirror_built_in_display 0
  log_info "Disabled mirror mode"

  # Enable desktop mode settings
  adb -s "$device" shell settings put global force_desktop_mode_on_external_displays 1
  adb -s "$device" shell settings put global enable_freeform_support 1
  adb -s "$device" shell settings put global development_enable_freeform_windows_on_secondary_displays 1
  adb -s "$device" shell settings put global development_enable_desktop_windowing 1
  adb -s "$device" shell settings put global allow_desktop_on_external_displays 1

  log_info "Desktop mode settings applied!"
  log_info "These settings persist across reboots."
}

# Reconnect to known WiFi device
reconnect_wifi() {
  if [ -f /tmp/xreal_phone_ip ]; then
    PHONE_IP=$(cat /tmp/xreal_phone_ip)
    log_info "Reconnecting to $PHONE_IP:$WIFI_PORT..."
    adb connect "$PHONE_IP:$WIFI_PORT" 2>/dev/null || true
    sleep 1
  fi
}

# Main logic
main() {
  check_adb

  case "${1:-auto}" in
  usb)
    setup_wifi_adb
    ;;
  density)
    reconnect_wifi
    device=$(get_device)
    if [ -z "$device" ]; then
      log_error "No device connected. Run './xreal-setup.sh usb' first."
      exit 1
    fi
    set_xreal_density "$device"
    ;;
  init)
    device=$(get_device)
    if [ -z "$device" ]; then
      log_error "No device connected."
      exit 1
    fi
    init_persistent_settings "$device"
    ;;
  auto)
    # Try to reconnect to WiFi device
    reconnect_wifi

    device=$(get_device)

    if [ -z "$device" ]; then
      log_warn "No device connected."
      echo ""
      echo "Usage:"
      echo "  $0 usb      - Setup ADB WiFi (connect phone via USB first)"
      echo "  $0 density  - Set Xreal display density"
      echo "  $0 init     - One-time setup of persistent settings"
      exit 1
    fi

    log_info "Connected to: $device"

    # Check if Xreal is connected
    display_id=$(find_xreal_display_id "$device")

    if [ -n "$display_id" ]; then
      set_xreal_density "$device"
    else
      log_warn "Xreal display not detected."
      log_info "Connect your Xreal glasses, then run: $0 density"
    fi
    ;;
  *)
    echo "Usage: $0 [usb|density|init|auto]"
    echo ""
    echo "Commands:"
    echo "  usb     - Setup ADB over WiFi (phone must be connected via USB)"
    echo "  density - Set density on Xreal display (requires WiFi ADB)"
    echo "  init    - One-time setup of persistent settings"
    echo "  auto    - Auto-detect and configure (default)"
    exit 1
    ;;
  esac
}

main "$@"
