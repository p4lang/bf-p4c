#ifndef BF_P4C_ARCH_HELPERS_H_
#define BF_P4C_ARCH_HELPERS_H_

#include <boost/optional.hpp>

#include "ir/ir.h"
#include "frontends/p4/methodInstance.h"

namespace BFN {

boost::optional<cstring> getExternTypeName(const P4::ExternMethod* extMethod);

}  // namespace BFN


#endif /* BF_P4C_ARCH_HELPERS_H_ */
