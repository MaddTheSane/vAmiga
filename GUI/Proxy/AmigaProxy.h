// -----------------------------------------------------------------------------
// This file is part of vAmiga
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

#import <Cocoa/Cocoa.h>
#import <MetalKit/MetalKit.h>

#import "va_std.h"

// Forward declarations
@class CPUProxy;
@class CIAProxy;
@class MemProxy;
@class AgnusProxy;
@class DeniseProxy;
@class PaulaProxy;
@class ControlPortProxy;
@class SerialPortProxy;
@class MouseProxy;
@class JoystickProxy;
@class KeyboardProxy;
@class DiskControllerProxy;
@class DriveProxy;
@class AmigaFileProxy;
@class ADFFileProxy;
@class SnapshotProxy;

/* Forward declarations of C++ class wrappers.
 * We wrap classes into normal C structs to avoid any reference to C++.
 */
struct AmigaWrapper;
struct CPUWrapper;
struct CIAWrapper;
struct MemWrapper;
struct AgnusWrapper;
struct DeniseWrapper;
struct PaulaWrapper;
struct AmigaControlPortWrapper;
struct AmigaSerialPortWrapper;
struct KeyboardWrapper;
struct DiskControllerWrapper;
struct AmigaDriveWrapper;
struct AmigaFileWrapper;

//
// Amiga proxy
//

@interface AmigaProxy : NSObject {
    
    struct AmigaWrapper *wrapper;
    
    CPUProxy *cpu;
    CIAProxy *ciaA;
    CIAProxy *ciaB;
    MemProxy *mem;
    AgnusProxy *agnus;
    DeniseProxy *denise;
    PaulaProxy *paula;
    ControlPortProxy *controlPort1;
    ControlPortProxy *controlPort2;
    SerialPortProxy *serialPort;
    MouseProxy *mouse;
    JoystickProxy *joystick1;
    JoystickProxy *joystick2;
    KeyboardProxy *keyboard;
    DiskControllerProxy *diskController;
    DriveProxy *df0;
    DriveProxy *df1;
    DriveProxy *df2;
    DriveProxy *df3;
}

@property (readonly) struct AmigaWrapper *wrapper;
@property (readonly) CPUProxy *cpu;
@property (readonly) CIAProxy *ciaA;
@property (readonly) CIAProxy *ciaB;
@property (readonly) MemProxy *mem;
@property (readonly) AgnusProxy *agnus;
@property (readonly) DeniseProxy *denise;
@property (readonly) PaulaProxy *paula;
@property (readonly) ControlPortProxy *controlPort1;
@property (readonly) ControlPortProxy *controlPort2;
@property (readonly) SerialPortProxy *serialPort;
@property (readonly) MouseProxy *mouse;
@property (readonly) JoystickProxy *joystick1;
@property (readonly) JoystickProxy *joystick2;
@property (readonly) KeyboardProxy *keyboard;
@property (readonly) DiskControllerProxy *diskController;
@property (readonly) DriveProxy *df0;
@property (readonly) DriveProxy *df1;
@property (readonly) DriveProxy *df2;
@property (readonly) DriveProxy *df3;

// - (DriveProxy *)df:(NSInteger)n;

- (void) kill;

- (BOOL) releaseBuild;

- (void) setInspectionTarget:(EventID)id;
- (void) clearInspectionTarget;
- (BOOL) debugMode;
- (void) enableDebugging;
- (void) disableDebugging;
- (void) setDebugLevel:(NSInteger)value;

- (void) powerOn;
- (void) powerOff;
- (void) reset;
- (void) ping;
- (void) dump;

- (AmigaInfo) getInfo;
- (AmigaStats) getStats;

// - (BOOL) readyToPowerUp;
@property (readonly, getter=isPoweredOn) BOOL poweredOn;
@property (readonly, getter=isPoweredOff) BOOL poweredOff;
@property (readonly, getter=isRunning) BOOL running;
@property (readonly, getter=isPaused) BOOL paused;
- (void) run;
- (void) pause;

- (void) suspend;
- (void) resume;

- (AmigaConfiguration) config;
- (BOOL) configure:(ConfigOption)option value:(NSInteger)value;
- (BOOL) configure:(ConfigOption)option enable:(BOOL)value;
- (BOOL) configureDrive:(NSInteger)nr connected:(BOOL)value;
- (BOOL) configureDrive:(NSInteger)nr type:(NSInteger)value;

// Message queue
- (void) addListener:(const void *)sender function:(Callback *)func;
- (void) removeListener:(const void *)sender;
- (Message)message;

- (void) stopAndGo;
- (void) stepInto;
- (void) stepOver;

@property (readonly) BOOL warp;
- (void) warpOn;
- (void) warpOff;

