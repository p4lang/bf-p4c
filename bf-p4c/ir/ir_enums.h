#ifndef BF_P4C_IR_IR_ENUMS_H_
#define BF_P4C_IR_IR_ENUMS_H_

#include <lib/cstring.h>
#include <iostream>

namespace IR {
namespace MAU {
enum class DataAggregation { NONE, PACKETS, BYTES, BOTH, AGGR_TYPES };
enum class MeterType { UNUSED = 0,
    // we use explicit constants here to map to the meter types defined by hardware
    // these are (currently) consistent across tofino1/2/3, but perhaps should be
    // moved to the Device model
    COLOR_BLIND = 2, SELECTOR = 4, COLOR_AWARE = 6,
    STFUL_INST0 = 1, STFUL_INST1 = 3, STFUL_INST2 = 5, STFUL_INST3 = 7,
    STFUL_CLEAR = 6,
    METER_TYPES = 8 };
enum class StatefulUse { NO_USE, DIRECT, INDIRECT, LOG, STACK_PUSH, STACK_POP, FIFO_PUSH,
                         FIFO_POP, FAST_CLEAR, STFUL_TYPES };
enum class AddrLocation { DIRECT, OVERHEAD, HASH, STFUL_COUNTER, GATEWAY_PAYLOAD, NOT_SET };
enum class PfeLocation { DEFAULT, OVERHEAD, GATEWAY_PAYLOAD, NOT_SET };
enum class TypeLocation { DEFAULT, OVERHEAD, GATEWAY_PAYLOAD, NOT_SET };
enum class ColorMapramAddress { IDLETIME, STATS, MAPRAM_ADDR_TYPES, NOT_SET };

}  // end namespace MAU

namespace BFN {
enum class ChecksumMode { VERIFY, RESIDUAL, CLOT };
enum class ParserWriteMode { SINGLE_WRITE, BITWISE_OR, CLEAR_ON_WRITE };
}  // end namespace BFN

}  // end namespace IR

std::ostream& operator<<(std::ostream &out, const IR::MAU::DataAggregation &d);
bool operator>>(cstring s, IR::MAU::DataAggregation &d);

std::ostream& operator<<(std::ostream &out, const IR::MAU::MeterType &m);
bool operator>>(cstring s, IR::MAU::MeterType &m);

std::ostream& operator<<(std::ostream &out, const IR::MAU::StatefulUse &u);
bool operator>>(cstring s, IR::MAU::StatefulUse &u);

std::ostream& operator<<(std::ostream &out, const IR::MAU::AddrLocation &a);
bool operator>>(cstring s, IR::MAU::AddrLocation &a);

std::ostream& operator<<(std::ostream &out, const IR::MAU::PfeLocation &p);
bool operator>>(cstring s, IR::MAU::PfeLocation &a);

std::ostream& operator<<(std::ostream &out, const IR::MAU::TypeLocation &t);
bool operator>>(cstring s, IR::MAU::TypeLocation &t);

std::ostream& operator<<(std::ostream &out, const IR::MAU::ColorMapramAddress &cma);
bool operator>>(cstring s, IR::MAU::ColorMapramAddress &cma);

std::ostream& operator<<(std::ostream &out, const IR::BFN::ChecksumMode &t);
bool operator>>(cstring s, IR::BFN::ChecksumMode &t);

std::ostream& operator<<(std::ostream &out, const IR::BFN::ParserWriteMode &t);
bool operator>>(cstring s, IR::BFN::ParserWriteMode &t);

#endif /* BF_P4C_IR_IR_ENUMS_H_ */
