#include "device.h"
#include <algorithm>

Device* Device::instance_ = nullptr;

void Device::init(cstring name) {
    if (instance_ != nullptr) return;

    std::string lower_name(name);
    std::transform(lower_name.begin(), lower_name.end(), lower_name.begin(), ::tolower);

    if (lower_name == "tofino")
        instance_ = new TofinoDevice();
    else if (lower_name == "jbay")
        instance_ = new JBayDevice();
    else
        BUG("Unknown device %s", name);
}
