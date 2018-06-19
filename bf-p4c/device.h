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
    struct StatefulAluSpec;
    static const StatefulAluSpec& statefulAluSpec() { return Device::get().getStatefulAluSpec(); }
    static int numStages() { return Device::get().getNumStages(); }
    static unsigned maxCloneId(gress_t gress) { return Device::get().getMaxCloneId(gress); }
    static unsigned maxResubmitId() { return Device::get().getMaxResubmitId(); }
    static unsigned maxDigestId() { return Device::get().getMaxDigestId(); }

 protected:
    explicit Device(cstring name) : name_(name) {}

    cstring name() const { return name_; }

    virtual const PhvSpec& getPhvSpec() const = 0;
    virtual const PardeSpec& getPardeSpec() const = 0;
    virtual const StatefulAluSpec& getStatefulAluSpec() const = 0;
    virtual int getNumStages() const = 0;
    virtual unsigned getMaxCloneId(gress_t) const = 0;
    virtual unsigned getMaxResubmitId() const = 0;
    virtual unsigned getMaxDigestId() const = 0;

    cstring name_;

 private:
    static Device* instance_;
};


class TofinoDevice : public Device {
    const TofinoPhvSpec phv_;
    const TofinoPardeSpec parde_;

 public:
    TofinoDevice() : Device("Tofino"), parde_() {}
    int getNumStages() const override { return 12; }
    unsigned getMaxCloneId(gress_t gress) const override {
        switch (gress) {
        case INGRESS: return 7;  // one id reserved for IBuf
        case EGRESS:  return 8;
        default:      return 8;
        }
    }
    unsigned getMaxResubmitId() const override { return 8; }
    unsigned getMaxDigestId() const override { return 8; }

    const PhvSpec& getPhvSpec() const override { return phv_; }
    const PardeSpec& getPardeSpec() const override { return parde_; }
    const StatefulAluSpec& getStatefulAluSpec() const override;
};

#if HAVE_JBAY
class JBayDevice : public Device {
    const JBayPhvSpec phv_;
    const JBayPardeSpec parde_;
#ifdef EMU_OVERRIDE_STAGE_COUNT
    const int NUM_MAU_STAGES = EMU_OVERRIDE_STAGE_COUNT;
#else
    const int NUM_MAU_STAGES = 20;
#endif

 public:
    JBayDevice() : Device("JBay"), parde_() {}
    int getNumStages() const override { return NUM_MAU_STAGES; }
    unsigned getMaxCloneId(gress_t /* gress */) const override { return 16; }
    unsigned getMaxResubmitId() const override { return 8; }
    unsigned getMaxDigestId() const override { return 8; }

    const PhvSpec& getPhvSpec() const override { return phv_; }
    const PardeSpec& getPardeSpec() const override { return parde_; }
    const StatefulAluSpec& getStatefulAluSpec() const override;
};
#endif /* HAVE_JBAY */

#endif /* EXTENSIONS_BF_P4C_DEVICE_H_ */
