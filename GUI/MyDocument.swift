// -----------------------------------------------------------------------------
// This file is part of vAmiga
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

class MyDocument: NSDocument {

    /// The window controller for this document
    var parent: MyController { return windowControllers.first as! MyController }

    /// The application delegate
    var myAppDelegate: MyAppDelegate { return NSApp.delegate as! MyAppDelegate }
    
    /**
     * Emulator proxy. This object is an Objective-C bridge between the Swift
     * GUI an the core emulator which is written in C++.
     */
    var amiga: AmigaProxy!

    /**
     * An otional media object attached to this document. This variable is
     * checked in `mountAttachment()` which is called in `windowDidLoad()`. If an
     * attachment is present, e.g., an ADF archive, it is automatically
     * attached to the emulator.
     */
    var amigaAttachment: AmigaFileProxy?
    
    // Snapshots
    private(set) var autoSnapshots = ManagedArray<SnapshotProxy>.init(capacity: 32)
    private(set) var userSnapshots = ManagedArray<SnapshotProxy>.init(capacity: Int.max)

    // Screenshots (DEPRECATED)
    private(set) var autoScreenshots = ManagedArray<Screenshot>.init(capacity: 32)
    private(set) var userScreenshots = ManagedArray<Screenshot>.init(capacity: Int.max)

    /// Fingerprint of the first disk inserted into df0 after reset
    private var bootDiskID = UInt64(0)
        
    //
    // MARK: - Initialization
    //
    
    override init() {
        
        track()
        super.init()

        // Check for Metal support
        if MTLCreateSystemDefaultDevice() == nil {
            showNoMetalSupportAlert()
            NSApp.terminate(self)
            return
        }

        // Register standard user defaults
        UserDefaults.registerUserDefaults()
        
        // Create emulator instance
        amiga = AmigaProxy()
    }
 
