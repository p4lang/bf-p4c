#include "all_pragmas.h"

std::set<const BFN::Pragma *, BFN::Pragma::PragmaCmp> BFN::Pragma::_supported_pragmas;
std::set<const BFN::Pragma *, BFN::Pragma::PragmaCmp> BFN::Pragma::_internal_pragmas;

const char *PragmaAlpm::name = "alpm";
const char *PragmaAlpm::description =
    "Requests the associated match table to be implemented as an Alogrithmic LPM (ALPM) table.";
const char *PragmaAlpm::help = "@pragma alpm 1\n"
    "+ attached to P4 match tables\n"
    "\n"
    "Specifies that the associated match table should be implemented as an "
    "algorithmic LPM table instead of using normal TCAM resources.  A value "
    "of ‘1’ turns the feature on.  All other values are ignored.  It is an "
    "error if the match key does not have one, and only one, field with a "
    "match type of lpm.  Note that this implementation approach will infer "
    "a TCAM partition pre-classifier that sets a metadata field for a "
    "partition index.  This implies that, at a minimum, any table "
    "implemented in this way will require two MAU stages.  Setting the "
    "partition index requires a match dependency between the TCAM "
    "pre-classifier and the remainder of the table.";

const char *PragmaAlpmPartitions::name = "alpm_partitions";
const char *PragmaAlpmPartitions::description =
    "Specifies the number of partitions for an ALPM table";
const char *PragmaAlpmPartitions::help = "@pragma alpm_partitions 2048\n"
    "+ attached to P4 match tables\n"
    "\n"
    "If the associated match table has been specified to be implemented as "
    "an algorithmic LPM table (see the alpm pragma), the alpm_partitions "
    "pragma specifies how many partitions to use.  The only supported "
    "values are 1024, 2048, 4096, 8192.  The default is 1024.";

const char *PragmaAlpmSubtreePartitions::name = "alpm_subtrees_per_partition";
const char *PragmaAlpmSubtreePartitions::description =
    "Specifies the number of subtrees per ALPM partition.";
const char *PragmaAlpmSubtreePartitions::help = "@pragma alpm_subtrees_per_partition 2\n"
    "+ attached to P4 match tables\n"
    "\n"
    "If the associated match table has been specified to be implemented as "
    "an algorithmic LPM table (see the alpm pragma), the "
    "alpm_subtrees_per_partition pragma specifies how many subtrees are "
    "supported per partition.  From a resource perspective, this indicates "
    "how many TCAM pre-classifier entries will be allocated.  For example, "
    "if the subtrees per partition is 2 and the number of partitions is "
    "1024, the TCAM pre-classifier will have 2048 entries.  Allowed values "
    "are in the range [1:10].  The default value is 2.";

const char *PragmaAtcamPartitions::name = "atcam_number_partitions";
const char *PragmaAtcamPartitions::description =
    "Specifies the number of partitions for an ATCAM table.";
const char *PragmaAtcamPartitions::help = "@pragma atcam_number_partitions 1024\n"
    "+ attached to P4 match tables\n"
    "\n"
    "Specifies the number of partitions to use for an algorithmic TCAM (ATCAM) "
    "implementation.  By default, the value will be 2 ** partition index "
    "bit width.  The pragma value is ignored unless atcam_partition_index "
    "is specified.  It is an error if this value is greater than 2 ** "
    "partition index bit width.  It is an error if this value is not a "
    "power of two.  4.28. lrt_enable";

const char *PragmaAtcamPartitionIndex::name = "atcam_partition_index";
const char *PragmaAtcamPartitionIndex::description =
    "Specifies the field used as partition index for ATCAM tables.";
const char *PragmaAtcamPartitionIndex::help =
    "@pragma atcam_partition_index atcam_meta.partition_index\n"
    "+ attached to P4 match tables\n"
    "\n"
    "Specifies the packet or metadata field to be used as the partition "
    "index for an algorithmic TCAM implementation.  It is an error if this "
    "field is not part of the algorithmic TCAM table’s match key.  This "
    "pragma turns on the algorithmic TCAM implementation path.";

const char *PragmaAutoInitMetadata::name = "pa_auto_init_metadata";
const char *PragmaAutoInitMetadata::description =
    "Enables automatic metadata initialization.";
const char *PragmaAutoInitMetadata::help =
    "@pragma pa_auto_init_metadata\n"
    "+ at the beginning of the P4 source file"
    "\n"
    "Indicates that the compiler should automatically initialize metadata to false 0. This is "
    "always enabled for P4_14. Initialization of individual fields can be disabled by using the "
    "pa_no_init annotation.";

const char *PragmaCalculatedFieldUpdateLocation::name = "calculated_field_update_location";
const char *PragmaCalculatedFieldUpdateLocation::description =
    "Specifies the pipe to update the checksum for a calculated field object.";
const char *PragmaCalculatedFieldUpdateLocation::help =
    "@pragma calculated_field_update_location [ingress/egress/ingress_and_egress]\n"
    "+attached to P4 field list calculation objects[c]\n"
    "\n"
    "This pragma indicates which pipe or pipes to perform the update "
    "operation for a calculated field object.  The options are: "
    "  * ingress - to update the calculated field in the ingress deparser "
    "  * egress - to update the calculated field in the egress deparser "
    "  * ingress_and_egress - to update the calculated field in both the ingress and "
    "egress deparsers "
    "\n"
    "The default value is egress.  Performing the update in both ingress "
    "and egress requires double the resources. "
    "\n"
    "P4 Example:\n"
    "@pragma calculated_field_update_location ingress_and_egress\n"
    "field_list_calculation udp_checksum {\n"
    "    input {\n"
    "        udp_checksum_list;\n"
    "    }\n"
    "    algorithm : csum16;\n"
    "    output_width : 16;\n"
    "}\n";

const char *PragmaChainAddress::name = "chain_address";  // FIXME
const char *PragmaChainAddress::description = "Something to do with hw learning.";
const char *PragmaChainAddress::help = "To be documented";

