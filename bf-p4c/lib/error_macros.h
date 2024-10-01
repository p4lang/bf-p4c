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

#ifndef EXTENSIONS_BF_P4C_LIB_ERROR_MACROS_H_
#define EXTENSIONS_BF_P4C_LIB_ERROR_MACROS_H_

/// Report an error if condition e is false.
#define ERROR_CHECK(e, ...) do { if (!(e)) ::error(__VA_ARGS__); } while (0)

/// Report a warning if condition e is false.
#define WARN_CHECK(e, ...) do { if (!(e)) ::warning(__VA_ARGS__); } while (0)


/// Trigger a diagnostic message which is treated as a warning by default.
#define DIAGNOSE_WARN(DIAGNOSTIC_NAME, ...) \
    do { ::diagnose(DiagnosticAction::Warn, DIAGNOSTIC_NAME, __VA_ARGS__); } while (0)

/// Trigger a diagnostic message which is treated as an error by default.
#define DIAGNOSE_ERROR(DIAGNOSTIC_NAME, ...) \
    do { ::diagnose(DiagnosticAction::Error, DIAGNOSTIC_NAME, __VA_ARGS__); } while (0)

#endif  /* EXTENSIONS_BF_P4C_LIB_ERROR_MACROS_H_ */
