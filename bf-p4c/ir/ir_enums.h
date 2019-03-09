#ifndef BF_P4C_IR_IR_ENUMS_H_
#define BF_P4C_IR_IR_ENUMS_H_

#include <lib/cstring.h>
#include <iostream>

namespace IR {
namespace MAU {
enum class DataAggregation { NONE, PACKETS, BYTES, BOTH, AGGR_TYPES };
enum class MeterType { UNUSED, STFUL_INST0, COLOR_BLIND, STFUL_INST1, SELECTOR, STFUL_INST2,
                       COLOR_AWARE, STFUL_INST3, METER_TYPES };
enum class StatefulUse { NO_USE, DIRECT, INDIRECT, LOG, STACK_PUSH, STACK_POP, FIFO_PUSH,
                         FIFO_POP, STFUL_TYPES };
enum class AddrLocation { DIRECT, OVERHEAD, HASH, STFUL_COUNTER, GATEWAY_PAYLOAD, NOT_SET };
enum class PfeLocation { DEFAULT, OVERHEAD, GATEWAY_PAYLOAD, NOT_SET };
enum class TypeLocation { DEFAULT, OVERHEAD, GATEWAY_PAYLOAD, NOT_SET };
enum class ColorMapramAddress { IDLETIME, STATS, MAPRAM_ADDR_TYPES, NOT_SET };

}  // end namespace MAU

namespace BFN {
enum class ChecksumMode { VERIFY, RESIDUAL, CLOT };
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

#endif /* BF_P4C_IR_IR_ENUMS_H_ */
