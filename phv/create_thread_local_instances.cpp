#include "create_thread_local_instances.h"

bool
CreateThreadLocalInstances::preorder(IR::NamedHeaderRef *hdr_ref) {
  hdr_ref->set_name(cstring::to_cstring(gress_) + "::" + hdr_ref->toString());
  return false;
}
