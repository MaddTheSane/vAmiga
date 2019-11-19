// -----------------------------------------------------------------------------
// This file is part of vAmiga
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

class MyDocument: NSDocument {

    /*
     Emulator proxy object. This object is an Objective-C bridge between
     the GUI (written in Swift) an the core emulator (written in C++).
     */
    var amiga: AmigaProxy!

    /*
     An otional media object attached to this document.
     This variable is checked by the GUI, e.g., when the READY_TO_RUN message
     is received. If an attachment is present, e.g., a T64 archive,
     is displays a user dialog. The user can then choose to mount the archive
     as a disk or to flash a single file into memory. If the attachment is a
     snapshot, it is read into the emulator without asking the user.
     This variable is also used when the user selects the "Insert Disk",
     "Insert Tape" or "Attach Cartridge" menu items. In that case, the selected
     URL is translated into an attachment and then processed. The actual
     post-processing depends on the attachment type and user options. E.g.,
     snapshots are flashed while T64 archives are converted to a disk and
     inserted into the disk drive.
     */
    var amigaAttachment: AmigaFileProxy?
    
    override init() {
        
        track()
        super.init()
        
        // Register standard user defaults
        MyController.registerUserDefaults()
        
        // Create emulator instance
        amiga = AmigaProxy()
        
        // Install the AROS Kickstart replacement per default
        amiga.mem.loadRom(fromBuffer: NSDataAsset(name: "aros-amiga-m68k-rom")?.data)
        amiga.mem.loadExt(fromBuffer: NSDataAsset(name: "aros-amiga-m68k-ext")?.data)
        // amiga.mem.loadRom(fromBuffer: NSDataAsset(name: "aros-rom")?.data)
        // amiga.mem.loadRom(fromBuffer: NSDataAsset(name: "aros-ext")?.data)
    }
 
    deinit {
        
        track()
        
        // Shut down the emulator
        amiga.kill()
    }
    
    override open func makeWindowControllers() {
        
        track()
        
        let nibName = NSNib.Name("MyDocument")
        let controller = MyController.init(windowNibName: nibName)
        controller.amiga = amiga
        self.addWindowController(controller)
    }

    //
    // Creating attachments
    //
    
    // Creates an ADF file proxy from a URL
    func createADF(from url: URL) throws -> ADFFileProxy? {

        track("Creating ADF proxy from URL \(url.lastPathComponent).")
        
        // Try to create a file wrapper
        let fileWrapper = try FileWrapper.init(url: url)
        guard let data = fileWrapper.regularFileContents else {
            throw NSError(domain: "vAmiga", code: 0, userInfo: nil)
        }
        
        // Try to create ADF file proxy
		let proxy = ADFFileProxy(data: data)
        
        if proxy != nil {
            myAppDelegate.noteNewRecentlyUsedURL(url)
        }
        
        return proxy
    }
    
    /// Creates an attachment from a URL
    func createAmigaAttachment(from url: URL) throws {
        
        track("Creating attachment from URL \(url.lastPathComponent).")
        
        // Try to create the attachment
        let fileWrapper = try FileWrapper.init(url: url)
        let pathExtension = url.pathExtension.uppercased()
        try createAmigaAttachment(from: fileWrapper, ofType: pathExtension)
        
        // Put URL in recently used URL lists
        myAppDelegate.noteNewRecentlyUsedURL(url)
    }
    
    // OLD CODE:
    /*
    func createAttachment(from url: URL) throws {
    
        track("Creating attachment from URL \(url.lastPathComponent).")

        // Try to create the attachment
        let fileWrapper = try FileWrapper.init(url: url)
        let pathExtension = url.pathExtension.uppercased()
        try createAttachment(from: fileWrapper, ofType: pathExtension)

        // Put URL in recently used URL lists
        noteNewRecentlyUsedURL(url)
    }
    */
    
