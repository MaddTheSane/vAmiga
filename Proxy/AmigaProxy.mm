// -----------------------------------------------------------------------------
// This file is part of vAmiga
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

#import "AmigaProxy.h"
#import "Amiga.h"
#import "vAmiga-Swift.h"

using namespace moira;

struct AgnusWrapper { Agnus *agnus; };
struct AmigaFileWrapper { AmigaFile *file; };
struct AmigaWrapper { Amiga *amiga; };
struct BlitterWrapper { Blitter *blitter; };
struct CIAWrapper { CIA *cia; };
struct ControlPortWrapper { ControlPort *port; };
struct CopperWrapper { Copper *copper; };
struct CPUWrapper { CPU *cpu; };
struct DiskControllerWrapper { DiskController *controller; };
struct DriveWrapper { Drive *drive; };
struct DmaDebuggerWrapper { DmaDebugger *dmaDebugger; };
struct DeniseWrapper { Denise *denise; };
struct GuardsWrapper { Guards *guards; };
struct JoystickWrapper { Joystick *joystick; };
struct KeyboardWrapper { Keyboard *keyboard; };
struct MemWrapper { Memory *mem; };
struct MouseWrapper { Mouse *mouse; };
struct PaulaWrapper { Paula *paula; };
struct ScreenRecorderWrapper { ScreenRecorder *screenRecorder; };
struct SerialPortWrapper { SerialPort *port; };


//
// Guards (Breakpoints, Watchpoints)
//

@implementation GuardsProxy

- (instancetype) initWithGuards:(Guards *)guards
{
    if (self = [super init]) {
        wrapper = new GuardsWrapper();
        wrapper->guards = guards;
    }
    return self;
}
- (NSInteger) count
{
    return wrapper->guards->elements();
}
- (NSInteger) addr:(NSInteger)nr
{
    return wrapper->guards->guardAddr(nr);
}
- (BOOL) isEnabled:(NSInteger)nr
{
    return wrapper->guards->isEnabled(nr);
}
- (BOOL) isDisabled:(NSInteger)nr
{
    return wrapper->guards->isDisabled(nr);
}
- (void) enable:(NSInteger)nr
{
    wrapper->guards->enable(nr);
}
- (void) disable:(NSInteger)nr
{
    wrapper->guards->disable(nr);
}
- (void) remove:(NSInteger)nr
{
    return wrapper->guards->remove(nr);
}
- (void) replace:(NSInteger)nr addr:(NSInteger)addr
{
    wrapper->guards->replace(nr, (u32)addr);
}
- (BOOL) isSetAt:(NSInteger)addr
{
    return wrapper->guards->isSetAt((u32)addr);
}
- (BOOL) isSetAndEnabledAt:(NSInteger)addr
{
    return wrapper->guards->isSetAndEnabledAt((u32)addr);
}
- (BOOL) isSetAndDisabledAt:(NSInteger)addr
{
    return wrapper->guards->isSetAndDisabledAt((u32)addr);
}
- (void) enableAt:(NSInteger)addr
{
    wrapper->guards->enableAt((u32)addr);
}
- (void) disableAt:(NSInteger)addr
{
    wrapper->guards->disableAt((u32)addr);
}
- (void) addAt:(NSInteger)addr
{
    wrapper->guards->addAt((u32)addr);
}
- (void) removeAt:(NSInteger)addr
{
    wrapper->guards->removeAt((u32)addr);
}

@end

//
// CPU
//

@implementation CPUProxy

- (instancetype) initWithCPU:(CPU *)cpu
{
    if (self = [super init]) {
        wrapper = new CPUWrapper();
        wrapper->cpu = cpu;
    }
    return self;
}
- (void) dump
{
    wrapper->cpu->dump();
}
- (CPUInfo) getInfo
{
    return wrapper->cpu->getInfo();
}
- (i64) clock
{
    return wrapper->cpu->getMasterClock(); 
}
- (i64) cycles
{
    return wrapper->cpu->getCpuClock();
}
- (bool) isHalted
{
    return wrapper->cpu->isHalted();
}
- (NSInteger) loggedInstructions
{
    return wrapper->cpu->debugger.loggedInstructions();
}
- (void) clearLog
{
    return wrapper->cpu->debugger.clearLog();
}
- (NSString *) disassembleRecordedInstr:(NSInteger)i length:(NSInteger *)len
{
    const char *str = wrapper->cpu->disassembleRecordedInstr((int)i, len);
    return str ? [NSString stringWithUTF8String:str] : NULL;
}
- (NSString *) disassembleRecordedBytes:(NSInteger)i length:(NSInteger)len
{
    const char *str = wrapper->cpu->disassembleRecordedWords((int)i, len);
    return str ? [NSString stringWithUTF8String:str] : NULL;
}
- (NSString *) disassembleRecordedFlags:(NSInteger)i
{
    const char *str = wrapper->cpu->disassembleRecordedFlags((int)i);
    return str ? [NSString stringWithUTF8String:str] : NULL;
}
- (NSString *) disassembleRecordedPC:(NSInteger)i
{
    const char *str = wrapper->cpu->disassembleRecordedPC((int)i);
    return str ? [NSString stringWithUTF8String:str] : NULL;
}
- (NSString *) disassembleInstr:(NSInteger)addr length:(NSInteger *)len
{
    const char *str = wrapper->cpu->disassembleInstr(addr, len);
    return str ? [NSString stringWithUTF8String:str] : NULL;
}
- (NSString *) disassembleWords:(NSInteger)addr length:(NSInteger)len
{
    const char *str = wrapper->cpu->disassembleWords(addr, len);
    return str ? [NSString stringWithUTF8String:str] : NULL;
}
- (NSString *) disassembleAddr:(NSInteger)addr
{
    const char *str = wrapper->cpu->disassembleAddr(addr);
    return str ? [NSString stringWithUTF8String:str] : NULL;
}

@end


//
// CIA
//

@implementation CIAProxy

- (instancetype) initWithCIA:(CIA *)cia
{
    if (self = [super init]) {
        wrapper = new CIAWrapper();
        wrapper->cia = cia;
    }
    return self;
}
- (CIAInfo) getInfo
{
    return wrapper->cia->getInfo();
}
- (void) dumpConfig
{
    wrapper->cia->dumpConfig();
}
- (void) dump
{
    wrapper->cia->dump();
}

