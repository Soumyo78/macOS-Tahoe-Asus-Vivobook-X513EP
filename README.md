# macOS Tahoe 26 on ASUS Vivobook 15 X513EP — Complete Step-by-Step Guide

This guide explains, in simple words, **exactly how macOS Tahoe 26.7.3 was installed on an ASUS Vivobook 15 X513EP** (Intel Core i7-1165G7, Tiger Lake), from a Windows laptop to a working Hackintosh. It includes every problem we hit, why it happened, and how it was fixed — so you can repeat it without guessing.

> ⚠️ **Disclaimer**
> - This erases Windows on the SSD. **Back up everything first.**
> - A Hackintosh is unofficial. Some features will never work (see the status table).
> - Follow the steps **in order**. Most problems come from skipping a step.
> - Only use this on the **same model** (X513EP, i7-1165G7, BIOS **318**). Other models / BIOS versions may need different values.


> **In short:** a working **OpenCore 1.0.8 EFI** and a complete, beginner-friendly guide for running **macOS Tahoe 26.7.3** on the **ASUS Vivobook 15 X513EP** (i7-1165G7 / Iris Xe, BIOS 318) — with graphics acceleration (WhateverXe), Wi-Fi, Bluetooth, audio, touchpad, Fn keys and keyboard backlight working. Every problem we hit is documented with its fix.

