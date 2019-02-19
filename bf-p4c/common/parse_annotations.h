#ifndef EXTENSIONS_BF_P4C_COMMON_PARSE_ANNOTATIONS_H_
#define EXTENSIONS_BF_P4C_COMMON_PARSE_ANNOTATIONS_H_

#include "ir/ir.h"
#include "bf-p4c/mau/split_alpm.h"
#include "bf-p4c/phv/pragma/phv_pragmas.h"
#include "frontends/p4/parseAnnotations.h"

namespace BFN {

/** Parses Barefoot-specific annotations. */
class ParseAnnotations : public P4::ParseAnnotations {
 public:
    ParseAnnotations() : P4::ParseAnnotations("BFN", true, {
                PARSE_TRIPLE(PHV::pragma::ALIAS, StringLiteral),
                PARSE_PAIR(PHV::pragma::ATOMIC, StringLiteral),
                PARSE_EXPRESSION_LIST(PHV::pragma::CONTAINER_SIZE),
                PARSE_TRIPLE(PHV::pragma::CONTAINER_TYPE, StringLiteral),
                PARSE_PAIR(PHV::pragma::DISABLE_DEPARSE_ZERO, StringLiteral),
                PARSE_TRIPLE(PHV::pragma::MUTUALLY_EXCLUSIVE, StringLiteral),
                PARSE_PAIR(PHV::pragma::NO_INIT, StringLiteral),
                PARSE_PAIR(PHV::pragma::NO_OVERLAY, StringLiteral),
                PARSE_PAIR(PHV::pragma::NOT_DEPARSED, StringLiteral),
                PARSE_PAIR(PHV::pragma::NOT_PARSED, StringLiteral),
                PARSE_PAIR(PHV::pragma::SOLITARY, StringLiteral),

                PARSE(SplitAlpm::ALGORITHMIC_LPM_PARTITIONS, Expression),
                PARSE(SplitAlpm::ALGORITHMIC_LPM_SUBTREES_PER_PARTITION, Expression),

                PARSE_EMPTY("__ghost_metadata"),
                PARSE_EMPTY("__intrinsic_metadata"),
                PARSE("alpm", Expression),
                PARSE("atcam_number_partitions", Expression),
                PARSE("atcam_partition_index", StringLiteral),
                PARSE("calculated_field_update_location", StringLiteral),
                PARSE_EMPTY("chain_address"),
                PARSE("chain_total_size", Expression),
                PARSE("dont_translate_extern_method", StringLiteral),
                PARSE("dynamic_table_key_masks", Expression),
                PARSE("entries_with_ranges", Expression),
                PARSE_TRIPLE("field_list_field_slice", Expression),
                PARSE_PAIR("force_shift", Expression),
                PARSE("idletime_interval", Expression),
                PARSE("idletime_per_flow_idletime", Expression),
                PARSE("idletime_precision", Expression),
                PARSE("idletime_two_way_notification", Expression),
                PARSE("ignore_table_dependency", StringLiteral),
                PARSE("lrt_enable", Expression),
                PARSE("lrt_scale", Expression),
                PARSE("max_loop_depth", Expression),
                PARSE("min_width", Expression),
                PARSE("mode", StringLiteral),
                PARSE_EMPTY("not_extracted_in_egress"),
                PARSE_PAIR("pa_do_not_bridge", StringLiteral),
                PARSE("pack", Expression),
                PARSE_EMPTY("packet_entry"),
                PARSE_TRIPLE("phase0", Expression),
                PARSE("pre_color", Expression),
                PARSE("proxy_hash_algorithm", StringLiteral),
                PARSE("proxy_hash_width", Expression),
                PARSE("random_seed", Expression),
                PARSE("reduction_or_group", StringLiteral),
                PARSE("reg", StringLiteral),
                PARSE("residual_checksum_parser_update_location", StringLiteral),
                PARSE("selector_max_group_size", Expression),
                PARSE("selector_num_max_groups", Expression),
                PARSE("stage", Expression),
                PARSE("terminate_parsing", StringLiteral),
                PARSE("ternary", Expression),
                PARSE("use_hash_action", Expression),
                PARSE("ways", Expression),

                PARSE_EMPTY("flexible"),

                PARSE_EXPRESSION_LIST("default_portmap"),

                // Ignore p4v annotations.
                PARSE_SKIP("assert"),
                PARSE_SKIP("assume"),

                // Ignore unused annotations appearing in headers for v1model.
                PARSE_SKIP("metadata"),
                PARSE_SKIP("alias"),
                PARSE_SKIP("pipeline"),
                PARSE_SKIP("deparser"),
            }, true) { }
};

}  // namespace BFN

#endif /* EXTENSIONS_BF_P4C_COMMON_PARSE_ANNOTATIONS_H_ */
