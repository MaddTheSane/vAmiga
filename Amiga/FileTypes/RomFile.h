// -----------------------------------------------------------------------------
// This file is part of vAmiga
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

#ifndef _ROMFILE_INC
#define _ROMFILE_INC

#include "AmigaFile.h"

class RomFile : public AmigaFile {

    // Accepted header signatures
    static const uint8_t bootRomHeaders[1][8];
    static const uint8_t kickRomHeaders[6][7];

public:
    
    //
    // Class methods
    //
    
    // Returns true iff buffer contains a Boot Rom or an Kickstart Rom image
    static bool isRomBuffer(const uint8_t *buffer, size_t length);
    
    // Returns true iff path points to a Boot Rom file or a Kickstart Rom file
    static bool isRomFile(const char *path);
    
    
    //
    // Creating and destructing
    //
    
    RomFile();
    
    // Factory methods
    static RomFile *makeWithBuffer(const uint8_t *buffer, size_t length);
    static RomFile *makeWithFile(const char *path);
    
    
    //
    // Methods from AmigaFile
    //
    
    AmigaFileType fileType() override { return FILETYPE_KICK_ROM; }
    const char *typeAsString() override { return "Kickstart Rom"; }
    bool bufferHasSameType(const uint8_t *buffer, size_t length) override {
        return isRomBuffer(buffer, length); }
    bool fileHasSameType(const char *path) override { return isRomFile(path); }
    bool readFromBuffer(const uint8_t *buffer, size_t length) override;
    
};

#endif
