#include "multiple_apply.h"

/** The whole point of the MultipleApply PassManager is to both convert all multiple applies of
 *  an individual match table to one IR::MAU::Table node in the backend.  The extract_maupipe
 *  code creates an IR::MAU::Table object for each table apply, even if multiple apply calls
 *  refer to an individual match table.
 *
 *  It is possible for an individual Tofino table to share multiple applies for the following
 *  reasons:
 *    - the applies are called on mutually exclusive paths, i.e. the table can only be applied
 *      once per packet
 *    - the next table path from each of the applies is the exact same
 *
 *  Fortunately, the backend IR structure gives us some easy ability to quickly manipulate and
 *  determine if the applies have been called correctly.  The IR tree is made up of
 *  IR::MAU::TableSeq objects.  If these Table Sequences are mutually exclusive and equivalent,
 *  then one can be replaced with another
 *
 *  There is a final constraint that the compiler is currently enforcing.  The gateways for
 *  all table applies must be equivalent.  If they are not equivalent, then the gateways must
 *  be placed separately from these match tables, as the pathways into a particular table might
 *  be different.  This is enforced by UniqueGatewayChain.
 *
 *  Examples of what is possible and what is not possible are displayed within the gtest
 *  multiple_apply.cpp
 */

void MultipleApply::MutuallyExclusiveApplies::postorder(const IR::MAU::Table *tbl) {
    if (tbl->match_table == nullptr)
        return;
    if (mutex_apply.find(tbl->match_table) != mutex_apply.end()) {
        for (auto paired_table : mutex_apply.at(tbl->match_table)) {
            if (!mutex(tbl, paired_table)) {
                ::error("%s: Not all applies of table %s are mutually exclusive",
                        tbl->srcInfo, tbl->name);
                errors.emplace(tbl->match_table->name);
            }
        }
    }
    mutex_apply[tbl->match_table].emplace(tbl);
}

Visitor::profile_t MultipleApply::EquivalentTableSequence::init_apply(const IR::Node *node) {
    equiv_seqs.clear();
    unique_seqs.clear();
    return MauInspector::init_apply(node);
}

/** Tries to find sequences that are equivalent. Saves them so that they can be replaced later
 */
void MultipleApply::EquivalentTableSequence::postorder(const IR::MAU::TableSeq *seq) {
    bool equiv_found = false;
    for (auto unique_seq : unique_seqs) {
        if (equiv(seq, unique_seq)) {
            equiv_seqs[seq] = unique_seq;
            equiv_found = true;
            break;
        }
    }

    if (!equiv_found)
        unique_seqs.emplace(seq);
}

/** Equivalence check.  If all match table in sequence A corresponds with all match table in
 *  sequence B, all gateways in sequence A correspond with all gateways in sequence B, and
 *  lastly, all next tables of each table in sequence A correspond with sequence B, then the
 *  the sequences are equivalent
 */
bool MultipleApply::EquivalentTableSequence::equiv(const IR::MAU::TableSeq *a,
        const IR::MAU::TableSeq *b) {
    if (a->tables.size() != b->tables.size())
        return false;
    for (size_t i = 0; i < a->tables.size(); i++) {
        auto a_table = a->tables[i];
        auto b_table = b->tables[i];

        if (a_table->match_table != b_table->match_table)
            return false;
        if (a_table->gateway_only() != b_table->gateway_only())
            return false;
        if (a_table->gateway_only()) {
            if (a_table->gateway_rows.size() != b_table->gateway_rows.size())
                 return false;
            for (size_t j = 0; j < a_table->gateway_rows.size(); j++) {
                auto a_gw_row = a_table->gateway_rows[j];
                auto b_gw_row = b_table->gateway_rows[j];
                if (!equiv_gateway(a_gw_row.first, b_gw_row.first) ||
                    a_gw_row.second != b_gw_row.second)
                    return false;
            }
        }

        if (a_table->next.size() != b_table->next.size())
            return false;

        for (auto next_table : a_table->next) {
            auto a_next = next_table.second;
            auto a_next_name = next_table.first;
            if (b_table->next.find(a_next_name) == b_table->next.end())
                return false;
            auto b_next = b_table->next.at(a_next_name);
            if (!equiv(a_next, b_next))
                return false;
        }
    }
    return true;
}

/** This is a rather dumb check of equivalent gateways.  Instead of comparing the symbolic value
 *  of the gateway, this just directly compares that the gateway expression are identical
 */
