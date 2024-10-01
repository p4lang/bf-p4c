/**
 * Copyright (C) 2024 Intel Corporation
 *
 * Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file
 * except in compliance with the License.  You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software distributed under the
 * License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,
 * either express or implied.  See the License for the specific language governing permissions
 * and limitations under the License.
 *
 *
 * SPDX-License-Identifier: Apache-2.0
 */

/**
 * \defgroup PortableSwitchTranslation BFN::PortableSwitchTranslation
 * \ingroup ArchTranslation
 * \brief Set of passes that translate PSA architecture.
 */
#ifndef EXTENSIONS_BF_P4C_ARCH_PSA_PSA_H_
#define EXTENSIONS_BF_P4C_ARCH_PSA_PSA_H_

#include <optional>
#include <boost/algorithm/string.hpp>
#include "ir/ir.h"
#include "ir/namemap.h"
#include "ir/pattern.h"
#include "lib/path.h"
#include "frontends/common/options.h"
#include "frontends/p4/typeChecking/typeChecker.h"
#include "frontends/p4/coreLibrary.h"
#include "frontends/p4/cloner.h"
#include "frontends/p4/uniqueNames.h"
#include "frontends/p4/sideEffects.h"
#include "frontends/p4/methodInstance.h"
#include "bf-p4c/bf-p4c-options.h"
#include "bf-p4c/ir/gress.h"
#include "bf-p4c/arch/arch.h"

namespace BFN {

/**
 * \ingroup PortableSwitchTranslation
 * \brief PassManager that governs normalization of PSA architecture.
 */
class PortableSwitchTranslation : public PassManager {
 public:
    const IR::ToplevelBlock   *toplevel = nullptr;
    PortableSwitchTranslation(P4::ReferenceMap* refMap, P4::TypeMap* typeMap,
                              BFN_Options& options);
};

}  // namespace BFN

#endif /* EXTENSIONS_BF_P4C_ARCH_PSA_PSA_H_ */
