#include "create_thread_local_instances.h"

CreateThreadLocalInstances::CreateThreadLocalInstances() :
  gress_(INGRESS), gress_valid_(false) {
  visitDagOnce = false;
}

bool
CreateThreadLocalInstances::preorder(IR::NamedRef *named_ref) {
  assert(true == gress_valid_);
  named_ref->name = cstring::to_cstring(gress_) + "::" + named_ref->name;
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
