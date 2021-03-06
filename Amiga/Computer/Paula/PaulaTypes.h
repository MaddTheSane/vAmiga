// -----------------------------------------------------------------------------
// This file is part of vAmiga
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

// This file must conform to standard ANSI-C to be compatible with Swift.

#ifndef _PAULA_T_INC
#define _PAULA_T_INC

#include "DriveTypes.h"

//
// Enumerations
//

typedef enum : long
{
    FILT_NONE,
    FILT_BUTTERWORTH,
    FILT_COUNT
}
FilterType;

static inline bool isFilterType(long value) { return value >= 0 && value < FILT_COUNT; }

typedef enum : long
{
    FILTACT_POWER_LED,
    FILTACT_NEVER,
    FILTACT_ALWAYS,
    FILTACT_COUNT
}
FilterActivation;

static inline bool isFilterActivation(long value) { return value >= 0 && value < FILTACT_COUNT; }

typedef enum : long
{
    INT_TBE,
    INT_DSKBLK,
    INT_SOFT,
    INT_PORTS,
    INT_COPER,
    INT_VERTB,
    INT_BLIT,
    INT_AUD0,
    INT_AUD1,
    INT_AUD2,
    INT_AUD3,
    INT_RBF,
    INT_DSKSYN,
    INT_EXTER,
    INT_COUNT
}
IrqSource;

static inline bool isIrqSource(long value) { return value >= 0 && value < INT_COUNT; }


//
// Structures
//

typedef struct
{
    uint16_t intreq;
    uint16_t intena;
    uint16_t adkcon;
}
PaulaInfo;

typedef struct
{
    uint16_t receiveBuffer;
    uint16_t receiveShiftReg;
    uint16_t transmitBuffer;
    uint16_t transmitShiftReg;
}
UARTInfo;

typedef struct
{
    bool connected[4];
    bool useFifo;
}
DiskControllerConfig;

typedef struct
{
    int8_t selectedDrive;
    DriveState state;
    int32_t fifo[6];
    uint8_t fifoCount;
    
    uint16_t dsklen;
    uint16_t dskbytr;
    uint16_t dsksync;
    uint8_t prb;
}
DiskControllerInfo;

typedef struct
{
    long wordCount[4];
}
DiskControllerStats;

typedef struct
{
    long reads;
    long writes;
}
UARTStats;

typedef struct
{
    // The sample rate in Hz
    double sampleRate;

    // Determines when the audio filter is active
    FilterActivation filterActivation;

    // Selected audio filter type
    FilterType filterType;
}
AudioConfig;

typedef struct
{
    int8_t state;

    uint16_t audlenLatch;
    uint16_t audlen;
    uint16_t audperLatch;
    int32_t audper;
    uint16_t audvolLatch;
    uint16_t audvol;
    uint16_t auddatLatch;
    uint16_t auddat;
    uint32_t audlcLatch;
}
AudioChannelInfo;

typedef struct
{
    AudioChannelInfo channel[4];
}
AudioInfo;

#endif