// Handling snapshots
@property BOOL takeAutoSnapshots;
- (void) suspendAutoSnapshots;
- (void) resumeAutoSnapshots;
@property NSInteger snapshotInterval;
 
- (void) loadFromSnapshot:(SnapshotProxy *)proxy;

- (BOOL) restoreAutoSnapshot:(NSInteger)nr;
- (BOOL) restoreUserSnapshot:(NSInteger)nr;
- (BOOL) restoreLatestAutoSnapshot;
- (BOOL) restoreLatestUserSnapshot;
@property (readonly) NSInteger numAutoSnapshots;
@property (readonly) NSInteger numUserSnapshots;

- (NSData *) autoSnapshotData:(NSInteger)nr;
- (NSData *) userSnapshotData:(NSInteger)nr;
- (unsigned char *) autoSnapshotImageData:(NSInteger)nr;
- (unsigned char *) userSnapshotImageData:(NSInteger)nr;
- (NSSize) autoSnapshotImageSize:(NSInteger)nr;
- (NSSize) userSnapshotImageSize:(NSInteger)nr;
- (time_t) autoSnapshotTimestamp:(NSInteger)nr;
- (time_t) userSnapshotTimestamp:(NSInteger)nr;

- (void) takeUserSnapshot;

- (void) deleteAutoSnapshot:(NSInteger)nr;
- (void) deleteUserSnapshot:(NSInteger)nr;

@end


//
// CPU Proxy
//

@interface CPUProxy : NSObject {
    
    struct CPUWrapper *wrapper;
}

- (void) dump;
- (CPUInfo) getInfo;
- (DisassembledInstruction) getInstrInfo:(NSInteger)index;
- (DisassembledInstruction) getTracedInstrInfo:(NSInteger)index;

- (int64_t) clock;
- (int64_t) cycles;

- (BOOL) hasBreakpointAt:(uint32_t)addr;
- (BOOL) hasDisabledBreakpointAt:(uint32_t)addr;
- (BOOL) hasConditionalBreakpointAt:(uint32_t)addr;
- (void) setBreakpointAt:(uint32_t)addr;
- (void) deleteBreakpointAt:(uint32_t)addr;
- (void) enableBreakpointAt:(uint32_t)addr;
- (void) disableBreakpointAt:(uint32_t)addr;

@property (readonly) NSInteger traceBufferCapacity;
- (void) truncateTraceBuffer:(NSInteger)count;

@property (readonly) NSInteger numberOfBreakpoints;
- (void) deleteBreakpoint:(NSInteger)nr; 
- (BOOL) isDisabled:(NSInteger)nr;
- (BOOL) hasCondition:(NSInteger)nr;
- (BOOL) hasSyntaxError:(NSInteger)nr;
- (uint32_t) breakpointAddr:(NSInteger)nr;
- (BOOL) setBreakpointAddr:(NSInteger)nr addr:(uint32_t)addr;
- (NSString *) breakpointCondition:(NSInteger)nr;
- (BOOL) setBreakpointCondition:(NSInteger)nr cond:(NSString *)cond;

@end


//
// CIA Proxy
//

@interface CIAProxy : NSObject {
    
    struct CIAWrapper *wrapper;
}

- (void) dumpConfig;
- (void) dump;
- (CIAInfo) getInfo;

@end


//
// Memory Proxy
//

@interface MemProxy : NSObject {
    
    struct MemWrapper *wrapper;
}

- (void) dump;

- (BOOL) isBootRom:(RomRevision)rev;
- (BOOL) isArosRom:(RomRevision)rev;
- (BOOL) isDiagRom:(RomRevision)rev;
- (BOOL) isOrigRom:(RomRevision)rev;

@property (readonly) BOOL hasRom;
@property (readonly) BOOL hasBootRom;
@property (readonly) BOOL hasKickRom;
- (void) deleteRom;
- (BOOL) isRom:(NSURL *)url;
- (BOOL) loadRomFromBuffer:(NSData *)buffer;
- (BOOL) loadRomFromFile:(NSURL *)url;
@property (readonly) uint64_t romFingerprint;
@property (readonly) RomRevision romRevision;
@property (readonly, copy) NSString *romTitle;
@property (readonly, copy) NSString *romVersion;
@property (readonly, copy) NSString *romReleased;

@property (readonly) BOOL hasExt;
- (void) deleteExt;
- (BOOL) isExt:(NSURL *)url;
- (BOOL) loadExtFromBuffer:(NSData *)buffer;
- (BOOL) loadExtFromFile:(NSURL *)url;
@property (readonly) uint64_t extFingerprint;
@property (readonly) RomRevision extRevision;
@property (readonly, copy) NSString *extTitle;
@property (readonly, copy) NSString *extVersion;
@property (readonly, copy) NSString *extReleased;
@property (readonly) NSInteger extStart;

