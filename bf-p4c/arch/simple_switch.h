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
#include "tofino/tofinoOptions.h"
#include "program_structure.h"

namespace Tofino {

class SimpleSwitchTranslation : public PassManager {
 public:
    P4::ReferenceMap refMap;
    P4::TypeMap      typeMap;
    ProgramStructure structure;
    explicit SimpleSwitchTranslation(Tofino_Options& options);
};

}  // namespace Tofino

#endif /* TOFINO_ARCH_SIMPLE_SWITCH_H_ */
