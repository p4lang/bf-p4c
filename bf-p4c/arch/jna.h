#ifndef BF_P4C_ARCH_JNA_H_
#define BF_P4C_ARCH_JNA_H_

#include "ir/ir.h"

namespace P4 {
class ReferenceMap;
class TypeMap;
}  // namespace P4


class BFN_Options;

namespace BFN {

struct PortTNAToJBay : public PassManager {
    PortTNAToJBay(P4::ReferenceMap* refMap, P4::TypeMap* typeMap, BFN_Options& options);
};

}  // namespace BFN

#endif /* BF_P4C_ARCH_JNA_H_ */
