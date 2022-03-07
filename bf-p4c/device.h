#ifndef EXTENSIONS_BF_P4C_DEVICE_H_
#define EXTENSIONS_BF_P4C_DEVICE_H_

#include "ir/gress.h"
#include "lib/cstring.h"
#include "lib/exceptions.h"
#include "lib/range.h"
#include "mau/power_spec.h"
#include "parde/parde_spec.h"
#include "phv/phv_spec.h"
#include "arch/arch_spec.h"

class Device {
 public:
    enum Device_t { TOFINO, JBAY,
#if HAVE_CLOUDBREAK
    CLOUDBREAK,
#endif
#if HAVE_FLATROCK
    FLATROCK,
#endif
    };
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
    struct GatewaySpec;
    static const GatewaySpec& gatewaySpec() { return Device::get().getGatewaySpec(); }
    struct StatefulAluSpec;
    static const StatefulAluSpec& statefulAluSpec() { return Device::get().getStatefulAluSpec(); }
    static const ArchSpec& archSpec() { return Device::get().getArchSpec(); }
    static const MauPowerSpec& mauPowerSpec() { return Device::get().getMauPowerSpec(); }
    static int numPipes() { return Device::get().getNumPipes(); }
    static int numStages() {
        return numStagesRuntimeOverride_ ? numStagesRuntimeOverride_ : Device::get().getNumStages();
    }
    static void overrideNumStages(int num);
    static int numLongBranchTags() { return Device::get().getLongBranchTags(); }
    static bool hasLongBranches() { return numLongBranchTags() > 0; }
    static int alwaysRunIMemAddr() { return Device::get().getAlwaysRunIMemAddr(); }
    static bool hasAlwaysRunInstr() { return alwaysRunIMemAddr() >= 0; }
    static unsigned maxCloneId(gress_t gress) { return Device::get().getMaxCloneId(gress); }
    static gress_t maxGress() { return Device::get().getMaxGress(); }
    static RangeIter<gress_t> allGresses() { return Range(INGRESS, maxGress()); }
    static unsigned maxResubmitId() { return Device::get().getMaxResubmitId(); }
    static unsigned maxDigestId() { return Device::get().getMaxDigestId(); }
    /* type is 'int' because width_bits() is defined as 'int' in ir/base.def */
    static int mirrorTypeWidth() { return Device::get().getMirrorTypeWidth(); }
    static int cloneSessionIdWidth() { return Device::get().getCloneSessionIdWidth(); }
    static int queueIdWidth() { return Device::get().getQueueIdWidth(); }
    static int portBitWidth() { return Device::get().getPortBitWidth(); }
    static unsigned maxDigestSizeInBytes() { return Device::get().getMaxDigestSizeInBytes(); }
    static int numParsersPerPipe() { return 18; }
    static int numMaxChannels() { return Device::get().getNumMaxChannels(); }
    static int numClots() { return pardeSpec().numClotsPerGress(); }
    static int isMemoryCoreSplit() { return Device::get().getIfMemoryCoreSplit(); }
    static bool hasCompareInstructions() { return Device::get().getHasCompareInstructions(); }
    static int numLogTablesPerStage() { return Device::get().getNumLogTablesPerStage(); }
    static bool hasIngressDeparser() { return Device::get().getHasIngressDeparser(); }
    static bool hasEgressParser() { return Device::get().getHasEgressParser(); }
    static bool hasImplictPHVValidBit() { return Device::get().getHasImplicitPHVValidBit(); }
    static bool hasGhostThread() { return Device::get().getHasGhostThread(); }
    static bool threadsSharePipe(gress_t a, gress_t b) {
        return Device::get().getThreadsSharePipe(a, b); }
    static bool hasMirrorIOSelect() { return Device::get().getHasMirrorIOSelect(); }

 protected:
    explicit Device(cstring name) : name_(name) {}

    virtual Device_t device_type() const = 0;
    virtual cstring get_name() const = 0;

