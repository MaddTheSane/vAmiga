// -----------------------------------------------------------------------------
// This file is part of vAmiga
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

#include "Amiga.h"

RgbColor::RgbColor(const AmigaColor &c)
{
    r = ((c.rawValue >> 4) & 0xF0) / 255.0;
    g = (c.rawValue & 0xF0) / 255.0;
    b = ((c.rawValue << 4) & 0xF0) / 255.0;

}
RgbColor::RgbColor(const GpuColor &c)
{
    r = (c.rawValue & 0xFF) / 255.0;
    g = ((c.rawValue >> 8) & 0xFF) / 255.0;
    b = ((c.rawValue >> 16) & 0xFF) / 255.0;
}

RgbColor::RgbColor(const YuvColor &c)
{
    r = c.y + 1.140 * c.v;
    g = c.y - 0.395 * c.u - 0.581 * c.v;
    b = c.y + 2.032 * c.u;
}

RgbColor
RgbColor::mix(RgbColor additive, double weight)
{
    // printf("mix: old %f %f %f weight = %f\n", r, g, b, weight);
    // printf("mix: add %f %f %f\n", additive.r, additive.g, additive.b);

    assert(additive.r <= 1.0);
    assert(additive.g <= 1.0);
    assert(additive.b <= 1.0);

    double newR = r + (additive.r - r) * weight;
    double newG = g + (additive.g - g) * weight;
    double newB = b + (additive.b - b) * weight;

    // RgbColor c = RgbColor(newR, newG, newB);
    // printf("mix: new %f %f %f\n", c.r, c.g, c.b);

    return RgbColor(newR, newG, newB);
}

const RgbColor RgbColor::black(0.0, 0.0, 0.0);
const RgbColor RgbColor::white(1.0, 1.0, 1.0);
const RgbColor RgbColor::red(1.0, 0.0, 0.0);
const RgbColor RgbColor::green(0.0, 1.0, 0.0);
const RgbColor RgbColor::blue(0.0, 0.0, 1.0);
const RgbColor RgbColor::yellow(1.0, 1.0, 0.0);
const RgbColor RgbColor::magenta(1.0, 0.0, 1.0);
const RgbColor RgbColor::cyan(0.0, 1.0, 1.0);

//
//
//

YuvColor::YuvColor(const RgbColor &c)
{
    y =  0.299 * c.r + 0.587 * c.g + 0.114 * c.b;
    u = -0.147 * c.r - 0.289 * c.g + 0.436 * c.b;
    v =  0.615 * c.r - 0.515 * c.g - 0.100 * c.b;
}

const YuvColor YuvColor::black(RgbColor::black);
const YuvColor YuvColor::white(RgbColor::white);
const YuvColor YuvColor::red(RgbColor::red);
const YuvColor YuvColor::green(RgbColor::green);
const YuvColor YuvColor::blue(RgbColor::blue);
const YuvColor YuvColor::yellow(RgbColor::yellow);
const YuvColor YuvColor::magenta(RgbColor::magenta);
const YuvColor YuvColor::cyan(RgbColor::cyan);

//
//
//

AmigaColor::AmigaColor(const GpuColor &c)
{
    uint8_t r = c.rawValue & 0x0000F0;
    uint8_t g = c.rawValue & 0x00F000;
    uint8_t b = c.rawValue & 0xF00000;

    rawValue = (r << 4) | g | (b >> 4);
}

AmigaColor::AmigaColor(const struct RgbColor &c)
{
    uint8_t r = c.r * 0xF;
    uint8_t g = c.g * 0xF;
    uint8_t b = c.b * 0xF;

    rawValue = (r << 8) | (g << 4) | b;
}

const AmigaColor AmigaColor::black(RgbColor::black);
const AmigaColor AmigaColor::white(RgbColor::white);
const AmigaColor AmigaColor::red(RgbColor::red);
const AmigaColor AmigaColor::green(RgbColor::green);
const AmigaColor AmigaColor::blue(RgbColor::blue);
const AmigaColor AmigaColor::yellow(RgbColor::yellow);
const AmigaColor AmigaColor::magenta(RgbColor::magenta);
const AmigaColor AmigaColor::cyan(RgbColor::cyan);

//
//
//

GpuColor::GpuColor(const AmigaColor &c)
{
    uint8_t a = 0xFF;
    uint8_t r = c.rawValue & 0xF00;
    uint8_t g = c.rawValue & 0x0F0;
    uint8_t b = c.rawValue & 0x00F;

    rawValue = (a << 24) | (b << 20) | (g << 8) | (r >> 4);
}

GpuColor::GpuColor(const RgbColor &c)
{
    uint8_t a = 255;
    uint8_t r = c.r * 255;
    uint8_t g = c.g * 255;
    uint8_t b = c.b * 255;

    rawValue = (a << 24) | (b << 16) | (g << 8) | r;
}

GpuColor::GpuColor(uint8_t r, uint8_t g, uint8_t b)
{
    uint8_t a = 255;
    rawValue = (a << 24) | (b << 16) | (g << 8) | r;
}

const GpuColor GpuColor::black(RgbColor::black);
const GpuColor GpuColor::white(RgbColor::white);
const GpuColor GpuColor::red(RgbColor::red);
const GpuColor GpuColor::green(RgbColor::green);
const GpuColor GpuColor::blue(RgbColor::blue);
const GpuColor GpuColor::yellow(RgbColor::yellow);
const GpuColor GpuColor::magenta(RgbColor::magenta);
const GpuColor GpuColor::cyan(RgbColor::cyan);

GpuColor
GpuColor::mix(const RgbColor &color, double weight)
{
    RgbColor mixedColor = RgbColor(*this).mix(color, weight);
    return GpuColor(mixedColor);
}