@end


//
// Memory
//

@implementation MemProxy

- (instancetype) initWithMemory:(Memory *)mem
{
    if (self = [super init]) {
        wrapper = new MemWrapper();
        wrapper->mem = mem;
    }
    return self;
}
- (MemoryConfig) getConfig
{
    return wrapper->mem->getConfig();
}
- (MemoryStats) getStats
{
    return wrapper->mem->getStats();
}
- (void) dump
{
    wrapper->mem->dump();
}
- (BOOL) isBootRom:(RomIdentifier)rev
{
    return RomFile::isBootRom(rev);
}
- (BOOL) isArosRom:(RomIdentifier)rev
{
    return RomFile::isArosRom(rev);
}
- (BOOL) isDiagRom:(RomIdentifier)rev
{
    return RomFile::isDiagRom(rev);
}
- (BOOL) isCommodoreRom:(RomIdentifier)rev
{
    return RomFile::isCommodoreRom(rev);
}
- (BOOL) isHyperionRom:(RomIdentifier)rev
{
    return RomFile::isHyperionRom(rev);
}
- (BOOL) hasRom
{
    return wrapper->mem->hasKickRom();
}
- (BOOL) hasBootRom
{
    return wrapper->mem->hasBootRom();
}
- (BOOL) hasKickRom
{
    return wrapper->mem->hasKickRom();
}
- (void) deleteRom
{
    wrapper->mem->deleteRom();
}
- (BOOL) isRom:(NSURL *)url
{
    return RomFile::isRomFile([url fileSystemRepresentation]);
}
- (BOOL) isEncryptedRom:(NSURL *)url
{
    return EncryptedRomFile::isEncryptedRomFile([url fileSystemRepresentation]);
}
- (BOOL) loadRomFromBuffer:(NSData *)data
{
    if (data == NULL) return NO;
    const u8 *bytes = (const u8 *)[data bytes];
    return wrapper->mem->loadRomFromBuffer(bytes, [data length]);
}
- (BOOL) loadRomFromFile:(NSURL *)url
{
    return wrapper->mem->loadRomFromFile([url fileSystemRepresentation]);
}
- (BOOL) loadEncryptedRomFromFile:(NSURL *)url error:(DecryptionError *)error
{
    return wrapper->mem->loadEncryptedRomFromFile([url fileSystemRepresentation], error);
}
- (u64) romFingerprint
{
    return wrapper->mem->romFingerprint();
}
- (RomIdentifier) romIdentifier
{
    return wrapper->mem->romIdentifier();
}
- (NSString *) romTitle
{
    const char *str = wrapper->mem->romTitle();
    return str ? [NSString stringWithUTF8String:str] : NULL;
}
- (NSString *) romVersion
{
    const char *str = wrapper->mem->romVersion();
    return str ? [NSString stringWithUTF8String:str] : NULL;
}
- (NSString *) romReleased
{
    const char *str = wrapper->mem->romReleased();
    return str ? [NSString stringWithUTF8String:str] : NULL;
}
- (BOOL) hasExt
{
    return wrapper->mem->hasExt();
}
- (void) deleteExt
{
    wrapper->mem->deleteExt();
}
- (BOOL) isExt:(NSURL *)url
{
    return ExtFile::isExtFile([url fileSystemRepresentation]);
}
- (BOOL) loadExtFromBuffer:(NSData *)data
{
    if (data == NULL) return NO;
    const u8 *bytes = (const u8 *)[data bytes];
    return wrapper->mem->loadExtFromBuffer(bytes, [data length]);
}
- (BOOL) loadExtFromFile:(NSURL *)url
{
    return wrapper->mem->loadExtFromFile([url fileSystemRepresentation]);
}
- (u64) extFingerprint
{
    return wrapper->mem->extFingerprint();
}
- (RomIdentifier) extIdentifier
{
    return wrapper->mem->extIdentifier();
}
- (NSString *) extTitle
{
    const char *str = wrapper->mem->extTitle();
    return str ? [NSString stringWithUTF8String:str] : NULL;
}
- (NSString *) extVersion
{
    const char *str = wrapper->mem->extVersion();
    return str ? [NSString stringWithUTF8String:str] : NULL;
}
- (NSString *) extReleased
{
    const char *str = wrapper->mem->extReleased();
    return str ? [NSString stringWithUTF8String:str] : NULL;
}
- (NSInteger) extStart
{
    return wrapper->mem->getConfigItem(OPT_EXT_START);
}
- (BOOL) saveWom:(NSURL *)url
{
    return wrapper->mem->saveWom([url fileSystemRepresentation]);
}
- (BOOL) saveRom:(NSURL *)url
{
    return wrapper->mem->saveRom([url fileSystemRepresentation]);
}
- (BOOL) saveExt:(NSURL *)url
{
    return wrapper->mem->saveExt([url fileSystemRepresentation]);
}
- (MemorySource) memSrc:(Accessor)accessor addr:(NSInteger)addr
{
    assert(accessor == CPU_ACCESS || accessor == AGNUS_ACCESS);
    
    if (accessor == CPU_ACCESS) {
        return wrapper->mem->getMemSrc <CPU_ACCESS> ((u32)addr);
    } else {
        return wrapper->mem->getMemSrc <AGNUS_ACCESS> ((u32)addr);
    }
}
- (NSInteger) spypeek16:(Accessor)accessor addr:(NSInteger)addr
{
    assert(accessor == CPU_ACCESS || accessor == AGNUS_ACCESS);
    
    if (accessor == CPU_ACCESS) {
        return wrapper->mem->spypeek16 <CPU_ACCESS> ((u32)addr);
    } else {
        return wrapper->mem->spypeek16 <AGNUS_ACCESS> ((u32)addr);
    }
}
- (NSString *) ascii:(Accessor)accessor addr:(NSInteger)addr
{
    assert(accessor == CPU_ACCESS || accessor == AGNUS_ACCESS);
    const char *str;

    if (accessor == CPU_ACCESS) {
        str = wrapper->mem->ascii <CPU_ACCESS> ((u32)addr);
    } else {
        str = wrapper->mem->ascii <AGNUS_ACCESS> ((u32)addr);
    }
    
    return str ? [NSString stringWithUTF8String:str] : NULL;
}
- (NSString *) hex:(Accessor)accessor addr: (NSInteger)addr bytes:(NSInteger)bytes
{
    assert(accessor == CPU_ACCESS || accessor == AGNUS_ACCESS);
    const char *str;

    if (accessor == CPU_ACCESS) {
        str = wrapper->mem->hex <CPU_ACCESS> ((u32)addr, bytes);
    } else {
        str = wrapper->mem->hex <AGNUS_ACCESS> ((u32)addr, bytes);
    }
    
    return str ? [NSString stringWithUTF8String:str] : NULL;
}