const char *PragmaChainTotalSize::name = "chain_total_size";  // FIXME
const char *PragmaChainTotalSize::description = "Something to do with hw learning.";
const char *PragmaChainTotalSize::help = "To be documented";

const char *PragmaCritical::name = "critical";
const char *PragmaCritical::description = "To be documented";  // FIXME
const char *PragmaCritical::help = "To be documented";

const char *PragmaCommandLine::name = "command_line";
const char *PragmaCommandLine::description = "Adds the argument as a command line options.";
const char *PragmaCommandLine::help = "@pragma command_line <cmd_line_option(s)>\n"
    "+ at the beginning of the P4 source file"
    "\n"
    "Adds the cmd_line_option to the set of options for the compiler. "
    "This enables program specific options to be added. "
    "The set of command line options is limited to the following set:\n"
    "  --no-dead-code-elimination,\n"
    "  --force-match-dependency,\n"
    "  --metadata-overlay,\n"
    "  --placement,\n"
    "  --placement-order,\n"
    "  --auto-init-metadata,\n"
    "  --decaf,\n"
    "  --infer-payload-offset";

const char *PragmaDefaultPortmap::name = "default_portmap";
const char *PragmaDefaultPortmap::description = "To be documented";  // FIXME
const char *PragmaDefaultPortmap::help = "To be documented";

const char *PragmaDisableAtomicModify::name = "disable_atomic_modify";
const char *PragmaDisableAtomicModify::description =
    "Do not reserve any table entries to handle atomic table modifications.";
const char *PragmaDisableAtomicModify::help = "@disable_atomic_modify(1)\n"
    "+attached to P4 match tables\n"
    "\n"
    "By default, tables reserve at least one table entry to handle table\n"
    "modifications atomically. This annotation, with a value of 1 instructs\n"
    " the compiler and the driver to not reserve such entries. A 0 indicates\n"
    "to enable reserving entries.  All other values are ignored.";

const char *PragmaDisableI2EReservedDropImplementation::name =
    "disable_reserved_i2e_drop_implementation";
const char *PragmaDisableI2EReservedDropImplementation::description =
    "Disabling reserving an ingress-to-egress clone to implement drop in the ingress MAU pipeline.";
const char *PragmaDisableI2EReservedDropImplementation::help =
    "@disable_reserved_i2e_drop_implementation\n"
    "By default, id 0 is reserved during clone in Tofino. Valid ids are 1 to 7. "
    "This is applicable only to ingress. Egress has all ids from 0 to 7 as valid. "
    "Using pragma will overridde this behavior and allow id 0 to be used";

const char *PragmaDontTranslateExternMethod::name = "dont_translate_extern_method";  // FIXME
const char *PragmaDontTranslateExternMethod::description = "To be documented";
const char *PragmaDontTranslateExternMethod::help = "To be documented";

const char *PragmaDynamicTableKeyMasks::name = "dynamic_table_key_masks";
const char *PragmaDynamicTableKeyMasks::description =
    "Enable runtime programmable mask for table key fields.";
const char *PragmaDynamicTableKeyMasks::help = "@pragma dynamic_table_key_masks 1\n"
    "+attached to P4 match tables\n"
    "\n"
    "Specifies that the associated match table, if it is an exact match "
    "table, will support runtime programmable masks for fields in the table "
    "key.  A value of 1 turns this feature on.  All other values are "
    "ignored.  It is an error if this pragma is applied to a table that "
    "must be implemented in TCAM resources or as an algorithmic TCAM.";

const char *PragmaEntriesWithRanges::name = "entries_with_ranges";
const char *PragmaEntriesWithRanges::description =
    "Specifies how many entries in the table will have ranges.";
const char *PragmaEntriesWithRanges::help = "@pragma entries_with_ranges <number>\n"
    "+ attached to P4 match tables\n"
    "\n"
    "If the match table uses ranges, this pragma specifies how many of the "
    "entries are expected to have ranges.  Ranges require expanding the "
    "depth of the physical memory resources because one entry may require "
    "multiple physical memory words.  The pragma value is expected to be a "
    "number from 0 to the table size, inclusive.  Values larger than the "
    "specified table size are capped at the table size.  The default value "
    "is 25% of the table size for tables that can use ranges.";

const char *PragmaFieldListFieldSlice::name = "field_list_field_slice";
const char *PragmaFieldListFieldSlice::description = "Adds field slice support to P4-14.";
const char *PragmaFieldListFieldSlice::help =
    "@pragma field_list_field_slice <field name> <msb bit> <lsb bit>\n"
    "+ attached to P4 field list definitions\n"
    "\n"
    "Specifies that the named field’s usages in the field list are actually "
    "field slices.  This pragma is intended to work around P4_14’s lack of "
    "field slicing syntax.  All usages of the named field in the field list "
    "will be interpreted as the field slice.  This pragma is only picked up "
    "when the field list is used to compute a hash value in the MAU.  Only "
    "one slice definition is allowed per field.\n"
    "\n"
    "Example:\n"
    "\n"
    "@pragma field_list_field_slice ipv4.dstAddr 19 4\n"
    "@pragma field_list_field_slice ipv4.srcAddr 27 20\n"
    "field_list fl_1 {\n"
    "    ipv4.dstAddr;\n"
    "    ipv4.protocol;\n"
    "    ipv4.srcAddr;\n"
    "}\n"
    "\n"
    "field_list_calculation hash_1 {\n"
    "   input {\n"
    "       fl_1;\n"
    "   }\n"
    "   algorithm {\n"
    "       identity;\n"
    "   }\n"
    "   output_width : 32;\n"
    "}\n"
    "\n"
    "This will result in a 32-bit identity hash computed that is populated as:\n"
    "   {ipv4.dstAddr[19:4], ipv4.protocol, ipv4.srcAddr[27:20]}.\n";

