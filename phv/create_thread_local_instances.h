#ifndef TOFINO_PHV_CREATE_THREAD_LOCAL_INSTANCES_H_
#define TOFINO_PHV_CREATE_THREAD_LOCAL_INSTANCES_H_
#include "ir/ir.h"
#include "tofino/ir/thread_visitor.h"

// This Visitor creates a thread-local instance of every metadata and header
// instance. The name of the new instance is gress-name::instance-name.
// TODO: When header/metadata instances are added to MAU_Pipe, this class must
// create 2 copies (one for each thread) of every header/metadata instance
// object.
class CreateThreadLocalInstances : public Modifier, ThreadVisitor {
 public:
    explicit CreateThreadLocalInstances(gress_t th) : ThreadVisitor(th), gress_(th) {}
    // Always returns false. It prepends "thread-name::" to named_ref->name.
    bool preorder(IR::HeaderOrMetadata *hdr_ref) override {
        hdr_ref->name = IR::ID(cstring::to_cstring(gress_) + "::" + hdr_ref->name);
        return false; }
    // It prepends "thread-name::" to every parse state.
    bool preorder(IR::Tofino::ParserState *ps) override {
        ps->name = cstring::to_cstring(gress_) + "::" + ps->name;
        return true; }
 private:
    gress_t gress_;
};

#endif /* TOFINO_PHV_CREATE_THREAD_LOCAL_INSTANCES_H_ */