    virtual const PhvSpec& getPhvSpec() const = 0;
    virtual const PardeSpec& getPardeSpec() const = 0;
    virtual const GatewaySpec& getGatewaySpec() const = 0;
    virtual const StatefulAluSpec& getStatefulAluSpec() const = 0;
    virtual const MauPowerSpec& getMauPowerSpec() const = 0;
    virtual const ArchSpec& getArchSpec() const = 0;
    virtual int getNumPipes() const = 0;
    virtual int getNumPortsPerPipe() const = 0;
    virtual int getNumChannelsPerPort() const = 0;
    virtual int getNumStages() const = 0;
    virtual int getLongBranchTags() const = 0;
    virtual int getAlwaysRunIMemAddr() const = 0;
    virtual unsigned getMaxCloneId(gress_t) const = 0;
    virtual gress_t getMaxGress() const = 0;
    virtual unsigned getMaxResubmitId() const = 0;
    virtual unsigned getMaxDigestId() const = 0;
    virtual unsigned getMaxDigestSizeInBytes() const = 0;
    virtual int getMirrorTypeWidth() const = 0;
    virtual int getCloneSessionIdWidth() const = 0;
    virtual int getQueueIdWidth() const = 0;
    virtual int getPortBitWidth() const = 0;
    virtual int getNumMaxChannels() const = 0;
    virtual bool getIfMemoryCoreSplit() const = 0;
    virtual bool getHasCompareInstructions() const = 0;
    virtual int getNumLogTablesPerStage() const = 0;
    virtual bool getHasIngressDeparser() const = 0;
    virtual bool getHasEgressParser() const = 0;
    virtual bool getHasImplicitPHVValidBit() const = 0;
    virtual bool getHasGhostThread() const = 0;
    virtual bool getThreadsSharePipe(gress_t a, gress_t b) const = 0;
    virtual bool getHasMirrorIOSelect() const = 0;

 private:
    static Device* instance_;
    static int numStagesRuntimeOverride_;
    cstring name_;
};


class TofinoDevice : public Device {
    const TofinoPhvSpec phv_;
    const TofinoPardeSpec parde_;
    const TofinoMauPowerSpec mau_power_;
    const TofinoArchSpec arch_;

 public:
    TofinoDevice() : Device("Tofino"), parde_() {}
    Device::Device_t device_type() const override { return Device::TOFINO; }
    cstring get_name() const override { return "Tofino"; }
    int getNumPipes() const override { return 4; }
    int getNumPortsPerPipe() const override { return 4; }
    int getNumChannelsPerPort() const override { return 18; }
    int getNumStages() const override { return 12; }
    int getLongBranchTags() const override { return 0; }
    int getAlwaysRunIMemAddr() const override { return -1; }
    unsigned getMaxCloneId(gress_t gress) const override {
        switch (gress) {
        case INGRESS: return 7;  // one id reserved for IBuf
        case EGRESS:  return 8;
        default:      return 8;
        }
    }
    gress_t getMaxGress() const override { return EGRESS; }
    unsigned getMaxResubmitId() const override { return 8; }
    unsigned getMaxDigestId() const override { return 8; }
    int getMirrorTypeWidth() const override { return 3; }
    int getCloneSessionIdWidth() const override { return 10; }
    int getQueueIdWidth() const override { return 5; }
    int getPortBitWidth() const override { return 9; }
    int getNumMaxChannels() const override {
        return getNumPipes() * getNumPortsPerPipe() * getNumChannelsPerPort(); }
    unsigned getMaxDigestSizeInBytes() const override { return (384/8); }

    const PhvSpec& getPhvSpec() const override { return phv_; }
    const PardeSpec& getPardeSpec() const override { return parde_; }
    const GatewaySpec& getGatewaySpec() const override;
    const StatefulAluSpec& getStatefulAluSpec() const override;
    const MauPowerSpec& getMauPowerSpec() const override { return mau_power_; }
    const ArchSpec& getArchSpec() const override { return arch_; }
    bool getIfMemoryCoreSplit() const override { return false; }
    bool getHasCompareInstructions() const override { return false; }
    int getNumLogTablesPerStage() const override { return 16; }
    bool getHasIngressDeparser() const override { return true; }
    bool getHasEgressParser() const override { return true; }
    bool getHasImplicitPHVValidBit() const override { return true; }
    bool getHasGhostThread() const override { return false; };
    bool getThreadsSharePipe(gress_t, gress_t) const override { return true; }
    bool getHasMirrorIOSelect() const override { return false; }
};