const char *PragmaFlexible::name = "flexible";
const char *PragmaFlexible::description = "";
const char *PragmaFlexible::help = "@flexible\n"
    "+attached to struct or struct field definitions\n"
    "\n"
    "Bridged metadata is user defined metadata that is made available in "
    "both the ingress and egress pipelines. In P416 the user is responsible "
    "for defining the structure that should be bridged, and offer the "
    "compiler the possibility of optimizing the layout of the "
    "structure. The @flexible struct annotation allows the compiler to "
    "optimize the bridged metadata packing with respect to PHV and MAU "
    "constraints. To take advantage of the flexible struct annotation, "
    "programmer needs to add @flexible annotation to the struct type "
    "declaration that is to be optimized by the compiler. To emit the "
    "struct in ingress deparser, the struct must be enclosed inside a "
    "header type. For example, suppose the user needs to use the following "
    "two ingress intrinsic metadata in egress pipeline. The ingress "
    "intrinsic metadata must be emitted as a bridged metadata by the "
    "ingress deparser, extracted by the egress parser and used by the "
    "egress MAU pipeline. Due to the constraint optimization performed by "
    "the compiler, it is sometimes necessary for the compiler to reorder "
    "the fields inside the bridged metadata struct to minimize the "
    "constraints imposed by the hardware. The @flexible annotation on "
    "bridged metadata struct is used to free the programmer from manually "
    "tweaking the field orders to minimize the constraints. Further, "
    "because compiler is taking care of the constraint optimization, it is "
    "no longer necessary to pad the bridged metadata struct to byte "
    "boundaries. Compiler will automatically insert padding wherever "
    "necessary.\n"
    "\n"
    "@flexible\n"
    "struct bridged_metadat_t {\n"
    "     bit<9> ingress_port;\n"
    "     bit<2> packet_color;\n"
    "}   \n"
    "\n"
    "header bridged_header_t {\n"
    "     bit<8> bridge_type;\n"
    "     bridged_metadata_t data;\n"
    "}\n"
    "\n"
    "// in ingress deparser.\n"
    "pkt.emit(bridged_hdr);\n"
    "\n"
    "// in egress parser.\n"
    "pkt.extract(bridged_hdr);\n"
    "\n"
    "// in egress pipeline.\n"
    "egress_md.ingress_port = bridged_hdr.ingress_port;\n";

const char *PragmaForceImmediate::name = "force_immediate";
const char *PragmaForceImmediate::description =
    "Requires that action parameters are packed in the match overhead of the table.";
const char *PragmaForceImmediate::help = "@pragma force_immediate 1\n"
    "+attached to P4 match tables\n"
    "\n"
    "Specifies that all action parameters from the match table’s associated "
    "action data table must be packed in match overhead instead of in the "
    "action data table.  A 1 tells the compiler to force this packing.  All "
    "other values are ignored.  The default value is 0.  Note that if all "
    "action parameters cannot be packed in match overhead, compilation will "
    "fail.  Also note that this pragma cannot be used when the action data "
    "table is indirectly addressed.";

const char *PragmaForceShift::name = "force_shift";
const char *PragmaForceShift::description = "Forces parser to shift cursor.";
const char *PragmaForceShift::help = "@pragma force_shift [ingress/egress] [bits]\n"
    "+attached to P4 parser state\n"
    "\n"
    "Forces the attached state of the ingress or egress parser to shift out "
    "the specified number of bits, regardless of the state's contents. If "
    "the state has to be split by the compiler, this pragma will cause "
    "compilation to fail.";

const char *PragmaGFMParityEnable::name = "gfm_parity_enable";
const char *PragmaGFMParityEnable::description =
    "Enable hash parity checking on the Galois Field Matrix (GFM)";
const char *PragmaGFMParityEnable::help = "@gfm_parity_enable\n"
    "Global pragma which applies to the entire program. Compiler reserves a single bit"
    " on each row of the GFM for parity and sets up the hardware to enable"
    " parity checking on hash groups used in the program";

const char *PragmaGhostMetadata::name = "__ghost_metadata";
const char *PragmaGhostMetadata::description =
    "Declare metadata that is shared between Ingress and Ghost thread.";
const char *PragmaGhostMetadata::help = "@__ghost_metatada\n"
    "+ attached to an intrinsic metadata struct\n"
    "\n"
    "Ghost intrinsic metadata is declared separately as arguments to both"
    "ingress and ghost, but both need to refer to the same thing (same PHV)";

const char *PragmaIdletimeInterval::name = "idletime_interval";
const char *PragmaIdletimeInterval::description =
    "Specifies the sweep interval for a table that has idletime.";
const char *PragmaIdletimeInterval::help = "@pragma idletime_interval 7\n"
    "+attached to P4 match tables\n"
    "\n"
    "Specifies, if the match table utilizes idle time counters, what the "
    "sweep interval should be.  Valid values are 0 through 12 inclusive. "
    "All other values are ignored.  The default value is 7.  Table 1 "
    "describes the approximate sweep interval, in milliseconds, for the "
    "various values.\n\n"
    "Note: Should not be used. Instead, the driver programs the sweep interval.\n"
    "\n"
    "idletime_sweep_interval value\n"
    "  Time (in milliseconds)\n"
    "  0\n"
    "  6.5 ms\n"
    "  1\n"
    "  13 ms\n"
    "  2\n"
    "  26 ms\n"
    "  3\n"
    "  52 ms\n"
    "  4\n"
    "  105 ms\n"
    "  5\n"
    "  210 ms\n"
    "  6\n"
    "  419 ms\n"
    "  7\n"
    "  839 ms\n"
    "  8\n"
    "  1680 ms\n"
    "  9\n"
    "  3360 ms\n"
    "  10\n"
    "  6710 ms\n"
    "  11\n"
    "  13400 ms\n"
    "  12\n"
    "  26800 ms\n"
    "\n"
    "Table 1: idletime_sweep_interval encoding.\n";

