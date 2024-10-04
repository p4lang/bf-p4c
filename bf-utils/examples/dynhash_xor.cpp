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

#include <cstdint>
#include <iomanip>
#include <iostream>
#include <sstream>
#include <string>
#include <vector>

#include "bfutils/dynamic_hash/dynamic_hash.h"

namespace {

void print_hash_matrix(
    std::ostream &os,
    const hash_column_t hash_matrix[PARITY_GROUPS_DYN][HASH_MATRIX_WIDTH_DYN],
    const hash_seed_t &seed) {
  const std::uint32_t BITS_PER_GROUP(64);
  const std::uint32_t COLUMNS(PARITY_GROUPS_DYN * BITS_PER_GROUP);

  /* -- print matrix heading */
  std::vector<std::string> heading;
  for (std::uint32_t col(0); col < HASH_MATRIX_WIDTH_DYN; ++col) {
    std::ostringstream oss;
    oss << std::setw(2) << std::setfill('0') << col;
    heading.push_back(oss.str());
  }
  for (std::uint32_t row(0); row < 2; ++row) {
    os << "     ";
    for (std::uint32_t col(0); col < HASH_MATRIX_WIDTH_DYN; ++col) {
      os << " " << heading[col][row];
    }
    os << std::endl;
  }
  os << std::endl;

  /* -- print the seed vector */
  os << std::setw(2) << "seed ";
  for (std::uint32_t col(0); col < HASH_MATRIX_WIDTH_DYN; ++col) {
    os << " " << std::setw(1)
       << (((seed.hash_seed_value >> col) & 0x01) ? 'X' : '.');
  }
  os << std::endl;

  /* -- print matrix lines */
  for (std::uint32_t row(0); row < COLUMNS; ++row) {
    if (row % BITS_PER_GROUP == 0) {
      os << std::endl;
    }
    os << std::setw(4) << std::setfill('0') << row << " ";
    for (std::uint32_t col(0); col < HASH_MATRIX_WIDTH_DYN; ++col) {
      os << " " << std::setw(1)
         << (((hash_matrix[row / BITS_PER_GROUP][col].column_value >>
               (row % BITS_PER_GROUP)) &
              0x01)
                 ? 'X'
                 : '.');
    }
    os << std::endl;
  }
}

}  // namespace

int main(int, char const *[]) {
  const int INPUT_SIZE(4);
  ixbar_input_t inputs[INPUT_SIZE];
  memset(inputs, 0, INPUT_SIZE * sizeof(ixbar_input_t));

  inputs[0].type = tPHV;
  inputs[0].ixbar_bit_position = 13;
  inputs[0].bit_size = 16;
  inputs[0].u.valid = true;

  inputs[1].type = tCONST;
  inputs[1].bit_size = 8;
  inputs[1].u.constant = 0xaa;

  inputs[2].type = tPHV;
  inputs[2].ixbar_bit_position = 64;
  inputs[2].bit_size = 16;
  inputs[2].u.valid = false;

  inputs[3].type = tPHV;
  inputs[3].ixbar_bit_position = 32;
  inputs[3].bit_size = 8;
  inputs[3].u.valid = true;

  std::uint32_t total_input_bits(0);
  for (std::uint32_t i(0); i < INPUT_SIZE; ++i) {
    total_input_bits += inputs[i].bit_size;
  }

  const int OUTPUT_SIZE(1);
  const int XOR_WIDTH(16);
  hash_matrix_output_t outputs[OUTPUT_SIZE];
  memset(outputs, 0, OUTPUT_SIZE * sizeof(hash_matrix_output_t));
  outputs[0].bit_size = XOR_WIDTH;

  ixbar_init_t init;
  init.ixbar_inputs = inputs;
  init.inputs_sz = INPUT_SIZE;
  init.hash_matrix_outputs = outputs;
  init.outputs_sz = OUTPUT_SIZE;
  init.parity_group = 1;

  bfn_hash_algorithm_t alg;
  alg.hash_alg = XOR_DYN;
  alg.hash_bit_width = XOR_WIDTH;
  alg.msb = false;
  alg.extend = false;

  hash_column_t matrix[PARITY_GROUPS_DYN][HASH_MATRIX_WIDTH_DYN];
  memset(matrix,
         0,
         sizeof(hash_column_t) * PARITY_GROUPS_DYN * HASH_MATRIX_WIDTH_DYN);
  determine_hash_matrix(&init, inputs, INPUT_SIZE, &alg, matrix);

  hash_seed_t seed;
  memset(&seed, 0, sizeof(hash_seed_t));
  determine_seed(
      outputs, OUTPUT_SIZE, inputs, INPUT_SIZE, total_input_bits, &alg, &seed);

  print_hash_matrix(std::cout, matrix, seed);

  return 0;
}