class JBayDevice : public Device {
    const JBayPhvSpec phv_;
    const JBayPardeSpec parde_;
    const JBayMauPowerSpec mau_power_;
    const JBayArchSpec arch_;

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
    int getLongBranchTags() const override { return 8; }
    int getAlwaysRunIMemAddr() const override { return 63; }
    unsigned getMaxCloneId(gress_t /* gress */) const override { return 16; }
    gress_t getMaxGress() const override { return GHOST; }
    unsigned getMaxResubmitId() const override { return 8; }
    unsigned getMaxDigestId() const override { return 8; }
    unsigned getMaxDigestSizeInBytes() const override { return (384/8); }
    int getMirrorTypeWidth() const override { return 4; }
    int getCloneSessionIdWidth() const override { return 8; }
    int getQueueIdWidth() const override { return 7; }
    int getPortBitWidth() const override { return 9; }
    int getNumMaxChannels() const override {
        return getNumPipes() * getNumPortsPerPipe() * getNumChannelsPerPort(); }

    const PhvSpec& getPhvSpec() const override { return phv_; }
    const PardeSpec& getPardeSpec() const override { return parde_; }
    const GatewaySpec& getGatewaySpec() const override;
    const StatefulAluSpec& getStatefulAluSpec() const override;
    const MauPowerSpec& getMauPowerSpec() const override { return mau_power_; }
    const ArchSpec& getArchSpec() const override { return arch_; }
    bool getIfMemoryCoreSplit() const override { return true; }
    bool getHasCompareInstructions() const override { return true; }
    int getNumLogTablesPerStage() const override { return 16; }
    bool getHasIngressDeparser() const override { return true; }
    bool getHasEgressParser() const override { return true; }
    bool getHasImplicitPHVValidBit() const override { return false; }
    bool getHasGhostThread() const override { return true; };
    bool getThreadsSharePipe(gress_t, gress_t) const override { return true; }
    bool getHasMirrorIOSelect() const override { return true; }
};

/// Tofino2 variants. The only difference between them is the number of
/// stages.
#if BAREFOOT_INTERNAL
class JBayHDevice : public JBayDevice {
 public:
    int getNumStages() const override { return 6; }
    cstring get_name() const override { return "Tofino2H"; }
};
#endif  /* BAREFOOT_INTERNAL */

class JBayMDevice : public JBayDevice {
 public:
    int getNumStages() const override { return 12; }
    cstring get_name() const override { return "Tofino2M"; }
};

class JBayUDevice : public JBayDevice {
 public:
    int getNumStages() const override { return 20; }
    cstring get_name() const override { return "Tofino2U"; }
};

class JBayA0Device : public JBayDevice {
 public:
    const JBayA0PardeSpec parde_;
    const PardeSpec& getPardeSpec() const override { return parde_; }
    cstring get_name() const override { return "Tofino2A0"; }
};

#if HAVE_CLOUDBREAK
class CloudbreakDevice : public Device {
    const CloudbreakPhvSpec phv_;
    const CloudbreakPardeSpec parde_;
    const CloudbreakMauPowerSpec mau_power_;
    const CloudbreakArchSpec arch_;

 protected:
#ifdef EMU_OVERRIDE_STAGE_COUNT
    const int NUM_MAU_STAGES = EMU_OVERRIDE_STAGE_COUNT;
#else
    const int NUM_MAU_STAGES = 20;
#endif

 public:
    CloudbreakDevice() : Device("Tofino3"), phv_(), parde_() {}
    Device::Device_t device_type() const override { return Device::CLOUDBREAK; }
    cstring get_name() const override { return "Tofino3"; }
    int getNumPipes() const override { return 8; }
    int getNumPortsPerPipe() const override { return 4; }
    int getNumChannelsPerPort() const override { return 18; }
    int getNumStages() const override { return NUM_MAU_STAGES; }
    int getLongBranchTags() const override { return 8; }
    int getAlwaysRunIMemAddr() const override { return 63; }
    unsigned getMaxCloneId(gress_t /* gress */) const override { return 16; }
    gress_t getMaxGress() const override { return GHOST; }
    unsigned getMaxResubmitId() const override { return 8; }
    unsigned getMaxDigestId() const override { return 8; }
    unsigned getMaxDigestSizeInBytes() const override { return (384/8); }
    int getMirrorTypeWidth() const override { return 4; }
    int getCloneSessionIdWidth() const override { return 8; }
    int getQueueIdWidth() const override { return 7; }
    int getPortBitWidth() const override { return 11; }
    int getNumMaxChannels() const override {
        return getNumPipes() * getNumPortsPerPipe() * getNumChannelsPerPort(); }

