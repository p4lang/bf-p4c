#ifndef EXTENSIONS_BF_P4C_DEVICE_H_
#define EXTENSIONS_BF_P4C_DEVICE_H_

#include "lib/cstring.h"
#include "lib/exceptions.h"
#include "phv/phv_spec.h"
#include "parde/parde_spec.h"

class Device {
 public:
    /**
     * Initialize the global device context for the provided target - e.g.
     * "Tofino" or "JBay".
     *
     * No-op if the global device context was already initialized.
     *
     * This should be called as early as possible at startup, since the Device
     * singleton is available everywhere in the compiler.
     */
    static void init(cstring name);

    /**
     * Initialize the global device context for the provided target - e.g.
     * "Tofino" or "JBay".
     *
     * If the global device context was already initialized, it is replaced.
     * This will invalidate many data structures throughout the compiler; it's
     * the responsibility of the caller to choose a safe point to do this.
     * This is intended for use with unit tests.
     */
    static void reinitialize(cstring name);


    static const Device& get() {
       BUG_CHECK(instance_ != nullptr, "No device specified");
       return *instance_;
    }

    static cstring currentDevice() { return Device::get().name(); }

    static const PhvSpec& phvSpec() { return Device::get().getPhvSpec(); }
    static const PardeSpec& pardeSpec() { return Device::get().getPardeSpec(); }
    static int numStages() { return Device::get().getNumStages(); }

 protected:
    explicit Device(cstring name) : name_(name) {}

    cstring name() const { return name_; }

    virtual const PhvSpec& getPhvSpec() const = 0;
    virtual const PardeSpec& getPardeSpec() const = 0;
    virtual int getNumStages() const = 0;

    cstring name_;

 private:
    static Device* instance_;
};


class TofinoDevice : public Device {
    const TofinoPhvSpec phv_;
    const TofinoPardeSpec parde_;

 public:
    TofinoDevice() : Device("Tofino"), parde_() {}
    int getNumStages() const { return 12; }

    const PhvSpec& getPhvSpec() const { return phv_; }
    const PardeSpec& getPardeSpec() const { return parde_; }
};

#if HAVE_JBAY
class JBayDevice : public Device {
    const JBayPhvSpec phv_;
    const JBayPardeSpec parde_;

 public:
    JBayDevice() : Device("JBay"), parde_() {}
    int getNumStages() const { return 20; }

    const PhvSpec& getPhvSpec() const { return phv_; }
    const PardeSpec& getPardeSpec() const { return parde_; }
};
#endif /* HAVE_JBAY */

#endif /* EXTENSIONS_BF_P4C_DEVICE_H_ */
