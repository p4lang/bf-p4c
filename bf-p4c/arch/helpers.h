#ifndef BF_P4C_ARCH_HELPERS_H_
#define BF_P4C_ARCH_HELPERS_H_

#include <boost/optional.hpp>

#include "ir/ir.h"
#include "frontends/p4/typeMap.h"
#include "frontends/common/resolveReferences/referenceMap.h"
#include "frontends/p4/externInstance.h"
#include "frontends/p4/methodInstance.h"

namespace BFN {

const IR::Declaration_Instance *
getDeclInst(const P4::ReferenceMap *refMap, const IR::PathExpression *path);

boost::optional<cstring> getExternTypeName(const P4::ExternMethod* extMethod);

boost::optional<P4::ExternInstance>
getExternInstanceFromPropertyByTypeName(const IR::P4Table* table,
                                        cstring propertyName,
                                        cstring typeName,
                                        P4::ReferenceMap* refMap,
                                        P4::TypeMap* typeMap,
                                        bool *isConstructedInPlace = nullptr);

/// @return an extern instance defined or referenced by the value of @table's
/// @propertyName property, or boost::none if no extern was referenced.
boost::optional<P4::ExternInstance>
getExternInstanceFromProperty(const IR::P4Table* table,
                              cstring propertyName,
                              P4::ReferenceMap* refMap,
                              P4::TypeMap* typeMap);

boost::optional<const IR::ExpressionValue*>
getExpressionFromProperty(const IR::P4Table* table,
                          const cstring& propertyName);

std::vector<const IR::Expression*>
convertConcatToList(const IR::Concat* expr);

}  // namespace BFN

#endif /* BF_P4C_ARCH_HELPERS_H_ */
