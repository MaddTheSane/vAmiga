// -----------------------------------------------------------------------------
// This file is part of vAmiga
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

#ifndef _CONTROL_PORT_INC
#define _CONTROL_PORT_INC

#include "SubComponent.h"

class ControlPort : public SubComponent {

    // Information shown in the GUI inspector panel
    ControlPortInfo info;

    // Represented control port (1 or 2)
    int nr;
    
    // Connected device
    ControlPortDevice device = CPD_NONE;
    
    // The two mouse position counters
    int64_t mouseCounterX = 0;
    int64_t mouseCounterY = 0;

    // The two potentiometer values
    uint8_t potX = 128;
    uint8_t potY = 128; 


    //
    // Constructing and destructing
    //
    
public:
    
    ControlPort(int nr, Amiga& ref);


    //
    // Iterating over snapshot items
    //

    template <class T>
    void applyToPersistentItems(T& worker)
    {
    }

    template <class T>
    void applyToResetItems(T& worker)
    {
        worker

        & mouseCounterX
        & mouseCounterY
        & potX
        & potY;
    }


    //
    // Methods from HardwareComponent
    //

private:

    void _reset() override { RESET_SNAPSHOT_ITEMS }
    void _inspect() override;
    void _dump() override;
    size_t _size() override { COMPUTE_SNAPSHOT_SIZE }
    size_t _load(uint8_t *buffer) override { LOAD_SNAPSHOT_ITEMS }
    size_t _save(uint8_t *buffer) override { SAVE_SNAPSHOT_ITEMS }

    
    //
    // Reading the internal state
    //

public:

    // Returns the latest internal state recorded by inspect()
    ControlPortInfo getInfo();

    // Getter for potX and potY
    uint8_t getPotX() { return potX; }
    uint8_t getPotY() { return potY; }
    

    //
    // Managing registers
    //
    
    public:
    
    // Returns the control port bits showing up in the POTGOR register.
    uint16_t potgor();

    // Returns the control port bits showing up in the JOYxDAT register.
    uint16_t joydat();

    // Returns the control port bits showing up in the CIAA PA register.
    uint8_t ciapa();

    // Emulates a write access to JOYTEST
    void pokeJOYTEST(uint16_t value);

    
    //
    // Connecting peripherals
    //
    
public:
    
    // Connects or disconnects a device
    void connectDevice(ControlPortDevice device);
};

#endif

