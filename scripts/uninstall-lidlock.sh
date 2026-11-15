#!/bin/zsh
# Removes the lid-lock LaunchAgent and script installed by install-lidlock.sh

launchctl bootout gui/$(id -u)/com.user.lidlock 2>/dev/null
rm -f ~/Library/LaunchAgents/com.user.lidlock.plist ~/.lidlock.sh
echo "Lid lock removed"
