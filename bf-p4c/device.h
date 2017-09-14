#ifndef EXTENSIONS_TOFINO_DEVICE_H_
#define EXTENSIONS_TOFINO_DEVICE_H_

#include "lib/exceptions.h"
#include "lib/cstring.h"
#include "phv/phv_spec.h"


class Device {
 public:
    static void init(cstring name);

    static const Device& get() {
       BUG_CHECK(instance_ != nullptr, "No device specified");
       return *instance_;
    }

    static const PhvSpec& phvSpec() { return *(Device::get().phv_); }

 protected:
    explicit Device(cstring name) : name_(name) {}

    cstring name() { return name_; }

    PhvSpec *phv_ = nullptr;

    cstring name_;

 private:
    static Device* instance_;
};


class TofinoDevice : public Device {
 public:
    TofinoDevice() : Device("Tofino") {
        phv_ = new TofinoPhvSpec;
    }
};

#endif /* EXTENSIONS_TOFINO_DEVICE_H_ */
