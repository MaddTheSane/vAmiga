// -----------------------------------------------------------------------------
// This file is part of vAmiga
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

// swiftlint:disable colon

extension PreferencesController {
    
    func refreshHardwareTab() {

        track()
        let config = amiga.config()
        let poweredOff = amiga.isPoweredOff()

        // Chipset
        hwAgnusRevisionPopup.selectItem(withTag: config.agnus.revision.rawValue)
        hwDeniseRevisionPopup.selectItem(withTag: config.denise.revision.rawValue)
        hwRealTimeClock.selectItem(withTag: config.rtc.model.rawValue)

        // Ports
        hwSerialDevice.selectItem(withTag: Int(config.serialPort.device.rawValue))

        // Memory
        hwChipRamPopup.selectItem(withTag: config.mem.chipSize / 1024)
        hwSlowRamPopup.selectItem(withTag: config.mem.slowSize / 1024)
        hwFastRamPopup.selectItem(withTag: config.mem.fastSize / 1024)

        // Drive
        hwDf1Connect.state = config.diskController.connected.1 ? .on : .off
        hwDf2Connect.state = config.diskController.connected.2 ? .on : .off
        hwDf3Connect.state = config.diskController.connected.3 ? .on : .off
        hwDf0Type.selectItem(withTag: config.df0.type.rawValue)
        hwDf1Type.selectItem(withTag: config.df1.type.rawValue)
        hwDf2Type.selectItem(withTag: config.df2.type.rawValue)
        hwDf3Type.selectItem(withTag: config.df3.type.rawValue)

        // Lock controls if emulator is powered on
        hwAgnusRevisionPopup.isEnabled = poweredOff
        hwDeniseRevisionPopup.isEnabled = poweredOff
        hwRealTimeClock.isEnabled = poweredOff
        hwChipRamPopup.isEnabled = poweredOff
        hwSlowRamPopup.isEnabled = poweredOff
        hwFastRamPopup.isEnabled = poweredOff
        hwDf1Connect.isEnabled = poweredOff
        hwDf2Connect.isEnabled = poweredOff
        hwDf3Connect.isEnabled = poweredOff
        hwDf0Type.isEnabled = poweredOff
        hwDf1Type.isEnabled = poweredOff && config.diskController.connected.1
        hwDf2Type.isEnabled = poweredOff && config.diskController.connected.2
        hwDf3Type.isEnabled = poweredOff && config.diskController.connected.3
        hwFactorySettingsPopup.isEnabled = poweredOff

        // Lock symbol and explanation
        hwLockImage.isHidden = poweredOff
        hwLockText.isHidden = poweredOff
        hwLockSubText.isHidden = poweredOff

        // OK Button
        hwOKButton.title = buttonLabel
    }

    @IBAction func hwAgnusRevAction(_ sender: NSPopUpButton!) {

        amiga.configure(VA_AGNUS_REVISION, value: sender.selectedTag())
        refresh()
    }

    @IBAction func hwDeniseRevAction(_ sender: NSPopUpButton!) {

        amiga.configure(VA_DENISE_REVISION, value: sender.selectedTag())
        refresh()
    }

    @IBAction func hwRealTimeClockAction(_ sender: NSPopUpButton!) {
        
        amiga.configure(VA_RT_CLOCK, value: sender.selectedTag())
        refresh()
    }
    
    @IBAction func hwChipRamAction(_ sender: NSPopUpButton!) {

        let chipRamWanted = sender.selectedTag()
        let chipRamLimit = amiga.agnus.chipRamLimit()

        if chipRamWanted > chipRamLimit {
            parent.mydocument?.showConfigurationAltert(ERR_CHIP_RAM_LIMIT)
        } else {
            amiga.configure(VA_CHIP_RAM, value: sender.selectedTag())
        }
        refresh()
    }

    @IBAction func hwSlowRamAction(_ sender: NSPopUpButton!) {
        
        amiga.configure(VA_SLOW_RAM, value: sender.selectedTag())
        refresh()
    }

    @IBAction func hwFastRamAction(_ sender: NSPopUpButton!) {
        
        amiga.configure(VA_FAST_RAM, value: sender.selectedTag())
        refresh()
    }

    @IBAction func hwDriveConnectAction(_ sender: NSButton!) {
        
        let driveNr = sender.tag
        amiga.configureDrive(driveNr, connected: sender.state == .on)
        refresh()
    }
    
    @IBAction func hwDriveTypeAction(_ sender: NSPopUpButton!) {
        
        track()
        
        let nr = sender.tag
        amiga.configureDrive(nr, type: sender.selectedTag())
        refresh()
    }
 
    @IBAction func hwSerialDeviceAction(_ sender: NSPopUpButton!) {

        amiga.configure(VA_SERIAL_DEVICE, value: sender.selectedTag())
        refresh()
    }

    @IBAction func hwFactorySettingsAction(_ sender: NSPopUpButton!) {
        
        track("\(sender.selectedTag())")

        switch sender.selectedTag() {

        case 0: hwFactorySettingsAction(Defaults.A500)
        case 1: hwFactorySettingsAction(Defaults.A1000)
        case 2: hwFactorySettingsAction(Defaults.A2000)
        default: track("Cannot restore factory defaults (unknown Amiga model).")
         }
    }

    func hwFactorySettingsAction(_ defaults: Defaults.ModelDefaults) {

        amiga.configure(VA_AGNUS_REVISION, value: defaults.agnusRevision.rawValue)
        amiga.configure(VA_DENISE_REVISION, value: defaults.deniseRevision.rawValue)
        amiga.configure(VA_RT_CLOCK, value: defaults.realTimeClock.rawValue)

        amiga.configure(VA_CHIP_RAM, value: defaults.chipRam)
        amiga.configure(VA_SLOW_RAM, value: defaults.slowRam)
        amiga.configure(VA_FAST_RAM, value: defaults.fastRam)

        amiga.configure(VA_SERIAL_DEVICE, value: defaults.serialDevice.rawValue)

        for i in 0...3 {
            amiga.configureDrive(i, connected: defaults.driveConnect[i])
            amiga.configureDrive(i, type:      defaults.driveType[i].rawValue)
        }

        refresh()
    }
}
