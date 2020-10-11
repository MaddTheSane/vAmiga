// -----------------------------------------------------------------------------
// This file is part of vAmiga
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

class BankTableView: NSTableView {
    
    @IBOutlet weak var inspector: Inspector!
    
    var amiga: AmigaProxy { return inspector.parent.amiga }

    /// Displayed memory bank
    var bank = 0

    /// Data caches
    var bankCache: [Int: MemorySource] = [:]

    override func awakeFromNib() {

        delegate = self
        dataSource = self
        target = self
        action = #selector(clickAction(_:))
    }

    func cache() {

        for i in 0 ..< 256 {
            bankCache[i] = inspector.memSrc(bank: i)
        }
    }

    func refresh(count: Int = 0, full: Bool = false) {

        if count % 8 != 0 { return }

        cache()
        reloadData()
    }

    @IBAction func clickAction(_ sender: NSTableView!) {

        inspector.jumpTo(bank: sender.clickedRow)
    }
}

extension BankTableView: NSTableViewDataSource {
    
    func numberOfRows(in tableView: NSTableView) -> Int { return 256; }
    
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        
        switch tableColumn?.identifier.rawValue {

        case "source":

            switch bankCache[row] {
                
            case .MEM_NONE:          return "Unmapped"
            case .MEM_CHIP:          return "Chip Ram"
            case .MEM_CHIP_MIRROR:   return "Chip Ram Mirror"
            case .MEM_FAST:          return "Fast Ram"
            case .MEM_SLOW:          return "Slow Ram"
            case .MEM_SLOW_MIRROR:   return "Slow Ram Mirror"
            case .MEM_CIA:           return "CIA"
            case .MEM_CIA_MIRROR:    return "CIA Mirror"
            case .MEM_RTC:           return "Real-time Clock"
            case .MEM_CUSTOM:        return "Chipset"
            case .MEM_CUSTOM_MIRROR: return "Chipset Mirror"
            case .MEM_AUTOCONF:      return "Autoconf"
            case .MEM_ROM:           return "Rom"
            case .MEM_ROM_MIRROR:    return "Rom Mirror"
            case .MEM_WOM:           return "Wom"
            case .MEM_EXT:           return "Extended Rom"
            default:                 fatalError()
            }

        default:
            return String(format: "%02X", row)
        }
    }
}

extension BankTableView: NSTableViewDelegate {
    
    func tableView(_ tableView: NSTableView, willDisplayCell cell: Any, for tableColumn: NSTableColumn?, row: Int) {
        
        if let cell = cell as? NSTextFieldCell {

            if bankCache[row] == .MEM_NONE {
                cell.textColor = .gray
            } else {
                cell.textColor = .textColor
            }
        }
    }
}
