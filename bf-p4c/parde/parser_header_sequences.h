#ifndef BF_P4C_PARDE_PARSER_HEADER_SEQUENCES_H_
#define BF_P4C_PARDE_PARSER_HEADER_SEQUENCES_H_

#include "ir/ir.h"
#include "ir/visitor.h"
#include "bf-p4c/ir/control_flow_visitor.h"
#include "bf-p4c/ir/gress.h"
#include "bf-p4c/parde/parde_visitor.h"
#include "bf-p4c/phv/phv_fields.h"

/**
 * @brief Identify _parsed_ header sequences.
 */
class ParserHeaderSequences : public BFN::ControlFlowVisitor, public PardeInspector {
 protected:
    PhvInfo& phv;

    /**
     * @brief Record that @p header was parsed in @p gress
     */
    void record_header(gress_t gress, cstring header);

 public:
    /** Headers extracted in the parser */
    std::map<gress_t, ordered_set<cstring>> headers;

    /** Header sequences extracted in the parser */
    std::map<gress_t, ordered_set<ordered_set<cstring>>> sequences;

    explicit ParserHeaderSequences(PhvInfo& phv) : phv(phv) {}

    Visitor::profile_t init_apply(const IR::Node* node) override;
    bool preorder(const IR::BFN::Parser*) override;
    bool preorder(const IR::BFN::Extract*) override;

    void flow_merge(Visitor&) override;

    void end_apply() override;

    ParserHeaderSequences *clone() const override { return new ParserHeaderSequences(*this); }
};

#endif  /* BF_P4C_PARDE_PARSER_HEADER_SEQUENCES_H_ */
