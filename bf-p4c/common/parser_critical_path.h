#ifndef BF_P4C_COMMON_PARSER_CRITICAL_PATH_H_
#define BF_P4C_COMMON_PARSER_CRITICAL_PATH_H_

#include "ir/ir.h"
#include "lib/cstring.h"
#include "bf-p4c/ir/control_flow_visitor.h"
#include "bf-p4c/parde/parde_visitor.h"
#include "bf-p4c/phv/phv_fields.h"

struct ParserCriticalPathResult {
    /// A vector of pairs where the first of a pair is
    /// the pointer to IR::BFN::ParserState,
    /// the second is the bits extracted in that state.
    std::vector<std::pair<const IR::BFN::ParserState*, int>> path;
    int length;
    ParserCriticalPathResult()
        : path(), length(0) {}
};

/** Produces a ParserCriticalPathResult that contains names and statistics of states
 * on the critical path, and the length (total bits extracted to PHV) of the critical path.
 *
 * The $valid bits are counted as well, because they are stored in PHV.
 * INGRESS/EGRESS need to be specified in the constructor.
 *
 * @pre This is a backend pass.
 */
class ParserCriticalPath : public BFN::ControlFlowVisitor,
                           public ParserInspector {
 private:
    bool preorder(const IR::BFN::AbstractParser* parser) override
    { return gress_ == parser->gress; };
    bool preorder(const IR::BFN::ParserPrimitive*) override
    { return false; };
    bool preorder(const IR::BFN::ParserState* state) override;

    void flow_merge(Visitor &) override;
    void end_apply() override;
    gress_t gress_;
    ParserCriticalPathResult& final_result;

 public:
    ParserCriticalPath(gress_t gress,
                       ParserCriticalPathResult& rst)
        : gress_(gress), final_result(rst)
    {   joinFlows = true;
        visitDagOnce = false; }

    ParserCriticalPath *clone() const override { return new ParserCriticalPath(*this); }

 public:
    ParserCriticalPathResult result;
};

/** Calculate critical path of both ingress and egress parser.
 */
class CalcParserCriticalPath : public PassManager {
 public:
    explicit CalcParserCriticalPath(const PhvInfo& phv) : phv(phv) {
        addPasses({
                new ParserCriticalPath(INGRESS, ingress_result),
                new ParserCriticalPath(EGRESS, egress_result)
           });
    }

    ordered_set<const PHV::Field *>
    calc_all_critical_fields() const;

    const ParserCriticalPathResult&
    get_ingress_result() const { return ingress_result; }
    const ParserCriticalPathResult&
    get_egress_result() const { return egress_result; }

 private:
    ordered_set<const PHV::Field *>
    calc_critical_fields(const ParserCriticalPathResult& critical_path) const;

 private:
    const PhvInfo& phv;
    ParserCriticalPathResult ingress_result;
    ParserCriticalPathResult egress_result;
};

std::ostream& operator<<(std::ostream& out, const ParserCriticalPathResult& rst);

#endif /* BF_P4C_COMMON_PARSER_CRITICAL_PATH_H_ */
