#include <cmath>
#include "ir/ir.h"
#include "lib/bitops.h"
#include "lib/log.h"
#include "split_alpm.h"

const std::set<unsigned> SplitAlpm::valid_partition_values = {1024, 2048, 4096, 8192};
const cstring SplitAlpm::ALGORITHMIC_LPM_PARTITIONS  = "alpm_partitions";
const cstring SplitAlpm::ALGORITHMIC_LPM_SUBTREES_PER_PARTITION  = "alpm_subtrees_per_partition";

/// create Pre-classifier table
const IR::MAU::Table* SplitAlpm::create_pre_classifier_tcam(
        IR::MAU::Table* tbl, IR::TempVar* tv, unsigned partition_index_bits,
        unsigned pre_classifer_number_entries) {
    auto clone = tbl->clone();

    clone->name = tbl->name + "__alpm_preclassifier";

    auto action_name = clone->name + "__set_partition_index";
    auto action_arg = new IR::MAU::ActionArg(IR::Type_Bits::get(partition_index_bits),
                                        action_name,
                                        IR::ID("partition_index"));
    auto prim = new IR::MAU::Instruction("set", tv, action_arg);
    auto action = new IR::MAU::Action(IR::ID(action_name));
    action->args.push_back(action_arg);
    action->action.push_back(prim);
    // Need a default action for potential meta init
    action->init_default = true;

    /// pre_classifier table has only one action.
    clone->actions.clear();
    clone->actions.emplace(action_name, action);

    // These values belong with the ATCAM table, not the pre-classifier
    clone->next.clear();
    clone->attached.clear();

    clone->layout.pre_classifier = true;
    clone->layout.pre_classifer_number_entries = pre_classifer_number_entries;

    return clone;
}

const IR::MAU::Table* SplitAlpm::create_atcam(IR::MAU::Table* tbl, IR::TempVar* tv,
        unsigned partition_count, unsigned partition_index_bits,
        unsigned subtrees_per_partition) {
    // add partition_index key to list of;
    auto clone = tbl->clone();

    auto partition_index = new IR::MAU::TableKey(tv, "exact");
    clone->match_key.push_back(partition_index);

    clone->layout.atcam = true;
    clone->layout.alpm = true;
    clone->layout.ternary = false;
    clone->layout.partition_count = partition_count;
    clone->layout.partition_bits = partition_index_bits;
    clone->layout.subtrees_per_partition = subtrees_per_partition;
    return clone;
}

const IR::Node* SplitAlpm::postorder(IR::MAU::Table* tbl) {
    if (!tbl->match_table)
        return tbl;

    auto annot = tbl->match_table->getAnnotations();
    if (auto s = annot->getSingle("alpm")) {
        ERROR_CHECK(s->expr.size() > 0, "%s: Please provide a valid alpm "
                "for table %s", tbl->srcInfo, tbl->name);
        auto pragma_val = s->expr.at(0)->to<IR::Constant>();
        ERROR_CHECK(pragma_val != nullptr, "%s: Please provide a valid alpm "
                "for table %s", tbl->srcInfo, tbl->name);
    } else {
        return tbl;
    }

    auto number_partitions = 1024;
    auto number_subtrees_per_partition = 2;

    if (auto s = annot->getSingle(ALGORITHMIC_LPM_PARTITIONS)) {
        ERROR_CHECK(s->expr.size() > 0, "%s: Please provide a valid %s "
                "for table %s", tbl->srcInfo, ALGORITHMIC_LPM_PARTITIONS, tbl->name);
        auto pragma_val = s->expr.at(0)->to<IR::Constant>();
        ERROR_CHECK(pragma_val != nullptr, "%s: Please provide a valid %s "
                "for table %s", tbl->srcInfo, ALGORITHMIC_LPM_PARTITIONS, tbl->name);

        auto alg_lpm_partitions_value = mpz_get_ui(pragma_val->value.get_mpz_t());
        if (valid_partition_values.find(alg_lpm_partitions_value) != valid_partition_values.end()) {
            number_partitions = mpz_get_ui(pragma_val->value.get_mpz_t());
        } else {
            ::error("Unsupported %s value of %s for table %s."
                            "\n  Allowed values are 1024, 2048, 4096, and 8192.",
                    ALGORITHMIC_LPM_PARTITIONS, pragma_val->value, tbl->name);
        }
    }

    if (auto s = annot->getSingle(ALGORITHMIC_LPM_SUBTREES_PER_PARTITION)) {
        ERROR_CHECK(s->expr.size() > 0, "%s: Please provide a valid %s "
                "for table %s", tbl->srcInfo, ALGORITHMIC_LPM_SUBTREES_PER_PARTITION, tbl->name);
        auto pragma_val = s->expr.at(0)->to<IR::Constant>();
        ERROR_CHECK(pragma_val != nullptr, "%s: Please provide a valid %s "
                "for table %s", tbl->srcInfo, ALGORITHMIC_LPM_SUBTREES_PER_PARTITION, tbl->name);

        auto alg_lpm_subtrees_value = mpz_get_ui(pragma_val->value.get_mpz_t());
        if (alg_lpm_subtrees_value <= 10) {
            number_subtrees_per_partition = alg_lpm_subtrees_value;
        } else {
            ::error("Unsupported %s value of %s for table %s."
                            "\n  Allowed values are in the range [1:10].",
                    ALGORITHMIC_LPM_SUBTREES_PER_PARTITION, pragma_val->value, tbl->name);
        }
    }

    auto partition_index_bits = ::ceil_log2(number_partitions);
    auto pre_classifer_number_entries = number_partitions * number_subtrees_per_partition;

    auto lpm_cnt = 0;
    for (auto f : tbl->match_key) {
        if (f->match_type == "lpm") {
            lpm_cnt += 1;
        }
    }
    ERROR_CHECK(lpm_cnt == 1, "To use algorithmic lpm, exactly one field in the match key "
            "must have a match type of lpm.  Table '%s' has %d.", tbl->name, lpm_cnt);

    auto hdr_type_name = tbl->name + "__metadata_t";
    auto hdr_instance_name = tbl->name + "__metadata";
    auto pidx_field_name = tbl->name + "_partition_index";
    auto tv_name = hdr_instance_name + "." + pidx_field_name;
    auto tv = new IR::TempVar(IR::Type_Bits::get(partition_index_bits), false, tv_name.c_str());

    auto tables = new IR::Vector<IR::MAU::Table>();
    tables->push_back(create_pre_classifier_tcam(tbl, tv, partition_index_bits,
                                                 pre_classifer_number_entries));
    tables->push_back(create_atcam(tbl, tv, number_partitions,
                partition_index_bits, number_subtrees_per_partition));
    return tables;
}

AlpmSetup::AlpmSetup() : PassManager {
    new SplitAlpm,
} {}
