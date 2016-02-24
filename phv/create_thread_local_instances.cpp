#include "create_thread_local_instances.h"

bool
CreateThreadLocalInstances::preorder(IR::HeaderOrMetadata *hdr_ref) {
    hdr_ref->name = IR::ID(cstring::to_cstring(gress_) + "::" + hdr_ref->name);
    return false;
}
