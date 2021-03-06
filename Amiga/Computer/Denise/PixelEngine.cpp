// -----------------------------------------------------------------------------
// This file is part of vAmiga
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

#include "Amiga.h"

PixelEngine::PixelEngine(Amiga& ref) : SubComponent(ref)
{
    setDescription("PixelEngine");

    // Allocate frame buffers
    for (int i = 0; i < 2; i++) {

        longFrame[i].data = new int[PIXELS];
        longFrame[i].longFrame = true;

        shortFrame[i].data = new int[PIXELS];
        shortFrame[i].longFrame = false;
    }

    // Create random background noise pattern
    const size_t noiseSize = 2 * 512 * 512;
    noise = new int[noiseSize];
    for (int i = 0; i < noiseSize; i++) {
        noise[i] = rand() % 2 ? 0x00000000 : 0x00FFFFFF;
    }

    // Setup some debug colors
    indexedRgba[64] = GpuColor(0xFF, 0x00, 0x00).rawValue;
    indexedRgba[65] = GpuColor(0xD0, 0x00, 0x00).rawValue;
    indexedRgba[66] = GpuColor(0xA0, 0x00, 0x00).rawValue;
    indexedRgba[67] = GpuColor(0x90, 0x00, 0x00).rawValue;
    indexedRgba[68] = GpuColor(0x00, 0xFF, 0xFF).rawValue;
    indexedRgba[69] = GpuColor(0x00, 0xD0, 0xD0).rawValue;
    indexedRgba[70] = GpuColor(0x00, 0xA0, 0xA0).rawValue;
    indexedRgba[71] = GpuColor(0x00, 0x90, 0x90).rawValue;
    /*
    colors[64] = 0x0F00;
    colors[65] = 0x0D00;
    colors[66] = 0x0A00;
    colors[67] = 0x0900;
    colors[68] = 0x00FF;
    colors[69] = 0x00DD;
    colors[70] = 0x00AA;
    colors[71] = 0x0099;
    */
}

PixelEngine::~PixelEngine()
{
    for (int i = 0; i < 2; i++) {

        delete[] longFrame[i].data;
        delete[] shortFrame[i].data;
    }

    delete[] noise;
}

void
PixelEngine::_powerOn()
{
    // Initialize frame buffers with a checkerboard debug pattern
    for (unsigned line = 0; line < VPIXELS; line++) {
        for (unsigned i = 0; i < HPIXELS; i++) {

            int pos = line * HPIXELS + i;
            int col = (line / 4) % 2 == (i / 8) % 2 ? 0x00222222 : 0x00444444;
            longFrame[0].data[pos] = longFrame[1].data[pos] = col;
            shortFrame[0].data[pos] = shortFrame[1].data[pos] = col;
        }
    }
}

void
PixelEngine::_reset()
{
    RESET_SNAPSHOT_ITEMS

    // Initialize frame buffers
    workingLongFrame = &longFrame[0];
    workingShortFrame = &shortFrame[0];
    stableLongFrame = &longFrame[1];
    stableShortFrame = &shortFrame[1];
    frameBuffer = &longFrame[0];

    updateRGBA();
}

void
PixelEngine::setPalette(Palette p)
{
    palette = p;
    updateRGBA();
}

void
PixelEngine::setBrightness(double value)
{
    brightness = value;
    updateRGBA();
}

void
PixelEngine::setSaturation(double value)
{
    saturation = value;
    updateRGBA();
}

void
PixelEngine::setContrast(double value)
{
    contrast = value;
    updateRGBA();

}

void
PixelEngine::setColor(int reg, uint16_t value)
{
    assert(reg < 32);

    colreg[reg] = value & 0xFFF;

    uint8_t r = (value & 0xF00) >> 8;
    uint8_t g = (value & 0x0F0) >> 4;
    uint8_t b = (value & 0x00F);

    indexedRgba[reg] = rgba[value & 0xFFF];
    indexedRgba[reg + 32] = rgba[((r / 2) << 8) | ((g / 2) << 4) | (b / 2)];
}

