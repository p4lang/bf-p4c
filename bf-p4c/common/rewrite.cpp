/*
Copyright 2013-present Barefoot Networks, Inc.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

#include "tofino/common/rewrite.h"

#include <boost/optional.hpp>

#include "frontends/common/resolveReferences/referenceMap.h"
#include "frontends/p4/coreLibrary.h"
#include "frontends/p4/methodInstance.h"
#include "frontends/p4/typeChecking/typeChecker.h"
#include "frontends/p4/typeMap.h"

// XXX(seth): This is a horrible hack. See below.
const IR::Expression*
RewriteForTofino::postorder(IR::MethodCallExpression* call) {
    CHECK_NULL(refMap);
    auto* mem = call->method->to<IR::Member>();
    if (!mem) return call;
    if (mem->member == "lookahead") {
        BUG_CHECK(call->typeArguments->size() == 1,
                  "Expected 1 type parameter for %1%", call);
        auto* typeArg = call->typeArguments->at(0);
        auto* typeArgType = typeMap->getTypeType(typeArg, true);
        int width = typeArgType->width_bits();
        BUG_CHECK(width > 0, "Nonpositive width for lookahead type %1%", typeArg);
        auto* lookahead = new IR::BFN::LookaheadExpression(call->srcInfo, 0, width);
        lookahead->type = call->type;
        return lookahead;
    }
    return call;
}

// XXX(seth): Calling MethodInstance causes later code to catastrophically fail
// for reasons that aren't clear to me. That's true even if we copy the entire
// ReferenceMap and TypeMap before calling it. So for now, we'll use the hacky
// implementation above.
/*
const IR::Expression*
RewriteForTofino::postorder(IR::MethodCallExpression* call) {
    auto* instance = P4::MethodInstance::resolve(call, refMap, typeMap, true);
    if (instance->is<P4::ExternMethod>())
        return convertExternMethod(call, instance->to<P4::ExternMethod>());
    return call;
}
*/

const IR::Expression* RewriteForTofino::postorder(IR::Slice* slice) {
    if (!slice->e0->is<IR::BFN::LookaheadExpression>()) return slice;
    auto* lookahead =
      slice->e0->to<IR::BFN::LookaheadExpression>()->clone();
    le_bitrange sliceRange(slice->getL(), slice->getH());
    boost::optional<nw_bitrange> lookaheadRange =
      sliceRange.toSpace<Endian::Network>(lookahead->bitRange().size())
                   .intersectWith(lookahead->bitRange());
    if (!lookaheadRange) {
        ::error("Slice is empty: %1%", slice);
        return slice;
    }
    lookahead->setBitRange(*lookaheadRange);
    lookahead->type = slice->type;
    return lookahead;
}

const IR::Expression*
RewriteForTofino::convertExternMethod(const IR::MethodCallExpression* call,
                                      const P4::ExternMethod* externMethod) {
    auto& corelib = P4::P4CoreLibrary::instance;
    if (externMethod->originalExternType->name == corelib.packetIn.name &&
        externMethod->method->name == corelib.packetIn.lookahead.name) {
        BUG_CHECK(call->typeArguments->size() == 1,
                  "Expected 1 type parameter for %1%", externMethod->method);
        auto* typeArg = call->typeArguments->at(0);
        auto* typeArgType = typeMap->getTypeType(typeArg, true);
        int width = typeArgType->width_bits();
        BUG_CHECK(width > 0, "Nonpositive width for lookahead type %1%", typeArg);
        auto* lookahead = new IR::BFN::LookaheadExpression(call->srcInfo, 0, width);
        lookahead->type = call->type;
        return lookahead;
    }
    return call;
}
