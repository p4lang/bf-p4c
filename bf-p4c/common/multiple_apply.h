#ifndef BF_P4C_COMMON_MULTIPLE_APPLY_H_
#define BF_P4C_COMMON_MULTIPLE_APPLY_H_

#include <set>
#include "bf-p4c/mau/mau_visitor.h"
#include "bf-p4c/mau/table_mutex.h"
#include "lib/ordered_set.h"
#include "lib/ordered_map.h"






class MultipleApply : public PassManager {
    // gtest requirements
    std::set<cstring> mutex_errors;
    std::set<cstring> distinct_errors;
    std::set<cstring> gateway_chain_errors;

    TablesMutuallyExclusive mutex;
    class MutuallyExclusiveApplies : public MauInspector {
        TablesMutuallyExclusive &mutex;
        std::set<cstring> &errors;
        ordered_map<const IR::P4Table *, ordered_set<const IR::MAU::Table *>> mutex_apply;
        void postorder(const IR::MAU::Table *) override;

     public:
        explicit MutuallyExclusiveApplies(TablesMutuallyExclusive &m, std::set<cstring> &e)
            : mutex(m), errors(e) {}
    };

    typedef ordered_map<const IR::MAU::TableSeq *, const IR::MAU::TableSeq *> tsmap_t;
    class EquivalentTableSequence : public MauInspector {
        tsmap_t &equiv_seqs;
        tsmap_t &equiv_tails;
        ordered_set<const IR::MAU::TableSeq *> unique_seqs;

        profile_t init_apply(const IR::Node *) override;
        void postorder(const IR::MAU::TableSeq *) override;
        bool equiv(const IR::MAU::Table *a, const IR::MAU::Table *b);
        bool equiv(const IR::MAU::TableSeq *a, const IR::MAU::TableSeq *b);
        bool tail_equiv(const IR::MAU::TableSeq *a, const IR::MAU::TableSeq *b);
        bool equiv_gateway(const IR::Expression *a, const IR::Expression *b);

     public:
        explicit EquivalentTableSequence(tsmap_t &es, tsmap_t &et)
            : equiv_seqs(es), equiv_tails(et) {}
    };

    class MergeTails : public MauModifier {
        tsmap_t                 &equiv_tails;
        std::set<cstring>       names;

        bool preorder(IR::BFN::Pipe *) override;
        void postorder(IR::BFN::Pipe *) override;
        bool preorder(IR::MAU::TableSeq *) override;
     public:
        explicit MergeTails(tsmap_t &et) : equiv_tails(et) {}
    };

    class RefactorSequence : public MauTransform {
        ordered_map<const IR::MAU::TableSeq *, const IR::MAU::TableSeq *> &equiv_seqs;
        const IR::MAU::TableSeq *preorder(IR::MAU::TableSeq *) override;

     public:
        explicit RefactorSequence(ordered_map<const IR::MAU::TableSeq *,
                                              const IR::MAU::TableSeq *> &es)
            : equiv_seqs(es) {}
    };

    class DistinctTables : public MauInspector {
        std::set<cstring> &errors;
        ordered_set<const IR::P4Table *> distinct_tables;
        bool preorder(const IR::MAU::Table *) override;

     public:
        explicit DistinctTables(std::set<cstring> &e) : errors(e) {}
    };

    class UniqueGatewayChain : public MauInspector {
        std::set<cstring> &errors;
        ordered_map<const IR::P4Table *, safe_vector<const IR::MAU::Table *>> gateway_chains;
        bool preorder(const IR::MAU::Table *) override;

     public:
        explicit UniqueGatewayChain(std::set<cstring> &e) : errors(e) { visitDagOnce = false; }
    };

    tsmap_t equiv_seqs;
    tsmap_t equiv_tails;

 public:
    bool mutex_error(cstring name) {
        return mutex_errors.find(name) != mutex_errors.end();
    }

    bool distinct_error(cstring name) {
        return distinct_errors.find(name) != distinct_errors.end();
    }

    bool gateway_chain_error(cstring name) {
        return gateway_chain_errors.find(name) != gateway_chain_errors.end();
    }

    MultipleApply();
};
#endif /* BF_P4C_COMMON_MULTIPLE_APPLY_H_ */