const char *PragmaIdletimePerFlow::name = "idletime_per_flow_idletime";
const char *PragmaIdletimePerFlow::description =
    "Enables per-flow ideletime for a table that has idletime.";
const char *PragmaIdletimePerFlow::help = "@pragma idletime_per_flow_idletime 1\n"
    "+attached to P4 match tables\n"
    "\n"
    "For a match table that uses idle time counters, this pragma specifies "
    "whether flows utilize per-flow idle time.  A value of 1 enables "
    "per-flow idle time.  A value of 0 disables per-flow idle time.  All "
    "other values are ignored.  The default value is 1 for precisions of 3 "
    "and 6 bits.  The default value is 0 for precisions of 1 and 2 bits. "
    "Turning on idle time per flow means the state space for counters is "
    "reduced by 1.  Per-flow idle time cannot be used with a precision of "
    "1.";

const char *PragmaIdletimePrecision::name = "idletime_precision";
const char *PragmaIdletimePrecision::description =
    "Specifies the counter precision for idletime counters.";
const char *PragmaIdletimePrecision::help = "@pragma idletime_precision 3\n"
    "+attached to P4 match tables\n"
    "\n"
    "Specifies, if the match table utilizes idle time counters, what the "
    "counter precision should be.  Valid values are 6, 3, 2, and 1.  All "
    "other values are ignored.  The default value is 3.";

const char *PragmaIdletimeTwoWayNotification::name = "idletime_two_way_notification";
const char *PragmaIdletimeTwoWayNotification::description =
    "Specifies whether to send CPU notifications for idletime events.";
const char *PragmaIdletimeTwoWayNotification::help = "@pragma idletime_two_way_notification 1\n"
    "+attached to P4 match tables\n"
    "\n"
    "For a match table that uses idle time counters, this pragma specifies "
    "whether notifications to the CPU should occur for transitions from "
    "active to inactive and inactive to active.  A value of 1 enables "
    "notifications for both transitions.  A value of 0 disables two-way "
    "notification, indicating that the CPU will be notified only when a "
    "flow transitions from active to inactive.  All other values are "
    "ignored.  The default value is 1 for precisions greater than 1 bit. "
    "Otherwise, the default is 0.";

const char *PragmaIgnoreTableDependency::name = "ignore_table_dependency";
const char *PragmaIgnoreTableDependency::description =
    "Override dependency analysis and force the compiler to ignore match and action "
    "dependencies for this table.";
const char *PragmaIgnoreTableDependency::help = "@pragma ignore_table_dependency table_name\n"
    "+attached to P4 match tables\n"
    "\n"
    "Specifies that the associated match table should ignore match and/or "
    "action dependencies to the indicated table.  Use this pragma with "
    "care.  It is assumed that the real dependency will be enforced by the "
    "control plane.  Note that this pragma will be silently ignored if it "
    "is used on tables that belong to different gress values. ";

const char *PragmaIntrinsicMetadata::name = "__intrinsic_metadata";
const char *PragmaIntrinsicMetadata::description =
    "Declare metadata that needs to be processed for architecture specific semantics.";
const char *PragmaIntrinsicMetadata::help = "@__intrinsic_metatada\n"
    "+ attached to intrinsic metadata\n"
    "\n"
    "Intrinsic metadata that requires special processing in the backend";

const char *PragmaLrtEnable::name = "lrt_enable";
const char *PragmaLrtEnable::description = "Enable automatic cache evictions.";
const char *PragmaLrtEnable::help = "@pragma lrt_enable 1\n"
    "+ attached to P4 statistics tables\n"
    "\n"
    "By default, Tofino performs automatic cache evictions of counter "
    "values from Tofino to the external CPU to prevent counter "
    "overflow. (Eviction is governed by the LR(t) algorithm, hence the name "
    "of this pragma.) A value of 0 disables LR(t) automatic eviction. A "
    "value of 1 enables LR(t) automatic eviction. You should only disable "
    "LR(t) automatic eviction if you're certain you will not overflow your "
    "on-chip counters or you will read and clear the counters faster than "
    "they can overflow.  LR(t) messages cannot be used if full width "
    "counters (64-bits) are in use.  By default, LR(t) is enabled for "
    "counter sizes less than 64 bits.";

const char *PragmaLrtScale::name = "lrt_scale";
const char *PragmaLrtScale::description =
    "Specifies the scale factor for the LR(t) threshold and interval.";
const char *PragmaLrtScale::help = "@pragma lrt_scale 200\n"
    "+ attached to P4 statistics tables\n"
    "\n"
    "For testing purposes, specifies that the computed LR(t) threshold and "
    "interval should be divided by the provided scale factor.  The default "
    "value is 1, meaning there is no scaling.  This value is only relevant "
    "if LR(t) is enabled.";

const char *PragmaMaxActions::name = "max_actions";
const char *PragmaMaxActions::description =
    "Specify the maximum number of actions supported by a table.";
const char *PragmaMaxActions::help = "@pragma max_actions 16\n"
    "+ attached to P4 match tables\n"
    "\n"
    "This pragma is intended for future-proofing against table layout "
    "changes caused by adding actions at a later date.  The user specifies "
    "the maximum supported actions that will ever be allowed for this "
    "table.  Normally, the compiler sizes the action instruction pointer "
    "based on how many actions can be run as a result of a table hit.  For "
    "example, three actions requires two bits of action instruction pointer "
    "storage in match overhead.  If the user indicated a maximum actions "
    "value of six, for example, this tells the compiler to allocate action "
    "instruction pointer overhead assuming six actions instead of three. "
    "This results in three bits of action instruction pointer space being "
    "used."
    "\n"
    "Any positive integer is allowed as the value, but an error will be "
    "thrown if the maximum actions value is less than the number of "
    "currently listed table actions.";

