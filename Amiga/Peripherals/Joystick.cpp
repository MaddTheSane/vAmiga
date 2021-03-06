/// -----------------------------------------------------------------------------
// This file is part of vAmiga
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

#include "Amiga.h"

Joystick::Joystick(int nr, Amiga& ref) : SubComponent(ref)
{
    assert(nr == 1 || nr == 2);
    
    this->nr = nr;
    setDescription(nr == 1 ? "Joystick1" : "Joystick2");
}

void
Joystick::_reset()
{
    RESET_SNAPSHOT_ITEMS

    button = false;
    axisX = 0;
    axisY = 0;
}

void
Joystick::_dump()
{
    plainmsg("Button:  %s AxisX: %d AxisY: %d\n", button ? "YES" : "NO", axisX, axisY);
}

size_t
Joystick::didLoadFromBuffer(uint8_t *buffer)
{
    // Discard any active joystick movements
    button = false;
    axisX = 0;
    axisY = 0;

    return 0;
}

void
Joystick::setAutofire(bool value)
{
    autofire = value;
    
    // Release button immediately if autofire-mode is switches off
    if (value == false) button = false;
}

void
Joystick::setAutofireBullets(int value)
{
    autofireBullets = value;
    
    // Update the bullet counter if we're currently firing
    if (bulletCounter > 0) {
        bulletCounter = (autofireBullets < 0) ? UINT64_MAX : autofireBullets;
    }
}

void
Joystick::scheduleNextShot()
{
    nextAutofireFrame = agnus.frame + (int)(50.0 / (2 * autofireFrequency));
}

uint16_t
Joystick::joydat()
{
    // debug("joydat\n");
    
    uint16_t result = 0;

    /* 15 14 13 12 11 10 09 08 07 06 05 04 03 02 01 00
     * Y7 Y6 Y5 Y4 Y3 Y2 Y1 Y0 X7 X6 X5 X4 X3 X2 X1 X0
     *
     *      Left: Y1 = 1
     *     Right: X1 = 1
     *        Up: Y0 xor Y1 = 1
     *      Down: X0 xor X1 = 1
     */

    if (axisX == -1) result |= 0x0300;
    else if (axisX == 1) result |= 0x0003;

    if (axisY == -1) result ^= 0x0100;
    else if (axisY == 1) result ^= 0x0001;

    return result;
}

uint8_t
Joystick::ciapa()
{
    // debug("ciapa\n");
    return button ? (nr == 1 ? 0xBF : 0x7F) : 0xFF;
}

void
Joystick::trigger(JoystickEvent event)
{
    assert(isJoystickEvent(event));

    debug(PORT_DEBUG, "trigger(%d)\n", event);
     
    switch (event) {
            
        case PULL_UP:    axisY = -1; break;
        case PULL_DOWN:  axisY =  1; break;
        case PULL_LEFT:  axisX = -1; break;
        case PULL_RIGHT: axisX =  1; break;
            
        case RELEASE_X:  axisX =  0; break;
        case RELEASE_Y:  axisY =  0; break;
        case RELEASE_XY: axisX = axisY = 0; break;
            
        case PRESS_FIRE:
            if (autofire) {
                if (bulletCounter) {
                    
                    // Cease fire
                    bulletCounter = 0;
                    button = false;
                    
                } else {
                
                    // Load magazine
                    bulletCounter = (autofireBullets < 0) ? UINT64_MAX : autofireBullets;
                    button = true;
                    scheduleNextShot();
                }
                
            } else {
                button = true;
            }
            break;
            
        case RELEASE_FIRE:
            if (!autofire) button = false;
            break;
            
        default:
            assert(0);
    }
}

void
Joystick::execute()
{
    if (!autofire || autofireFrequency <= 0.0)
        return;
    
    // Wait until it's time to push or release fire
    if (agnus.frame != nextAutofireFrame)
        return;
    
    // Are there any bullets left?
    if (bulletCounter) {
        if (button) {
            button = false;
            bulletCounter--;
        } else {
            button = true;
        }
        scheduleNextShot();
    }
}