bool MultipleApply::EquivalentTableSequence::equiv_gateway(const IR::Expression *a,
        const IR::Expression *b) {
    if (a == nullptr && b == nullptr) return true;
    if (a == nullptr || b == nullptr) return false;
    if (*a == *b) return true;
    if (typeid(*a) != typeid(*b)) return false;
    if (auto a_bin = a->to<IR::Operation_Binary>()) {
        auto b_bin = b->to<IR::Operation_Binary>();
        return equiv_gateway(a_bin->left, b_bin->left)
            && equiv_gateway(a_bin->right, b_bin->right);
    }

    if (auto a_rel = a->to<IR::Operation_Relation>()) {
        auto b_rel = b->to<IR::Operation_Relation>();
        return equiv_gateway(a_rel->left, b_rel->left)
            && equiv_gateway(a_rel->right, b_rel->right);
    }
    return false;
}

/** This replaces all copies of a sequence with just one version of the sequence.  This must be
 *  a preorder rather than a postorder, as one could have nested replaceable sequences
 */
const IR::MAU::TableSeq *MultipleApply::RefactorSequence::preorder(IR::MAU::TableSeq *seq) {
    auto orig = getOriginal<IR::MAU::TableSeq>();
    if (equiv_seqs.find(orig) != equiv_seqs.end())
        return equiv_seqs.at(orig);
    return seq;
}

/** This pass ensures that after our Transform, only one copy of the match table exists
 */
bool MultipleApply::DistinctTables::preorder(const IR::MAU::Table *tbl) {
    if (tbl->match_table == nullptr)
        return true;
    if (distinct_tables.find(tbl->match_table) != distinct_tables.end()) {
        ::error("%s: Table %s is applied multiple times, and the next table information cannot "
                "correctly propagate through this multiple application", tbl->srcInfo,
                tbl->match_table->name);
        errors.emplace(tbl->match_table->name);
    } else {
        distinct_tables.emplace(tbl->match_table);
    }
    return true;
}

/** This particular pass ensures that any table considered a gateway is identical in the IR
 *  tree above each appearance of a match table.  This is to ensure that these gateways
 *  do not have any limitations on being paired with any table
 */
bool MultipleApply::UniqueGatewayChain::preorder(const IR::MAU::Table *tbl) {
    if (tbl->match_table == nullptr)
        return true;

    safe_vector<const IR::MAU::Table *> gateway_chain;
    for (auto ctxt = getContext(); ctxt; ctxt = ctxt->parent) {
        if (ctxt->node->is<IR::BFN::Pipe>()) {
            break;
        } else if (ctxt->node->is<IR::MAU::TableSeq>()) {
            continue;
        } else if (auto upper_table = ctxt->node->to<IR::MAU::Table>()) {
            if (upper_table->gateway_only())
                gateway_chain.push_back(upper_table);
        } else {
            BUG("Unexpected IR Node within the table structure.");
        }
    }

    if (gateway_chains.find(tbl->match_table) == gateway_chains.end()) {
        gateway_chains[tbl->match_table] = gateway_chain;
    } else {
        auto chain_check = gateway_chains.at(tbl->match_table);
        if (chain_check.size() != gateway_chain.size()) {
            ::error("%s: Table %s is applied multiple times, but the gateway conditionals "
                    "determining control flow are different for these instances.  Currently, "
                    "the compiler does not allow different gateway conditionals above a "
                    "repeated apply", tbl->srcInfo, tbl->name);
            errors.emplace(tbl->name);
            return true;
        }

        for (size_t i = 0; i < gateway_chain.size(); i++) {
            if (chain_check[i] != gateway_chain[i]) {
                ::error("%s: Table %s is applied multiple times, but the gateway conditionals "
                       "determining control flow are different for these instances.  Currently, "
                       "the compiler does not allow different gateway conditionals above a "
                       "repeated apply", tbl->srcInfo, tbl->name);
                errors.emplace(tbl->name);
                return true;
            }
        }
    }
    return true;
}

MultipleApply::MultipleApply() {
    addPasses({
        &mutex,
        new MutuallyExclusiveApplies(mutex, mutex_errors),
        new EquivalentTableSequence(equiv_seqs),
        new RefactorSequence(equiv_seqs),
        new DistinctTables(distinct_errors),
        new UniqueGatewayChain(gateway_chain_errors)
    });
}
