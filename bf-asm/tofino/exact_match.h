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

#ifndef BF_ASM_TOFINO_EXACT_MATCH_H_
#define BF_ASM_TOFINO_EXACT_MATCH_H_

#include <tables.h>

class Target::Tofino::ExactMatchTable : public ::ExactMatchTable {
    friend class ::ExactMatchTable;
    ExactMatchTable(int line, const char *n, gress_t gr, Stage *s, int lid) :
        ::ExactMatchTable(line, n, gr, s, lid) { }

    void setup_ways() override;
};

#endif /* BF_ASM_TOFINO_EXACT_MATCH_H_ */
