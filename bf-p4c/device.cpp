#include "device.h"

Device* Device::instance_ = nullptr;

void Device::init(cstring name) {
    if (instance_ != nullptr) return;

    if (name == "Tofino")
        instance_ = new TofinoDevice();
    else
        BUG("Unknown device %s", name);
}
