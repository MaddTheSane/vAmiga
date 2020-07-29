// -----------------------------------------------------------------------------
// This file is part of vAmiga
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

extension ConfigurationController {
    
    func refreshRomTab() {

        let poweredOff      = amiga.isPoweredOff

        let romIdentifier   = amiga.mem.romIdentifier()
        let hasRom          = romIdentifier != .ROM_MISSING
        let hasArosRom      = amiga.mem.isArosRom(romIdentifier)
        let hasDiagRom      = amiga.mem.isDiagRom(romIdentifier)
        let hasCommodoreRom = amiga.mem.isCommodoreRom(romIdentifier)
        let hasHyperionRom  = amiga.mem.isHyperionRom(romIdentifier)

        let extIdentifier   = amiga.mem.extIdentifier
        let hasExt          = extIdentifier != .ROM_MISSING
        let hasArosExt      = amiga.mem.isArosRom(extIdentifier)
        let hasDiagExt      = amiga.mem.isDiagRom(extIdentifier)
        let hasCommodoreExt = amiga.mem.isCommodoreRom(extIdentifier)
        let hasHyperionExt  = amiga.mem.isHyperionRom(extIdentifier)

        let romMissing      = NSImage.init(named: "ROMs/missing")
        let romOrig         = NSImage.init(named: "ROMs/original")
        let romHyperion     = NSImage.init(named: "ROMs/hyp")
        let romAros         = NSImage.init(named: "ROMs/aros")
        let romDiag         = NSImage.init(named: "ROMs/diag")
        let romUnknown      = NSImage.init(named: "ROMs/unknown")
        
        // Lock controls if emulator is powered on
        romDropView.isEnabled = poweredOff
        romDeleteButton.isEnabled = poweredOff
        extDropView.isEnabled = poweredOff
        extDeleteButton.isEnabled = poweredOff
        romArosButton.isEnabled = poweredOff
        
        // Icons
        romDropView.image =
            hasHyperionRom  ? romHyperion :
            hasArosRom      ? romAros :
            hasDiagRom      ? romDiag :
            hasCommodoreRom ? romOrig :
            hasRom          ? romUnknown : romMissing

        extDropView.image =
            hasHyperionExt  ? romHyperion :
            hasArosExt      ? romAros :
            hasDiagExt      ? romDiag :
            hasCommodoreExt ? romOrig :
            hasExt          ? romUnknown : romMissing

        // Titles and subtitles
        romTitle.stringValue = amiga.mem.romTitle
        romSubtitle.stringValue = amiga.mem.romVersion
        romSubsubtitle.stringValue = amiga.mem.romReleased

        extTitle.stringValue = amiga.mem.extTitle()
        extSubtitle.stringValue = amiga.mem.extVersion()
        extSubsubtitle.stringValue = amiga.mem.extReleased()

        // Rom mapping addresses
        extMapAddr.selectItem(withTag: amiga.mem.extStart())

        // Hide some controls
        romDeleteButton.isHidden = !hasRom
        romMapText.isHidden = true
        romMapAddr.isHidden = true

        extDeleteButton.isHidden = !hasExt
        extMapText.isHidden = !hasExt
        extMapAddr.isHidden = !hasExt
        
        // Lock symbol and explanation
        romLockImage.isHidden = poweredOff
        romLockText.isHidden = poweredOff
        romLockSubText.isHidden = poweredOff

        // Boot button
        romPowerButton.isHidden = !bootable
    }

    //
    // Action methods
    //

    @IBAction func romDeleteAction(_ sender: NSButton!) {

        // config.romURL = URL(fileURLWithPath: "/")
        amiga.mem.deleteRom()
        
        refresh()
    }

    @IBAction func extDeleteAction(_ sender: NSButton!) {

        track()

        // config.extURL = URL(fileURLWithPath: "/")
        amiga.mem.deleteExt()

        refresh()
    }

    @IBAction func romMapAddrAction(_ sender: NSPopUpButton!) {

        // Nothing to do here at the moment.
        // All supported Roms are mapped at $FE0000
        refresh()
    }

    @IBAction func extMapAddrAction(_ sender: NSPopUpButton!) {

        config.extStart = sender.selectedTag()
        refresh()
    }

    @IBAction func installArosAction(_ sender: NSButton!) {

        let arosRom = NSDataAsset(name: "aros-amiga-m68k-rom")?.data
        let arosExt = NSDataAsset(name: "aros-amiga-m68k-ext")?.data

        // Install the Aros Roms
        amiga.mem.loadRom(fromBuffer: arosRom)
        amiga.mem.loadExt(fromBuffer: arosExt)
        config.extStart = 0xE0

        // Make sure the machine has enough Ram to run Aros
        let chip = amiga.getConfig(OPT_CHIP_RAM)
        let slow = amiga.getConfig(OPT_SLOW_RAM)
        let fast = amiga.getConfig(OPT_FAST_RAM)
        if chip + slow + fast < 1024*1024 { config.slowRam = 512 }
        
        refresh()
    }
    
    @IBAction func romDefaultsAction(_ sender: NSButton!) {
        
        config.saveRomUserDefaults()
    }
}
