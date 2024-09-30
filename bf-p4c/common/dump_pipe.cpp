#include <iostream>

#include "utils.h"
#include "ir/dump.h"
#include "lib/gc.h"

#if BAREFOOT_INTERNAL
bool DumpPipe::preorder(const P4::IR::Node *pipe) {
    if (LOGGING(1)) {
        if (heading) {
            LOG1("-------------------------------------------------");
            LOG1(heading);
            LOG1("-------------------------------------------------");
            size_t maxMem = 0;
            size_t memUsed = gc_mem_inuse(&maxMem)/(1024*1024);
            maxMem = maxMem/(1024*1024);
            LOG1("*** mem in use = " << memUsed << "MB, heap size = " << maxMem << "MB");
        }
        if (LOGGING(2))
            dump(::Log::Detail::fileLogOutput(__FILE__), pipe);
        else
            LOG1(*pipe);
    }
    return false;
}
#endif  // BAREFOOT_INTERNAL
