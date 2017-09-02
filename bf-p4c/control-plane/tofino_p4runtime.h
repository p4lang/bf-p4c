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

#ifndef EXTENSIONS_TOFINO_CONTROL_PLANE_TOFINO_P4RUNTIME_H_
#define EXTENSIONS_TOFINO_CONTROL_PLANE_TOFINO_P4RUNTIME_H_

namespace IR {
class P4Program;
}  // namespace IR

class Tofino_Options;

namespace Tofino {

/// A wrapper for P4::serializeP4Runtime() that applies Tofino-specific
/// transformations to the program before serialization.
void serializeP4Runtime(const IR::P4Program* program,
                        const Tofino_Options& options);

}  // namespace Tofino

#endif /* EXTENSIONS_TOFINO_CONTROL_PLANE_TOFINO_P4RUNTIME_H_ */