    /// Creates an attachment from a file wrapper
    fileprivate func createAmigaAttachment(from fileWrapper: FileWrapper,
                                           ofType typeName: String) throws {
        
        guard let filename = fileWrapper.filename else {
            throw NSError(domain: "vAmiga", code: 0, userInfo: nil)
        }
        guard let data = fileWrapper.regularFileContents else {
            throw NSError(domain: "vAmiga", code: 0, userInfo: nil)
        }
        
        let length = data.count
        var openAsUntitled = true
        
        track("Read \(length) bytes from file \(filename) [\(typeName)].")
        
        switch typeName {
            
        case "VAMIGA":
            // Check for outdated snapshot formats
            if SnapshotProxy.isUnsupportedSnapshotData(data) {
                throw NSError.snapshotVersionError(filename: filename)
            }
            amigaAttachment = SnapshotProxy(data: data)
            openAsUntitled = false
            
        case "ADF":
			amigaAttachment = ADFFileProxy(data: data)
            
        default:
            throw NSError.unsupportedFormatError(filename: filename)
        }
        
        if amigaAttachment == nil {
            throw NSError.corruptedFileError(filename: filename)
        }
        if openAsUntitled {
            fileURL = nil
        }
        amigaAttachment!.setPath(filename)
    }

    //
    // Processing attachments
    //
    
    @discardableResult
    func mountAmigaAttachment() -> Bool {
        
        // guard let controller = myController else { return false }
        
        switch amigaAttachment {

        case _ as SnapshotProxy:
            
            amiga.load(fromSnapshot: amigaAttachment as? SnapshotProxy)
            return true
       
        case _ as ADFFileProxy:
            
            if let df = myController?.dragAndDropDrive?.nr {
                amiga.diskController.insert(df, adf: amigaAttachment as? ADFFileProxy)
            } else {
                runDiskMountDialog()
            }
            
        default:
            break
        }
        
        return true
    }
    
    func runDiskMountDialog() {
        let nibName = NSNib.Name("DiskMountDialog")
        let controller = DiskMountController.init(windowNibName: nibName)
        controller.showSheet()
    }

    //
    // Loading
    //
    
    override open func read(from url: URL, ofType typeName: String) throws {
        
        try createAmigaAttachment(from: url)
    }

    //
    // Saving
    //
    
    override open func data(ofType typeName: String) throws -> Data {
        
        track("Trying to write \(typeName) file.")
        
        if typeName == "vAmiga" {
            
            // Take snapshot
            if let snapshot = SnapshotProxy(amiga: amiga) {

                // Write to data buffer
                if let data = NSMutableData.init(length: snapshot.sizeOnDisk) {
                    snapshot.write(toBuffer: data.mutableBytes)
                    return data as Data
                }
            }
        }
        
        throw NSError(domain: NSOSStatusErrorDomain, code: unimpErr, userInfo: nil)
    }
    
    //
    // Exporting disks
    //
    
    func export(drive nr: Int, to url: URL, ofType typeName: String) -> Bool {
        
        track("url = \(url) typeName = \(typeName)")
        assert(["ADF"].contains(typeName))
        
        let drive = amiga.df(nr)
        
        // Convert disk to ADF format
		guard let adf = ADFFileProxy(drive: drive) else {
            track("ADF conversion failed")
            return false
        }

        // Serialize data
        let data = NSMutableData.init(length: adf.sizeOnDisk)!
        adf.write(toBuffer: data.mutableBytes)
        
        // Write to file
        if !data.write(to: url, atomically: true) {
            showExportErrorAlert(url: url)
            return false
        }

        // Mark disk as "not modified"
        drive.setModifiedDisk(false)
        
        // Remember export URL
        myAppDelegate.noteNewRecentlyExportedDiskURL(url, drive: nr)
        return true
    }
        
    @discardableResult
    func export(drive nr: Int, to url: URL?) -> Bool {
        
        if let suffix = url?.pathExtension {
            return export(drive: nr, to: url!, ofType: suffix.uppercased())
        } else {
            return false
        }
    }
}