> [!WARNING]
> **Generate your own SMBIOS with [GenSMBIOS](https://github.com/corpnewt/GenSMBIOS) (`MacBookPro16,2`) before using this EFI.**
> The `config.plist` files in this repo contain **placeholders** (`XXXXXXXXXXXX` serial, `XXXXXXXXXXXXXXXXX` MLB, all-zero UUID and ROM). The EFI boots, but **iCloud, App Store and iMessage will not work** until you fill in your own values — see [section 5.4](#54-make-your-own-serial-numbers-smbios). Never use someone else's serials.

### Which config to use

| File | When | What's different |
|---|---|---|
| `EFI/OC/config-install.plist` | **Installing** (sections 5–11) | WhateverXe **off**, boot-args start with `-v -igfxvesa`, boot menu shown (`ShowPicker = true`, `HideAuxiliary = false`, `LauncherOption = Disabled`). **Rename it to `config.plist` on the USB stick.** |
| `EFI/OC/config.plist` | **After [section 12](#12-graphics-acceleration-whateverxe)** (and on the SSD, section 17) | Final daily-use config: graphics acceleration on, Apple-logo boot, no menu. |

Both files are identical apart from those settings.

## Folder structure

```
macOS-Tahoe-Asus-Vivobook-X513EP/
├── README.md                     ← this guide
├── EFI/                          ← copy this folder to the USB stick (and later to the SSD's EFI partition)
│   ├── BOOT/BOOTx64.efi
│   └── OC/
│       ├── ACPI/                 ← compiled SSDTs (incl. SSDT-ASUSKEYS.aml, SSDT-TPD-ETPD.aml)
│       ├── Drivers/              ← OpenRuntime, OpenCanopy, ResetNvramEntry, HfsPlus, apfs_aligned
│       ├── Kexts/
│       ├── Resources/            ← OpenCanopy theme (font, images, labels)
│       ├── Tools/                ← ControlMsrE2, modGRUBShell (CFG Lock unlock)
│       ├── OpenCore.efi
│       ├── config.plist          ← final config (placeholders for SMBIOS!)
│       └── config-install.plist  ← config for the first install
├── ACPI-sources/
│   ├── SSDT-ASUSKEYS.dsl         ← Fn keys + keyboard light (Appendix B)
│   └── SSDT-TPD-ETPD.dsl         ← touchpad always present (Appendix B)
├── scripts/
│   ├── install-lidlock.sh        ← lock the Mac when the lid closes (section 18 / Appendix C)
│   └── uninstall-lidlock.sh
├── LICENSE                       ← MIT, for the guide, ACPI sources and scripts only
└── .gitignore
```

The macOS recovery (`com.apple.recovery.boot/BaseSystem.dmg`) is **not** included — download it yourself with `macrecovery.py` ([section 5.2](#52-download-the-macos-tahoe-recovery)).

## Versions

| Component | Version | In config.plist | Notes |
|---|---|---|---|
| macOS | **26.7.3** (Tahoe) | — | Installed from 26.6.2 recovery |
| OpenCore | **1.0.8** | — | DEBUG build, `Misc → Debug → Target = 0` |
| Lilu | 1.7.3 | ✅ | |
| CpuTscSync | 1.1.2 | ✅ | |
| AMFIPass | **1.4.1 Mod** | ✅ | SHA-256 of the binary starts with `2d36aeca` (from WhateverXe-Graphics `extras/`) |
| AirportItlwm | 2.4.0 | ✅ | Tahoe build |
| AppleALC | 1.9.9 | ✅ | layout-id 28 |
| BlueToolFixup | 2.7.3 | ✅ | |
| BrightnessKeys | 1.0.4 | ✅ | |
| ForgedInvariant | 1.5.0 | ❌ | Disabled — caused the PCI hang |
| IntelBluetoothFirmware | 2.5.0 | ✅ | |
| IntelBTPatcher | 2.5.0 | ✅ | |
| NVMeFix | 1.1.4 | ✅ | |
| RestrictEvents | 1.1.7 | ✅ | |
| VirtualSMC | 1.3.9 | ✅ | |
| SMCBatteryManager | 1.3.9 | ✅ | |
| SMCLightSensor / SMCProcessor / SMCSuperIO | 1.3.9 | ❌ | Disabled — caused freezes |
| SimpleHDA | 1.0.1 | ✅ | Audio on Tahoe |
| USBToolBox | 1.2.0 | ✅ | |
| UTBMap | 1.1 | ✅ | USB port map for this laptop |
| VoodooI2C | 2.9.1 (dev build) | ✅ | Newer than the 2.9.1 release — includes the Tiger Lake I2C (`0xA0E8`) match |
| ↳ VoodooI2CServices / VoodooGPIO / VoodooInput | 1 / 1.1 / 1.1.7 | ✅ | Plug-ins inside VoodooI2C |
| VoodooI2CHID | 1 | ✅ | |
| VoodooPS2Controller | 2.3.8 | ✅ | |
| ↳ VoodooPS2Keyboard | 2.3.8 | ✅ | |
| ↳ VoodooPS2Mouse / VoodooPS2Trackpad / VoodooInput | 2.3.8 / 2.3.8 / 1.1.7 | ❌ | Disabled — touchpad is I2C |
| WhateverXe | **0.8.2** | ✅ (❌ in config-install) | Iris Xe graphics acceleration |
| XHCI-unsupported | 0.9.2 | ✅ | |
| AsusSMC | **1.4.1** | ✅ | Fn keys, keyboard backlight |
| WhateverXe-Graphics | **0.4.4** | — | Package installed **inside macOS** (section 12.2), not part of the EFI |

Kext versions were read from each kext's `Info.plist` (`CFBundleVersion`).

---

## Table of contents

1. [What works and what doesn't](#1-what-works-and-what-doesnt)
2. [The hardware](#2-the-hardware)
3. [What you need](#3-what-you-need)
4. [Before you start (backup!)](#4-before-you-start-backup)
5. [Make the USB installer (on Windows)](#5-make-the-usb-installer-on-windows)
6. [BIOS settings](#6-bios-settings)
7. [Unlock "CFG Lock" (very important)](#7-unlock-cfg-lock-very-important)
8. [Why the default EFI did not boot — and the fixes](#8-why-the-default-efi-did-not-boot--and-the-fixes)
9. [Install macOS](#9-install-macos)
10. [Black screen at first setup → create the user from Recovery](#10-black-screen-at-first-setup--create-the-user-from-recovery)
11. [First login and setup screens](#11-first-login-and-setup-screens)
12. [Graphics acceleration (WhateverXe)](#12-graphics-acceleration-whateverxe)
13. [Keyboard Fn keys, keyboard light and audio language](#13-keyboard-fn-keys-keyboard-light-and-audio-language)
14. [Touchpad](#14-touchpad)
15. [Bluetooth and battery](#15-bluetooth-and-battery)
16. [The second 1 TB hard drive](#16-the-second-1-tb-hard-drive)
17. [Boot without the USB stick (OpenCore on the SSD) + clean Apple-logo boot](#17-boot-without-the-usb-stick-opencore-on-the-ssd--clean-apple-logo-boot)
18. [Lid close, sleep and screen lock](#18-lid-close-sleep-and-screen-lock)
19. [Apple Account, App Store and iCloud](#19-apple-account-app-store-and-icloud)
20. [Daily use tips (for Windows users)](#20-daily-use-tips-for-windows-users)
21. [macOS updates — the golden rule](#21-macos-updates--the-golden-rule)
22. [Troubleshooting](#22-troubleshooting)
23. [Repairing macOS without losing data (reinstall over itself)](#repairing-macos-without-losing-data-reinstall-over-itself)
24. [Lessons from the first week (good to know)](#lessons-from-the-first-week-good-to-know)
25. [Appendix A — Final configuration summary](#appendix-a--final-configuration-summary)
26. [Appendix B — Custom ACPI source files](#appendix-b--custom-acpi-source-files)
27. [Appendix C — Lid-lock script](#appendix-c--lid-lock-script)
28. [Appendix D — Useful commands](#appendix-d--useful-commands)
29. [Credits](#credits)

---

## 1. What works and what doesn't

| Feature | Status | Notes |
|---|---|---|
| macOS Tahoe 26.7.3 | ✅ | Installed from Tahoe Recovery |
| All 8 CPU threads | ✅ | Needed CpuTscSync + kernel patches |
| Graphics acceleration (Iris Xe, Metal 2) | ✅ | WhateverXe. Occasional boot hang (just restart) |
| Wi-Fi (Intel AX201) | ✅ | AirportItlwm (Tahoe build) |
| Bluetooth (Intel AX201) | ✅ | Sometimes needs a restart to reconnect |
| Audio (speakers) | ✅ | SimpleHDA + AppleALC, layout-id 28 |
| Touchpad (ELAN I2C) | ✅ | Tap, two-finger scroll, gestures (polling mode) |
| Keyboard | ✅ | VoodooPS2 |
| Screen brightness keys (Fn+F4/F5) | ✅ | AsusSMC + custom ACPI |
| Volume keys (Fn+F1/F2/F3) | ✅ | |
| Keyboard backlight (Fn+F7) | ✅ | Cycles 25% → 50% → 75% → 100% → off |
| Battery percentage | ✅ | SMCBatteryManager |
| Boot without USB, Apple logo, no menu | ✅ | OpenCore on the internal SSD |
| Lid close → Mac locks | ✅ | Small script (see section 18) |
| 1 TB HDD | ✅ | Formatted as APFS |
| Fn-lock (Fn+Esc) | ❌ | Tried, does not work on macOS |
| Sleep / wake | ❌ | Disabled on purpose (not reliable) |
| Screen off → back on | ❌ | Screen stays black after display sleep — display sleep is disabled |
| Fingerprint reader (ELAN, SPI) | ❌ | Impossible on macOS (Touch ID needs Apple hardware) |
| NVIDIA MX330 | ❌ | macOS has no NVIDIA drivers. Not needed. |
| Built-in microphone | ❌ | Not done yet (possible with TGLDmic) |
| HDMI, webcam, SD card, headphone jack | ❓ | Not tested yet |

---

## 2. The hardware

| Part | Details |
|---|---|
| Model | ASUS Vivobook 15 **X513EP** |
| BIOS | **X513EP.318** |
| CPU | Intel Core i7-1165G7 (Tiger Lake, 4 cores / 8 threads) |
| iGPU | Intel Iris Xe (96 EU) — **used by macOS** |
| dGPU | NVIDIA GeForce MX330 — **not usable** in macOS |
| RAM | 12 GB DDR4 |
| SSD | WD PC SN530 256 GB NVMe (macOS goes here) |
| HDD | Seagate 1 TB (ST1000LM035) — extra storage |
| Wi-Fi / BT | Intel AX201 |
| Touchpad | ELAN, I2C (ACPI name `ETPD`, bus `I2C1`, address `0x15`) |
| Keyboard | PS/2 |
| Fingerprint | ELAN WBF (`ACPI\ELAN7001`, SPI) |
| SMBIOS used | **MacBookPro16,2** |

---

## 3. What you need

- A **USB pen drive** (16 GB is enough). It will be erased.
- A **Windows PC** (the laptop itself, before you erase Windows, is fine).
- Internet (Wi-Fi works inside the macOS installer).
- A **USB mouse** (helpful during install — the touchpad only works after the touchpad setup).
- About **3–4 hours** the first time.
- Tools (all free):
  - [OpenCore](https://github.com/acidanthera/OpenCorePkg/releases) (we used **1.0.8**)
  - [OpCore Simplify](https://github.com/lzhoang2801/OpCore-Simplify) (generates a starting EFI for your hardware)
  - [ProperTree](https://github.com/corpnewt/ProperTree) (to edit `config.plist`)
  - [Python](https://www.python.org/downloads/) for Windows
  - [GenSMBIOS](https://github.com/corpnewt/GenSMBIOS) (to make your own serial numbers)
  - `macrecovery.py` (inside OpenCorePkg → `Utilities/macrecovery`)
  - [modGRUBShell / grub-mod-setup_var](https://github.com/datasone/grub-mod-setup_var/releases) (to unlock CFG Lock)

> 💡 **Easiest path:** use the ready-made `EFI` folder from this repository. Then you only need sections 4, 5 (copy the EFI + recovery), 6, 7, 9 and onward. Section 8 explains *why* the EFI looks the way it does.

---

## 4. Before you start (backup!)

1. **Back up all your files** from both the SSD and the HDD. Both will be erased later.
2. If your drives use **BitLocker** (Windows encryption), save your **BitLocker recovery keys** somewhere safe, or turn BitLocker off before backing up. macOS **cannot read** BitLocker drives.
3. Note your Windows product key if you ever want Windows back (it's stored in the BIOS on most ASUS laptops, so usually not needed).

---

## 5. Make the USB installer (on Windows)

### 5.1 Format the USB stick

1. Plug in the USB stick.
2. Open **Command Prompt as Administrator** and type `diskpart`.
3. Run (replace `X` with your USB disk number — check the size carefully!):
   ```
   list disk
   select disk X
   clean
   convert gpt
   create partition primary
   format fs=fat32 quick label=OPENCORE
   assign
   exit
   ```
4. The USB now shows up in Windows as a drive named **OPENCORE**.

> If the drive letter changes later (e.g. it appears as `D:` instead of `F:`), you can fix it in PowerShell:
> `Get-Partition -DriveLetter D | Set-Partition -NewDriveLetter F`

### 5.2 Download the macOS Tahoe Recovery

1. Download **OpenCorePkg** and open the folder `Utilities\macrecovery`.
2. Open Command Prompt in that folder and run:
   ```
   py macrecovery.py -b Mac-CFF7D910A743CAAF -m 00000000000000000 -os latest download
   ```
3. It downloads `BaseSystem.dmg` and `BaseSystem.chunklist` (~1 GB) into a folder called `com.apple.recovery.boot`.
4. Copy the whole **`com.apple.recovery.boot`** folder to the root of the USB stick.

> We used the Tahoe 26.6.2 recovery. The installer then downloaded **26.7.3** from Apple during install.

### 5.3 Put the EFI on the USB

**Option A (recommended):** copy the `EFI` folder from this repository to the root of the USB stick, then do the [SMBIOS step below](#54-make-your-own-serial-numbers-smbios).

**Option B (from scratch):** run OpCore Simplify → let it create a hardware report → choose **macOS Tahoe** → let it build the EFI. Copy the result to the USB. **Then you must apply every fix in section 8**, because the auto-generated EFI does not boot on this laptop as-is.

Your USB should look like this:
```
OPENCORE (USB)
├── EFI
│   ├── BOOT
│   │   └── BOOTx64.efi
│   └── OC
│       ├── ACPI
│       ├── Drivers
│       ├── Kexts
│       ├── Resources
│       ├── Tools
│       ├── config.plist
│       └── OpenCore.efi
└── com.apple.recovery.boot
    ├── BaseSystem.dmg
    └── BaseSystem.chunklist
```

> 🔧 **For installing, use the install config.** In this repository, `EFI/OC/config-install.plist` is the version for installing (graphics acceleration OFF, verbose text ON, boot menu shown). Rename it to `config.plist` on the **USB stick** for the install. After macOS is installed and graphics are set up, use the normal `config.plist` (see sections 12 and 17).

### 5.4 Make your own serial numbers (SMBIOS)

**Never use someone else's serial numbers.** Every Hackintosh needs its own.

1. Run **GenSMBIOS**, choose **"Generate SMBIOS"**, and type `MacBookPro16,2`.
2. It gives you: **Type, Serial, Board Serial (MLB), SmUUID**.
3. Open `EFI/OC/config.plist` in **ProperTree** → `PlatformInfo` → `Generic`, and fill in:
   - `SystemProductName` = `MacBookPro16,2`
   - `SystemSerialNumber` = Serial
   - `MLB` = Board Serial
   - `SystemUUID` = SmUUID
   - `ROM` = your Wi-Fi card's MAC address, without the colons (or any 6 random bytes, e.g. `112233445566`)
4. Check the serial at **[checkcoverage.apple.com](https://checkcoverage.apple.com)**. The answer you **want** is *"The serial number you've entered isn't valid"*. If it shows a real Mac with a purchase date, generate a new one.

---

## 6. BIOS settings

Enter the BIOS by pressing **F2** repeatedly while turning on the laptop. Press **F7** for **Advanced Mode**.

| Setting | Where | Value |
|---|---|---|
| Secure Boot | Security → Secure Boot | **Disabled** |
| VMD controller | Advanced → VMD setup menu | **Disabled** (macOS can't see the SSD if VMD is on) |
| Fn Lock Option | Advanced | Enabled (default, harmless) |
| Internal Pointing Device | Advanced | Enabled |
| VT-d | Advanced | Can stay **Enabled** (the EFI drops the DMAR table) |

Press **F10** to save and exit.

> ⚠️ **Never press F9 (Load Defaults) later** unless you want to redo section 7. Loading defaults **re-locks CFG Lock**.

To boot from the USB: turn on the laptop and press **F8** (boot menu) or **Esc**, then pick the USB stick.

---

## 7. Unlock "CFG Lock" (very important)

### What is it?
"CFG Lock" is a setting that stops macOS from controlling the CPU's power management. If it's locked, macOS hangs early in boot. The ASUS BIOS **hides** this option, so we change it directly.

### How we found it
- Running **ControlMsrE2** (an OpenCore tool) confirmed CFG Lock was **ON**, but it failed to change it with the error *"Could not allocate memory for HiiString"*.
- The BIOS menu data for BIOS **318** says: **CFG Lock** = variable store **`CpuSetup`**, offset **`0x43`**, values `0 = Disabled`, `1 = Enabled`.

### Steps

1. Put **modGRUBShell.efi** (from [grub-mod-setup_var](https://github.com/datasone/grub-mod-setup_var/releases)) into `EFI/OC/Tools/` and add it to `config.plist` → `Misc` → `Tools` (ProperTree: *File → OC Snapshot* adds it automatically). It is already included in this repository's EFI.
2. Boot from the USB. In the OpenCore menu, press **Space** to show tools, and choose **modGRUBShell**.
3. **Read** the current value (it should say `0x01` = locked):
   ```
   setup_var_cv CpuSetup 0x43 0x01
   ```
4. **Write** `0x00` (unlock):
   ```
   setup_var_cv CpuSetup 0x43 0x01 0x00
   ```
5. Type `reboot`.
6. Optional check: run **ControlMsrE2** from the OpenCore menu. It should say **UNLOCKED**.

> **To undo:** `setup_var_cv CpuSetup 0x43 0x01 0x01`, or load BIOS defaults with F9.
> ⚠️ This offset is for **BIOS 318**. If your BIOS version is different, check the offset first (extract the BIOS "IFR" data, or ask in the Hackintosh community). A wrong offset can change the wrong setting.

---

## 8. Why the default EFI did not boot — and the fixes

The EFI made by OpCore Simplify did **not** boot as-is. These are the problems we hit, **in the order we hit them**, and what fixed them. All of these fixes are already in this repository's EFI.

### Problem 1 — Stuck at `EXITBS:START`
**Fix:** CFG unlock (section 7) **plus** these `Booter → Quirks` (the same ones used by an older working X513EP EFI):

| Quirk | Value |
|---|---|
| AvoidRuntimeDefrag | True |
| DevirtualiseMmio | **False** |
| EnableWriteUnprotector | **True** |
| ProtectUefiServices | **False** |
| ProvideCustomSlide | True |
| RebuildAppleMemoryMap | **False** |
| SetupVirtualMap | **True** |
| SyncRuntimePermissions | **True** |

…and `Kernel → Quirks → ProvideCurrentCpuInfo` = **False** (setting it True made things worse).

### Problem 2 — The main ACPI table (DSDT) failed to load
**Why:** The BIOS's DSDT has a block of code for a USB port called `HS10` that doesn't exist at that moment. Windows doesn't care, but the older ACPI code inside macOS **rejects the whole DSDT**, which breaks almost everything.

**Fix:** an ACPI patch that renames that one reference from `HS10` to `HS07` (a port that exists):

| Field | Value |
|---|---|
| Comment | HS10 BPRR scope to HS07 (fix DSDT load) |
| Table | DSDT |
| Find | `485331305B844B0542505252` |
| Replace | `485330375B844B0542505252` |
| Count | 1 |

### Problem 3 — Stuck at `AppleACPICPU`
**Why:** The CPU cores' timers (TSC) were not in sync. Booting with `cpus=1` (only one core) worked, which proved this.

**Fix (keeps all 8 threads):**
- Kext **CpuTscSync** (load right after Lilu).
- Two kernel patches named **"non-monotonic time"** (one for macOS 12.0–26.3, one for 26.4+). Both enabled.
- Boot-arg `TSC_sync_margin=0`.

### Problem 4 — Stuck at `PCI configuration begin` (PC00)
We tried `npci=0x2000` / `npci=0x3000`, dropping the DMAR table, disabling the NVIDIA GPU SSDT, and `ProvideCurrentCpuInfo=True`. **None of them fixed it.**

**The real cause:** the **ForgedInvariant** kext. **Fix: disable ForgedInvariant.**
(`npci=0x3000` and the DMAR drop were kept; they don't hurt.)

### Problem 5 — Random freezes and a `PS2Controller` panic
**Fixes:**
- Disable the VirtualSMC plugins **SMCProcessor, SMCSuperIO, SMCLightSensor** (and SMCBatteryManager at first — it was re-enabled later without problems).
- Disable **VoodooPS2Mouse**, **VoodooPS2Trackpad** and the **VoodooInput inside VoodooPS2**. The touchpad is I2C, not PS/2, so these only cause trouble. Keep **VoodooPS2Controller** and **VoodooPS2Keyboard**.
- Disable **VoodooI2C** for now (it's set up properly in section 14).

### Problem 6 — Tahoe-specific settings
- **AirportItlwm 2.4.0** (the Tahoe build, MinKernel 25.0.0) for Wi-Fi in Recovery and macOS.
- **AMFIPass** kext + boot-arg `-amfipassbeta`.
- Boot-arg `-lilubetaall` (lets Lilu plugins load on new macOS versions).
- `Misc → Security → SecureBootModel` = `Disabled`.

### Boot-args used for the installation
```
-v keepsyms=1 -amfipassbeta -allow3d -disablegfxfirmware -igfxdvmt -vi2c-force-polling -ibtcompatbeta -igfxvesa debug=0x100 npci=0x3000 TSC_sync_margin=0 -lilubetaall
```
`-v` shows text while booting (so you can see where it stops), and `-igfxvesa` keeps graphics in a simple mode (no acceleration) until macOS is installed.

> 💡 **Debugging tip:** if boot gets stuck, use the **DEBUG** build of OpenCore and set `Misc → Debug → Target` = `67`. OpenCore then writes a log file to the USB. Set it back to `0` afterwards, because writing the log makes every boot slower.

---

## 9. Install macOS

1. Boot from the USB (**F8** → USB). In the OpenCore menu, pick the **Recovery (dmg)** entry.
2. Wait. The first boot of Recovery takes a while (lots of text is normal with `-v`).
3. Connect to **Wi-Fi** (top-right menu). A USB mouse helps here.
4. Open **Disk Utility**:
   - Menu **View → Show All Devices**.
   - Select the **WD PC SN530 256 GB** disk (the top-level device, not a volume).
   - Click **Erase**: Name `Macintosh HD`, Format **APFS**, Scheme **GUID Partition Map**.
   - ⚠️ Do **not** erase the 1 TB HDD here unless you want to (it's covered in section 16).
5. Close Disk Utility and choose **Reinstall macOS Tahoe**. Select **Macintosh HD** as the target.
6. The laptop will **restart several times**. Each time, in the OpenCore menu, choose the entry called **macOS Installer** (and later **Macintosh HD**). The text, the Apple logo with a progress bar, and restarts are all normal. It takes 30–60 minutes.

> ⚠️ The OpenCore menu picks the **first entry** automatically after a few seconds (often the Recovery dmg). Press an arrow key to stop the timer and pick the right entry yourself.

---

## 10. Black screen at first setup → create the user from Recovery

### Problem
After the install, the first-time **Setup Assistant** (the screens where you choose country, create a user, etc.) showed only a **black screen with a mouse pointer**. Without graphics acceleration, it can't draw its screens.

### Fix: create your user account by hand and skip Setup Assistant
1. Boot the USB → choose **Recovery**.
2. Menu **Utilities → Terminal**.
3. Type these lines one by one (replace `yourname`, `Your Name` and `yourpassword`):
   ```
   diskutil mount "Macintosh HD - Data"
   D="/Volumes/Macintosh HD - Data"
   N="$D/private/var/db/dslocal/nodes/Default"
   U=yourname
   dscl -f "$N" localhost -create /Local/Default/Users/$U
   dscl -f "$N" localhost -create /Local/Default/Users/$U UserShell /bin/zsh
   dscl -f "$N" localhost -create /Local/Default/Users/$U RealName "Your Name"
   dscl -f "$N" localhost -create /Local/Default/Users/$U UniqueID 501
   dscl -f "$N" localhost -create /Local/Default/Users/$U PrimaryGroupID 20
   dscl -f "$N" localhost -create /Local/Default/Users/$U NFSHomeDirectory /Users/$U
   dscl -f "$N" localhost -passwd /Local/Default/Users/$U "yourpassword"
   dscl -f "$N" localhost -append /Local/Default/Groups/admin GroupMembership $U
   touch "$D/private/var/db/.AppleSetupDone"
   ```
4. Type `reboot`, boot **Macintosh HD**. You'll get the **login screen**. 🎉

> Side effect: because the normal setup (language/region) was skipped, the audio driver later showed its names in Chinese. Section 13 fixes this.

---

## 11. First login and setup screens

After logging in, a few setup screens appear. They're slow without graphics acceleration — click once and wait.

| Screen | Choose |
|---|---|
| Update Mac Automatically | **Only Download Automatically** (never auto-install) |
| Accessibility | Not Now |
| Apple Account | **Other Sign-In Options → Sign in Later** (do this after the serial check in section 19) |
| Analytics | Leave unticked → Continue |
| Siri | Untick "Enable Ask Siri" (the mic doesn't work yet) |
| FileVault | **Not Now → Continue** (FileVault needs extra OpenCore settings; leave it off) |
| Choose Your Look | Your choice |
| "The disk you attached was not readable" | **Ignore** (it's the BitLocker HDD — never "Initialize" unless you want it erased) |
| Keyboard Setup Assistant ("cannot identify keyboard") | **Quit** (it's a USB mouse receiver) |

> If it gets stuck on a setup screen with a spinning wheel for a long time (ours froze on "Choose Your Look"), **hold the power button** to force a restart. It continues to the desktop afterwards.

Then, in **System Settings**:
- **General → Date & Time:** set your time zone.
- **General → Software Update → ⓘ next to Automatic Updates:** turn **everything off**.
- **Accessibility → Display:** turn on **Reduce transparency**, and **Accessibility → Motion:** **Reduce motion** (only until graphics acceleration works; you can turn them off later).

---

## 12. Graphics acceleration (WhateverXe)

Without this, macOS is slow and laggy (the CPU draws everything). [WhateverXe](https://github.com/b00t0x/WhateverXe) makes Apple's graphics driver work on Tiger Lake Iris Xe.

It needs **three parts**: the **WhateverXe kext**, a special **AMFIPass "Mod"**, and the **WhateverXe-Graphics package** installed inside macOS.

### 12.1 Check the requirements
In Terminal (`EFI` is the USB here; later it's the SSD's EFI):
```
cd /Volumes/OPENCORE/EFI/OC
shasum -a 256 Kexts/AMFIPass.kext/Contents/MacOS/AMFIPass   # must start with 2d36aeca (the Mod build)
defaults read $PWD/Kexts/WhateverXe.kext/Contents/Info.plist CFBundleVersion   # we used 0.8.2
nvram csr-active-config   # we had %03%0a%00%00 (0xA03) — includes the required 0x803
```
- **AMFIPass:** the normal AMFIPass and the Mod are both version 1.4.1, so check the **hash**. The Mod is in the WhateverXe-Graphics repo (`extras/AMFIPass-v1.4.1-Mod-RELEASE.zip`).
- **SIP (`csr-active-config`):** WhateverXe needs `03080000` (0x803). Our `03 0A 00 00` (0xA03) includes it, so we kept it.
- **Graphics memory (already in config):** `DeviceProperties` → `PciRoot(0x0)/Pci(0x2,0x0)`:
  - `framebuffer-patch-enable` = `01000000`
  - `framebuffer-stolenmem` = `0000C003`
  - plus boot-args `-allow3d -disablegfxfirmware -igfxdvmt`

### 12.2 Install the graphics package (inside macOS)
Download **WhateverXe-Graphics** from its GitHub releases (we started with 0.4.3 and updated to **0.4.4**), then:
```
cd ~/Downloads
curl -fLO https://github.com/b00t0x/WhateverXe-Graphics/releases/download/v0.4.4/WhateverXe-Graphics-0.4.4.pkg
sudo installer -pkg ~/Downloads/WhateverXe-Graphics-0.4.4.pkg -target /
```
Wait for **"The install was successful."**

### 12.3 Turn on WhateverXe in config.plist
- `Kernel → Add` → **WhateverXe.kext** → Enabled = **True** (it must load after Lilu).
- Remove **`-igfxvesa`** from boot-args.
- Restart.

(Or just switch from `config-install.plist` to this repo's normal `config.plist`.)

### 12.4 Check it works
- ** → About This Mac** should say **Intel Iris Xe Graphics 1536 MB**.
- The **wallpaper** appears (before, the background was plain white).
- Terminal: `system_profiler SPDisplaysDataType | grep -E "Chipset|Metal"` → **Metal Support: Metal 2**.

### 12.5 Known WhateverXe problems on this laptop
- **GPU freeze:** once, Safari froze the whole system. The logs showed `gpuRestart` files in `/Library/Logs/DiagnosticReports` (the GPU was reset again and again inside **WindowServer**). Updating to Graphics **0.4.4** helped. If it happens again, turn **Reduce transparency** back on.
- **Boot sometimes hangs at the Apple logo** (progress bar at about ⅓). Just **hold the power button and start again** — the next boot works.
- **Screen doesn't turn back on after display sleep.** That's why display sleep is disabled (section 18).

---

## 13. Keyboard Fn keys, keyboard light and audio language

### 13.1 Why the Fn keys didn't work
ASUS sends brightness and keyboard-light keys through its own system (**ATK**), which macOS doesn't understand. Volume keys already worked.

### 13.2 The fix
1. Kext **[AsusSMC](https://github.com/hieplpvip/AsusSMC) 1.4.1** (add to `Kernel → Add` after Lilu and VirtualSMC). Keep **SMCLightSensor disabled** (AsusSMC provides the light sensor).
2. Custom ACPI file **`SSDT-ASUSKEYS.aml`** (source in [Appendix B](#appendix-b--custom-acpi-source-files)). It sends brightness and keyboard-light keys to AsusSMC, and makes the single keyboard-light key **cycle** like on Windows.
3. Five ACPI renames in the DSDT (so our file can replace the original key handlers):

| Comment | Find (text) | Replace (text) | Find (hex) | Replace (hex) |
|---|---|---|---|---|
| Keyboard light down | `_Q0C` | `XQ0C` | `5F513043` | `58513043` |
| Keyboard light up | `_Q0D` | `XQ0D` | `5F513044` | `58513044` |
| Brightness down | `_Q0E` | `XQ0E` | `5F513045` | `58513045` |
| Brightness up | `_Q0F` | `XQ0F` | `5F513046` | `58513046` |
| Fn-lock (Fn+Esc) | `_QD5` | `XQD5` | `5F514435` | `58514435` |

All: Table `DSDT`, Count `1`. (Each name appears exactly once in this DSDT.)

### 13.3 How to use the keys
- The keyboard starts in **F1–F12 mode**, so **hold Fn** for brightness, volume and the light.
- **Fn + F7** cycles the keyboard light: 25% → 50% → 75% → 100% → off.
- The slider is in **System Settings → Keyboard → Keyboard brightness**.
- ⚠️ Turn **OFF "Adjust keyboard brightness in low light"** in the same place. The laptop has no real light sensor, and this option fights your setting.
- **Fn + Esc (Fn-lock) does not work** on macOS. We tried two ACPI approaches; the keyboard controller doesn't accept it from macOS.

### 13.4 Audio names in Chinese ("耳机")
The audio driver **SimpleHDA** (Tahoe removed Apple's own audio driver) picks its language from a setting that was never filled in (we skipped Setup Assistant), so it defaulted to Chinese. **Fix:** add boot-arg **`shda-lang=en`**.

### 13.5 Print Screen key
macOS sees PrtSc as **F13**. Assign it: **System Settings → Keyboard → Keyboard Shortcuts → Screenshots** → double-click a shortcut → press **PrtSc**.
(Built-in: ⌘⇧3 full screen, ⌘⇧4 area, ⌘⇧5 toolbar — the **Windows key is ⌘**.)

---

## 14. Touchpad

### Why it didn't work
1. The **ELAN touchpad** is connected over **I2C** to Tiger Lake's I2C controller (`I2C1`, PCI ID `0xA0E9`). The official VoodooI2C **2.9.1 release** doesn't support this controller, but **newer development builds** do (they have the `0xa0e88086&0xFFFCFFFF` match). The VoodooI2C in this repo's EFI is such a build.
2. Its interrupt pin (**0x39**) is too high for VoodooI2C's interrupt mode, so we use **polling** mode: boot-arg **`-vi2c-force-polling`**.
3. The touchpad's ACPI device **`ETPD`** reported "not present" on macOS (its `_STA` depends on BIOS flags). Without the device, VoodooI2C has nothing to attach to.

### The fix
1. Enable these kexts (in this order): **VoodooI2CServices, VoodooGPIO, VoodooI2C, VoodooInput (inside VoodooI2C), VoodooI2CHID**.
2. Keep **VoodooPS2Mouse, VoodooPS2Trackpad and the VoodooInput inside VoodooPS2 disabled** (two VoodooInputs would conflict).
3. Add **`SSDT-TPD-ETPD.aml`** (source in [Appendix B](#appendix-b--custom-acpi-source-files)). It tells macOS "the touchpad is always present".
4. Add this ACPI patch (renames `ETPD._STA` to `XSTA`; the pattern matches exactly one place):

| Field | Value |
|---|---|
| Comment | ETPD _STA to XSTA (touchpad) |
| Table | DSDT |
| Find | `141B5F53544100A011919293545049460190` |
| Replace | `141B5853544100A011919293545049460190` |
| Count | 1 |

5. Restart. Then **System Settings → Trackpad**:
   - **Tap to click** → ON.
   - **Secondary click** → "Click or Tap with Two Fingers".

---

## 15. Bluetooth and battery

### Bluetooth (Intel AX201)
- Enable **BlueToolFixup** (first), **IntelBluetoothFirmware**, **IntelBTPatcher**. Keep boot-arg **`-ibtcompatbeta`**.
- **Known issue:** sometimes, after a restart, Bluetooth turns itself **off and on** when you connect a device, and it won't connect. **Fix: restart again** (or Shut Down, wait 15 seconds, power on).
- Tip: if audio devices drop out, connect Wi-Fi to **5 GHz** (Wi-Fi and Bluetooth share one chip).

### Battery
- Enable **SMCBatteryManager** (only this SMC plugin; keep SMCProcessor, SMCSuperIO, SMCLightSensor off).
- Then: **System Settings → Menu Bar → Battery → Show percentage**.

---

## 16. The second 1 TB hard drive

The HDD was **BitLocker-encrypted NTFS**, which macOS can't read, so it showed *"The disk you attached was not readable"* at every boot.

⚠️ **This erases the HDD.** Only do it if your data is backed up.

1. Find the disk number (they can **change after restarts**, so always check):
   ```
   diskutil list internal physical
   ```
   Look for **1.0 TB** with "Microsoft Basic Data".
2. Erase it (replace `diskN` with the 1 TB disk, e.g. `disk0`):
   ```
   diskutil eraseDisk APFS Storage GPT diskN
   ```
3. It appears in Finder as **Storage** (rename it if you like). Good for Xcode projects, simulators or Time Machine backups.

> If Finder's sidebar shows the drive **twice** after renaming, it's only a leftover shortcut: run `killall Finder`.

---

## 17. Boot without the USB stick (OpenCore on the SSD) + clean Apple-logo boot

Do this once everything works. **Keep the USB stick as an emergency boot disk.**

### 17.1 Copy OpenCore to the SSD's EFI partition
This finds the EFI partition **of the disk macOS is running from** (so it can't pick the HDD by mistake), and copies the USB's EFI there:
```
P=$(diskutil info / | awk -F': *' '/APFS Physical Store/{print $2}'); E=${P%s2}s1
echo "EFI to use: $E"; diskutil info $E | grep -E "Device Identifier|Disk Size"
sudo diskutil mount $E
M=$(diskutil info $E | awk -F': *' '/Mount Point/{print $2}')
[ -d "$M/EFI" ] && sudo mv "$M/EFI" "$M/EFI-old-$(date +%s)"
sudo cp -R /Volumes/OPENCORE/EFI "$M/"
```
Check that the EFI partition is on the **256 GB SSD** before copying.

### 17.2 Settings for a normal Mac-like boot (on the SSD copy)
| Setting | Value | Why |
|---|---|---|
| `Misc → Boot → LauncherOption` | `Full` | OpenCore registers itself as a boot entry in the BIOS |
| `Misc → Boot → LauncherPath` | `Default` | |
| `Misc → Boot → HideAuxiliary` | `True` | Hides Recovery/tools (press **Space** in the menu to show them) |
| `Misc → Boot → ShowPicker` | `False` | No OpenCore menu, boots straight to macOS |
| `Misc → Boot → Timeout` | `5` | |
| `Misc → Security → AllowSetDefault` | `True` | |
| `Misc → Debug → Target` | `0` | No log file (faster boot) |
| boot-args | remove `-v`, `debug=0x100`, `keepsyms=1` | Apple logo instead of text |

### 17.3 BIOS
1. **Shut down**, remove the USB stick, turn on and press **F2**.
2. In **Boot Priority**, the SSD should appear as **"UEFI OS (WDC PC SN530 …)"** — put it first. (If not, use **Advanced → Boot → Add New Boot Option** and select `EFI\OC\OpenCore.efi` on the SSD.)
3. **F10** to save.

Now it boots: **Apple logo → login**, like a real Mac. 🎉

> **To show the OpenCore menu once** (e.g. for Recovery): hold **Alt (⌥)** or **Esc** right after pressing the power button. If that ever fails, boot the USB stick with **F8**.

---

## 18. Lid close, sleep and screen lock

### What we found
- macOS **detects the lid** fine (`AppleClamshellState` changes to Yes).
- But it has **`AppleClamshellCausesSleep = No`**: macOS refuses to sleep on lid close. The BIOS is designed for Windows "Modern Standby", and the graphics driver doesn't give macOS the signal it normally uses. WhateverXe also lists sleep/wake as unverified.
- Turning the **screen off** (`pmset displaysleepnow`) works, but the screen **never comes back on**.
- Leaving the lid closed for a long time can **hang the graphics driver** when the lid is opened. The crash report showed **AppleIntelTGLGraphics** stuck (with IOAcceleratorFamily2 and IOSurface waiting), and macOS **killed WindowServer** after 80 seconds, which logs you out.
- The **lock screen's own display-off** (after about 1 minute of idle) is fine. A key press wakes it.

### Safe setup we use
1. **Disable sleep and display sleep** (otherwise the screen goes black after 10 idle minutes and doesn't wake):
   ```
   sudo pmset -a displaysleep 0 sleep 0
   ```
2. **Lock immediately:** System Settings → Lock Screen → *"Require password after screen saver begins or display is turned off"* → **Immediately**.
3. **Install the lid-lock script** ([Appendix C](#appendix-c--lid-lock-script)): when you close the lid, the Mac **locks** and the display is **kept awake** behind the lid, so it never has to wake up. After you open the lid, the lock screen stays visible for 60 seconds, then the normal lock-screen timer applies (press a key to wake).
4. Manual lock any time: **Win + Ctrl + Q**.

> ⚠️ With the lid closed, the laptop **stays awake**. **Shut it down** before putting it in a bag.
> macOS may show *"App Background Activity: zsh can run in the background"* — that's the lid-lock script. Leave it enabled.

---

## 19. Apple Account, App Store and iCloud

### 19.1 Check your Mac's identity first
Bad serial numbers can get an Apple Account flagged. Run this (it prints only OK/NOT OK):
```
P=$(diskutil info / | awk -F': *' '/APFS Physical Store/{print $2}'); E=${P%s2}s1; sudo diskutil mount $E >/dev/null; M=$(diskutil info $E | awk -F': *' '/Mount Point/{print $2}'); C="$M/EFI/OC/config.plist"
S=$(plutil -extract PlatformInfo.Generic.SystemSerialNumber raw "$C"); MLB=$(plutil -extract PlatformInfo.Generic.MLB raw "$C"); U=$(plutil -extract PlatformInfo.Generic.SystemUUID raw "$C"); R=$(plutil -extract PlatformInfo.Generic.ROM raw "$C" | base64 -D | xxd -p)
echo "Serial length: ${#S} (want 12)"; echo "MLB length: ${#MLB} (want 17)"; echo "UUID valid: $([[ $U =~ ^[0-9A-Fa-f-]{36}$ ]] && echo yes || echo NO)"; echo "ROM: ${#R} hex chars (want 12), all zeros: $([[ $R =~ ^0+$ ]] && echo YES-bad || echo no)"
ioreg -rc IOEthernetInterface -lw0 | grep -E '"BSD Name"|"IOBuiltin"'   # want en0 with IOBuiltin = Yes
```
Then check the serial at **checkcoverage.apple.com** → you want *"isn't valid"*.

### 19.2 Create and sign in
1. Create the Apple Account in a **phone browser** at **account.apple.com** (an iPhone is not needed). Verify email and SMS.
2. Sign in on the website once and accept any terms.
3. On the Mac: **App Store → Store → Sign In**. Use your **email address**. The SMS code comes to your phone.
4. Add iCloud later (System Settings → Sign in), once the App Store works.

> If you get **"An unknown error occurred"** on a brand-new account: don't retry many times (it can lock the account). Sign in on the website first, wait 15–30 minutes, and use the email address instead of the phone number.

---

## 20. Daily use tips (for Windows users)

| Action | Windows | On this Mac |
|---|---|---|
| Copy / Paste / Cut | Ctrl + C / V / X | **Win** + C / V / X (Win key = ⌘) |
| Undo | Ctrl + Z | Win + Z |
| Quit app | Alt + F4 | Win + Q |
| Switch apps | Alt + Tab | Win + Tab |
| Search | Start menu | Win + Space (Spotlight) |
| Lock screen | Win + L | Win + Ctrl + Q |
| Delete file | Delete | **Win + Backspace** |
| Delete character to the right | Delete | Delete |

- **Alt = ⌥ Option.** You can swap Ctrl and ⌘ in **System Settings → Keyboard → Keyboard Shortcuts → Modifier Keys**.
- **Turn off auto-period and smart quotes** (they break code): System Settings → Keyboard → Input Sources → **Edit…** → turn off *Add period with double-space* and *Use smart quotes and dashes*.
- **Terminal text size:** Terminal → Settings → Profiles → Text → Font → Change… → then click **Default**. (⌘+/⌘− only zooms the current window.)
- **System Settings window can't be made wider** — that's normal since macOS Ventura.
- **Uninstall apps:** drag to Trash, or use **System Settings → General → Storage → Applications**, or the free app **Pearcleaner** / **AppCleaner** to also remove leftovers.
- **Ad-free browsing:** install **Brave** (brave.com), or **uBlock Origin Lite** for Safari from the App Store (pick the one by Raymond Hill). If a browser freezes on video, turn off its "graphics acceleration" setting.
- **Install apps on the SSD** (Applications), not on the HDD.

---

## 21. macOS updates — the golden rule

| Update | Safe? |
|---|---|
| Safari updates, App Store apps, Xcode | ✅ Safe |
| **Any macOS update** (26.7.x → 26.8, etc.), "Background Security Improvements" | ⚠️ **Check first** |

Before any macOS update, check that **WhateverXe** (graphics) and **AirportItlwm** (Wi-Fi) support the new version, and keep the USB stick ready. Automatic updates are turned off for this reason.

---

## 22. Troubleshooting

| Problem | Fix |
|---|---|
| Stuck at the Apple logo (progress ~⅓) | Hold power, start again (intermittent graphics hang) |
| Won't boot at all after a config change | Hold **Alt/Esc** at power-on, or boot the USB (**F8**), then restore a backup config (below) |
| Black screen after the screen turned off | Hold power to restart. Make sure `displaysleep 0` and `sleep 0` are set, and use the lid-lock script from [Appendix C](#appendix-c--lid-lock-script) |
| **Logged out after opening the lid** (WindowServer crash) | The graphics driver's display-wake bug. Install the [Appendix C](#appendix-c--lid-lock-script) script (it keeps the display awake while the lid is closed) |
| **About This Mac / System Information crash**, and the log shows `apfs … Data hash mismatch` | A system file got damaged (usually by forced power-offs). Reinstall macOS over itself from Recovery; it keeps apps and files |
| **Bluetooth turns off and on** when connecting | `sudo pkill bluetoothd`, or restart |
| "Disk not readable" popup | It's an NTFS/BitLocker disk: **Ignore**, or erase it (section 16) |
| Keyboard light fights you | Turn off "Adjust keyboard brightness in low light" |
| Settings or apps lag | Graphics acceleration isn't active → section 12 |
| System froze while browsing | Check `ls -t /Library/Logs/DiagnosticReports \| head` for `gpuRestart`; update WhateverXe-Graphics; enable Reduce transparency |

### Restore a backup config from Recovery
Boot the USB → Recovery → Utilities → Terminal:
```
ls /Volumes                       # find OPENCORE (USB) or mount the SSD EFI:
diskutil list                     # find the SSD's EFI partition (e.g. disk0s1)
diskutil mount disk0s1
cp /Volumes/EFI/EFI/OC/config-backup.plist /Volumes/EFI/EFI/OC/config.plist
reboot
```
💡 **Always make a backup before editing:** `cp config.plist config-before-<change>.plist`

---

## Repairing macOS without losing data (reinstall over itself)

**When:** Apple apps crash right away (About This Mac, System Information, the photo picker), usually after a freeze or forced power-off.

**1. Check for a damaged system file** (open the crashing app once first):
```
log show --last 1h --style compact --predicate 'sender == "apfs"' | grep -i "hash mismatch" | tail -3
diskutil info disk0 | grep SMART; diskutil verifyVolume /
```
- Lines with **"hash mismatch"** → a sealed system file is damaged. Continue below.
- **SMART: Failing** → back up immediately, the SSD is dying.

**2. Show the OpenCore menu** (and back up the config):
```
P=$(diskutil info / | awk -F': *' '/APFS Physical Store/{print $2}'); E=${P%s2}s1
sudo diskutil mount $E
M=$(diskutil info $E | awk -F': *' '/Mount Point/{print $2}'); C="$M/EFI/OC/config.plist"
sudo cp "$C" "$M/EFI/OC/config-before-reinstall.plist"
sudo plutil -replace Misc.Boot.ShowPicker -bool YES "$C"
sudo plutil -replace Misc.Boot.HideAuxiliary -bool NO "$C"
plutil -lint "$C"
```

**3. Reinstall** (charger plugged in, lid open):
- Restart → **Recovery 26.x (dmg)** (on Tahoe the SSD's own Recovery is also labelled "dmg") → **Reinstall macOS Tahoe** → **Macintosh HD** (not the HDD) → Install.
- Each restart: choose **macOS Installer** while it is listed, then **Macintosh HD** ("Macintosh HD - Data" may appear mid-install — that's normal).
- Takes about 1–1.5 hours. If the final boot freezes on the Apple logo for 20+ minutes, hold power and pick **Macintosh HD** again.

**4. After logging in:**
- About This Mac should open and show **Intel Iris Xe Graphics 1536 MB** (if not: `sudo installer -pkg ~/Downloads/WhateverXe-Graphics-0.4.4.pkg -target /` and restart).
- ⚠️ The reinstall **resets display sleep to 30 minutes** — set it back:
  ```
  sudo pmset -a displaysleep 0 sleep 0
  pmset -g custom | grep -E "Power|^ sleep|displaysleep"
  ```
  All values must be **0** (Battery and AC).
- Apps, files, settings, Apple Account and the lid-lock script are kept.

**5. Hide the OpenCore menu again:**
```
P=$(diskutil info / | awk -F': *' '/APFS Physical Store/{print $2}'); E=${P%s2}s1
sudo diskutil mount $E
M=$(diskutil info $E | awk -F': *' '/Mount Point/{print $2}'); C="$M/EFI/OC/config.plist"
sudo plutil -replace Misc.Boot.ShowPicker -bool NO "$C"
sudo plutil -replace Misc.Boot.HideAuxiliary -bool YES "$C"
plutil -lint "$C"
```

**Prevention:** wait 2–3 minutes before forcing a power-off, never force off during updates, and back up regularly. If corruption keeps returning without forced shutdowns, test the RAM with MemTest86.

⚠️ **Lesson learned: a same-version reinstall may NOT repair the damage.** When you reinstall the *same* macOS version, the installer can **reuse (clone) the existing system data** instead of writing fresh copies. Check this after reinstalling — if the log shows the **same offset and the same "got" hash** as before, nothing was replaced:
```
log show --last 2d --style compact --predicate 'sender == "apfs"' | grep "hash mismatch" | awk '{d=$1" "substr($2,1,8); match($0,/hash_mismatch:[0-9]+: [^ ]+/); v=substr($0,RSTART,RLENGTH); sub(/.*: /,"",v); match($0,/offset [0-9]+/); o=substr($0,RSTART+7,RLENGTH-7); k=v" offset="o; if(!(k in f)) f[k]=d; l[k]=d; n[k]++} END{for(k in n) print n[k], k, "| first:", f[k], "| last:", l[k]}'
```
(`os.dmgs1` = the system-library cryptex on Preboot; `disk1s4` = the sealed Macintosh HD system volume.) If the damage survives a reinstall, the reliable fix is a **clean install**: Time Machine backup → erase only the "Macintosh HD" volume group (never the whole SSD — the EFI partition must stay) → install → restore with Migration Assistant.

Symptoms of these damaged blocks can be **delayed**: right after a restart things work, then hours later About This Mac, System Information or **bluetoothd** crash when macOS re-reads the damaged block. Quick check since the last boot:
```
log show --last boot --style compact --predicate 'sender == "apfs"' | grep -c "hash mismatch"
```

---

## Lessons from the first week (good to know)

- **Do NOT enable `SSDT-Disable_GPU_RP05` (NVIDIA off).** It saves only ~2 W but caused **repeated Intel GPU resets** (laggy clicks, `gpuRestart` reports every few minutes, all GPU rings idle). Leave it disabled.
- **Laggy clicks but smooth mouse pointer** = GPU resets. Check:
  ```
  ls -lT /Library/Logs/DiagnosticReports | grep -i gpuRestart | awk '{print $6, $7, substr($8,1,5)}' | tail -5
  ```
- **Bluetooth:** drivers, firmware, USB map (HS07 = internal 255) and the NVRAM entries `bluetoothExternalDongleFailed` / `bluetoothInternalControllerInfo` are already correct in this EFI. If it toggles off/on: `sudo pkill bluetoothd`. Keep **Sound → Input** on "Internal Microphone" and pick the headset mic only inside apps (Handsfree mode is less stable).
- **Built-in microphone:** [TGLDmic](https://github.com/labrouss/TGLDmic) v0.5.0 loads and its firmware runs (`BootResult = "OK FW_READY"`), but on the X513EP it records **silence** (flat −76.9 dBFS on all channels) — the DMIC setup it replays doesn't match this laptop. Getting it to work needs a Linux capture (`capture-sof-dmic.sh` from an Ubuntu live USB) sent to the developer. Use a Bluetooth/USB/wired headset mic meanwhile.
- **Battery:** check health with `ioreg -rn AppleSmartBattery | grep -E '"DesignCapacity"|"MaxCapacity"|"CycleCount"'`. Exact drain in watts (unplugged):
  ```
  A=$(ioreg -rn AppleSmartBattery | grep -oE '"Amperage"=[0-9]+' | head -1 | cut -d= -f2); V=$(ioreg -rn AppleSmartBattery | grep -oE '"Voltage"=[0-9]+' | head -1 | cut -d= -f2); D=$(echo "18446744073709551616 - $A" | bc); echo "Drain: $D mA at $V mV = $(echo "scale=1; $D*$V/1000000" | bc) W"
  ```
  Idle package power is ~7–8 W because the CPU package never reaches deep C-states (likely touchpad polling / ASPM / Wi-Fi driver).
- **Lid closed = still fully running** (sleep is disabled). Fans may keep spinning. **Never put it in a bag while on — shut down.**
- **After any macOS reinstall:** run `sudo pmset -a displaysleep 0 sleep 0` again (reinstall resets display sleep to 30 min).
- **Cleaner apps** (PureMac etc.): never delete WhateverXe-Graphics files, `~/.lidlock.sh`, `~/Library/LaunchAgents/com.user.lidlock.plist`, `/Library/User Pictures/Custom/`, TGLDmic files, or anything EFI/OpenCore/kext related.
- **Login-screen picture from Terminal** (when the picker doesn't work): convert with `sips`, then `sudo dscl . -delete /Users/$USER JPEGPhoto; sudo dscl . -create /Users/$USER Picture "<path>"; sudo diskutil apfs updatePreboot /`. Fix rotation with `sudo sips -r 90|180|270 "<path>"`.

---

## Appendix A — Final configuration summary

### Boot-args (final, on the SSD)
```
-amfipassbeta -allow3d -disablegfxfirmware -igfxdvmt -vi2c-force-polling -ibtcompatbeta npci=0x3000 TSC_sync_margin=0 -lilubetaall shda-lang=en
```

### Kexts (in load order)
| Kext | Enabled | Purpose |
|---|---|---|
| Lilu | ✅ | Base for most kexts |
| CpuTscSync | ✅ | Syncs CPU timers (fixes AppleACPICPU hang) |
| AMFIPass (**1.4.1 Mod**) | ✅ | Needed by WhateverXe on Tahoe |
| AirportItlwm (Tahoe 2.4.0) | ✅ | Wi-Fi |
| AppleALC | ✅ | Audio layout (layout-id 28) |
| BlueToolFixup | ✅ | Bluetooth |
| BrightnessKeys | ✅ | (harmless; AsusSMC handles the keys) |
| ForgedInvariant | ❌ | **Caused the PCI hang** |
| IntelBTPatcher | ✅ | Bluetooth |
| IntelBluetoothFirmware | ✅ | Bluetooth |
| NVMeFix | ✅ | NVMe power management |
| RestrictEvents | ✅ | |
| VirtualSMC | ✅ | SMC emulation |
| SMCBatteryManager | ✅ | Battery |
| SMCLightSensor / SMCProcessor / SMCSuperIO | ❌ | Caused freezes; AsusSMC replaces the light sensor |
| SimpleHDA | ✅ | Audio on Tahoe |
| USBToolBox + UTBMap | ✅ | USB port map |
| VoodooI2CServices, VoodooGPIO, VoodooI2C, VoodooInput (I2C), VoodooI2CHID | ✅ | Touchpad |
| VoodooPS2Controller + VoodooPS2Keyboard | ✅ | Keyboard |
| VoodooInput (PS2) / VoodooPS2Mouse / VoodooPS2Trackpad | ❌ | Not needed; caused a panic |
| WhateverXe | ✅ | Graphics acceleration |
| XHCI-unsupported | ✅ | USB controller |
| AsusSMC | ✅ | Fn keys, keyboard backlight |

### ACPI → Add
SSDT-ALS0, SSDT-SBUS, SSDT-EC, SSDT-GPI0, SSDT-MCHC, SSDT-PLUG, SSDT-PNLF, SSDT-RTCAWAC, SSDT-USB-Reset, SSDT-USBX, SSDT-XOSI, **SSDT-ASUSKEYS**, **SSDT-TPD-ETPD** (enabled); SSDT-Disable_GPU_RP05 (disabled).

### ACPI → Delete
- `DMAR` table (All = True).

### ACPI → Patch
| Comment | Find | Replace |
|---|---|---|
| GPI0 _STA → XSTA | (from OpCore Simplify) | |
| PNLF → XNLF | (from OpCore Simplify) | |
| _OSI → XOSI | (from OpCore Simplify) | |
| HS10 BPRR scope → HS07 | `485331305B844B0542505252` | `485330375B844B0542505252` |
| _Q0C / _Q0D / _Q0E / _Q0F → XQ0x | `_Q0C` … | `XQ0C` … |
| _QD5 → XQD5 | `_QD5` | `XQD5` |
| ETPD _STA → XSTA | `141B5F53544100A011919293545049460190` | `141B5853544100A011919293545049460190` |

### Kernel → Patch
- "non-monotonic time" patch for macOS 12.0–26.3 — enabled
- "non-monotonic time" patch for macOS 26.4+ — enabled

### Kernel → Quirks (important ones)
AppleXcpmCfgLock **False** (CFG is unlocked), AppleXcpmExtraMsrs True, DisableIoMapper True, DisableRtcChecksum True, LapicKernelPanic True, CustomSMBIOSGuid True, **ProvideCurrentCpuInfo False**.

### Booter → Quirks
See [Problem 1](#problem-1--stuck-at-exitbsstart).

### DeviceProperties
- `PciRoot(0x0)/Pci(0x2,0x0)`: `framebuffer-patch-enable` = `01000000`, `framebuffer-stolenmem` = `0000C003`
- `PciRoot(0x0)/Pci(0x1f,0x3)`: `layout-id` = `28`

### Other
- SMBIOS: **MacBookPro16,2** (generate your own serials!)
- `csr-active-config`: `030A0000` (0xA03)
- `Misc → Security → SecureBootModel`: Disabled
- OpenCore **1.0.8** (we kept the DEBUG build with `Target = 0`; the RELEASE build also works)

---

## Appendix B — Custom ACPI source files

Compile with **MaciASL** (on macOS) or `iasl` to get the `.aml` files. The sources are also in [`ACPI-sources/`](ACPI-sources/); the compiled `.aml` files are already in `EFI/OC/ACPI/`. Put the `.aml` files in `EFI/OC/ACPI/` and add them to `ACPI → Add`.

### SSDT-ASUSKEYS.dsl (Fn keys, keyboard light)
Needs the 5 DSDT renames from section 13.2 and the **AsusSMC** kext.
```asl
/*
 * ASUS Vivobook 15 X513EP - Fn keys for AsusSMC (v4)
 * Requires DSDT renames: _Q0C->XQ0C, _Q0D->XQ0D, _Q0E->XQ0E, _Q0F->XQ0F, _QD5->XQD5
 * Fn+Esc toggles ASUS Fn-lock (normally done by the Windows ASUS driver)
 * Fn+F7 (single keyboard-light key) cycles: off -> 25% -> 50% -> 75% -> 100% -> off
 */
DefinitionBlock ("", "SSDT", 2, "HACK", "ASUSKEYS", 0x00000004)
{
    External (_SB_.ATKD, DeviceObj)
    External (_SB_.ATKD.IANE, MethodObj)    // 1 Arguments
    External (_SB_.PC00.LPCB.EC0_, DeviceObj)
    External (_SB_.PC00.LPCB.EC0_.ST9E, MethodObj)    // 3 Arguments
    External (_SB_.PC00.LPCB.EC0_.XQ0C, MethodObj)    // 0 Arguments
    External (_SB_.PC00.LPCB.EC0_.XQ0D, MethodObj)    // 0 Arguments
    External (_SB_.PC00.LPCB.EC0_.XQ0E, MethodObj)    // 0 Arguments
    External (_SB_.PC00.LPCB.EC0_.XQ0F, MethodObj)    // 0 Arguments
    External (_SB_.PC00.LPCB.EC0_.XQD5, MethodObj)    // 0 Arguments
    External (_SB_.KFSK, FieldUnitObj)

    Scope (\_SB.ATKD)
    {
        Name (KBVL, Zero)   // last keyboard backlight level set by macOS (0x00-0xFF)

        // Keyboard backlight level from AsusSMC (0x00-0xFF) -> EC PWM
        Method (SKBV, 1, NotSerialized)
        {
            KBVL = Arg0
            \_SB.PC00.LPCB.EC0.ST9E (0x1F, 0xFF, Arg0)
            Return (Arg0)
        }

        // Send the same ATK key event Arg1 times
        Method (KBRP, 2, Serialized)
        {
            Local0 = Arg1
            While (Local0)
            {
                IANE (Arg0)
                Local0--
            }
        }
    }

    Scope (\_SB.PC00.LPCB.EC0)
    {
        // Keyboard backlight down (one step)
        Method (_Q0C, 0, NotSerialized)
        {
            If (_OSI ("Darwin")) { \_SB.ATKD.IANE (0xC5) }
            Else { XQ0C () }
        }

        // Keyboard backlight key: 4 steps up, wrap to off after full brightness
        Method (_Q0D, 0, NotSerialized)
        {
            If (_OSI ("Darwin"))
            {
                If ((\_SB.ATKD.KBVL >= 0xF0))
                {
                    \_SB.ATKD.KBRP (0xC5, 0x10)
                }
                Else
                {
                    \_SB.ATKD.KBRP (0xC4, 0x04)
                }
            }
            Else { XQ0D () }
        }

        // Screen brightness down
        Method (_Q0E, 0, NotSerialized)
        {
            If (_OSI ("Darwin")) { \_SB.ATKD.IANE (0x20) }
            Else { XQ0E () }
        }

        // Screen brightness up
        Method (_Q0F, 0, NotSerialized)
        {
            If (_OSI ("Darwin")) { \_SB.ATKD.IANE (0x10) }
            Else { XQ0F () }
        }

        // Fn+Esc: toggle Fn-lock (same EC command as ATK DEVS 0x00100023)
        // NOTE: does not work in practice on this laptop (kept for reference).
        Method (_QD5, 0, NotSerialized)
        {
            If (_OSI ("Darwin"))
            {
                If ((\_SB.KFSK & 0x80)) { Local0 = 0x04 } Else { Local0 = 0x08 }
                ST9E (0x3C, 0xFF, (\_SB.KFSK | Local0))
            }
            Else { XQD5 () }
        }
    }
}
```

### SSDT-TPD-ETPD.dsl (touchpad always present)
Needs the `ETPD _STA → XSTA` patch from section 14.
```asl
/*
 * ASUS Vivobook 15 X513EP - always expose the ELAN I2C touchpad (ETPD) to macOS
 * Requires OpenCore ACPI patch: ETPD _STA -> XSTA (Find 141B5F53544100A011919293545049460190)
 */
DefinitionBlock ("", "SSDT", 2, "HACK", "TPDETPD", 0x00000001)
{
    External (_SB_.PC00.I2C1.ETPD, DeviceObj)
    External (_SB_.PC00.I2C1.ETPD.XSTA, MethodObj)    // 0 Arguments

    Scope (\_SB.PC00.I2C1.ETPD)
    {
        Method (_STA, 0, NotSerialized)
        {
            If (_OSI ("Darwin"))
            {
                Return (0x0F)
            }

            Return (\_SB.PC00.I2C1.ETPD.XSTA ())
        }
    }
}
```

---

## Appendix C — Lid-lock script

What it does: lid closed → **lock + keep the display awake** (`caffeinate -d`). Lid opened → after **60 seconds**, the display may sleep again normally.

**Easiest:** run `zsh scripts/install-lidlock.sh` from this repository (remove it with `zsh scripts/uninstall-lidlock.sh`). It also replaces an older version if one is running. Or paste this into Terminal:
```bash
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
```
**Remove it:**
```
launchctl bootout gui/$(id -u)/com.user.lidlock; rm ~/Library/LaunchAgents/com.user.lidlock.plist ~/.lidlock.sh
```
⚠️ Never use `pmset displaysleepnow` on this laptop, because the screen doesn't come back on.

---

## Appendix D — Useful commands

```bash
# Mount the SSD's EFI partition (safe: finds the disk macOS runs from)
P=$(diskutil info / | awk -F': *' '/APFS Physical Store/{print $2}'); E=${P%s2}s1; sudo diskutil mount $E

# Check config.plist for syntax errors
plutil -lint /Volumes/EFI/EFI/OC/config.plist

# Read / change boot-args (example: add an argument)
K="NVRAM.Add.7C436110-AB2A-4BBB-A880-FE41995C9F82.boot-args"; C=/Volumes/EFI/EFI/OC/config.plist
plutil -extract "$K" raw "$C"
sudo plutil -replace "$K" -string "$(plutil -extract "$K" raw "$C") new-arg" "$C"

# Which kexts are loaded
kmutil showloaded 2>/dev/null | grep -i -E "voodoo|whatever|asus|airport|blue|smc"

# Graphics status
system_profiler SPDisplaysDataType | grep -E "Chipset|Metal|VRAM"

# Recent crashes / GPU resets
ls -t /Library/Logs/DiagnosticReports | head -10

# Lid state and sleep settings
ioreg -r -n IOPMrootDomain -d 1 | grep -E '"AppleClamshell'
pmset -g

# Disks
diskutil list internal physical
```

---

## Credits

- [Acidanthera](https://github.com/acidanthera) — OpenCore, Lilu, VirtualSMC, AppleALC, VoodooPS2, CpuTscSync, NVMeFix, RestrictEvents, BrightnessKeys
- [Dortania OpenCore Install Guide](https://dortania.github.io/OpenCore-Install-Guide/)
- [lzhoang2801 / OpCore Simplify](https://github.com/lzhoang2801/OpCore-Simplify)
- [b00t0x / WhateverXe](https://github.com/b00t0x/WhateverXe) and [WhateverXe-Graphics](https://github.com/b00t0x/WhateverXe-Graphics)
- [OpenIntelWireless](https://github.com/OpenIntelWireless) — AirportItlwm, IntelBluetoothFirmware
- [VoodooI2C](https://github.com/VoodooI2C/VoodooI2C)
- [hieplpvip / AsusSMC](https://github.com/hieplpvip/AsusSMC)
- [laobamac / SimpleHDA](https://github.com/laobamac/SimpleHDA)
- [datasone / grub-mod-setup_var](https://github.com/datasone/grub-mod-setup_var) — modGRUBShell
- [corpnewt](https://github.com/corpnewt) — ProperTree, GenSMBIOS
- [USBToolBox](https://github.com/USBToolBox)
- Reference EFIs that helped a lot:
  - [Ashfaqul-Awal-Himel / Asus-Vivobook-15_X513EP-Hackintosh](https://github.com/Ashfaqul-Awal-Himel/Asus-Vivobook-15_X513EP-Hackintosh) (same laptop, Big Sur — booter quirks, CFG offset, identical DSDT)
  - [xiananliu / g83-11gen-hackintosh-tahoe-efi](https://github.com/xiananliu/g83-11gen-hackintosh-tahoe-efi) (Tiger Lake on Tahoe with WhateverXe)
  - [tiwarisatyadeep / Dell_Latitude_5420_EFI](https://github.com/tiwarisatyadeep/Dell_Latitude_5420_EFI)
  - [Akariayumu / xstation-v2-hackintosh](https://github.com/Akariayumu/xstation-v2-hackintosh)
  - [Chizuui / Acer-A514-54G-Hackintosh-Tahoe](https://github.com/Chizuui/Acer-A514-54G-Hackintosh-Tahoe)

> **Licenses:** OpenCore, all kexts, drivers and tools in `EFI/` belong to their respective authors and are distributed under **their own licenses**. `HfsPlus.efi` and `apfs_aligned.efi` are Apple binaries as commonly distributed via [acidanthera/OcBinaryData](https://github.com/acidanthera/OcBinaryData). The MIT [LICENSE](LICENSE) in this repository only covers the guide, the ACPI sources and the scripts written for it.

Built step by step with help from Claude (Anthropic).
