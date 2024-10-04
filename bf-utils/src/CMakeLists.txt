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

project(libbfutils VERSION 0.1 LANGUAGES C)

set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY "${CMAKE_INSTALL_PREFIX}/lib")
add_subdirectory(dynamic_hash)
add_library(bfsysutil_o OBJECT
  bf_utils.c
)
add_library(bfutils SHARED
  $<TARGET_OBJECTS:bfsysutil_o>
  $<TARGET_OBJECTS:dynhash_o>
)
add_dependencies(bfutils build_edit)
ExternalProject_Get_Property(build_edit binary_dir)
target_link_libraries(bfutils PUBLIC ${binary_dir}/src/.libs/libedit.a target_sys)