- (MemorySource *) getMemSrcTable; 
- (MemorySource) memSrc:(NSInteger)addr;
- (NSInteger) spypeek8:(NSInteger)addr;
- (NSInteger) spypeek16:(NSInteger)addr;

- (NSString *) ascii:(NSInteger)addr;
- (NSString *) hex:(NSInteger)addr bytes:(NSInteger)bytes;

@end


//
// AgnusProxy Proxy
//

@interface AgnusProxy : NSObject {
    
    struct AgnusWrapper *wrapper;
}

@property (readonly) NSInteger chipRamLimit;

- (void) dump;
- (void) dumpEvents;
- (void) dumpCopper;
- (void) dumpBlitter;

- (AgnusInfo) getInfo;
- (DMADebuggerInfo) getDebuggerInfo;
- (EventSlotInfo) getEventSlotInfo:(NSInteger)slot;
- (EventInfo) getEventInfo;
- (CopperInfo) getCopperInfo;
- (BlitterInfo) getBlitterInfo;

@property (readonly) BOOL interlaceMode;
@property (readonly, getter=isLongFrame) BOOL longFrame;
@property (readonly, getter=isShortFrame) BOOL shortFrame;

- (BOOL) isIllegalInstr:(NSInteger)addr;
- (NSInteger) instrCount:(NSInteger)list;
- (NSString *) disassemble:(NSInteger)addr;
- (NSString *) disassemble:(NSInteger)list instr:(NSInteger)offset;

- (void) dmaDebugSetEnable:(BOOL)value;
- (void) dmaDebugSetVisualize:(BusOwner)owner value:(BOOL)value;
- (void) dmaDebugSetColor:(BusOwner)owner r:(double)r g:(double)g b:(double)b;
- (void) dmaDebugSetOpacity:(double)value;
- (void) dmaDebugSetDisplayMode:(NSInteger)mode;

@end


//
// Denise Proxy
//

@interface DeniseProxy : NSObject {
    
    struct DeniseWrapper *wrapper;
}

- (void) dump;
- (DeniseInfo) getInfo;
- (SpriteInfo) getSpriteInfo:(NSInteger)nr;
- (void) inspect;

/*
- (void) pokeColorReg:(NSInteger)reg value:(UInt16)value;
*/
- (double) palette;
- (void) setPalette:(Palette)p;
@property double brightness;
@property double saturation;
@property double contrast;

- (void) setBPU:(NSInteger)count;
- (void) setBPLCONx:(NSInteger)x value:(NSInteger)value;
- (void) setBPLCONx:(NSInteger)x bit:(NSInteger)bit value:(BOOL)value;
- (void) setBPLCONx:(NSInteger)x nibble:(NSInteger)nibble value:(NSInteger)value;

- (ScreenBuffer) stableLongFrame;
- (ScreenBuffer) stableShortFrame;
- (int32_t *) noise;

@end


//
// Paula Proxy
//

@interface PaulaProxy : NSObject {
    
    struct PaulaWrapper *wrapper;
}

- (void) dump;
- (PaulaInfo) getInfo;
- (AudioInfo) getAudioInfo;
- (DiskControllerConfig) getDiskControllerConfig;
- (DiskControllerInfo) getDiskControllerInfo;
- (UARTInfo) getUARTInfo;

- (uint32_t) sampleRate;
- (void) setSampleRate:(double)rate;

@property (readonly) NSInteger ringbufferSize;
- (double) ringbufferDataL:(NSInteger)offset;
- (double) ringbufferDataR:(NSInteger)offset;
// - (double) ringbufferData:(NSInteger)offset;
@property (readonly) double fillLevel;
@property (readonly) NSInteger bufferUnderflows;
@property (readonly) NSInteger bufferOverflows;

- (void) readMonoSamples:(float *)target size:(NSInteger)n;
- (void) readStereoSamples:(float *)target1 buffer2:(float *)target2 size:(NSInteger)n;
- (void) readStereoSamplesInterleaved:(float *)target size:(NSInteger)n;

- (void) rampUp;
- (void) rampUpFromZero;
- (void) rampDown;

@end


//
// ControlPort Proxy
//

@interface ControlPortProxy : NSObject {
    
    struct AmigaControlPortWrapper *wrapper;
}

- (void) dump;
- (ControlPortInfo) getInfo;
- (void) connectDevice:(ControlPortDevice)value;

@end


//
// SerialPort Proxy
//

@interface SerialPortProxy : NSObject {

    struct AmigaSerialPortWrapper *wrapper;
}

- (void) dump;
- (SerialPortInfo) getInfo;
- (void) setDevice:(SerialPortDevice)value;

@end


//
// Mouse Proxy
//

@interface MouseProxy : NSObject {
    
    struct MouseWrapper *wrapper;
}

- (void) dump;