const char *PragmaMaxLoopDepth::name = "max_loop_depth";
const char *PragmaMaxLoopDepth::description =
    "Specifies the maximum number of loops in the parser.";
const char *PragmaMaxLoopDepth::help = "@pragma max_loop_depth [count]\n"
    "+attached to P4 parser state\n"
    "\n"
    "Allows the parser to infer the maximum number of loops that could "
    "happen in ingress or egress in a state. This is used to flatten the "
    "parse graph when other inference mechanisms fail.";

const char *PragmaMinWidth::name = "min_width";
const char *PragmaMinWidth::description = "Minimum counter width?";  // FIXME
const char *PragmaMinWidth::help = "To be documented";

const char *PragmaMode::name = "mode";  // FIXME
const char *PragmaMode::description = "To be documented";
const char *PragmaMode::help = "To be documented";

const char *PragmaDontMerge::name = "dontmerge";
const char *PragmaDontMerge::description = "The specific parser state will not be merged with "
                                           "any other state";
const char *PragmaDontMerge::help = "@dontmerge gress state state_name";

const char *PragmaNotExtractedInEgress::name = "not_extracted_in_egress";  // FIXME
const char *PragmaNotExtractedInEgress::description = "To be documented";
const char *PragmaNotExtractedInEgress::help = "To be documented";

const char *PragmaDoNotBridge::name = "pa_do_not_bridge";
const char *PragmaDoNotBridge::description = "Do not bridge the annotated metadata field.";
const char *PragmaDoNotBridge::help = "@pragma pa_do_not_bridge gress instance_name.field_name\n"
    "+ attached to P4 header instances\n"
    "\n"
    "Specifies that the indicated metadata field should not be included in "
    "the auto-inferred bridged metadata field list that is passed from the "
    "ingress pipeline to the egress pipeline.  This pragma is ignored if "
    "the field is already not going to be bridged.  The gress value can be "
    "either ingress or egress. ";

const char *PragmaNoVersioning::name = "no_versioning";
const char *PragmaNoVersioning::description =
    "Specifies whether or not to allocate version/valid bits for each table entry";
const char *PragmaNoVersioning::help = "@pragma no_versioning 1\n"
    "+attached to P4 match tables\n"
    "\n"
    "A boolean parameter, i.e. only 0 or 1 is allowed."
    "\n"
    "Currently only supported for tables headed to the TCAM array";

const char *PragmaPack::name = "pack";
const char *PragmaPack::description =
    "Specifies the number of entries to pack per wide table word.";
const char *PragmaPack::help = "@pragma pack 2\n"
    "+attached to P4 match tables\n"
    "\n"
    "Specifies that the associated match table, if it is an exact match "
    "table, should pack the given number of entries per wide table word. "
    "\n"
    "Allowed values are integers from 1 to 9.  Depending on the "
    "requirements of the match table, a large pack value may prevent the "
    "table from being placed.";

const char *PragmaPadding::name = "padding";
const char *PragmaPadding::description =
    "Specifies the padding bits in header.";
const char *PragmaPadding::help = "@pragma padding\n"
    "+attached to header fields\n"
    "\n"
    "Specifies that the associated header field is padding field. A padding field represents a "
    "set of fields that can hold any value and the programmer/protocol does not care what value "
    "it is. This allows the compiler to overlap it with other fields and involve them in ALU "
    "operations that may polute the value stored.";


const char *PragmaPacketEntry::name = "packet_entry";
const char *PragmaPacketEntry::description = "Specifies additional parser entry states.";
const char *PragmaPacketEntry::help = "@pragma packet_entry\n"
    "+attached to P4 parser states\n"
    "\n"
    "Indicates the attached parser state is an special entrypoint for "
    "certain kinds of packets. Other than ‘start’, the currently supported "
    "entry points are:\n"
    "  * ‘start_egress’, for packets that want a different parser egress start state\n"
    "  * ‘start_i2e_mirrored’, for packets mirrored via the clone_ingress_pkt_to_egress() "
    "primitive\n"
    "  * ‘start_e2e_mirrored’, for packets mirrored via the clone_egress_pkt_to_egress() "
    "primitive\n"
    "  * ‘start_coalesced’, for packets built out of samples from the sample_e2e() primitive\n"
    "\n"
    "These entry points are all used only by the egress parser, but you "
    "should write your parser program as if it were at the beginning of the "
    "pipeline entering the normal ingress control flow. In other words: "
    "return ingress, even though in reality your code will exit to egress.";

const char *PragmaPhase0::name = "phase0";
const char *PragmaPhase0::description = "";
const char *PragmaPhase0::help = "@pragma phase0 1\n"
    "+ attached to P4 match tables\n"
    "\n"
    "Specifies that the indicated table must or must not be implemented as "
    "the “Phase 0” table.  A ‘1’ indicates the table must be implemented as "
    "phase 0.  A ‘0’ indicates the table should not be implemented as phase "
    "0.  All other values result in an error.\n"
    "\n"
    "If the table is required to be implemented as phase 0 but cannot for "
    "other constraint reasons, compilation fails.  A phase 0 table is "
    "implemented using the parser, by using per-port configuration data. "
    "Utilizing phase 0 is one mechanism to eliminate MAU table "
    "dependencies.  Only one table can be implemented as the phase 0 table, "
    "and it is subject to following requirements and restrictions:\n"
    "\n"
    "  * The table must be the first table of the ingress control flow\n"
    "  * The table has no side effect tables other than action data\n"
    "  * The table has the following condition gating its execution:\n"
    "    (ig_intr_md.resubmit_flag == 0)\n"
    "  * The table key is an exact match lookup on ig_intr_md.ingress_port\n"
    "  * The maximum table size is 288 entries\n"
    "  * There is only one action, and it is also specified as the default action.\n"
    "  * The single action can only perform assignment operations "
    "    (i.e. modify_field) from action parameters or constants.\n"
    "  * The sum of the PHV containers width the fields written by the "
    "    action reside in is less than or equal to 64 bits.  Note that "
    "    packing constraints may not allow all fields to be allocated in "
    "    the same container or contiguously in a container.\n"
    "  * The action does not modify fields that would otherwise be written "
    "    by the parser (i.e. written by a set_metadata call)\n"
    "\n"
    "P4 example:\n"
    "\n"
    "action set_port_info(port_info, port_type) {\n"
    "    modify_field(port_metadata.port_info, port_info);\n"
    "    modify_field(port_metadata.port_type, port_type);\n"
    "    modify_field(port_metadata.port_up, 1);\n"
    "}\n"
    "\n"
    "table ingress_port_mapping {\n"
    "    reads {\n"
    "        ig_intr_md.ingress_port : exact;\n"
    "    }\n"
    "    actions {\n"
    "        set_port_info;\n"
    "    }\n"
    "    default_action : set_port_info;\n"
    "    size : 288;\n"
    "}\n"
    "\n"
    "control ingress {\n"
    "    if (ig_intr_md.resubmit_flag == 0) {\n"
    "        apply(ingress_port_mapping);\n"
    "    }\n"
    "\n"
    "    // other apply statements\n"
    "}\n"
    "\n"
    "Note: for P4-16 on Tofino, use the port_metadata_unpack extern.";