@end


//
// Agnus
//

@implementation AgnusProxy

- (instancetype) initWithAgnus:(Agnus *)agnus
{
    if (self = [super init]) {
        wrapper = new AgnusWrapper();
        wrapper->agnus = agnus;
    }
    return self;
}
- (NSInteger) chipRamLimit
{
    return wrapper->agnus->chipRamLimit();
}
- (void) dump
{
    wrapper->agnus->dump();
}
- (AgnusInfo) getInfo
{
    return wrapper->agnus->getInfo();
}
- (EventSlotInfo) getEventSlotInfo:(NSInteger)slot
{
    return wrapper->agnus->getEventSlotInfo(slot);
}
- (EventInfo) getEventInfo
{
    return wrapper->agnus->getEventInfo();
}
- (AgnusStats) getStats
{
    return wrapper->agnus->getStats();
}

@end


//
// Copper
//

@implementation CopperProxy

- (instancetype) initWithCopper:(Copper *)copper
{
    if (self = [super init]) {
        wrapper = new CopperWrapper();
        wrapper->copper = copper;
    }
    return self;
}
- (void) dump
{
    wrapper->copper->dump();
}
- (CopperInfo) getInfo
{
    return wrapper->copper->getInfo();
}
- (NSInteger) instrCount:(NSInteger)list
{
    return wrapper->copper->instrCount(list);
}
- (void) adjustInstrCount:(NSInteger)list offset:(NSInteger)offset
{
    wrapper->copper->adjustInstrCount(list, offset);
}
- (BOOL) isIllegalInstr:(NSInteger)addr
{
    return wrapper->copper->isIllegalInstr(addr);
}
- (NSString *) disassemble:(NSInteger)addr
{
    const char *str = wrapper->copper->disassemble(addr);
    return str ? [NSString stringWithUTF8String:str] : NULL;
}
- (NSString *) disassemble:(NSInteger)list instr:(NSInteger)offset
{
    const char *str = wrapper->copper->disassemble(list, offset);
    return str ? [NSString stringWithUTF8String:str] : NULL;
}

@end


//
// Blitter
//

@implementation BlitterProxy

- (instancetype) initWithBlitter:(Blitter *)blitter
{
    if (self = [super init]) {
        wrapper = new BlitterWrapper();
        wrapper->blitter = blitter;
    }
    return self;
}
- (void) dump
{
    wrapper->blitter->dump();
}
- (BlitterInfo) getInfo
{
    return wrapper->blitter->getInfo();
}

@end


//
// DMA Debugger
//

@implementation DmaDebuggerProxy

- (instancetype) initWithDmaDebugger:(DmaDebugger *)dmaDebugger
{
    if (self = [super init]) {
        wrapper = new DmaDebuggerWrapper();
        wrapper->dmaDebugger = dmaDebugger;
    }
    return self;
}
- (DMADebuggerInfo) getInfo
{
    return wrapper->dmaDebugger->getInfo();
}
- (void) setEnable:(BOOL)value
{
    wrapper->dmaDebugger->setEnabled(value);
}
- (void) visualizeCopper:(BOOL)value
{
    wrapper->dmaDebugger->visualizeCopper(value);
}
- (void) visualizeBlitter:(BOOL)value
{
    wrapper->dmaDebugger->visualizeBlitter(value);
}
- (void) visualizeDisk:(BOOL)value
{
    wrapper->dmaDebugger->visualizeDisk(value);
}
- (void) visualizeAudio:(BOOL)value
{
    wrapper->dmaDebugger->visualizeAudio(value);
}
- (void) visualizeSprite:(BOOL)value
{
    wrapper->dmaDebugger->visualizeSprite(value);
}
- (void) visualizeBitplane:(BOOL)value
{
    wrapper->dmaDebugger->visualizeBitplane(value);
}
- (void) visualizeCpu:(BOOL)value
{
    wrapper->dmaDebugger->visualizeCpu(value);
}
- (void) visualizeRefresh:(BOOL)value
{
    wrapper->dmaDebugger->visualizeRefresh(value);
}
- (void) setOpacity:(double)value
{
    wrapper->dmaDebugger->setOpacity(value);
}
- (void) setDisplayMode:(NSInteger)mode
{
    wrapper->dmaDebugger->setDisplayMode((DmaDisplayMode)mode);
}
- (void) setCopperColor:(double)r g:(double)g b:(double)b
{
    wrapper->dmaDebugger->setCopperColor(r, g, b);
}
- (void) setBlitterColor:(double)r g:(double)g b:(double)b
{
    wrapper->dmaDebugger->setBlitterColor(r, g, b);
}
- (void) setDiskColor:(double)r g:(double)g b:(double)b
{
    wrapper->dmaDebugger->setDiskColor(r, g, b);
}
- (void) setAudioColor:(double)r g:(double)g b:(double)b
{
    wrapper->dmaDebugger->setAudioColor(r, g, b);
}
- (void) setSpriteColor:(double)r g:(double)g b:(double)b
{
    wrapper->dmaDebugger->setSpriteColor(r, g, b);
}
- (void) setBitplaneColor:(double)r g:(double)g b:(double)b
{
    wrapper->dmaDebugger->setBitplaneColor(r, g, b);
}
- (void) setCpuColor:(double)r g:(double)g b:(double)b
{
    wrapper->dmaDebugger->setCpuColor(r, g, b);
}
- (void) setRefreshColor:(double)r g:(double)g b:(double)b
{
    wrapper->dmaDebugger->setRefreshColor(r, g, b);
}
@end


