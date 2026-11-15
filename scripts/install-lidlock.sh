#!/bin/zsh
# Lid-lock for ASUS Vivobook 15 X513EP (macOS Tahoe Hackintosh)
# Locks the Mac when the lid is closed, without turning the screen off.
# Installs ~/.lidlock.sh and a LaunchAgent (com.user.lidlock) for the current user.
# See README → section 18 and Appendix C.
#
# Do NOT add `pmset displaysleepnow` here — on this laptop the screen doesn't come back on.

cat > ~/.lidlock.sh <<'SH'
#!/bin/zsh
prev=No
while true; do
  s=$(ioreg -r -n IOPMrootDomain -d 1 | awk -F'= ' '/"AppleClamshellState"/{print $2; exit}')
  if [[ $s == Yes && $prev != Yes ]]; then
    /usr/bin/osascript -l JavaScript -e 'ObjC.import("Foundation"); $.NSBundle.bundleWithPath("/System/Library/PrivateFrameworks/login.framework").load; ObjC.bindFunction("SACLockScreenImmediate", ["int", []]); $.SACLockScreenImmediate();' >/dev/null 2>&1
  fi
  prev=$s
  sleep 2
done
SH

mkdir -p ~/Library/LaunchAgents
cat > ~/Library/LaunchAgents/com.user.lidlock.plist <<PL
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>Label</key><string>com.user.lidlock</string>
<key>ProgramArguments</key><array><string>/bin/zsh</string><string>$HOME/.lidlock.sh</string></array>
<key>RunAtLoad</key><true/><key>KeepAlive</key><true/>
</dict></plist>
PL

launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.user.lidlock.plist && echo "Lid lock running"
