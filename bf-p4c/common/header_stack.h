#ifndef BF_P4C_COMMON_HEADER_STACK_H_
#define BF_P4C_COMMON_HEADER_STACK_H_

#include "ir/ir.h"
#include "lib/map.h"

/** Walk over the IR and collect metadata about the usage of header stacks in
 * the program. The results are stored in `IR::BFN::Pipe::headerStackInfo`.
 *
 * @warning Cannot run after InstructionSelection, which replaces push and
 *          pop operations with `set` instructions.
 */
struct CollectHeaderStackInfo : public Modifier {
    CollectHeaderStackInfo();

 private:
    void postorder(IR::HeaderStack* stack) override;
    void postorder(IR::Primitive* primitive) override;
    void postorder(IR::BFN::Pipe* pipe) override;

    BFN::HeaderStackInfo* stacks;
};

/// Remove header stack info for unused headers, eg. removed by ElimUnused.  Can be used after
/// InstructionSelection, unlike CollectHeaderStackInfo.
class ElimUnusedHeaderStackInfo : public PassManager {
    ordered_set<cstring> unused;

    // Find unused headers.
    struct Find : public Inspector {
        ElimUnusedHeaderStackInfo& self;
        const BFN::HeaderStackInfo* stacks = nullptr;
        ordered_set<cstring> used;

        explicit Find(ElimUnusedHeaderStackInfo& self) : self(self) { }

        bool preorder(const IR::BFN::Pipe* pipe) override {
            BUG_CHECK(pipe->headerStackInfo != nullptr,
                      "Running ElimUnusedHeaderStackInfo without running "
                      "CollectHeaderStackInfo first?");
            stacks = pipe->headerStackInfo;
            return true;
        }

        void postorder(const IR::HeaderStack* stack) override;
        void end_apply() override;
    };

    // Remove from pipe->headerStackInfo.
    struct Elim : public Modifier {
        ElimUnusedHeaderStackInfo& self;
        explicit Elim(ElimUnusedHeaderStackInfo& self) : self(self) { }

        void postorder(IR::BFN::Pipe* pipe) override;
    };

 public:
    ElimUnusedHeaderStackInfo() {
        addPasses({
            new Find(*this),
            new Elim(*this) });
    }
};

namespace BFN {

/// Metadata about how header stacks are used in the program.
struct HeaderStackInfo {
    struct Info {
        /// The name of the header stack this metadata describes.
        cstring name;

        /// Which threads is this header stack visible in? By default, the same
        /// header stack is used in both threads, but after
        /// CreateThreadLocalInstances runs, header stacks are thread-specific.
        bool inThread[2] = { true, true };

        /// How many elements are in this header stack?
        int size = 0;

        /// What is the maximum number of elements that are pushed onto this
        /// header stack in a single `push_front` primitive invocation?
        int maxpush = 0;

        /// What is the maximum number of elements that are popped off of this
        /// header stack in a single `pop_front` primitive invocation?
        int maxpop = 0;
    };

 private:
    friend struct ::CollectHeaderStackInfo;
    friend struct ::ElimUnusedHeaderStackInfo;
    std::map<cstring, Info> info;

 public:
    auto begin() const -> decltype(Values(info).begin()) { return Values(info).begin(); }
    auto begin() -> decltype(Values(info).begin()) { return Values(info).begin(); }
    auto end() const -> decltype(Values(info).end()) { return Values(info).end(); }
    auto end() -> decltype(Values(info).end()) { return Values(info).end(); }
    auto at(cstring n) const -> decltype(info.at(n)) { return info.at(n); }
    auto at(cstring n) -> decltype(info.at(n)) { return info.at(n); }
};

}  // namespace BFN

#endif /* BF_P4C_COMMON_HEADER_STACK_H_ */