//
// Denise
//

@implementation DeniseProxy

- (instancetype) initWithDenise:(Denise *)denise
{
    if (self = [super init]) {
        wrapper = new DeniseWrapper();
        wrapper->denise = denise;
    }
    return self;
}
- (void) dump
{
    wrapper->denise->dump();
}
- (DeniseInfo) getInfo
{
    return wrapper->denise->getInfo();
}
- (SpriteInfo) getSpriteInfo:(NSInteger)nr
{
    return wrapper->denise->getSpriteInfo(nr);
}
- (NSInteger) sprDataLines:(NSInteger)nr
{
    return wrapper->denise->getSpriteHeight(nr);
}
- (u64) sprData:(NSInteger)nr line:(NSInteger)line
{
    return wrapper->denise->getSpriteData(nr, line);
}
- (u16) sprColor:(NSInteger)nr reg:(NSInteger)reg
{
    return wrapper->denise->getSpriteColor(nr, reg);
}
- (Palette) palette
{
   return wrapper->denise->pixelEngine.getPalette();
}
- (void) setPalette:(Palette)p
{
    wrapper->denise->pixelEngine.setPalette(p);
}
- (double) brightness
{
    return wrapper->denise->pixelEngine.getBrightness();
}
- (void) setBrightness:(double)value
{
    wrapper->denise->pixelEngine.setBrightness(value);
}
- (double) saturation
{
    return wrapper->denise->pixelEngine.getSaturation();
}
- (void) setSaturation:(double)value
{
    wrapper->denise->pixelEngine.setSaturation(value);
}
- (double) contrast
{
    return wrapper->denise->pixelEngine.getContrast();
}
- (void) setContrast:(double)value
{
    wrapper->denise->pixelEngine.setContrast(value);
}
- (ScreenBuffer) stableBuffer
{
    return wrapper->denise->pixelEngine.getStableBuffer();
}
- (u32 *) noise
{
    return wrapper->denise->pixelEngine.getNoise(); 
}

@end


//
// ScreenRecorder
//

@implementation ScreenRecorderProxy

- (instancetype) initWithScreenRecorder:(ScreenRecorder *)screenRecorder
{
    if (self = [super init]) {
        wrapper = new ScreenRecorderWrapper();
        wrapper->screenRecorder = screenRecorder;
    }
    return self;
}
- (BOOL) hasFFmpeg
{
    return wrapper->screenRecorder->hasFFmpeg();
}
- (BOOL) recording
{
    return wrapper->screenRecorder->isRecording();
}
- (NSInteger) recordCounter
{
    return wrapper->screenRecorder->getRecordCounter();
}
- (BOOL) startRecording:(NSRect)rect
                bitRate:(NSInteger)rate
                aspectX:(NSInteger)aspectX
                aspectY:(NSInteger)aspectY
{
    int x1 = (int)rect.origin.x;
    int y1 = (int)rect.origin.y;
    int x2 = x1 + (int)rect.size.width;
    int y2 = y1 + (int)rect.size.height;

    return wrapper->screenRecorder->startRecording(x1, y1, x2, y2,
                                                   rate,
                                                   aspectX,
                                                   aspectY);
}
- (void) stopRecording
{
    wrapper->screenRecorder->stopRecording();
}
- (BOOL) exportAs:(NSString *)path
{
    return wrapper->screenRecorder->exportAs([path fileSystemRepresentation]);
}

@end


//
// Paula
//

@implementation PaulaProxy

- (instancetype) initWithPaula:(Paula *)paula
{
    if (self = [super init]) {
        wrapper = new PaulaWrapper();
        wrapper->paula = paula;
    }
    return self;
}
- (PaulaInfo) getInfo
{
    return wrapper->paula->getInfo();
}
- (AudioInfo) getAudioInfo
{
    return wrapper->paula->getAudioInfo();
}
- (MuxerStats) getMuxerStats
{
    return wrapper->paula->muxer.getStats();
}
- (UARTInfo) getUARTInfo
{
    return wrapper->paula->uart.getInfo();
}
- (void) dump
{
    wrapper->paula->muxer.dump();
}
- (u32) sampleRate
{
    return (u32)wrapper->paula->muxer.getSampleRate();
}
- (void) setSampleRate:(double)rate
{
    wrapper->paula->muxer.setSampleRate(rate);
}
- (void) readMonoSamples:(float *)target size:(NSInteger)n
{
    wrapper->paula->muxer.copyMono(target, n);
}
- (void) readStereoSamples:(float *)target1 buffer2:(float *)target2 size:(NSInteger)n
{
    wrapper->paula->muxer.copyStereo(target1, target2, n);
}
- (void) rampUp
{
    wrapper->paula->muxer.rampUp();
}
- (void) rampUpFromZero
{
    wrapper->paula->muxer.rampUpFromZero();
}
- (void) rampDown
{
    wrapper->paula->muxer.rampDown();
}
- (float) drawWaveformL:(unsigned *)buffer w:(NSInteger)w h:(NSInteger)h scale:(float)s color:(unsigned)c
{
    return wrapper->paula->muxer.stream.draw(buffer, w, h, true, s, c);
}
- (float) drawWaveformL:(unsigned *)buffer size:(NSSize)size scale:(float)s color:(unsigned)c
{
    return [self drawWaveformL:buffer
                             w:(NSInteger)size.width
                             h:(NSInteger)size.height
                         scale:s
                         color:c];
}
- (float) drawWaveformR:(unsigned *)buffer w:(NSInteger)w h:(NSInteger)h scale:(float)s color:(unsigned)c
{
    return wrapper->paula->muxer.stream.draw(buffer, w, h, false, s, c);
}
- (float) drawWaveformR:(unsigned *)buffer size:(NSSize)size scale:(float)s color:(unsigned)c
{
    return [self drawWaveformR:buffer
                             w:(NSInteger)size.width
                             h:(NSInteger)size.height
                         scale:s
                         color:c];
}

@end


//
// Control port
//

@implementation ControlPortProxy

- (instancetype) initWithControlPort:(ControlPort *)port
{
    if (self = [super init]) {
        wrapper = new ControlPortWrapper();
        wrapper->port = port;
    }
    return self;
}

