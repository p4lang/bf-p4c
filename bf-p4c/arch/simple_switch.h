#ifndef BF_P4C_ARCH_SIMPLE_SWITCH_H_
#define BF_P4C_ARCH_SIMPLE_SWITCH_H_

#include <boost/algorithm/string.hpp>
#include <boost/optional.hpp>
#include "ir/ir.h"
#include "lib/path.h"
#include "frontends/common/options.h"
#include "frontends/p4/typeChecking/typeChecker.h"
#include "frontends/p4/coreLibrary.h"
#include "frontends/p4/cloner.h"
#include "frontends/p4/uniqueNames.h"
#include "frontends/p4/sideEffects.h"
#include "midend/actionsInlining.h"
#include "midend/localizeActions.h"
#include "bf-p4c/bf-p4c-options.h"
#include "program_structure.h"

namespace BFN {

enum class Target { Unknown, Simple, Tofino, Portable };
enum class BlockType { Unknown, Parser, Ingress, Egress, Deparser};

std::ostream& operator<<(std::ostream& out, BlockType block);
bool operator>>(cstring s, BlockType& blockType);

// TODO(hanw): auto-generate the name of these const cstring from v1model.p4
namespace P4_14 {
static const cstring MeterType = "MeterType";
static const cstring DirectMeter = "direct_meter";
static const cstring Meter = "meter";
static const cstring Counter = "counter";
static const cstring PACKETS = "packets";
static const cstring BYTES = "bytes";
static const cstring PACKETS_AND_BYTES = "packets_and_bytes";
static const cstring Random = "random";
static const cstring HashAlgorithm = "HashAlgorithm";
static const cstring CRC16 = "crc16";
static const cstring CRC32 = "crc32";
static const cstring RANDOM = "random";
static const cstring IDENTITY = "identity";
static const cstring Hash = "hash";
static const cstring Checksum = "Checksum16";
static const cstring RESUBMIT = "resubmit";
static const cstring StandardMetadata = "standard_metadata";
static const cstring IntrinsicMetadataForTM = "ig_intr_md_for_tm";
static const cstring IngressIntrinsicMetadataFromParser = "ig_intr_md_from_parser_aux";
static const cstring EgressIntrinsicMetadataFromParser = "eg_intr_md_from_parser_aux";
}  // namespace P4_14

// TODO(hanw): auto-generate the name of these const cstring from tofino.p4
namespace P4_16 {
static const cstring DirectMeter = "DirectMeter";
static const cstring Meter = "meter";
static const cstring MeterType = "meter_type_t";
static const cstring MeterColor = "meter_color_t"/**/;
static const cstring MeterExec = "execute";
static const cstring CounterType = "counter_type_t";
static const cstring Counter = "counter";
static const cstring PACKETS = "PACKETS";
static const cstring BYTES = "BYTES";
static const cstring PACKETS_AND_BYTES = "PACKETS_AND_BYTES";
static const cstring BIT_OF_COLOR = "bit_of_color";
static const cstring Random = "random";
static const cstring RandomExec = "get";
static const cstring HashAlgorithm = "hash_algorithm_t";
static const cstring CRC16 = "CRC16";
static const cstring CRC32 = "CRC32";
static const cstring RANDOM = "RANDOM";
static const cstring IDENTITY = "IDENTITY";
static const cstring Hash = "get_hash";

// XXX(hanw): need to be in sync with tofino.p4
static const cstring IngressIntrinsics = "ingress_intrinsic_metadata_t";
static const cstring IngressIntrinsicsForTM = "ingress_intrinsic_metadata_for_tm_t";
static const cstring IngressIntrinsicsFromParser = "ingress_intrinsic_metadata_from_parser_t";
static const cstring IngressIntrinsicsForMirror = "ingress_intrinsic_metadata_for_mirror_buffer_t";
static const cstring IngressIntrinsicsForDeparser = "ingress_intrinsic_metadata_for_deparser_t";
static const cstring EgressIntrinsics = "egress_intrinsic_metadata_t";
static const cstring EgressIntrinsicsForMirror = "egress_intrinsic_metadata_for_mirror_buffer_t";
static const cstring EgressIntrinsicsFromParser = "egress_intrinsic_metadata_from_parser_t";
static const cstring EgressIntrinsicsForOutputPort = "egress_intrinsic_metadata_for_output_port_t";
static const cstring EgressIntrinsicsForDeparser = "egress_intrinsic_metadata_for_deparser_t";
}  // namespace P4_16

class SimpleSwitchTranslation : public PassManager {
 public:
    ProgramStructure structure;
    Target   target;
    const IR::ToplevelBlock   *toplevel = nullptr;

    SimpleSwitchTranslation(P4::ReferenceMap* refMap, P4::TypeMap* typeMap, BFN_Options& options);

    const IR::P4Control* getIngress(const IR::ToplevelBlock* blk);
    const IR::P4Control* getEgress(const IR::ToplevelBlock* blk);
    const IR::P4Control* getDeparser(const IR::ToplevelBlock* blk);
    const IR::P4Parser*  getParser(const IR::ToplevelBlock* blk);
    const IR::P4Control* getIngressDeparser(const IR::ToplevelBlock* blk);

    const IR::ToplevelBlock* getToplevelBlock() { CHECK_NULL(toplevel); return toplevel; }
};

}  // namespace BFN

#endif /* BF_P4C_ARCH_SIMPLE_SWITCH_H_ */
