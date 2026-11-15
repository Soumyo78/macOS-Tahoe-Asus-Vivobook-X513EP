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