- (void) dump
{
    wrapper->port->dump();
}
- (ControlPortInfo) getInfo
{
    return wrapper->port->getInfo();
}
- (void) connectDevice:(ControlPortDevice)value
{
    wrapper->port->connectDevice(value);
}

@end


//
// Serial port
//

@implementation SerialPortProxy

- (instancetype) initWithSerialPort:(SerialPort *)port
{
    if (self = [super init]) {
        wrapper = new SerialPortWrapper();
        wrapper->port = port;
    }
    return self;
}

- (void) dump
{
    wrapper->port->dump();
}
- (SerialPortInfo) getInfo
{
    return wrapper->port->getInfo();
}

@end


//
// Mouse
//

@implementation MouseProxy

- (instancetype) initWithMouse:(Mouse *)mouse
{
    if (self = [super init]) {
        wrapper = new MouseWrapper();
        wrapper->mouse = mouse;
    }
    return self;
}
- (void) dump
{
    wrapper->mouse->dump();
}
- (void) setXY:(NSPoint)pos
{
    wrapper->mouse->setXY((double)pos.x, (double)pos.y);
}
- (void) setDeltaXY:(NSPoint)pos
{
    wrapper->mouse->setDeltaXY((double)pos.x, (double)pos.y);
}
- (void) trigger:(GamePadAction)event
{
    wrapper->mouse->trigger(event);
}

@end


//
// Joystick
//

@implementation JoystickProxy

- (instancetype) initWithJoystick:(Joystick *)joystick
{
    if (self = [super init]) {
        wrapper = new JoystickWrapper();
        wrapper->joystick = joystick;
    }
    return self;
}
- (void) dump
{
    wrapper->joystick->dump();
}
- (void) trigger:(GamePadAction)event
{
    wrapper->joystick->trigger(event);
}
- (BOOL) autofire
{
    return wrapper->joystick->getAutofire();
}
- (void) setAutofire:(BOOL)value
{
    return wrapper->joystick->setAutofire(value);
}
- (NSInteger) autofireBullets
{
    return (NSInteger)wrapper->joystick->getAutofireBullets();
}
- (void) setAutofireBullets:(NSInteger)value
{
    wrapper->joystick->setAutofireBullets((int)value);
}
- (float) autofireFrequency
{
    return wrapper->joystick->getAutofireFrequency();
}
- (void) setAutofireFrequency:(float)value
{
    wrapper->joystick->setAutofireFrequency(value);
}

@end


//
// Keyboard
//

@implementation KeyboardProxy

- (instancetype) initWithKeyboard:(Keyboard *)keyboard
{
    if (self = [super init]) {
        wrapper = new KeyboardWrapper();
        wrapper->keyboard = keyboard;
    }
    return self;
}
- (void) dump
{
    wrapper->keyboard->dump();
}
- (BOOL) keyIsPressed:(NSInteger)keycode
{
    return wrapper->keyboard->keyIsPressed(keycode);
}
- (void) pressKey:(NSInteger)keycode
{
    wrapper->keyboard->pressKey(keycode);
}
- (void) releaseKey:(NSInteger)keycode
{
    wrapper->keyboard->releaseKey(keycode);
}
- (void) releaseAllKeys
{
    wrapper->keyboard->releaseAllKeys();
}

@end


//
// Disk Controller
//

@implementation DiskControllerProxy

- (instancetype) initWithDiskController:(DiskController *)controller
{
    if (self = [super init]) {
        wrapper = new DiskControllerWrapper();
        wrapper->controller = controller;
    }
    return self;
}
- (void) dump
{
    wrapper->controller->dump();
}
- (DiskControllerConfig) getConfig
{
    return wrapper->controller->getConfig();
}
- (DiskControllerInfo) getInfo
{
    return wrapper->controller->getInfo();
}
- (NSInteger) selectedDrive
{
    return wrapper->controller->getSelected();
}
- (DriveState) state
{
    return wrapper->controller->getState();
}
- (BOOL) isSpinning
{
    return wrapper->controller->spinning();
}
/*
- (BOOL) connected:(NSInteger)nr
{
    return wrapper->controller->isConnected(nr);
}
- (BOOL) disconnected:(NSInteger)nr
{
    return wrapper->controller->isDisconnected(nr);
}
- (void) setConnected:(NSInteger)nr value:(BOOL)value;
{
    wrapper->controller->setConnected(nr, value);
}
*/
- (void) eject:(NSInteger)nr
{
    wrapper->controller->ejectDisk(nr);
}
- (void) insert:(NSInteger)nr adf:(ADFFileProxy *)fileProxy
{
    AmigaFileWrapper *fileWrapper = [fileProxy wrapper];
    wrapper->controller->insertDisk((ADFFile *)(fileWrapper->file), nr);
}
- (void) insert:(NSInteger)nr dms:(ADFFileProxy *)fileProxy
{
    AmigaFileWrapper *fileWrapper = [fileProxy wrapper];
    wrapper->controller->insertDisk((DMSFile *)(fileWrapper->file), nr);
}
- (void) insert:(NSInteger)nr img:(ADFFileProxy *)fileProxy
{
    AmigaFileWrapper *fileWrapper = [fileProxy wrapper];
    wrapper->controller->insertDisk((IMGFile *)(fileWrapper->file), nr);
}
- (void) setWriteProtection:(NSInteger)nr value:(BOOL)value
{
    wrapper->controller->setWriteProtection(nr, value);
}

@end


//
// Drive
//

@implementation DriveProxy

@synthesize wrapper;

