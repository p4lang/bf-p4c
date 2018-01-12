#ifndef BF_P4C_ARCH_SIMPLE_SWITCH_H_
#define BF_P4C_ARCH_SIMPLE_SWITCH_H_

#include <boost/algorithm/string.hpp>
#include <boost/optional.hpp>
#include "ir/ir.h"
#include "ir/namemap.h"
#include "lib/path.h"
#include "frontends/common/options.h"
#include "frontends/p4/typeChecking/typeChecker.h"
#include "frontends/p4/coreLibrary.h"
#include "frontends/p4/cloner.h"
#include "frontends/p4/uniqueNames.h"
#include "frontends/p4/sideEffects.h"
#include "frontends/p4/methodInstance.h"
#include "bf-p4c/bf-p4c-options.h"
#include "bf-p4c/ir/gress.h"
#include "program_structure.h"
#include "architecture.h"
#include "converters.h"

namespace BFN {

enum class Target { Unknown, Simple, Tofino, Portable };
enum class BlockType { Unknown, Parser, Ingress, Egress, Deparser};

std::ostream& operator<<(std::ostream& out, BlockType block);
bool operator>>(cstring s, BlockType& blockType);


class SimpleSwitchTranslation : public PassManager {
 public:
    V1::ProgramStructure structure;
    Target   target;
    const IR::ToplevelBlock   *toplevel = nullptr;

    SimpleSwitchTranslation(P4::ReferenceMap* refMap, P4::TypeMap* typeMap, BFN_Options& options);

    const IR::ToplevelBlock* getToplevelBlock() { CHECK_NULL(toplevel); return toplevel; }
};


}  // namespace BFN

#endif /* BF_P4C_ARCH_SIMPLE_SWITCH_H_ */
