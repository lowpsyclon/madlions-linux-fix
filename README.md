# Madlions MAD68 Linux Fix

Fix for Madlions magnetic keyboards (MAD68) on Linux.

## Problem

The keyboard works for typing, but the web configurator cannot detect or access the device due to `hidraw` permission restrictions.

## Solution

This script:

- detects the keyboard (`373b:105c`)
- creates a dedicated access group
- adds your user to the group
- creates a proper udev rule
- reloads udev
- applies immediate permissions (works without reboot)

## Requirements

- Linux (udev-based)
- fish shell
- git
- github-cli (`gh`)
- packages:
  - `usbutils`
  - `acl` (optional but recommended)

## Usage

```fish
chmod +x mad68-fix.fish
./mad68-fix.fish

Then open the configurator using:

Chromium
Google Chrome
Notes
No permanent 0666 permissions are used (secure)
If the script adds you to a group, logout/login is recommended
Keywords

madlions linux fix, mad68 linux, webhid linux, hidraw permissions, keyboard configurator not working linux

License

MIT
