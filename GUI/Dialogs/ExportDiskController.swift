// -----------------------------------------------------------------------------
// This file is part of vAmiga
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

import Foundation

class ExportDiskController : DialogController {

    @IBOutlet weak var button: NSPopUpButton!
    var type: C64FileType = D64_FILE
    var savePanel: NSSavePanel!
    var selectedURL: URL?
    
    func showSheet(forDrive nr: Int) {
        
        assert(nr == 1 || nr == 2)
        
        // Create save panel
        savePanel = NSSavePanel()
        savePanel.allowedFileTypes = ["d64"]
        savePanel.prompt = "Export"
        savePanel.title = "Export"
        savePanel.nameFieldLabel = "Export As:"
        savePanel.accessoryView = window?.contentView

        // Run panel as sheet
        if let win = myWindow {
            savePanel.beginSheetModal(for: win, completionHandler: { result in
                if result == .OK {
                    myDocument?.export(drive: nr, to: self.savePanel.url)
                }
            })
        }
    }
    
    @IBAction func selectADF(_ sender: Any!) {
        track()
        savePanel.allowedFileTypes = ["adf"]
        type = G64_FILE
    }
}
