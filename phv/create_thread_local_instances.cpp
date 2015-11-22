#include "create_thread_local_instances.h"

CreateThreadLocalInstances::CreateThreadLocalInstances() :
  gress_(INGRESS), gress_valid_(false) {
  visitDagOnce = false;
}

bool
CreateThreadLocalInstances::preorder(IR::HeaderRef *hdr_ref) {
  assert(true == gress_valid_);
  hdr_ref->set_name(cstring::to_cstring(gress_) + "::" + hdr_ref->toString());
  return false;
}

bool
CreateThreadLocalInstances::preorder(IR::Tofino_Parser *parser) {
  assert(false == gress_valid_);
  gress_ = parser->gress;
  gress_valid_ = true;
  return true;
}

void
CreateThreadLocalInstances::postorder(IR::Tofino_Deparser *) {
  assert(true == gress_valid_);
  gress_valid_ = false;
}
