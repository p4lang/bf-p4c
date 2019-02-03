#ifndef EXTENSIONS_BF_P4C_DEVICE_H_
#define EXTENSIONS_BF_P4C_DEVICE_H_

#include "lib/cstring.h"
#include "lib/exceptions.h"
#include "phv/phv_spec.h"
#include "parde/parde_spec.h"
#include "ir/gress.h"

class Device {
 public:
    enum Device_t { TOFINO, JBAY };
    /**
     * Initialize the global device context for the provided target - e.g.
     * "Tofino" or "JBay".
     *
     * This should be called as early as possible at startup, since the Device
     * singleton is available everywhere in the compiler.
     */
    static void init(cstring name);

    static const Device& get() {
       BUG_CHECK(instance_ != nullptr, "Target device not initialized!");
       return *instance_;
    }

    static Device_t currentDevice() { return Device::get().device_type(); }
    static cstring name() { return Device::get().get_name(); }

    static const PhvSpec& phvSpec() { return Device::get().getPhvSpec(); }
    static const PardeSpec& pardeSpec() { return Device::get().getPardeSpec(); }
    struct StatefulAluSpec;
    static const StatefulAluSpec& statefulAluSpec() { return Device::get().getStatefulAluSpec(); }
    static int numStages() { return Device::get().getNumStages(); }
    static unsigned maxCloneId(gress_t gress) { return Device::get().getMaxCloneId(gress); }
    static unsigned maxResubmitId() { return Device::get().getMaxResubmitId(); }
    static unsigned maxDigestId() { return Device::get().getMaxDigestId(); }
    /* type is 'int' because width_bits() is defined as 'int' in ir/base.def */
    static int cloneSessionIdWidth() { return Device::get().getCloneSessionIdWidth(); }
    static int queueIdWidth() { return Device::get().getQueueIdWidth(); }
    static int portBitWidth() { return Device::get().getPortBitWidth(); }
    static unsigned maxDigestSizeInBytes() { return Device::get().getMaxDigestSizeInBytes(); }
    static int numParsersPerPipe() { return 18; }
    static int numMaxChannels() { return Device::get().getNumMaxChannels(); }

 protected:
    explicit Device(cstring name) : name_(name) {}

    virtual Device_t device_type() const = 0;
    virtual cstring get_name() const = 0;

    virtual const PhvSpec& getPhvSpec() const = 0;
    virtual const PardeSpec& getPardeSpec() const = 0;
    virtual const StatefulAluSpec& getStatefulAluSpec() const = 0;
    virtual int getNumPipes() const = 0;
    virtual int getNumPortsPerPipe() const = 0;
    virtual int getNumChannelsPerPort() const = 0;
    virtual int getNumStages() const = 0;
    virtual unsigned getMaxCloneId(gress_t) const = 0;
    virtual unsigned getMaxResubmitId() const = 0;
    virtual unsigned getMaxDigestId() const = 0;
    virtual unsigned getMaxDigestSizeInBytes() const = 0;
    virtual int getCloneSessionIdWidth() const = 0;
    virtual int getQueueIdWidth() const = 0;
    virtual int getPortBitWidth() const = 0;
    virtual int getNumMaxChannels() const = 0;

 private:
    static Device* instance_;
    cstring name_;
};


class TofinoDevice : public Device {
    const TofinoPhvSpec phv_;
    const TofinoPardeSpec parde_;

 public:
    TofinoDevice() : Device("Tofino"), parde_() {}
    Device::Device_t device_type() const override { return Device::TOFINO; }
    cstring get_name() const override { return "Tofino"; }
    int getNumPipes() const override { return 4; }
    int getNumPortsPerPipe() const override { return 4; }
    int getNumChannelsPerPort() const override { return 18; }
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
    int getCloneSessionIdWidth() const override { return 10; }
    int getQueueIdWidth() const override { return 5; }
    int getPortBitWidth() const override { return 9; }
    int getNumMaxChannels() const override {
        return getNumPipes() * getNumPortsPerPipe() * getNumChannelsPerPort(); }
    unsigned getMaxDigestSizeInBytes() const override { return (384/8); }

    const PhvSpec& getPhvSpec() const override { return phv_; }
    const PardeSpec& getPardeSpec() const override { return parde_; }
    const StatefulAluSpec& getStatefulAluSpec() const override;
};

#if HAVE_JBAY
class JBayDevice : public Device {
    const JBayPhvSpec phv_;
    const JBayPardeSpec parde_;

 protected:
#ifdef EMU_OVERRIDE_STAGE_COUNT
    const int NUM_MAU_STAGES = EMU_OVERRIDE_STAGE_COUNT;
#else
    const int NUM_MAU_STAGES = 20;
#endif

 public:
    JBayDevice() : Device("Tofino2"), parde_() {}
    Device::Device_t device_type() const override { return Device::JBAY; }
    cstring get_name() const override { return "Tofino2"; }
    int getNumPipes() const override { return 4; }
    int getNumPortsPerPipe() const override { return 4; }
    int getNumChannelsPerPort() const override { return 18; }
    int getNumStages() const override { return NUM_MAU_STAGES; }
    unsigned getMaxCloneId(gress_t /* gress */) const override { return 16; }
    unsigned getMaxResubmitId() const override { return 8; }
    unsigned getMaxDigestId() const override { return 8; }
    unsigned getMaxDigestSizeInBytes() const override { return (384/8); }
    int getCloneSessionIdWidth() const override { return 8; }
    int getQueueIdWidth() const override { return 7; }
    int getPortBitWidth() const override { return 9; }
    int getNumMaxChannels() const override {
        return getNumPipes() * getNumPortsPerPipe() * getNumChannelsPerPort(); }

    const PhvSpec& getPhvSpec() const override { return phv_; }
    const PardeSpec& getPardeSpec() const override { return parde_; }
    const StatefulAluSpec& getStatefulAluSpec() const override;
};

/// Tofino2 variants. The only difference between them is the number of
/// stages.
class JBayHDevice : public JBayDevice {
 public:
    int getNumStages() const override { return 6; }
};

class JBayMDevice : public JBayDevice {
 public:
    int getNumStages() const override { return 12; }
};

class JBayUDevice : public JBayDevice {
 public:
    int getNumStages() const override { return 20; }
};

#endif /* HAVE_JBAY */

#endif /* EXTENSIONS_BF_P4C_DEVICE_H_ */
