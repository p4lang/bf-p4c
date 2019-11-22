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
  *   the field is set to solitary (to prevent other fields in the same header from being tacked on
  *   and forcing allocation into a larger container size).
  * - If the field is less than 32b, the field is made no_split.
  * - Depending on the size of field (for fields less than 32b in size), pa_container_size pragmas
  *   are inserted to occupy the smallest size of containers possible.
  *
  * A second constraint implemented here is related to the use of constant extractors in the parser.
  * If a field is written to using a constant extractor, that field can be allocated to a 16b
  * container only if the constant is expressible in less than 4 consecutive bits (all other bits
  * can be zero, and these 4 bits can be rotated in to form the 16b value to be copied).
  * Additionally, the field can be allocated to a 32b container only if the constant is expressible
  * in less than 3 consecutive bits. Therefore, this pass constraints fields in constant extractors
  * requiring more than 3b for the expression of the source constant to 8b containers only.
  * XXX(Deep): Add ability to distinguish between the 3b limit for 32b containers and 4b
  * limit for 16b containers. This requires the implementation of a
  * `do-not-allocate-to-a-particular-container-size` constraint in PHV.
 */
class PardePhvConstraints : public Inspector {
 private:
     static constexpr int MAX_CONSTANT_WINDOW = 3;

     /// Maximum size of learning quanta in bytes.
     unsigned DIGEST_BYTES_THRESHOLD;

     PhvInfo                &phv;
     PragmaContainerSize    &sizePragmas;

     profile_t init_apply(const IR::Node* root) override;
     bool preorder(const IR::BFN::Digest* digest) override;
     bool preorder(const IR::BFN::Extract* extract) override;
 public:
     explicit PardePhvConstraints(PhvInfo &p, PragmaContainerSize& pa) : phv(p), sizePragmas(pa) {
         // Set the threshold for setting restrictions of unused bits in digest fields to 90% of the
         // maximum.
         DIGEST_BYTES_THRESHOLD = Device::maxDigestSizeInBytes() * 9 / 10;
     }
};

class TofinoParserConstantExtract : public Inspector {
 private:
    PhvInfo         &phv;

    ordered_map<const IR::BFN::ParserState*, ordered_set<PHV::Field*>> stateToPOVMap;

    profile_t init_apply(const IR::Node* root) override;
    bool preorder(const IR::BFN::Extract* extract) override;
    void end_apply() override;

 public:
    explicit TofinoParserConstantExtract(PhvInfo& p) : phv(p) { }
};

#endif  /* BF_P4C_PHV_PARDE_PHV_CONSTRAINTS_H_ */