const char *PragmaOverridePhase0TableName::name = "override_phase0_table_name";
const char *PragmaOverridePhase0TableName::description = "";
const char *PragmaOverridePhase0TableName::help = "@pragma override_phase0_table_name(...)\n"
    "+ attached to P4 parser state\n"
    "\n"
    "Specifies the name of phase0 table in context.json\n";

const char *PragmaOverridePhase0ActionName::name = "override_phase0_action_name";
const char *PragmaOverridePhase0ActionName::description = "";
const char *PragmaOverridePhase0ActionName::help = "@pragma override_phase0_action_name(...)\n"
    "+ attached to P4 parser state\n"
    "\n"
    "Specifies the name of phase0 action in context.json\n";

const char *PragmaPlacementPriority::name = "placement_priority";
const char *PragmaPlacementPriority::description =
    "Changes the order in which tables are considered for placement in a stage.";
const char *PragmaPlacementPriority::help = "@pragma placement_priority (N)\n"
    "+attached to P4 match tables\n"
    "\n"
    "Specifies that a table should have higher (or lower) priority when "
    "trying to place tables in the pipeline.  All tables have a default "
    "priority of 0, so a positive priority will cause a table to be placed "
    "in preference to other tables (earlier in the pipeline), while a "
    "negative priority will cause a table to be placed later.";

const char *PragmaPreColor::name = "pre_color";  // FIXME
const char *PragmaPreColor::description = "To be documented";
const char *PragmaPreColor::help = "To be documented";

const char *PragmaProxyHashAlgorithm::name = "proxy_hash_algorithm";
const char *PragmaProxyHashAlgorithm::description =
    "Specifies the hash algorithm to use for a proxy hash table implementation.";
const char *PragmaProxyHashAlgorithm::help = "@pragma proxy_hash_algorithm crc16\n"
    "+ attached to P4 match tables\n"
    "\n"
    "Specifies the hash algorithm to use to compute the proxy hash value to "
    "store in place of the match key.  This is ignored if the pragma "
    "proxy_hash_width is not specified.  By default, the hash algorithm "
    "used is random.";

const char *PragmaProxyHashWidth::name = "proxy_hash_width";
const char *PragmaProxyHashWidth::description =
    "Specifies the width of a proxy hash table implementation.";
const char *PragmaProxyHashWidth::help = "@pragma proxy_hash_width 32\n"
    "+ attached to P4 match tables\n"
    "\n"
    "Specifies that an exact match table should be specified with a proxy "
    "hash result stored as the key.  Two hash computations are performed. "
    "The first hash computes the entry location in memory.  The second hash "
    "computed is stored in place of the exact match key.  This pragma can "
    "only be used if the table can be implemented as an exact match table. "
    "Valid bit widths are in the range [1:52].  Proxy hashing is off by "
    "default.";

const char *PragmaRandomSeed::name = "random_seed";
const char *PragmaRandomSeed::description =
    "Specifies the seed for the random number generator for the hash computation.";
const char *PragmaRandomSeed::help = "@pragma random_seed 0x1234\n"
    "+ attached to P4 match tables\n"
    "\n"
    "Specifies that the associated match table, if it is an exact match "
    "table, should set the random number generator’s seed to the specified "
    "value before creating the hash function.  This pragma is intended to "
    "help testing of exact match entries by making the table immune to "
    "global program changes that impact the generated hash function.\n"
    "\n"
    "Allowed values are positive integers.";

const char *PragmaReductionOrGroup::name = "reduction_or_group";  // FIXME(han)
const char *PragmaReductionOrGroup::description = "To be documented";
const char *PragmaReductionOrGroup::help = "To be documented";

const char *PragmaReg::name = "reg";  // FIXME(To be documented)
const char *PragmaReg::description = "To be documented";
const char *PragmaReg::help = "To be documented";

const char *PragmaResidualChecksumParserUpdateLocation::name =
    "residual_checksum_parser_update_location";
const char *PragmaResidualChecksumParserUpdateLocation::description = "To be documented";  // FIXME
const char *PragmaResidualChecksumParserUpdateLocation::help = "To be documented";

const char *PragmaSelectorMaxGroupSize::name = "selector_max_group_size";
const char *PragmaSelectorMaxGroupSize::description =
    "Specifies the maximum size for a selector.";
const char *PragmaSelectorMaxGroupSize::help = "@pragma selector_max_group_size 512\n"
    "+attached to P4 match tables[v]\n"
    "\n"
    "Specifies that the match table’s selector should allocate enough space "
    "for the indicated maximum group size.  Valid values are in the range "
    "[2:119040].  Invalid values are ignored.  By default, the maximum "
    "group size is 120 members.";

