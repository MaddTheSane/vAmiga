// -----------------------------------------------------------------------------
// This file is part of vAmiga
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

#ifndef _AMIGA_FILE_INC
#define _AMIGA_FILE_INC

#include "AmigaObject.h"

/* Base class of all file readable types.
 * Provides the basic functionality for reading and writing files.
 */
class AmigaFile : public AmigaObject {
    
protected:
    
    // Physical location of this file on disk
    char *path = NULL;
    
    // The raw data of this file
    uint8_t *data = NULL;
    
    // The size of this file in bytes
    size_t size = 0;
    
    /* File pointer
     * An offset into the data array with -1 indicating EOF
     */
    long fp = -1;
    
    /* End of file position
     * This value equals the last valid offset plus 1
     */
    long eof = -1;
    
    
    //
    // Creating and destructing objects
    //
    
public:
    
    AmigaFile();
    virtual ~AmigaFile();
    
    // Allocates memory for storing the object data.
    virtual bool alloc(size_t capacity);
    
    // Frees the allocated memory.
    virtual void dealloc();
    
    
    //
    // Accessing file attributes
    //
    
    // Returns the type of this file.
    virtual AmigaFileType fileType() { return FILETYPE_UKNOWN; }
    
    // Returns a string representation of the file type, e.g., "ADF".
    virtual const char *typeAsString() { return ""; }
    
    // Returns the physical name of this file.
    const char *getPath() { return path ? path : ""; }
    
    // Sets the physical name of this file.
    void setPath(const char *path);
    
    // Returns a fingerprint (hash value) for the file's data.
    uint64_t fingerprint() { return fnv_1a_64(data, size); }
    
    //
    // Reading data from the file
    //
    
    //  Returns the number of bytes in this file.
    virtual size_t getSize() { return size; }
    
    // Moves the file pointer to the specified offset.
    virtual void seek(long offset);
    
    /*  Reads a byte.
     *  Returns EOF (-1) if the end of file has been reached.
     */
    virtual int read();
    
    /* Reads multiple bytes in form of a hex dump string.
     * Number of bytes ranging from 1 to 85.
     */
    // const char *readHex(size_t num = 1);
    
    //! Copies the whole file data into a buffer.
    virtual void flash(uint8_t *buffer, size_t offset = 0);
    
    
    //
    // Serializing
    //
    
    // Returns the required buffer size for this file
    size_t sizeOnDisk() { return writeToBuffer(NULL); }

    /* Returns true iff this specified buffer is compatible with this object.
     * This function is used in readFromBuffer().
     */
    virtual bool bufferHasSameType(const uint8_t *buffer, size_t length) { return false; }


    /* Returns true iff this specified file is compatible with this object.
     * This function is used in readFromFile().
     */
    virtual bool fileHasSameType(const char *path) { return false; }
    
    /* Deserializes this object from a memory buffer.
     *   - buffer   The address of a binary representation in memory.
     *   - length   The size of the binary representation.
     * This function uses bufferHasSameType() to verify that the buffer
     * contains a compatible binary representation.
     */
    virtual bool readFromBuffer(const uint8_t *buffer, size_t length);
    
    /* Deserializes this object from a file.
     *   - path     The name of the file containing the binary representation.
     * This function uses fileHasSameType() to verify that the buffer
     * contains a compatible binary representation.
     * This function requires no custom implementation. It first reads in the
     * file contents in memory and invokes readFromBuffer afterwards.
     */
    bool readFromFile(const char *filename);
    
    /* Writes the file contents into a memory buffer.
     * If a NULL pointer is passed in, a test run is performed. Test runs can
     * be performed to determine the size of the file on disk.
     */
    virtual size_t writeToBuffer(uint8_t *buffer);
    
    /* Writes the file contents to a file.
     * This function requires no custom implementation. It invokes writeToBuffer
     * first and writes the data to disk afterwards.
     *   - filename   The name of a file to be written.
     */
    bool writeToFile(const char *filename);
};

#endif