    const PhvSpec& getPhvSpec() const override { return phv_; }
    const PardeSpec& getPardeSpec() const override { return parde_; }
    const GatewaySpec& getGatewaySpec() const override;
    const StatefulAluSpec& getStatefulAluSpec() const override;
    const MauPowerSpec& getMauPowerSpec() const override { return mau_power_; }
    const ArchSpec& getArchSpec() const override { return arch_; }
    bool getIfMemoryCoreSplit() const override { return true; }
    bool getHasCompareInstructions() const override { return true; }
    int getNumLogTablesPerStage() const override { return 16; }
    bool getHasIngressDeparser() const override { return true; }
    bool getHasEgressParser() const override { return true; }
    bool getHasImplicitPHVValidBit() const override { return false; }
    bool getHasGhostThread() const override { return true; };
    bool getThreadsSharePipe(gress_t, gress_t) const override { return true; }
    bool getHasMirrorIOSelect() const override { return true; }
};
#endif /* HAVE_CLOUDBREAK */

#if HAVE_FLATROCK
class FlatrockDevice : public Device {
    const FlatrockPhvSpec phv_;
    const FlatrockPardeSpec parde_;
    const FlatrockMauPowerSpec mau_power_;
    const FlatrockArchSpec arch_;

 protected:
#ifdef EMU_OVERRIDE_STAGE_COUNT
    const int NUM_MAU_STAGES = EMU_OVERRIDE_STAGE_COUNT;
#else
    const int NUM_MAU_STAGES = 14;  // ingress stages, egress is 12
#endif

 public:
    FlatrockDevice() : Device("Tofino5"), phv_(), parde_() {}
    Device::Device_t device_type() const override { return Device::FLATROCK; }
    cstring get_name() const override { return "Tofino5"; }
    int getNumPipes() const override { return 8; }
    int getNumPortsPerPipe() const override { return 4; }
    int getNumChannelsPerPort() const override { return 18; }
    int getNumStages() const override { return NUM_MAU_STAGES; }
    int getLongBranchTags() const override { return 8; }
    int getAlwaysRunIMemAddr() const override { return 63; }
    unsigned getMaxCloneId(gress_t /* gress */) const override { return 16; }
    gress_t getMaxGress() const override { return GHOST; }
    unsigned getMaxResubmitId() const override { return 8; }
    unsigned getMaxDigestId() const override { return 8; }
    unsigned getMaxDigestSizeInBytes() const override { return (384/8); }
    int getMirrorTypeWidth() const override { return 4; }
    int getCloneSessionIdWidth() const override { return 10; }
    int getQueueIdWidth() const override { return 5; }
    int getPortBitWidth() const override { return 9; }
    int getNumMaxChannels() const override {
        return getNumPipes() * getNumPortsPerPipe() * getNumChannelsPerPort(); }

    const PhvSpec& getPhvSpec() const override { return phv_; }
    const PardeSpec& getPardeSpec() const override { return parde_; }
    const GatewaySpec& getGatewaySpec() const override;
    const StatefulAluSpec& getStatefulAluSpec() const override;
    const MauPowerSpec& getMauPowerSpec() const override { return mau_power_; }
    const ArchSpec& getArchSpec() const override { return arch_; }
    bool getIfMemoryCoreSplit() const override { return true; }
    bool getHasCompareInstructions() const override { return true; }
    int getNumLogTablesPerStage() const override { return 16; }
    bool getHasIngressDeparser() const override { return false; }
    bool getHasEgressParser() const override { return false; }
    bool getHasImplicitPHVValidBit() const override { return false; }
    bool getHasGhostThread() const override { return false; /* TBD */ };
    bool getThreadsSharePipe(gress_t a, gress_t b) const {
        // just check bottom bit, as ingress/ghost share a pipe
        return (a&1) == (b&1); }
    bool getHasMirrorIOSelect() const override { return false; }
};
#endif /* HAVE_FLATROCK */

#endif /* EXTENSIONS_BF_P4C_DEVICE_H_ */
