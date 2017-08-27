/*
  Copyright 2013-present Barefoot Networks, Inc.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

  http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

#ifndef TOFINO_ARCH_SIMPLE_SWITCH_H_
#define TOFINO_ARCH_SIMPLE_SWITCH_H_

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
#include "tofino/tofinoOptions.h"
#include "program_structure.h"

namespace Tofino {

namespace P4_14 {
static const cstring MeterType = "MeterType";
static const cstring DirectMeter = "direct_meter";
static const cstring Meter = "meter";
static const cstring Counter = "counter";
static const cstring PACKETS = "packets";
static const cstring BYTES = "bytes";
static const cstring PACKETS_AND_BYTES = "packets_and_bytes";
static const cstring Random = "random";
}  // namespace P4_14

namespace P4_16 {

static const cstring DirectMeter = "DirectMeter";
static const cstring Meter = "meter";
static const cstring MeterType = "meter_type_t";
static const cstring MeterColor = "meter_color_t";
static const cstring MeterExec = "execute";
static const cstring CounterType = "counter_type_t";
static const cstring Counter = "counter";
static const cstring PACKETS = "PACKETS";
static const cstring BYTES = "BYTES";
static const cstring PACKETS_AND_BYTES = "PACKETS_AND_BYTES";
static const cstring BIT_OF_COLOR = "bit_of_color";
static const cstring Random = "random";
static const cstring RandomExec = "get";
}  // namespace P4_16

class SimpleSwitchTranslation : public PassManager {
 public:
    P4::ReferenceMap refMap;
    P4::TypeMap      typeMap;
    ProgramStructure structure;
    explicit SimpleSwitchTranslation(Tofino_Options& options);
};

}  // namespace Tofino

#endif /* TOFINO_ARCH_SIMPLE_SWITCH_H_ */
