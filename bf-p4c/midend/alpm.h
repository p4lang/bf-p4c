#ifndef BF_P4C_MIDEND_ALPM_H_
#define BF_P4C_MIDEND_ALPM_H_

#include "ir/ir.h"
#include "lib/cstring.h"
#include "frontends/p4/typeMap.h"
#include "frontends/p4/externInstance.h"
#include "frontends/p4/methodInstance.h"
#include "frontends/common/resolveReferences/resolveReferences.h"

namespace BFN {

class CollectAlpmInfo : public Inspector {
 public:
    std::set<cstring> alpm_actions;
    std::set<cstring> alpm_table;
    P4::ReferenceMap* refMap;
    P4::TypeMap* typeMap;

 public:
    CollectAlpmInfo(P4::ReferenceMap* refMap, P4::TypeMap* typeMap) :
        refMap(refMap), typeMap(typeMap) {}

    void postorder(const IR::P4Table* tbl) override;
};

/**
 *
 */
class HasTableApply : public Inspector {
    P4::ReferenceMap* refMap;
    P4::TypeMap*      typeMap;

 public:
    const IR::P4Table*  table;
    const IR::MethodCallExpression* call;
    HasTableApply(P4::ReferenceMap* refMap, P4::TypeMap* typeMap) :
        refMap(refMap), typeMap(typeMap), table(nullptr), call(nullptr)
    { CHECK_NULL(refMap); CHECK_NULL(typeMap); setName("HasTableApply"); }
    void postorder(const IR::MethodCallExpression* expression) override {
        auto mi = P4::MethodInstance::resolve(expression, refMap, typeMap);
        if (!mi->isApply()) return;
        auto am = mi->to<P4::ApplyMethod>();
        if (!am->object->is<IR::P4Table>()) return;
        BUG_CHECK(table == nullptr, "%1% and %2%: multiple table applications in one expression",
                  table, am->object);
        table = am->object->to<IR::P4Table>();
        call = expression;
        LOG3("Invoked table is " << dbp(table));
    }
    bool preorder(const IR::Member* member) override {
        if (member->member == "hit" || member->member == "miss")
            return true;
        return false;
    }
};

// This class implements ALPM as a pair of pre-classifer tcam table and an
// algorithmic tcam table. Currently, this class supports two different
// implementations selected based on the constructor parameters to the Alpm
// extern.
//
// 1). Alpm(number_partitions = 4095, subtrees_per_partition=2) alpm;
//     table alpm {
//        key = { f0 : exact; f1 : lpm }
//        actions = { ... }
//        alpm = alpm;
//     }
//
// is translated to
//     table alpm_preclassifier {
//         key = { f0 : exact; f1 : lpm }
//         actions = { set_partition_index; }
//     }
//     table alpm {
//          key = { f0 : exact; f1 : lpm; partition_index : atcam_partition_index; }
//          actions = { ... }
//     }
//
// 2). Alpm(number_partitions = 4095, subtrees_per_partition=2,
//          atcam_subset_width = 12, shift_granularity=1) alpm;
//
// is translated to
//     action set_partition_index_0 ( bit<..> pidx, bit<..> pkey ) {
//         partition_index = pidx;
//         partition_key = pkey;
//     }
//
//     ...
//
//     table alpm_preclassifier {
//         key = { f0 : exact; f1 : lpm {
//         actions = { set_partition_index_0; set_partition_index_1; ... }
//     }
//
//     table alpm {
//         key = { partition_key : lpm; partition_index : atcam_partition_index; }
//         actions = { ... }
//     }
//
class SplitAlpm : public Transform {
    CollectAlpmInfo* alpm_info;
    P4::ReferenceMap* refMap;
    P4::TypeMap* typeMap;
    static const std::set<unsigned> valid_partition_values;
    const IR::MAU::Table* create_pre_classifier_tcam(
            IR::MAU::Table* tbl, IR::TempVar* tv, IR::TempVar* tk,
            unsigned partition_index_bits,
            unsigned pre_classifer_number_entries,
            unsigned pre_classifer_number_actions);
    bool values_through_pragmas(const IR::P4Table *tbl, int &number_of_partitions,
            int &number_subtrees_par_partition);
    bool values_through_impl(const IR::P4Table *tbl, int &number_of_partitions,
            int &number_subtrees_per_partition, int &atcam_subset_width,
            int &shift_granularity);

    const IR::Node* postorder(IR::P4Table* tbl) override;
    const IR::Node* postorder(IR::MethodCallStatement*) override;
    const IR::Node* postorder(IR::IfStatement*) override;

    const IR::IndexedVector<IR::Declaration>* create_temp_var(
            const IR::P4Table*, unsigned, unsigned, unsigned);
    const IR::IndexedVector<IR::Declaration>* create_preclassifer_actions(
            const IR::P4Table*, unsigned, unsigned, unsigned,
            unsigned, const IR::Expression*);
    const IR::P4Table* create_preclassifier_table(const IR::P4Table*, unsigned,
            unsigned, unsigned);
    const IR::P4Table* create_atcam_table(const IR::P4Table*, unsigned,
            unsigned, unsigned, int, int);

 public:
    static const cstring ALGORITHMIC_LPM_PARTITIONS;
    static const cstring ALGORITHMIC_LPM_SUBTREES_PER_PARTITION;

    SplitAlpm(CollectAlpmInfo *info, P4::ReferenceMap* refMap, P4::TypeMap* typeMap) :
        alpm_info(info), refMap(refMap), typeMap(typeMap) {}
};

class AlpmImplementation : public PassManager {
 public:
    AlpmImplementation(P4::ReferenceMap* refMap, P4::TypeMap* typeMap);
};

}  // namespace BFN

#endif  /* BF_P4C_MIDEND_ALPM_H_ */


