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

#include "filelog.h"

std::set<cstring> Logging::FileLog::filesWritten;

// static
const cstring& Logging::FileLog::name2type(cstring logName) {
    static const cstring unknown("Unknown");
    static const std::map<cstring, cstring> logNames2Type = {
        {"clot_allocation",             "parser"},
        {"decaf",                       "parser"},
        {"flexible_packing",            "parser"},
        {"ixbar",                       "mau"},
        {"parser.characterize",         "parser"},
        {"parser",                      "parser"},
        {"phv_allocation",              "phv"},
        {"phv_optimization",            "phv"},
        {"phv_incremental_allocation",  "phv"},
        {"phv_trivial_allocation",      "phv"},
        {"phv_greedy_allocation",       "phv"},
        {"table_",                      "mau"},
        {"pragmas",                     "phv"},
        {"live_range_split",            "phv"},
        {"backend_passes",              "text"}
    };

    for (auto &logType : logNames2Type)
        if (logName.startsWith(logType.first))
            return logType.second;
    return unknown;
}