- (instancetype) initWithDrive:(Drive *)drive
{
    if (self = [super init]) {
        wrapper = new DriveWrapper();
        wrapper->drive = drive;
    }
    return self;
}
- (DriveInfo) getInfo
{
    return wrapper->drive->getInfo();
}
- (NSInteger) nr
{
    return wrapper->drive->getNr();
}
- (void) dump
{
    wrapper->drive->dump();
}
- (BOOL) hasDisk
{
    return wrapper->drive->hasDisk();
}
- (BOOL) hasWriteProtectedDisk
{
    return wrapper->drive->hasWriteProtectedDisk();
}
- (void) setWriteProtection:(BOOL)value
{
    wrapper->drive->setWriteProtection(value);
}
- (void) toggleWriteProtection
{
    wrapper->drive->toggleWriteProtection();
}
- (BOOL) isModifiedDisk
{
    return wrapper->drive->hasModifiedDisk();
}
- (void) setModifiedDisk:(BOOL)value
{
    wrapper->drive->setModifiedDisk(value);
}
- (BOOL) motor
{
    return wrapper->drive->getMotor();
}
- (NSInteger) cylinder
{
    return wrapper->drive->getCylinder();
}
- (u64) fnv
{
    return wrapper->drive->fnv();
}
- (ADFFileProxy *)convertDisk
{
    return NULL;
}


@end


//
// AmigaFile
//

@implementation AmigaFileProxy

- (instancetype) initWithFile:(AmigaFile *)file
{
    if (file == nil) {
        return nil;
    }
    if (self = [super init]) {
        wrapper = new AmigaFileWrapper();
        wrapper->file = file;
    }
    return self;
}
+ (AmigaFileProxy *) makeWithFile:(AmigaFile *)file
{
    if (file == nil) {
        return nil;
    }
    return [[self alloc] initWithFile:file];
}
- (void)setPath:(NSString *)path
{
    AmigaFile *file = (AmigaFile *)([self wrapper]->file);
    file->setPath([path fileSystemRepresentation]);
}
- (AmigaFileWrapper *)wrapper
{
    return wrapper;
}
- (AmigaFileType)type
{
    return wrapper->file->fileType();
}
- (NSInteger) sizeOnDisk
{
    return wrapper->file->sizeOnDisk();
}
- (u64) fnv
{
    return wrapper->file->fnv();
}
- (void) seek:(NSInteger)offset
{
    wrapper->file->seek(offset);
}
- (NSInteger)read
{
    return wrapper->file->read();
}
- (void) readFromBuffer:(const void *)buffer length:(NSInteger)length
{
    wrapper->file->readFromBuffer((const u8 *)buffer, length);
}
- (NSInteger) writeToBuffer:(void *)buffer
{
    return wrapper->file->writeToBuffer((u8 *)buffer);
}