const char *PragmaSelectorNumMaxGroups::name = "selector_max_group_size";
const char *PragmaSelectorNumMaxGroups::description =
    "Specifies the maximum number of groups in a selector.";
const char *PragmaSelectorNumMaxGroups::help = "@pragma selector_num_max_groups 32\n"
    "+attached to P4 match tables\n"
    "\n"
    "Specifies that the match table’s selector should allocate enough "
    "resources to support the indicated number of groups of maximum size. "
    "By default, the number of maximum groups is 1.";

const char *PragmaSelectorEnableScramble::name = "selector_enable_scramble";
const char *PragmaSelectorEnableScramble::description =
    "Specifies whether to enable or disable SPS scrambling.";
const char *PragmaSelectorEnableScramble::help = "@pragma selector_enable_scramble 0\n"
    "+attached to P4 match tables\n"
    "\n"
    "Specifies that the match table’s selector should enable or disable the "
    "SPS scrambling logic.  A value of 0 disables the scramble logic.  A value "
    "of 1 enables the scramble logic.  By default, scrambling is enabled.";

const char *PragmaSymmetric::name = "symmetric";
const char *PragmaSymmetric::description =
    "Specifies the symmetric hash fields.";
const char *PragmaSymmetric::help = "@pragma symmetric field_1, field_2\n"
    "+attached to P4 hash extern\n"
    "\n"
    "Specifies that the two fields specified are to be considered symmetric "
    "when computing a hash result.  This pragma is only available in the "
    "context of field list hash calculations.  All other usages are silently "
    "ignored.  It is an error if the two fields are not the same bit width.";

const char *PragmaStage::name = "stage";
const char *PragmaStage::description =
    "Specifies the stage for a table.";
// FIXME: Brig does not support entries
const char *PragmaStage::help = "@pragma stage 5\n"
    "+attached to P4 match tables\n"
    "\n"
    "Specifies that the associated match table must be placed in the "
    "indicated stage.  Optionally, a second value denoting the number of "
    "entries of the table to place in the stage may also be specified.  For "
    "example:\n"
    "\n"
    "@pragma stage 5 1024\n"
    "\n"
    "The stage number is required. If the number of entries is not "
    "specified, an attempt will be made to place all table entries in the "
    "indicated stage.\n"
    "\n"
    "Multiple stage pragmas may be specified for a table, each with their "
    "own number of entries.  Currently, only one of the stage pragmas "
    "attached to a table may skip specifying the number of entries.  When a "
    "stage pragma does not specify the number of entries, it effectively "
    "means the remaining table entries will be placed in that stage.  For "
    "example:\n"
    "\n"
    "@pragma stage 4 1024\n"
    "@pragma stage 6 1024\n"
    "@pragma stage 7\n"
    "\n"
    "This instructs the compiler to allocate the rest of the table entries to stage 7.\n"
    "\n"
    "For Tofino allowed stage numbers are 0 to 11.  The sum of the "
    "specified entries must be less than or equal to the table size.\n"
    "\n"
    "Note: the stage pragma will be deprecated. Please use the placement_priority pragma.";

const char *PragmaTerminateParsing::name = "terminate_parsing";
const char *PragmaTerminateParsing::description =
    "Unconditionally terminate parsing in the annotated parser state.";
const char *PragmaTerminateParsing::help = "@pragma terminate_parsing ingress/egress\n"
    "+ attached to a parser state.\n"
    "\n"
    "It informs the ingress/egress parser to ignore the instructions, "
    "header extractions, and branching decisions performed in that state "
    "and unconditionally end the parsing process. The header fields "
    "extracted in this state are not considered for PHV allocation unless "
    "they are used in other states. It is the programmer’s responsibility "
    "to ensure that these fields are not used in the MAU pipeline.";

const char *PragmaDontUnroll::name = "dont_unroll";
const char *PragmaDontUnroll::description =
    "do not unroll the annotated parser state (if in a loop).";
const char *PragmaDontUnroll::help = "@pragma dont_unroll\n"
    "+ attached to a parser state.\n"
    "\n"
    "By default, the compiler unrolls parser loops. "
    "Use this pragma to keep the parser loops.";

const char *PragmaTernary::name = "ternary";
const char *PragmaTernary::description = "Forces the use of TCAM memories for the table.";
const char *PragmaTernary::help = "@pragma ternary 1\n"
    "+attached to P4 match tables\n"
    "\n"
    "Specifies that the match table should be placed within TCAM resources. "
    "A 1 tells the compiler to use ternary resources.  All other values are "
    "ignored.";

const char *PragmaUseHashAction::name = "use_hash_action";
const char *PragmaUseHashAction::description =
    "Specifies that the match table should use the hash-action path";
const char *PragmaUseHashAction::help = "@pragma use_hash_action 1\n"
    "+ attached to P4 match tables\n"
    "\n"
    "Specifies that the match table should use the hash-action path.  This "
    "forces the table to use hash action, even if it is less efficient.  If "
    "the table cannot be implemented using hash action, the compiler will "
    "report an error.  A value of 1 forces hash action.  A value of 0 turns "
    "off the optimization, even if it is preferred.  All other values are "
    "ignored.";

const char *PragmaUserAnnotation::name = "user_annotation";
const char *PragmaUserAnnotation::description =
    "Specifies a list of strings that should be passed through to context.json.";
const char *PragmaUserAnnotation::help = "@pragma user_annotation str_1 .. str_N\n"
    "+attached to P4 action declarations\n"
    "+attached to P4 action parameters\n"
    "+attached to P4 extern instantiations\n"
    "+attached to P4 table declarations\n"
    "+attached to P4 table match keys\n"
    "\n"
    "Provides a list of strings to be passed through to the context.json representation of the "
    "associated P4 program element.";

const char *PragmaWays::name = "ways";
const char *PragmaWays::description =
    "Specifies the number of ways for an exact match table";
