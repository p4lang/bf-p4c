#include "utils.h"
#include "bf-p4c/bf-p4c-options.h"
#include "bf-p4c/device.h"

bool ghost_only_on_other_pipes(int pipe_id) {
    if (pipe_id < 0) return false;  // invalid pipe id

    auto options = BackendOptions();
    if (!Device::hasGhostThread()) return false;
    if (options.ghost_pipes == 0) return false;

    if ((options.ghost_pipes & (0x1 << pipe_id)) == 0) {
       return true;
    }
    return false;
}
