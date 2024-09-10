/**
 * \defgroup RemoveSelectBooleans BFN::RemoveSelectBooleans
 * \ingroup midend
 * \brief Set of passes that convert boolean values in select statements
 *        to bit<1> values.  The node is also transformed to
 *        IR:BFN:ReinterpretCasts.
 *
 *        These passes take care of select statements with boolean values
 *        such as this one:
 *
 *          (...)
 *
 *          header example_bridge_h {
 *              bit<32> dst_mac_addr_low;
 *              bit<32> src_mac_addr_low;
 *              bool    ipv4_valid_in_ingress;
 *          }
 *
 *          struct metadata_t {
 *              example_bridge_h example_bridge_hdr;
 *          }
 *
 *          (...)
 *
 *          transition select(eg_md.example_bridge_hdr.ipv4_valid_in_ingress) {
 *              true: accept;
 *              default: reject;
 *          }
 *
 *       Expression "eg_md.example_bridge_hdr.ipv4_valid_in_ingress" is translated to
 *       "(bit<1>)eg_md.example_bridge_hdr.ipv4_valid_in_ingress", select value "true"
 *       is translated to (bit<1>)1 while the associated nodes are transformed to
 *       IR::BFN::ReinterpretCast.
 */

#ifndef BF_P4C_MIDEND_REMOVE_SELECT_BOOLEANS_H_
#define BF_P4C_MIDEND_REMOVE_SELECT_BOOLEANS_H_

#include "ir/ir.h"
#include "frontends/p4/typeMap.h"
#include "midend/removeSelectBooleans.h"
#include "backends/tofino/midend/elim_cast.h"

namespace BFN {

class RemoveSelectBooleans : public PassManager {
 public:
    RemoveSelectBooleans(P4::ReferenceMap* refMap, P4::TypeMap* typeMap) {
        addPasses({
           new P4::ClearTypeMap(typeMap),
           new BFN::TypeChecking(refMap, typeMap, true),
           new P4::RemoveSelectBooleans(refMap, typeMap),
           new BFN::TypeChecking(refMap, typeMap, true),
           new BFN::RewriteCastToReinterpretCast(typeMap),
           // RewriteCastToReinterpretCast might change some of the Type_Bits
           // to different objects representing the same type =>
           // rerun typechecking with empty typemap to properly
           // unify those new types
           new P4::ClearTypeMap(typeMap),
           new BFN::TypeChecking(refMap, typeMap, true),
        });
    }
};

}

#endif /* BF_P4C_MIDEND_REMOVE_SELECT_BOOLEANS_H_ */
