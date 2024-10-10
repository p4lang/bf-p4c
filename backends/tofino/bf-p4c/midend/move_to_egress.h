#ifndef BF_P4C_MIDEND_MOVE_TO_EGRESS_H_
#define BF_P4C_MIDEND_MOVE_TO_EGRESS_H_

#include "ir/ir.h"
#include "midend/type_checker.h"
#include "defuse.h"

class MoveToEgress : public PassManager {
    BFN::EvaluatorPass  *evaluator;
    ordered_set<const IR::P4Parser *>   ingress_parser, egress_parser;
    ordered_set<const IR::P4Control *>  ingress, egress, ingress_deparser, egress_deparser;
    ComputeDefUse       defuse;

    class FindIngressPacketMods;

 public:
    explicit MoveToEgress(BFN::EvaluatorPass *ev);
};

#endif /* BF_P4C_MIDEND_MOVE_TO_EGRESS_H_ */
