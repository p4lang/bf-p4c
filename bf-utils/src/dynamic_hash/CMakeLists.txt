# Copyright (C) 2024 Intel Corporation
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License.  You may obtain
# a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.  See the
# License for the specific language governing permissions and limitations
# under the License.
#
#
# SPDX-License-Identifier: Apache-2.0

project(libdynhash VERSION 0.1 LANGUAGES C)
add_library(dynhash_o OBJECT
  dynamic_hash.c
  bfn_hash_algorithm.c)
add_library(dynhash SHARED EXCLUDE_FROM_ALL $<TARGET_OBJECTS:dynhash_o>)

# static lib for compiler with no syslibs
add_library(dynhashStatic STATIC dynamic_hash.c bfn_hash_algorithm.c)
set_target_properties(dynhashStatic PROPERTIES OUTPUT_NAME dynhash)
target_compile_definitions(dynhashStatic PUBLIC NO_BFSYSLIBS)
