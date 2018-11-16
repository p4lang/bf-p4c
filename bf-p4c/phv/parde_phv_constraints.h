#ifndef BF_P4C_PHV_PARDE_PHV_CONSTRAINTS_H_
#define BF_P4C_PHV_PARDE_PHV_CONSTRAINTS_H_

#include "ir/ir.h"
#include "bf-p4c/mau/mau_visitor.h"
#include "bf-p4c/phv/phv_fields.h"
#include "bf-p4c/phv/pragma/pa_container_size.h"

/** This class is meant to gather parser/deparser constraints related to digests. Here is a running
  * list of constraints gathered by this pass:
  * - The total size of containers containing fields that are involved in a learning quanta is
  *   Device::maxDigestSizeInBytes().
  *
  * In both Tofino and Tofino2, the maximum size of learning quanta is 384b (48B). This class
  * introduces a learning quanta threshold (set currently to 90% of the maximum learning quanta
  * size). If the learning quanta exceeds this threshold, then it imposes the following constraints
  * on PHV fields used in that learning quanta:
  * - If the field is byte aligned, the exact containers property for the field is set to true and
  *   the field is set to no_pack (to prevent other fields in the same header from being tacked on
  *   and forcing allocation into a larger container size).
  * - If the field is less than 32b, the field is made no_split.
  * - Depending on the size of field (for fields less than 32b in size), pa_container_size pragmas
  *   are inserted to occupy the smallest size of containers possible.
  */
class PardePhvConstraints : public Inspector {
 private:
     /// Maximum size of learning quanta in bytes.
     unsigned DIGEST_BYTES_THRESHOLD;

     PhvInfo                &phv;
     PragmaContainerSize    &sizePragmas;

     profile_t init_apply(const IR::Node* root) override;
     bool preorder(const IR::BFN::Digest* digest) override;

 public:
     explicit PardePhvConstraints(PhvInfo &p, PragmaContainerSize& pa) : phv(p), sizePragmas(pa) {
         // Set the threshold for setting restrictions of unused bits in digest fields to 90% of the
         // maximum.
         DIGEST_BYTES_THRESHOLD = Device::maxDigestSizeInBytes() * 9 / 10;
     }
};

#endif  /* BF_P4C_PHV_PARDE_PHV_CONSTRAINTS_H_ */