const char *PragmaWays::help = "@pragma ways 4\n"
    "+attached to P4 match tables\n"
    "\n"
    "Specifies that the associated match table, if it is an exact match "
    "table, should use the given number of ways. "
    "\n"
    "Allowed values are integers greater than or equal to 1.  Depending on "
    "the requirements of the match table, a large ways value may prevent "
    "the table from being placed.";

const char *PragmaNoFieldInits::name = "no_field_initialization";
const char *PragmaNoFieldInits::description =
    "Forbids the insertion of initialization instructions in the actions of the match table";
const char *PragmaNoFieldInits::help = "@pragma no_field_initialization \n"
    "+attached to P4 match tables\n"
    "\n"
    "Specifies that the associated match table should not allow insertion of "
    "field initialization instructions into its actions.";

const char *PragmaRed::name = "red";
const char *PragmaRed::description = "To be documented";  // FIXME
const char *PragmaRed::help = "To be documented";

const char *PragmaYellow::name = "yellow";
const char *PragmaYellow::description = "To be documented";  // FIXME
const char *PragmaYellow::help = "";

const char *PragmaGreen::name = "green";
const char *PragmaGreen::description = "To be documented";  // FIXME
const char *PragmaGreen::help = "To be documented";

const char *PragmaTrueEgressAccounting::name = "true_egress_accounting";
const char *PragmaTrueEgressAccounting::description =
    "Use the final byte count for the packet for counter or meter.";
const char *PragmaTrueEgressAccounting::help = "@pragma true_egress_accounting\n"
    "+ attached to a counter or meter (egress only).\n"
    "\n"
    "By default, counter or meter at egress uses the computed packet length "
    "for the ingress pipeline. This means that the counter or meter is unaware "
    "of the final packet size and will not reflect the real output packets on the "
    "wire. Use this pragma to use the final byte count from egress deparser after "
    "the final output packet has been re-assembled.\n"
    "\n"
    "This feature is only available for the egress pipeline and on Tofino2 and later"
    " devices.";

const char *PragmaHeaderChecksum::name = "header_checksum";
const char *PragmaHeaderChecksum::description =
    "Informs p4testgen that a field in a header contains a header checksum.";
const char *PragmaHeaderChecksum::help =
    "@pragma header_checksum\n"
    "+ attached to P4 field declarations\n"
    "\n"
    "A p4testgen pragma. Specifies that the indicated packet or metadata "
    "field is a calculated header checksum that undergoes checksum "
    "verification.";

const char *PragmaPayloadChecksum::name = "payload_checksum";
const char *PragmaPayloadChecksum::description =
    "Informs p4testgen that a field in a header contains a payload checksum.";
const char *PragmaPayloadChecksum::help =
    "@pragma payload_checksum\n"
    "+ attached to P4 field declarations\n"
    "\n"
    "A p4testgen pragma. Specifies that the indicated packet or metadata "
    "field is a calculated payload checksum (i.e., one whose computation "
    "involves the packet payload) that undergoes checksum verification.";


const char *PragmaDisableDeparseZero::name = "pa_disable_deparse_0_optimization";
const char *PragmaDisableDeparseZero::description = "To be documented";  // FIXME
const char *PragmaDisableDeparseZero::help = "To be documented";

const char *PragmaNotDeparsed::name = "not_deparsed";
const char *PragmaNotDeparsed::description =
    "Specifies that the header instance should not be deparsed.";
const char *PragmaNotDeparsed::help = "@pragma not_deparsed[a][b] [ingress/egress]\n"
    "+attached to P4 header instances\n"
    "\n"
    "Prevents the attached header instance from being deparsed in the "
    "specified gress (ingress or egress). Note that this pragma will not "
    "prevent POV bits from being allocated and manipulated for the "
    "instance. It will not prevent the header and its fields from being "
    "accessed in the deparser either. It just prevents POV bits from being "
    "referenced in the deparser.\n"
    "\n"
    "Note that PHV allocation also uses this to help shrink packet field "
    "liveness.";

const char *PragmaNotParsed::name = "not_parsed";
const char *PragmaNotParsed::description =
    "Specifies that the header is not parsed.";
const char *PragmaNotParsed::help = "@pragma not_parsed [ingress/egress]\n"
    "+attached to P4 header instances\n"
    "\n"
    "Indicates the attached header instance, though appearing in the parse "
    "graph, will never actually be parsed.  This pragma is used by the PHV "
    "allocator to reduce the lifetime of the packet fields to be from first "
    "use to the deparser.  Normally, packet fields are considered live from "
    "the parser to the deparser.  The intended use case for this pragma is "
    "for packet headers that will be added during processing.  Note that "
    "the packet header must still be extracted in the parse graph in order "
    "to infer the correct deparse order of the header.  This can be "
    "achieved using an invalid select condition to branch to a parse state "
    "where the extraction occurs.";

// internal annotations to be removed
const char *PragmaActionSelectorHashFieldCalcName::name = "action_selector_hash_field_calc_name";
const char *PragmaActionSelectorHashFieldCalcName::description = "internal";
const char *PragmaActionSelectorHashFieldCalcName::help = "internal";

const char *PragmaActionSelectorHashFieldListName::name = "action_selector_hash_field_list_name";
const char *PragmaActionSelectorHashFieldListName::description = "internal";
const char *PragmaActionSelectorHashFieldListName::help = "internal";

const char *PragmaActionSelectorHashFieldCalcOutputWidth::name =
                                                    "action_selector_hash_field_calc_output_width";
const char *PragmaActionSelectorHashFieldCalcOutputWidth::description = "internal";
const char *PragmaActionSelectorHashFieldCalcOutputWidth::help = "internal";

const char *PragmaAlgorithm::name = "algorithm";
const char *PragmaAlgorithm::description = "internal";
const char *PragmaAlgorithm::help = "internal";

/*

const char *Pragma::name = "";
const char *Pragma::description = "";
const char *Pragma::help = "";

*/
