#include "device.h"
#include <algorithm>

Device* Device::instance_ = nullptr;

void Device::init(cstring name) {
    instance_ = nullptr;

    std::string lower_name(name);
    std::transform(lower_name.begin(), lower_name.end(), lower_name.begin(), ::tolower);

    if (lower_name == "tofino")
        instance_ = new TofinoDevice();
#if HAVE_JBAY
    else if (lower_name == "tofino2")
        instance_ = new JBayDevice();
#endif /* HAVE_JBAY */
    else
        BUG("Unknown device %s", name);
}