+ (instancetype)makeWithBuffer:(const void *)buffer length:(NSInteger)length
{
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

+ (instancetype)makeWithData:(NSData *)buffer
{
    return [self makeWithBuffer:buffer.bytes length:buffer.length];
}

- (void) dealloc
{
    if (wrapper) {
        if (wrapper->file) delete wrapper->file;
        delete wrapper;
    }
}

@end


//
// Snapshot
//

@implementation SnapshotProxy

+ (BOOL) isSupportedSnapshot:(const void *)buffer length:(NSInteger)length
{
    return Snapshot::isSupportedSnapshot((u8 *)buffer, length);
}
+ (BOOL) isUnsupportedSnapshot:(const void *)buffer length:(NSInteger)length
{
    return Snapshot::isUnsupportedSnapshot((u8 *)buffer, length);
}
+ (BOOL) isSupportedSnapshotFile:(NSString *)path
{
    return Snapshot::isSupportedSnapshotFile([path fileSystemRepresentation]);
}
+ (BOOL) isUnsupportedSnapshotFile:(NSString *)path
{
    return Snapshot::isUnsupportedSnapshotFile([path fileSystemRepresentation]);
}
+ (instancetype) make:(Snapshot *)snapshot
{
    if (snapshot == NULL) { return nil; }
    
    SnapshotProxy *proxy = [[self alloc] initWithFile:snapshot];
    proxy->preview = NULL;
    
    return proxy;
}
+ (instancetype) makeWithBuffer:(const void *)buffer length:(NSInteger)length
{
    Snapshot *snapshot = Snapshot::makeWithBuffer((u8 *)buffer, length);
    return [self make:snapshot];
}
+ (instancetype) makeWithFile:(NSString *)path
{
    Snapshot *snapshot = Snapshot::makeWithFile([path fileSystemRepresentation]);
    return [self make:snapshot];
}
+ (instancetype) makeWithAmiga:(AmigaProxy *)proxy
{
    Amiga *amiga = [proxy wrapper]->amiga;
    
    amiga->suspend();
    Snapshot *snapshot = Snapshot::makeWithAmiga(amiga);
    amiga->resume();
    
    return [self make:snapshot];
}
- (NSImage *)previewImage
{
    if (preview != NULL) { return preview; }
    
    // Create preview image
    Snapshot *snapshot = (Snapshot *)wrapper->file;
    
    NSInteger width = snapshot->getImageWidth();
    NSInteger height = snapshot->getImageHeight();
    unsigned char *data = snapshot->getImageData();
    
    
    NSBitmapImageRep *rep = [[NSBitmapImageRep alloc]
                             initWithBitmapDataPlanes:&data
                             pixelsWide:width
                             pixelsHigh:height
                             bitsPerSample:8
                             samplesPerPixel:4
                             hasAlpha:true
                             isPlanar:false
                             colorSpaceName:NSCalibratedRGBColorSpace
                             bytesPerRow:4*width
                             bitsPerPixel:32];
    
    preview = [[NSImage alloc] initWithSize:[rep size]];
    [preview addRepresentation:rep];
    
    // image.makeGlossy()

    return preview;
}
- (time_t)timeStamp
{
    return ((Snapshot *)wrapper->file)->getTimestamp();
}
- (NSData *)data
{
    Snapshot *snapshot = (Snapshot *)wrapper->file;
    return [NSData dataWithBytes: (void *)snapshot->getHeader()
                          length: snapshot->sizeOnDisk()];
}
    
@end


//
// DiskFileProxy
//

@implementation DiskFileProxy

- (DiskType)diskType
{
    return ((DiskFile *)wrapper->file)->getDiskType();
}
- (NSInteger)numSides
{
    return ((DiskFile *)wrapper->file)->numSides();
}
- (NSInteger)numCylinders
{
    return ((DiskFile *)wrapper->file)->numCyclinders();
}
- (NSInteger)numTracks
{
    return ((DiskFile *)wrapper->file)->numTracks();
}
- (NSInteger)numSectorsPerTrack
{
    return ((DiskFile *)wrapper->file)->numSectorsPerTrack();
}
- (NSInteger)numSectorsTotal
{
    return ((DiskFile *)wrapper->file)->numSectorsTotal();
}

@end


//
// ADFFileProxy
//

@implementation ADFFileProxy

+ (BOOL)isADFFile:(NSString *)path
{
    return ADFFile::isADFFile([path fileSystemRepresentation]);
}
+ (instancetype) make:(ADFFile *)archive
{
    if (archive == NULL) return nil;
    return [[self alloc] initWithFile:archive];
}
+ (instancetype) makeWithBuffer:(const void *)buffer length:(NSInteger)length
{
    ADFFile *archive = ADFFile::makeWithBuffer((const u8 *)buffer, length);
    return [self make: archive];
}
+ (instancetype) makeWithFile:(NSString *)path
{
    ADFFile *archive = ADFFile::makeWithFile([path fileSystemRepresentation]);
    return [self make: archive];
}
+ (instancetype) makeWithDiskType:(DiskType)type
{
    ADFFile *archive = ADFFile::makeWithDiskType(type);
    return [self make: archive];
}
+ (instancetype) makeWithDrive:(DriveProxy *)drive
{
    Drive *d = [drive wrapper]->drive;
    ADFFile *archive = ADFFile::makeWithDisk(d->disk);
    return archive ? [self make: archive] : nil;
}
- (void)formatDisk:(FileSystemType)fs
{
    ((ADFFile *)wrapper->file)->formatDisk(fs);
}

@end


//
// DMSFileProxy
//

@implementation DMSFileProxy

+ (BOOL)isDMSFile:(NSString *)path
{
    return DMSFile::isDMSFile([path fileSystemRepresentation]);
}
+ (instancetype) make:(DMSFile *)archive
{
    if (archive == NULL) return nil;
    return [[self alloc] initWithFile:archive];
}
+ (instancetype) makeWithBuffer:(const void *)buffer length:(NSInteger)length
{
    DMSFile *archive = DMSFile::makeWithBuffer((const u8 *)buffer, length);
    return [self make: archive];
}
+ (instancetype) makeWithFile:(NSString *)path
{
    DMSFile *archive = DMSFile::makeWithFile([path fileSystemRepresentation]);
    return [self make: archive];
}

- (ADFFileProxy *)adf
{
    DMSFile *archive = (DMSFile *)wrapper->file;
    return [ADFFileProxy make:archive->adf];
}

@end


//
// IMGFileProxy
//

@implementation IMGFileProxy

+ (BOOL)isIMGFile:(NSString *)path
{
    return IMGFile::isIMGFile([path fileSystemRepresentation]);
}
+ (instancetype) make:(IMGFile *)archive
{
    if (archive == NULL) return nil;
    return [[self alloc] initWithFile:archive];
}
+ (instancetype) makeWithBuffer:(const void *)buffer length:(NSInteger)length
{
    IMGFile *archive = IMGFile::makeWithBuffer((const u8 *)buffer, length);
    return [self make: archive];
}
+ (instancetype) makeWithFile:(NSString *)path
{
    IMGFile *archive = IMGFile::makeWithFile([path fileSystemRepresentation]);
    return [self make: archive];
}
+ (instancetype) makeWithDrive:(DriveProxy *)drive
{
    Drive *d = [drive wrapper]->drive;
    IMGFile *archive = IMGFile::makeWithDisk(d->disk);
    return archive ? [self make: archive] : nil;
}
- (DiskType)diskType
{
    return ((IMGFile *)wrapper->file)->getDiskType();
}
- (NSInteger)numCylinders
{
    return ((IMGFile *)wrapper->file)->numCyclinders();
}
- (NSInteger)numHeads
{
    return 2;
}
- (NSInteger)numTracks
{
    return ((IMGFile *)wrapper->file)->numTracks();
}
- (NSInteger)numSectors
{
    return ((IMGFile *)wrapper->file)->numSectorsTotal();
}
- (NSInteger)numSectorsPerTrack
{
    return ((IMGFile *)wrapper->file)->numSectorsPerTrack();
}
- (u64) fnv
{
    return ((IMGFile *)wrapper->file)->fnv();
}

@end


//
// Amiga
//

@implementation AmigaProxy

@synthesize wrapper;
@synthesize agnus;
@synthesize blitter;
@synthesize breakpoints;
@synthesize ciaA;
@synthesize ciaB;
@synthesize controlPort1;
@synthesize controlPort2;
@synthesize copper;
@synthesize cpu;
@synthesize denise;
@synthesize df0;
@synthesize df1;
@synthesize df2;
@synthesize df3;
@synthesize diskController;
@synthesize dmaDebugger;
@synthesize joystick1;
@synthesize joystick2;
@synthesize keyboard;
@synthesize mem;
@synthesize mouse1;
@synthesize mouse2;
@synthesize paula;
@synthesize serialPort;
@synthesize screenRecorder;
@synthesize watchpoints;

- (instancetype) init
{
    NSLog(@"AmigaProxy::init");
    
    if (!(self = [super init]))
        return self;
    
    Amiga *amiga = new Amiga();
    wrapper = new AmigaWrapper();
    wrapper->amiga = amiga;
    
    // Create sub proxys
    agnus = [[AgnusProxy alloc] initWithAgnus:&amiga->agnus];
    blitter = [[BlitterProxy alloc] initWithBlitter:&amiga->agnus.blitter];
    breakpoints = [[GuardsProxy alloc] initWithGuards:&amiga->cpu.debugger.breakpoints];
    ciaA = [[CIAProxy alloc] initWithCIA:&amiga->ciaA];
    ciaB = [[CIAProxy alloc] initWithCIA:&amiga->ciaB];
    controlPort1 = [[ControlPortProxy alloc] initWithControlPort:&amiga->controlPort1];
    controlPort2 = [[ControlPortProxy alloc] initWithControlPort:&amiga->controlPort2];
    copper = [[CopperProxy alloc] initWithCopper:&amiga->agnus.copper];
    cpu = [[CPUProxy alloc] initWithCPU:&amiga->cpu];
    denise = [[DeniseProxy alloc] initWithDenise:&amiga->denise];
    df0 = [[DriveProxy alloc] initWithDrive:&amiga->df0];
    df1 = [[DriveProxy alloc] initWithDrive:&amiga->df1];
    df2 = [[DriveProxy alloc] initWithDrive:&amiga->df2];
    df3 = [[DriveProxy alloc] initWithDrive:&amiga->df3];
    diskController = [[DiskControllerProxy alloc] initWithDiskController:&amiga->paula.diskController];
    dmaDebugger = [[DmaDebuggerProxy alloc] initWithDmaDebugger:&amiga->agnus.dmaDebugger];
    joystick1 = [[JoystickProxy alloc] initWithJoystick:&amiga->joystick1];
    joystick2 = [[JoystickProxy alloc] initWithJoystick:&amiga->joystick2];
    keyboard = [[KeyboardProxy alloc] initWithKeyboard:&amiga->keyboard];
    mem = [[MemProxy alloc] initWithMemory:&amiga->mem];
    mouse1 = [[MouseProxy alloc] initWithMouse:&amiga->mouse1];
    mouse2 = [[MouseProxy alloc] initWithMouse:&amiga->mouse2];
    paula = [[PaulaProxy alloc] initWithPaula:&amiga->paula];
    screenRecorder = [[ScreenRecorderProxy alloc] initWithScreenRecorder:&amiga->denise.screenRecorder];
    serialPort = [[SerialPortProxy alloc] initWithSerialPort:&amiga->serialPort];
    watchpoints = [[GuardsProxy alloc] initWithGuards:&amiga->cpu.debugger.watchpoints];

    return self;
}

- (void) kill
{
    assert(wrapper->amiga != NULL);
    NSLog(@"AmigaProxy::kill");
    
    // Kill the emulator
    delete wrapper->amiga;
    wrapper->amiga = NULL;
}

- (BOOL) isReleaseBuild
{
    return releaseBuild();
}
- (BOOL) debugMode
{
    return wrapper->amiga->inDebugMode();
}
- (void) enableDebugging
{
    wrapper->amiga->enableDebugMode();
}
- (void) disableDebugging
{
    wrapper->amiga->disableDebugMode();
}
- (void) setInspectionTarget:(EventID)id
{
    wrapper->amiga->setInspectionTarget(id);
}
- (void) clearInspectionTarget
{
    wrapper->amiga->clearInspectionTarget();
}
- (BOOL) isReady:(ErrorCode *)error
{
    return wrapper->amiga->isReady(error);
}
- (BOOL) isReady
{
    return wrapper->amiga->isReady();
}
- (void) powerOn
{
    wrapper->amiga->powerOn();
}
- (void) powerOff
{
    wrapper->amiga->powerOff();
}
- (void) hardReset
{
    wrapper->amiga->reset(true);
}
- (void) softReset
{
    wrapper->amiga->reset(false);
}
- (void) dump
{
    wrapper->amiga->dump();
}
- (AmigaInfo) getInfo
{
    return wrapper->amiga->getInfo();
}
- (BOOL) isPoweredOn
{
    return wrapper->amiga->isPoweredOn();
}
- (BOOL) isPoweredOff
{
    return wrapper->amiga->isPoweredOff();
}
- (BOOL) isRunning
{
    return wrapper->amiga->isRunning();
}
- (BOOL) isPaused
{
    return wrapper->amiga->isPaused();
}
- (void) run
{
    wrapper->amiga->run();
}
- (void) pause
{
    wrapper->amiga->pause();
}
- (void) suspend
{
    return wrapper->amiga->suspend();
}
- (void) resume
{
    return wrapper->amiga->resume();
}
- (void) requestAutoSnapshot
{
    wrapper->amiga->requestAutoSnapshot();
}
- (void) requestUserSnapshot
{
    wrapper->amiga->requestUserSnapshot();
}
- (SnapshotProxy *) latestAutoSnapshot
{
    Snapshot *snapshot = wrapper->amiga->latestAutoSnapshot();
    return [SnapshotProxy make:snapshot];
}
- (SnapshotProxy *) latestUserSnapshot
{
    Snapshot *snapshot = wrapper->amiga->latestUserSnapshot();
    return [SnapshotProxy make:snapshot];
}
- (void) loadFromSnapshot:(SnapshotProxy *)proxy
{
    Snapshot *snapshot = (Snapshot *)([proxy wrapper]->file);
    wrapper->amiga->loadFromSnapshotSafe(snapshot);
}
- (AmigaConfiguration) config
{
    return wrapper->amiga->getConfig();
}
- (NSInteger) getConfig:(ConfigOption)opt
{
    return wrapper->amiga->getConfigItem(opt);
}
- (NSInteger) getConfig:(ConfigOption)opt drive:(NSInteger)nr
{
    return wrapper->amiga->getConfigItem(nr, opt);
}
- (BOOL) configure:(ConfigOption)opt value:(NSInteger)val
{
    return wrapper->amiga->configure(opt, val);
}
- (BOOL) configure:(ConfigOption)opt enable:(BOOL)val
{
    return wrapper->amiga->configure(opt, val ? 1 : 0);
}
- (BOOL) configure:(ConfigOption)opt drive:(NSInteger)nr value:(NSInteger)val
{
    return wrapper->amiga->configure(nr, opt, val);
}
- (BOOL) configure:(ConfigOption)opt drive:(NSInteger)nr  enable:(BOOL)val
{
    return wrapper->amiga->configure(nr, opt, val ? 1 : 0);
}
- (void) addListener:(const void *)sender function:(Callback *)func
{
    wrapper->amiga->messageQueue.addListener(sender, func);
}
- (void) removeListener:(const void *)sender
{
    wrapper->amiga->messageQueue.removeListener(sender);
}
- (Message)message
{
    return wrapper->amiga->messageQueue.get();
}
- (void) stopAndGo
{
    wrapper->amiga->stopAndGo();
}
- (void) stepInto
{
    wrapper->amiga->stepInto();
}
- (void) stepOver
{
    wrapper->amiga->stepOver();
}
- (BOOL) warp
{
    return wrapper->amiga->inWarpMode();
}
- (void) warpOn
{
    wrapper->amiga->setWarp(true);
}
- (void) warpOff
{
    wrapper->amiga->setWarp(false);
}

@end
