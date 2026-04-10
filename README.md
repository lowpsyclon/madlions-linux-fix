# Madlions MAD68 Linux Fix

A Fish script to fix WebHID/hidraw access issues for the Madlions MAD68 on Linux.

## Problem

The keyboard works for typing, but the web configurator cannot detect or access the device due to `hidraw` permission restrictions.

## Solution

This script:

- detects the keyboard (`373b:105c`)
- creates a dedicated access group
- adds your user to the group
- creates a proper udev rule
- reloads udev
- applies immediate permissions so it works without reboot

## Requirements

- Linux (udev-based)
- fish shell
- `usbutils`
- `acl` (optional but recommended)

## Usage

```fish
chmod +x mad68-fix.fish
./mad68-fix.fish
