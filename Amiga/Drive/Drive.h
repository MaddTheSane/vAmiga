// -----------------------------------------------------------------------------
// This file is part of vAmiga
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

#ifndef _AMIGA_DRIVE_INC
#define _AMIGA_DRIVE_INC

#include "SubComponent.h"
#include "Disk.h"

class Drive : public SubComponent {
    
    friend class DiskController;
        
    // Drive number (0 = df0, 1 = df1, 2 = df2, 3 = df3)
    long nr = 0;

    // The current configuration
    DriveConfig config;

    // Position of the currently transmitted identification bit
    uint8_t idCount;

    // Value of the currently transmitted identification bit
    bool idBit;

    
    /* The latched MTR bit (motor control bit)
     * Each drive latches the motor signal at the time it is selected (i.e.,
     * when the SELx line is pulled down to 0). The disk drive motor stays in
     * this state until the drive is selected again. This bit also controls the
     * activity light on the front of the disk drive.
     */
    // bool mtr;
    
    /* Indicates if the motor is running at full speed
     * On a real drive, it can take up to one half second (500ms) until the
     * drive runs at full speed. We don't emulate  accurate timing here and
     * set the variable to true once the drive motor is switched on.
     *
     * TODO: MAKE it A COMPUTED VALUE:
     * bool motor() { motorOffCycle >= motorOnCycle; }
     */
    bool motor;

    // Records when the drive motor was switch on the last time
    Cycle motorOnCycle;

    // Records when the drive motor was switch off the last time
    Cycle motorOffCycle;

    /* Disk change status
     * This variable controls the /CHNG bit in the CIA A PRA register. Note
     * that the variable only changes its value under certain circumstances.
     * If a head movement pulse is sent and no disk is inserted, the variable
     * is set to false (which is also the reset value). It becomes true when
     * a disk is ejected.
     */
    bool dskchange;
    
    // A copy of the DSKLEN register
    uint8_t dsklen;
    
    // A copy of the PRB register of CIA B
    uint8_t prb;
    
    // The current drive head location
    struct {
        uint8_t side;
        uint8_t cylinder;
        uint16_t offset;
    } head;
    
    /* History buffer storing the most recently visited tracks.
     * The buffer is used to detect the polling head movements that are issued
     * by track disc device to detect a newly inserted disk.
     */
    uint64_t cylinderHistory;
    
public:
    
    // The currently inserted disk (NULL if the drive is empty)
    Disk *disk = NULL;
    

    //
    // Iterating over snapshot items
    //

    template <class T>
    void applyToPersistentItems(T& worker)
    {
        worker

        & config.type
        & config.speed;
    }

    template <class T>
    void applyToResetItems(T& worker)
    {
        worker

        & idCount
        & idBit
        & motor
        & motorOnCycle
        & motorOffCycle
        & dskchange
        & dsklen
        & prb
        & head.side
        & head.cylinder
        & head.offset
        & cylinderHistory;
    }


    //
    // Constructing and configuring
    //
    
public:
    
    Drive(unsigned nr, Amiga& ref);

    // Returns the current configuration
    DriveConfig getConfig() { return config; }

    // Configures the drive type
    DriveType getType() { return config.type; }
    void setType(DriveType t);

    bool isOriginal() { return config.speed == 1; }
    bool isTurbo() { return config.speed < 0; }

    // Configures the speed acceleration factor
    uint16_t getSpeed() { return config.speed; }
    void setSpeed(int16_t value);


    //
    // Methods from HardwareComponent
    //
    
private:

    void _reset() override { RESET_SNAPSHOT_ITEMS }
    void _ping() override;
    void _dumpConfig() override;
    void _dump() override;
    size_t _size() override;
    size_t _load(uint8_t *buffer) override;
    size_t _save(uint8_t *buffer) override;

    
public:
    
    //
    // Getter and setter
    //
    
    // Returns the device number (0 = df0, 1 = df1, 2 = df2, 3 = df3).
    long getNr() { return nr; }

    // Indicates whether identification mode is enabled.
    bool idMode() { return !motor; }

    /* Returns the drive identification code.
     * Each drive identifies itself by a 32 bit identification code that is
     * transmitted via the DRVRDY signal in a special identification mode. The
     * identification mode is activated by switching the drive motor on and
     * off.
     */
    uint32_t getDriveId();
    
    
    //
    // Handling the drive status register flags
    //
    
    // Returns true if this drive is currently selected
    inline bool isSelected() { return (prb & (0b1000 << nr)) == 0; }
    
    // Returns true if this drive is pushing data onto the data lines
    bool isDataSource();

    uint8_t driveStatusFlags();
    

    //
    // Operating the drive
    //
    
    // Turns the drive motor on or off.
    void setMotor(bool value);
    void switchMotorOn() { setMotor(true); }
    void switchMotorOff() { setMotor(false); }

    Cycle motorOnTime();
    Cycle motorOffTime();
    bool motorAtFullSpeed();
    bool motorStopped();
    bool motorSpeedingUp() { return motor && !motorAtFullSpeed(); }
    bool motorSlowingDown() { return !motor && !motorStopped(); }

    // Selects the active drive head (0 = lower, 1 = upper).
    void selectSide(int side);

    // Reads a value from the drive head and rotates the disk.
    uint8_t readHead();
    uint16_t readHead16();
    
    // Writes a value to the drive head and rotates the disk.
    void writeHead(uint8_t value);
    void writeHead16(uint16_t value);

    // Emulate a disk rotation (moves head to the next byte).
    void rotate();

    // Rotates the disk to the next sync mark.
    void findSyncMark();

    //
    // Moving the drive head
    //

    // Moves the drive head (0 = inwards, 1 = outwards).
    void moveHead(int dir);

    // Records a cylinder change (needed for diskPollingMode() to work)
    void recordCylinder(uint8_t cylinder);

    /* Returns true if the drive is in disk polling mode
     * Disk polling mode is detected by analyzing the movement history that
     * has been recorded by recordCylinder()
     */
    bool pollsForDisk();

    
    //
    // Handling disks
    //

    bool hasDisk() { return disk != NULL; }
    bool hasModifiedDisk() { return disk ? disk->isModified() : false; }
    void setModifiedDisk(bool value) { if (disk) disk->setModified(value); }
    
    bool hasWriteEnabledDisk();
    bool hasWriteProtectedDisk();
    void setWriteProtection(bool value); 
    void toggleWriteProtection();
    
    void ejectDisk();
    void insertDisk(Disk *disk);
    
    
    //
    // Delegation methods
    //
    
    // Write handler for the PRB register of CIA B
    void PRBdidChange(uint8_t oldValue, uint8_t newValue);
};

#endif