void
PixelEngine::updateRGBA()
{
    debug("updateRGBA\n");

    // Iterate through all 4096 colors
    for (uint16_t col = 0x000; col <= 0xFFF; col++) {

        // Convert the Amiga color into an RGBA value
        uint8_t r = (col >> 4) & 0xF0;
        uint8_t g = (col >> 0) & 0xF0;
        uint8_t b = (col << 4) & 0xF0;

        // Convert the Amiga value to an RGBA value
        adjustRGB(r, g, b);

        // Write the result into the register lookup table
        rgba[col] = HI_HI_LO_LO(0xFF, b, g, r);
    }

    // Update all RGBA values that are cached in indexedRgba[]
    for (int i = 0; i < 32; i++) setColor(i, colreg[i]);
}

void
PixelEngine::adjustRGB(uint8_t &r, uint8_t &g, uint8_t &b)
{
    // Normalize adjustment parameters
    double brightness = this->brightness - 50.0;
    double contrast = this->contrast / 100.0;
    double saturation = this->saturation / 50.0;

    // Convert RGB to YUV
    double y =  0.299 * r + 0.587 * g + 0.114 * b;
    double u = -0.147 * r - 0.289 * g + 0.436 * b;
    double v =  0.615 * r - 0.515 * g - 0.100 * b;

    // Adjust saturation
    u *= saturation;
    v *= saturation;

    // Apply contrast
    y *= contrast;
    u *= contrast;
    v *= contrast;

    // Apply brightness
    y += brightness;

    // Translate to monochrome if applicable
    switch(palette) {

        case BLACK_WHITE_PALETTE:
            u = 0.0;
            v = 0.0;
            break;

        case PAPER_WHITE_PALETTE:
            u = -128.0 + 120.0;
            v = -128.0 + 133.0;
            break;

        case GREEN_PALETTE:
            u = -128.0 + 29.0;
            v = -128.0 + 64.0;
            break;

        case AMBER_PALETTE:
            u = -128.0 + 24.0;
            v = -128.0 + 178.0;
            break;

        case SEPIA_PALETTE:
            u = -128.0 + 97.0;
            v = -128.0 + 154.0;
            break;

        default:
            assert(palette == COLOR_PALETTE);
    }

    // Convert YUV to RGB
    double newR = y             + 1.140 * v;
    double newG = y - 0.396 * u - 0.581 * v;
    double newB = y + 2.029 * u;
    newR = MAX(MIN(newR, 255), 0);
    newG = MAX(MIN(newG, 255), 0);
    newB = MAX(MIN(newB, 255), 0);

    // Apply Gamma correction for PAL models
    /*
     r = gammaCorrect(r, 2.8, 2.2);
     g = gammaCorrect(g, 2.8, 2.2);
     b = gammaCorrect(b, 2.8, 2.2);
     */

    r = uint8_t(newR);
    g = uint8_t(newG);
    b = uint8_t(newB);
}

bool
PixelEngine::isLongFrame(ScreenBuffer *buf)
{
    bool result = (buf == &longFrame[0] || buf == &longFrame[1]);
    assert(result == buf->longFrame);
    return result;
}

bool
PixelEngine::isShortFrame(ScreenBuffer *buf)
{
    bool result = (buf == &shortFrame[0] || buf == &shortFrame[1]);
    assert(result == !buf->longFrame);
    return result;
}

ScreenBuffer
PixelEngine::getStableLongFrame()
{
    pthread_mutex_lock(&lock);
    ScreenBuffer result = *stableLongFrame;
    pthread_mutex_unlock(&lock);

    return result;
}

ScreenBuffer
PixelEngine::getStableShortFrame()
{
    pthread_mutex_lock(&lock);
    ScreenBuffer result = *stableShortFrame;
    pthread_mutex_unlock(&lock);

    return result;
}

int32_t *
PixelEngine::getNoise()
{
    int offset = rand() % (512 * 512);
    return noise + offset;
}

int *
PixelEngine::pixelAddr(int pixel)
{
    int offset = pixel + agnus.pos.v * HPIXELS;

    assert(pixel < HPIXELS);
    assert(offset < PIXELS);

    return frameBuffer->data + offset;
}