- (void) setXY:(NSPoint)pos;
- (void) setLeftButton:(BOOL)value;
- (void) setRightButton:(BOOL)value;

@end


//
// Joystick Proxy
//

@interface JoystickProxy : NSObject {
    
    struct JoystickWrapper *wrapper;
}

- (void) dump;

- (void) trigger:(JoystickEvent)event;
@property BOOL autofire;
@property NSInteger autofireBullets;
@property float autofireFrequency;

@end


//
// Keyboard Proxy
//

@interface KeyboardProxy : NSObject {
    
    struct KeyboardWrapper *wrapper;
}

- (void) dump;

- (BOOL) keyIsPressed:(NSInteger)keycode;
- (void) pressKey:(NSInteger)keycode;
- (void) releaseKey:(NSInteger)keycode;
- (void) releaseAllKeys;

@end


//
// DiskController Proxy
//

@interface DiskControllerProxy : NSObject {
    
    struct DiskControllerWrapper *wrapper;
}

- (void) dump;

- (BOOL) spinning:(NSInteger)nr;
- (BOOL) spinning;

// - (BOOL) isConnected:(NSInteger)nr;
- (void) setConnected:(NSInteger)nr value:(BOOL)value;

- (void) eject:(NSInteger)nr;
- (void) insert:(NSInteger)nr adf:(ADFFileProxy *)fileProxy;
- (void) setWriteProtection:(NSInteger)nr value:(BOOL)value;

@end


//
// AmigaDrive Proxy
//

@interface DriveProxy : NSObject {
    
    struct AmigaDriveWrapper *wrapper;
}

@property (readonly) struct AmigaDriveWrapper *wrapper;

- (void) dump;

@property (readonly) NSInteger nr;
@property (readonly) DriveType type;

- (BOOL) hasDisk;
- (BOOL) hasWriteProtectedDisk;
- (void) setWriteProtection:(BOOL)value;
- (void) toggleWriteProtection;

- (BOOL) hasModifiedDisk;
- (void) setModifiedDisk:(BOOL)value;

// - (void) ejectDisk;
// - (void) insertDisk:(ADFFileProxy *)file;

- (ADFFileProxy *)convertDisk;

@end


//
// F I L E   T Y P E   P R O X Y S
//

//
// AmigaFile proxy
//

@interface AmigaFileProxy : NSObject {
    
    struct AmigaFileWrapper *wrapper;
}

- (struct AmigaFileWrapper *)wrapper;

@property (readonly) AmigaFileType type;
- (void)setPath:(NSString *)path;
@property (readonly) NSInteger sizeOnDisk;

- (void)seek:(NSInteger)offset;
- (NSInteger)read;

- (void)readFromBuffer:(const void *)buffer length:(NSInteger)length;
- (NSInteger)writeToBuffer:(void *)buffer;

@end


//
// Snapshot proxy
//

@interface SnapshotProxy : AmigaFileProxy {
}

+ (BOOL)isSupportedSnapshot:(const void *)buffer length:(NSInteger)length;
+ (BOOL)isSupportedSnapshotData:(NSData *)buffer;
+ (BOOL)isUnsupportedSnapshot:(const void *)buffer length:(NSInteger)length;
+ (BOOL)isUnsupportedSnapshotData:(NSData *)buffer;
+ (BOOL)isSupportedSnapshotFile:(NSString *)path;
+ (BOOL)isUnsupportedSnapshotFile:(NSString *)path;
+ (instancetype)snapshotProxyWithData:(NSData *)buffer;
+ (instancetype)snapshotProxyWithBuffer:(const void *)buffer length:(NSInteger)length;
+ (instancetype)snapshotProxyWithFile:(NSString *)path;
+ (instancetype)snapshotProxyWithAmiga:(AmigaProxy *)amiga;

@end


//
// ADFFile proxy
//

@interface ADFFileProxy : AmigaFileProxy {
}

+ (BOOL)isADFFile:(NSString *)path;
+ (instancetype)fileProxyWithData:(NSData *)buffer;
+ (instancetype)fileProxyWithBuffer:(const void *)buffer length:(NSInteger)length;
+ (instancetype)fileProxyWithFile:(NSString *)path;
+ (instancetype)fileProxyWithDiskType:(DiskType)type;
+ (instancetype)fileProxyWithDrive:(DriveProxy *)drive;

@property (readonly) DiskType diskType;
@property (readonly) NSInteger numCylinders;
@property (readonly) NSInteger numHeads;
@property (readonly) NSInteger numTracks;
@property (readonly) NSInteger numSectors;
@property (readonly) NSInteger numSectorsPerTrack;
- (void)formatDisk:(FileSystemType)fs;
- (void)seekTrack:(NSInteger)nr;
- (void)seekSector:(NSInteger)nr;

@end