    deinit {
        
        track()
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
    // MARK: - Creating attachments
    //
    
    func fileType(url: URL) -> AmigaFileType {
        
        switch url.pathExtension.uppercased() {
        
        case "VAMIGA": return .FILETYPE_SNAPSHOT
        case "ADF":    return .FILETYPE_ADF
        case "IMG":    return .FILETYPE_IMG
        case "IMA":    return .FILETYPE_IMG
        case "DMS":    return .FILETYPE_DMS
        default:       return .FILETYPE_UKNOWN
        }
    }
    
    fileprivate
    func createFileProxy(url: URL, allowedTypes: [AmigaFileType]) throws -> AmigaFileProxy? {
        
        track("Creating proxy object from URL: \(url.lastPathComponent)")
        
        // If the provided URL points to compressed file, decompress it first
        let newUrl = url.unpacked
        
        // Only proceed if the file type is an allowed type
        let type = fileType(url: newUrl)
        if !allowedTypes.contains(type) { return nil }
        
        // Get the file wrapper and create the proxy with it
        let wrapper = try FileWrapper.init(url: newUrl)
        return try createFileProxy(wrapper: wrapper, type: type)
    }
    
    fileprivate
    func createFileProxy(wrapper: FileWrapper, type: AmigaFileType) throws -> AmigaFileProxy? {
                
        guard let name = wrapper.filename else {
            throw NSError.fileAccessError()
        }
        guard let data = wrapper.regularFileContents else {
            throw NSError.fileAccessError(filename: name)
        }
        
        var result: AmigaFileProxy?
        let buffer = (data as NSData).bytes
        let length = data.count
        
        track("Read \(length) bytes from file \(name) [\(type.rawValue)].")
        
        switch type {
            
        case .FILETYPE_SNAPSHOT:
            if SnapshotProxy.isUnsupportedSnapshot(buffer, length: length) {
                throw NSError.snapshotVersionError(filename: name)
            }
            result = SnapshotProxy.make(with: data)
            
        case .FILETYPE_ADF:
            result = ADFFileProxy.make(with: data)
            
        case .FILETYPE_DMS:
            result = DMSFileProxy.make(with: data)

        case .FILETYPE_IMG:
            result = IMGFileProxy.make(with: data)

        default:
            fatalError()
        }
        
        if result == nil {
            throw NSError.corruptedFileError(filename: name)
        }
        result!.setPath(name)
        track("Attachment created successfully")
        return result
    }
    
    func createADFProxy(from url: URL) throws -> ADFFileProxy? {
        
        track("Trying to create ADF proxy from URL \(url.lastPathComponent).")
                
        let types = [ AmigaFileType.FILETYPE_ADF, AmigaFileType.FILETYPE_DMS ]
        let proxy = try createFileProxy(url: url, allowedTypes: types)
        
        switch proxy {
            
        case _ as ADFFileProxy: return (proxy as! ADFFileProxy)
        case _ as DMSFileProxy: return (proxy as! DMSFileProxy).adf()
        default: fatalError()
        }
    }
    
    func createAttachment(from url: URL) throws {
                
        track("Creating attachment from URL: \(url.lastPathComponent)")
        
        // Create file proxy
        let types: [AmigaFileType] =
            [ .FILETYPE_SNAPSHOT, .FILETYPE_ADF, .FILETYPE_DMS, .FILETYPE_IMG ]
        
        amigaAttachment = try createFileProxy(url: url, allowedTypes: types)
        
        // Remember the URL
        myAppDelegate.noteNewRecentlyUsedURL(url)
    }

    //
    // MARK: - Processing attachments
    //
    
    @discardableResult
    func mountAttachment() -> Bool {
        
        switch amigaAttachment {

        case _ as SnapshotProxy:
            
            parent.load(snapshot: amigaAttachment as? SnapshotProxy)
       
        case _ as ADFFileProxy:
            
            if let df = parent.dragAndDropDrive?.nr {
                amiga.diskController.insert(df, adf: amigaAttachment as? ADFFileProxy)
            } else {
                runDiskMountDialog()
            }
            
        case _ as DMSFileProxy:
            
            if let df = parent.dragAndDropDrive?.nr {
                amiga.diskController.insert(df, dms: amigaAttachment as? DMSFileProxy)
            } else {
                runDiskMountDialog()
            }

        case _ as IMGFileProxy:
            
            if let df = parent.dragAndDropDrive?.nr {
                amiga.diskController.insert(df, img: amigaAttachment as? IMGFileProxy)
            } else {
                runDiskMountDialog()
            }

        default:
            break
        }
        
        return true
    }
    
    func runDiskMountDialog() {
        let name = NSNib.Name("DiskMountDialog")
        let controller = DiskMountDialog.make(parent: parent, nibName: name)
        controller?.showSheet()
    }

    //
    // MARK: - Loading
    //
    
    override open func read(from url: URL, ofType typeName: String) throws {
        
        try createAttachment(from: url)
    }

    //
    // MARK: - Saving
    //
    
    override open func data(ofType typeName: String) throws -> Data {
        
        track("\(typeName)")
        
        if typeName == "vAmiga" {
            
            // Take snapshot
            if let snapshot = SnapshotProxy.make(withAmiga: amiga) {

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
    // MARK: - Exporting disks
    //
    
    @discardableResult
    func export(drive nr: Int, to url: URL) -> Bool {
                
        var df: DiskFileProxy?
        switch url.pathExtension {
        case "adf", "ADF":
            df = ADFFileProxy.make(withDrive: amiga.df(nr)!)
        case "img", "IMG", "ima", "IMA":
            df = IMGFileProxy.make(withDrive: amiga.df(nr)!)
        default:
            break
        }
        
        if df != nil {
            return export(drive: nr, to: url, diskFileProxy: df!)
        } else {
            showExportDecodingAlert(driveNr: nr)
            return false
        }
    }
    
    @discardableResult
    func export(drive nr: Int, to url: URL, diskFileProxy df: DiskFileProxy) -> Bool {
                        
        track("Exporting disk to \(url)")
        
        // Serialize data
        let data = NSMutableData.init(length: df.sizeOnDisk)!
        df.write(toBuffer: data.mutableBytes)
        
        // Write to file
        if !data.write(to: url, atomically: true) {
            showExportAlert(url: url)
            return false
        }

        // Mark disk as "not modified"
        amiga.df(nr)!.isModifiedDisk = false
        
        // Remember export URL
        myAppDelegate.noteNewRecentlyExportedDiskURL(url, drive: nr)

        track("Export complete")
        return true
    }
    
    //
    // MARK: - Snapshots
    //
        
    private func thinOut(numItems: Int, counter: inout Int) -> Int? {
        
        if numItems < 32 { return nil }
              
        var itemToDelete = 0
        
        if counter % 2 == 0 {
            itemToDelete = 24
        } else if (counter >> 1) % 2 == 0 {
            itemToDelete = 16
        } else if (counter >> 2) % 2 == 0 {
            itemToDelete = 8
        }
        counter += 1
        
        return itemToDelete
    }
    
    //
    // MARK: - Screenshots
    //
    
    func deleteBootDiskID() {
     
        bootDiskID = 0
    }

    @discardableResult
    func setBootDiskID(_ id: UInt64) -> Bool {
        
        if bootDiskID == 0 {
            bootDiskID = id
            try? loadScreenshots()
            return true
        }
        return false
    }
    
    /// Writes screenshots back to disk if needed
    func persistScreenshots() throws {

        if userScreenshots.modified { try saveScreenshots() }
    }

    func saveScreenshots() throws {
        
        track("Saving user screenshots to disk (\(bootDiskID))")
        
        let format = parent.pref.screenshotTarget
        
        Screenshot.deleteFolder(forDisk: bootDiskID)
        for n in 0 ..< userScreenshots.count {
            let data = userScreenshots.element(at: n)?.screen?.representation(using: format)
            if let url = Screenshot.newUrl(diskID: bootDiskID, using: format) {
                try data?.write(to: url, options: .atomic)
            }
        }
    }
        
    func loadScreenshots() throws {
        
        track("Seeking screenshots for disk with id \(bootDiskID)")
        
        userScreenshots.clear()
        for url in Screenshot.collectFiles(forDisk: bootDiskID) {
            if let screenshot = Screenshot.init(fromUrl: url) {
                userScreenshots.append(screenshot)
            }
        }
        
        track("\(userScreenshots.count) screenshots loaded")
    }
}