void
PixelEngine::beginOfFrame(bool interlace)
{
    assert(workingLongFrame == &longFrame[0] || workingLongFrame == &longFrame[1]);
    assert(workingShortFrame == &shortFrame[0] || workingShortFrame == &shortFrame[1]);
    assert(stableLongFrame == &longFrame[0] || stableLongFrame == &longFrame[1]);
    assert(stableShortFrame == &shortFrame[0] || stableShortFrame == &shortFrame[1]);
    assert(workingLongFrame != stableLongFrame);
    assert(workingShortFrame != stableShortFrame);
    assert(frameBuffer == workingLongFrame || frameBuffer == workingShortFrame);

    pthread_mutex_lock(&lock);

    if (isLongFrame(frameBuffer)) {

        // Declare the finished buffer stable
        swap(workingLongFrame, stableLongFrame);

        // Select the next buffer to work on
        frameBuffer = interlace ? workingShortFrame : workingLongFrame;

    } else {

        assert(isShortFrame(frameBuffer));

        // Declare the finished buffer stable
        swap(workingShortFrame, stableShortFrame);

        // Select the next buffer to work on
        frameBuffer = workingLongFrame;
    }

    frameBuffer->interlace = interlace;
    
    pthread_mutex_unlock(&lock);

    dmaDebugger.vSyncHandler();
}

void
PixelEngine::endOfVBlankLine()
{
    // Apply all color register changes that happened in this line
    for (int i = colRegChanges.begin(); i != colRegChanges.end(); i = colRegChanges.next(i)) {
        applyRegisterChange(colRegChanges.change[i]);
    }
}

void
PixelEngine::applyRegisterChange(const Change &change)
{
    switch (change.addr) {

        case REG_NONE:
            break;

        default:

            // It must be a color register then
            assert(change.addr >= 0x180 && change.addr <= 0x1BE);

            // debug("Changing color reg %d to %X\n", (change.addr - 0x180) >> 1, change.value);
            setColor((change.addr - 0x180) >> 1, change.value);
            break;
    }
}

void
PixelEngine::colorize(uint8_t *src, int line)
{
    // Jump to the first pixel in the specified line in the active frame buffer
    int32_t *dst = frameBuffer->data + line * HPIXELS;
    int pixel = 0;

    // Check for HAM mode
    bool ham = denise.ham();

    // Initialize the HAM mode hold register with the current background color
    uint16_t hold = colreg[0];

    // Add a dummy register change to ensure we draw until the line end
    colRegChanges.add(HPIXELS, REG_NONE, 0);

    // Iterate over all recorded register changes
    for (int i = colRegChanges.begin(); i != colRegChanges.end(); i = colRegChanges.next(i)) {

        Change &change = colRegChanges.change[i];

        // Colorize a chunk of pixels
        if (ham) {
            colorizeHAM(src, dst, pixel, change.trigger, hold);
        } else {
            colorize(src, dst, pixel, change.trigger);
        }
        pixel = change.trigger;

        // Perform the register change
        applyRegisterChange(change);
    }

    // Wipe out the HBLANK area
    for (int pixel = 4 * 0x0F; pixel <= 4 * 0x35; pixel++) {
        dst[pixel] = rgbaHBlank;
    }

    // Clear the history cache
    colRegChanges.clear(); 
}

void
PixelEngine::colorize(uint8_t *src, int *dst, int from, int to)
{
    for (int i = from; i < to; i++) {
        dst[i] = indexedRgba[src[i]];
    }
}

void
PixelEngine::colorizeHAM(uint8_t *src, int *dst, int from, int to, uint16_t& ham)
{
    for (int i = from; i < to; i++) {

        uint8_t index = src[i];
        assert(isRgbaIndex(index));

        switch ((index >> 4) & 0b11) {

            case 0b00: // Get color from register

                ham = colreg[index];
                break;

            case 0b01: // Modify blue

                ham &= 0xFF0;
                ham |= (index & 0b1111);
                break;

            case 0b10: // Modify red

                ham &= 0x0FF;
                ham |= (index & 0b1111) << 8;
                break;

            case 0b11: // Modify green

                ham &= 0xF0F;
                ham |= (index & 0b1111) << 4;
                break;

            default:
                assert(false);
        }

        // Synthesize pixel
        dst[i] = rgba[ham];
    }
}
