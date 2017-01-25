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

#ifndef TOFINO_COMMON_GRESS_H_
#define TOFINO_COMMON_GRESS_H_

#include <iosfwd>
#include "lib/cstring.h"

enum gress_t {
  INGRESS,
  EGRESS
};


std::ostream& operator<<(std::ostream& out, gress_t gress);
bool operator>>(cstring s, gress_t& gressOut);

#endif /* TOFINO_COMMON_GRESS_H_ */
