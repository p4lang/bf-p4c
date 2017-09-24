#ifndef EXTENSIONS_BF_P4C_DEVICE_H_
#define EXTENSIONS_BF_P4C_DEVICE_H_

#include "lib/cstring.h"
#include "lib/exceptions.h"
#include "phv/phv_spec.h"


class Device {
 public:
    static void init(cstring name);

    static const Device& get() {
       BUG_CHECK(instance_ != nullptr, "No device specified");
       return *instance_;
    }

    static const PhvSpec& phvSpec() { return Device::get().getPhvSpec(); }

 protected:
    explicit Device(cstring name) : name_(name) {}

    cstring name() { return name_; }

    virtual const PhvSpec& getPhvSpec() const = 0;

    cstring name_;

 private:
    static Device* instance_;
};


class TofinoDevice : public Device {
    const TofinoPhvSpec phv_;

 public:
    TofinoDevice() : Device("Tofino") {}

    const PhvSpec& getPhvSpec() const { return phv_; }
};

#if HAVE_JBAY
class JBayDevice : public Device {
    const JBayPhvSpec phv_;

 public:
    JBayDevice() : Device("JBay") {}

    const PhvSpec& getPhvSpec() const { return phv_; }
};
#endif /* HAVE_JBAY */

#endif /* EXTENSIONS_BF_P4C_DEVICE_H_ */
