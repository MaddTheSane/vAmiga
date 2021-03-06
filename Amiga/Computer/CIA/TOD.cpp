// -----------------------------------------------------------------------------
// This file is part of vAmiga
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

#include "Amiga.h"

TOD::TOD(CIA *cia, Amiga& ref) : SubComponent(ref)
{
    setDescription("TOD");
    debug(3, "    Creating TOD at address %p...\n", this);
    
    this->cia = cia;
}

void
TOD::_powerOn()
{

}

void
TOD::_inspect()
{
    // Prevent external access to variable 'info'
    pthread_mutex_lock(&lock);
    
    info.value = tod;
    info.latch = latch;
    info.alarm = alarm;
    
    pthread_mutex_unlock(&lock);
}

void 
TOD::_dump()
{
    msg("           Counter : %02X:%02X:%02X\n", tod.hi, tod.mid, tod.lo);
    msg("             Alarm : %02X:%02X:%02X\n", alarm.hi, alarm.mid, alarm.lo);
    msg("             Latch : %02X:%02X:%02X\n", latch.hi, latch.mid, latch.lo);
    msg("            Frozen : %s\n", frozen ? "yes" : "no");
    msg("           Stopped : %s\n", stopped ? "yes" : "no");
    msg("\n");
}

void
TOD::_reset()
{
    RESET_SNAPSHOT_ITEMS
    stopped = true;
}

CounterInfo
TOD::getInfo()
{
    CounterInfo result;
    
    pthread_mutex_lock(&lock);
    result = info;
    pthread_mutex_unlock(&lock);
    
    return result;
}

void
TOD::increment()
{
    if (stopped)
    return;
    
    if (++tod.lo == 0) {
        if (++tod.mid == 0) {
            ++tod.hi;
        }
    }
    
    checkForInterrupt();
}

void
TOD::checkForInterrupt()
{
    // Quote from SAE: "hack: do not trigger alarm interrupt if KS code and both
    // tod and alarm == 0. This incorrectly triggers on non-cycle exact
    // modes. Real hardware value written to ciabtod by KS is always
    // at least 1 or larger due to bus cycle delays when reading old value."
    // Needs further investigation.
    if (cia->nr == 1 /* CIA B */ && alarm.value == 0) {
        // return;
    }
    
    if (!matching && tod.value == alarm.value) {
        cia->todInterrupt();
    }
    
    matching = (tod.value == alarm.value);
}
