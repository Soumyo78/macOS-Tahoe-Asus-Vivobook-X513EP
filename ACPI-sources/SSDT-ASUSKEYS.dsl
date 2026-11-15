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
