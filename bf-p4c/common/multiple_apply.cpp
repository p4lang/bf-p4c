#include "multiple_apply.h"
#include "bf-p4c/mau/default_next.h"

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
                errors.emplace(tbl->match_table->externalName());
            }
        }
    }
    mutex_apply[tbl->match_table].emplace(tbl);
}

Visitor::profile_t MultipleApply::EquivalentTableSequence::init_apply(const IR::Node *node) {
    equiv_tails.clear();
    unique_seqs.clear();
    return MauInspector::init_apply(node);
}

/** Tries to find sequences that are equivalent. Saves them so that they can be replaced later
 */
void MultipleApply::EquivalentTableSequence::postorder(const IR::MAU::TableSeq *seq) {
    BUG_CHECK(unique_seqs.count(seq) == 0, "Inspector calling same seq more than once");
    for (auto unique_seq : unique_seqs) {
        if (auto len = tail_equiv(seq, unique_seq)) {
            if (equiv_tails[seq].len < len) {
                equiv_tails[seq].len = len;
                equiv_tails[seq].other = unique_seq; }
            if (equiv_tails[unique_seq].len < len) {
                equiv_tails[unique_seq].len = len;
                equiv_tails[unique_seq].other = seq; }
        }
    }
    unique_seqs.emplace(seq);
}

/** Equivalence checks. If all match table in sequence A corresponds with all match table in
 *  sequence B, all gateways in sequence A correspond with all gateways in sequence B, and
 *  lastly, all next tables of each table in sequence A correspond with sequence B, then the
 *  the sequences are equivalent
 */
bool MultipleApply::EquivalentTableSequence::equiv(const IR::MAU::Table *a,
                                                   const IR::MAU::Table *b) {
    if (a->match_table != b->match_table)
        return false;
    if (a->gateway_only() != b->gateway_only())
        return false;
    if (a->gateway_only()) {
        if (a->name.startsWith("$tstail"))
            // created by previous iteration of MergeTails, so don't do it again
            return false;
        if (a->gateway_rows.size() != b->gateway_rows.size())
             return false;
        for (size_t j = 0; j < a->gateway_rows.size(); j++) {
            auto a_gw_row = a->gateway_rows[j];
            auto b_gw_row = b->gateway_rows[j];
            if (!equiv_gateway(a_gw_row.first, b_gw_row.first) ||
                a_gw_row.second != b_gw_row.second)
                return false;
        }
    }

    if (a->next.size() != b->next.size())
        return false;

    for (auto next_table : a->next) {
        auto a_next = next_table.second;
        auto a_next_name = next_table.first;
        if (b->next.find(a_next_name) == b->next.end())
            return false;
        auto b_next = b->next.at(a_next_name);
        if (!equiv(a_next, b_next))
            return false;
    }

    return true;
}

bool MultipleApply::EquivalentTableSequence::equiv(const IR::MAU::TableSeq *a,
        const IR::MAU::TableSeq *b) {
    if (a->tables.size() != b->tables.size())
        return false;
    for (size_t i = 0; i < a->tables.size(); i++) {
        if (!equiv(a->tables[i], b->tables[i])) return false;
    }
    return true;
}

/** return the number of trailing identical tables for two sequences. */
size_t MultipleApply::EquivalentTableSequence::tail_equiv(const IR::MAU::TableSeq *a,
        const IR::MAU::TableSeq *b) {
    size_t rv = 0;
    auto atail = a->tables.end(), btail = b->tables.end();
    while (rv < a->tables.size() && rv < b->tables.size() && equiv(*--atail, *--btail))
        ++rv;
    return rv;
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

const IR::BFN::Pipe *MultipleApply::MergeTails::preorder(IR::BFN::Pipe *pipe) {
    if (equiv_tails.empty()) {
        // if equiv_tails is empty, there's nothing to be done, so return immediately
        prune();
    } else {
        LOG5("MergeTails size=" << equiv_tails.size() << ":\n" << pipe->thread[INGRESS].mau);
        for (auto &el : equiv_tails)
            LOG5("  [" << el.first->id << "] matches [" << el.second.other->id << "] "
                 "len=" << el.second.len); }
    return pipe;
}

const IR::BFN::Pipe *MultipleApply::MergeTails::postorder(IR::BFN::Pipe *pipe) {
    LOG5("MergeTails after:\n" << pipe->thread[INGRESS].mau);
    return pipe;
}

/** If the tail-end of this TableSeq is identical to the tail another TableSeq, then remove
 *  it and replace it with a trivial table that just runs the tail directly.  If (one of)
 *  the sequences IS the entire tail, then that sequence can be used directly in both places
 *  and an noop gateway is not needed when it is the entire sequence.  If both sequences
 *  are the whole tail (identical sequences), then they are just replaced by one.
 *  If when looking at another table with a common tail, that table has a longer tail with
 *  3rd table, then we do nothing, letting the pass merge (just) the longest tails.  We
 *  run this pass repeatedly until all tails are merged.
 *
 *  This may introduce a noop gateway to set the next table, wasting a logical
 *  table and a gateway.  Unfortunately we currently have no other way of representing this
 *  in the Table/TableSeq DAG.  The later RemoveNoopGateways pass will probably remove it,
 *  but there are corner cases where it is unable to remove it.
 *
 *  The code in EquivalentTableSequence identifies TableSeq that have matching tails, and this
 *  method splits those matched seqs into a prefix and the tail.  As an example, with
 *
 *      if (test) {
 *          t1.apply();
 *          t2.apply();
 *          t3.apply();
 *          t4.apply();
 *      } else {
 *          t3.apply();
 *          t4.apply();
 *      }
 *
 *  EquivalentTableSequence will mark the t3/t4 sequence as matching the tail of the t1/t2/t3/t4
 *  sequence, so the latter will have its tail split off, rewriting this as
 *
 *      if (test) {
 *          t1.apply();
 *          t2.apply();
 *          if (1) {
 *              t3.apply();
 *              t4.apply(); }
 *      } else {
 *          t3.apply();
 *          t4.apply();
 *      }
 *
 * with a common t3/t4 sequence.  This allows table placement to place those tables once.
 */
const IR::MAU::TableSeq *MultipleApply::MergeTails::postorder(IR::MAU::TableSeq *seq) {
    auto *orig = getOriginal<IR::MAU::TableSeq>();
    if (!equiv_tails.count(orig)) return seq;
    auto &info = equiv_tails.at(orig);
    if (!info.tail) {
        auto &rinfo = equiv_tails.at(info.other);
        if (rinfo.len > info.len) {
            // the other seq has longer common tail with a 3rd seq, so we need
            // to defer dealing with this seq until they've been merged.
            return seq; }
        BUG_CHECK(rinfo.len == info.len, "MergeTails invalid data");
        if (!(info.tail = rinfo.tail)) {
            if (info.len == seq->size()) {
                info.tail = rinfo.tail = *seq == *orig ? orig : seq;
                return seq;
            } else if (info.len == rinfo.other->size()) {
                info.tail = rinfo.tail = rinfo.other;
            } else {
                auto *split = new IR::MAU::TableSeq();
                split->tables.insert(split->tables.begin(),
                    seq->tables.begin() + (seq->size() - info.len), seq->tables.end());
                info.tail = rinfo.tail = split; } } }
    if (info.len == seq->size())
        return info.tail;
    seq->tables.erase(seq->tables.begin() + (seq->size() - info.len), seq->tables.end());
    auto *tbl = new IR::MAU::Table(cstring::make_unique(names, "$tstail", '.'),
                                   seq->tables.front()->gress);
    names.insert(tbl->name);
    tbl->gateway_rows.emplace_back(nullptr, "$jmp");
    tbl->next["$jmp"] = info.tail;
    seq->tables.push_back(tbl);
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
        errors.emplace(tbl->match_table->externalName());
    } else {
        distinct_tables.emplace(tbl->match_table);
    }
    return true;
}

