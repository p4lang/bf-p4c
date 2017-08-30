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

#ifndef _COMMON_PARAM_BINDING_H_
#define _COMMON_PARAM_BINDING_H_

#include <map>
#include "ir/ir.h"

namespace P4 {
class TypeMap;
}  // namespace P4


/// ParamBinding creates and tracks instances of package parameters and
/// variable declarations.
class ParamBinding {
    const P4::TypeMap *typeMap;
    std::map<const IR::Type*, const IR::InstanceRef *>          by_type;
    std::map<const IR::Parameter *, const IR::InstanceRef *>    by_param;
    std::map<const IR::Declaration_Variable *, const IR::InstanceRef *>    by_declvar;

 public:
    explicit ParamBinding(const P4::TypeMap *typeMap) : typeMap(typeMap) { }

    /// Add a new header or metadata instance bound to the given parameter.
    void bind(const IR::Parameter *param);

    /// Add a new header or metadata instance bound to the given variable
    /// declaration.
    void bind(const IR::Declaration_Variable *var);

    /// Get the header or metadata instance previously bound to the given
    /// parameter.
    const IR::InstanceRef *get(const IR::Parameter *param) const {
        return by_param.count(param) ? by_param.at(param) : nullptr; }

    /// Get the header or metadata instance previously bound to the given
    /// variable declaration.
    const IR::InstanceRef *get(const IR::Declaration_Variable *var) const {
        return by_declvar.count(var) ? by_declvar.at(var) : nullptr; }
};

#endif /* _COMMON_PARAM_BINDING_H_ */
