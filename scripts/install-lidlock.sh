#!/bin/zsh
# Lid-lock for ASUS Vivobook 15 X513EP (macOS Tahoe Hackintosh)
# Lid closed -> lock the Mac and keep the display awake (caffeinate -d), so the
# graphics driver never has to wake the display (that wake can hang it and crash WindowServer).
# Lid opened -> after 60 seconds the display may sleep again normally.
# Installs ~/.lidlock.sh and a LaunchAgent (com.user.lidlock) for the current user,
# replacing an older version if one is running.
# See README → section 18 and Appendix C.
#
# Never use `pmset displaysleepnow` on this laptop — the screen doesn't come back on.

launchctl bootout gui/$(id -u)/com.user.lidlock 2>/dev/null

cat > ~/.lidlock.sh <<'SH'
#!/bin/zsh
prev=No; cpid=""
while true; do
  s=$(ioreg -r -n IOPMrootDomain -d 1 | awk -F'= ' '/"AppleClamshellState"/{print $2; exit}')
  if [[ $s == Yes && $prev != Yes ]]; then
    /usr/bin/caffeinate -d & cpid=$!
    /usr/bin/osascript -l JavaScript -e 'ObjC.import("Foundation"); $.NSBundle.bundleWithPath("/System/Library/PrivateFrameworks/login.framework").load; ObjC.bindFunction("SACLockScreenImmediate", ["int", []]); $.SACLockScreenImmediate();' >/dev/null 2>&1
  elif [[ $s != Yes && $prev == Yes ]]; then
    [[ -n $cpid ]] && (sleep 60; kill $cpid 2>/dev/null) &!; cpid=""
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