MultipleApply::MultipleApply() {
    addPasses({
        &mutex,
        new MutuallyExclusiveApplies(mutex, mutex_errors),
        new PassRepeatUntil({
            new EquivalentTableSequence(equiv_tails),
            new MergeTails(equiv_tails)
        }, [this]()->bool { return equiv_tails.empty(); }),
        new DistinctTables(distinct_errors),
        // Still currently guaranteeing this data for both Tofino and JBay, until we change the
        // IR rules
        new DefaultNext(true),
    });
}

void MultipleApply2::CheckStaticNextTable::postorder(const IR::MAU::Table *tbl) {
    if (self.canon_table.count(tbl->match_table) == 0) {
        // This is the first time we are encountering an application of this table. Nothing to
        // check, but record this as the canonical table.
        self.canon_table[tbl->match_table] = tbl;
        return;
    }

    // Mark the table as needing de-duplication.
    self.to_replace.insert(tbl);

    // Check that the conditional control flow following this table application is the same as that
    // for the canonical Table object.
    //
    // Check that the next-table entries for the table being visited also appear as next-table
    // entries for the canonical table.
    auto canon_tbl = self.canon_table.at(tbl->match_table);
    for (auto& entry : tbl->next) {
        auto& key = entry.first;
        auto& cur_seq = entry.second;

        if (canon_tbl->next.count(key) == 0) {
            ::error("Table %1% has incompatible next-table chains: not all applications of this "
                    "table have a next-table chain for %2%.",
                    tbl->externalName(), key);
            return;
        }

        auto canon_seq = canon_tbl->next.at(key);
        if (canon_seq->size() != cur_seq->size()) {
            ::error("Table %1% has incompatible next-table chains: not all applications of this "
                    "table have the same chain length for %2%.",
                    tbl->externalName(), key);
            return;
        }

        for (size_t i = 0; i < cur_seq->size(); i++) {
            auto cur_seq_tbl = cur_seq->tables.at(i);
            auto canon_seq_tbl = canon_seq->tables.at(i);
            if (cur_seq_tbl->match_table != canon_seq_tbl->match_table)
                ::error("Table %1% has incompatible next-table chains for %2%, differing at "
                        "position %3%, with tables %4% and %5%", tbl->externalName(), key,
                        i, cur_seq_tbl->externalName(), canon_seq_tbl->externalName());
        }
    }

    // Also check the reverse: the next-table entries for the canonical table also appear as
    // next-table entries for the table being visited.
    for (auto& entry : canon_tbl->next) {
        auto& key = entry.first;

        if (tbl->next.count(key) == 0) {
            ::error("Table %1% has incompatible next-table chains: not all applications of this "
                    "table have a next-table chain for %2%.",
                    tbl->externalName(), key);
            return;
        }
    }
}

const IR::Node *MultipleApply2::DeduplicateTables::preorder(IR::MAU::Table *tbl) {
    auto orig_tbl = getOriginal<IR::MAU::Table>();
    if (self.to_replace.count(orig_tbl) == 0)
        return tbl;

    auto orig_p4_tbl = orig_tbl->match_table;
    return self.canon_table.at(orig_p4_tbl);
}

MultipleApply2::MultipleApply2(bool check_topology) {
    addPasses({
        new CheckStaticNextTable(*this),
        new DeduplicateTables(*this),
        check_topology ? new CheckTopologicalTables() : nullptr
    });
}

