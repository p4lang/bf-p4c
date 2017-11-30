#include "parser_critical_path.h"
#include "ir/ir.h"
#include "lib/log.h"

std::ostream& operator<<(std::ostream& out, const ParserCriticalPathResult& rst) {
    out << "Critical Path Length: " << rst.length << "\n";
    for (const auto& s : rst.path) {
        out << s.first->name << "(" << s.second << ")" << "\n"; }
    return out;
}

ordered_set<const PHV::Field *>
CalcParserCriticalPath::calc_all_critical_fields() const {
    auto ingress = calc_critical_fields(ingress_result);
    auto egress = calc_critical_fields(egress_result);
    ingress.insert(egress.begin(), egress.end());
    return ingress;
}

ordered_set<const PHV::Field *>
CalcParserCriticalPath::calc_critical_fields(const ParserCriticalPathResult& critical_path) const {
    ordered_set<const PHV::Field *> rtn;
    for (const auto& v : critical_path.path) {
        for (const auto& st : v.first->statements) {
            if (auto *ex = st->to<IR::BFN::Extract>()) {
                rtn.insert(phv.field(ex->dest->field)); } } }
    return rtn;
}

bool ParserCriticalPath::preorder(const IR::BFN::ParserState* state) {
    int total_extracted = 0;
    for (const IR::BFN::ParserPrimitive* prim : state->statements) {
        // In this backend stage,
        // set_metadata is Extract as well
        if (auto *ex = prim->to<IR::BFN::Extract>()) {
            total_extracted += ex->dest->field->type->width_bits(); } }

    result.length += total_extracted;
    result.path.push_back(std::make_pair(state, total_extracted));
    return true;
}

void ParserCriticalPath::flow_merge(Visitor &other_) {
    auto other = dynamic_cast<ParserCriticalPath&>(other_);
    if (other.result.length > result.length) {
        result = other.result; }
}

void ParserCriticalPath::end_apply() {
    if (LOGGING(4)) {
        LOG4("Critical Path Result of " << gress_);
        LOG4(result); }
    final_result = result;
}
