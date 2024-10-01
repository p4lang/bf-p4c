#!/usr/bin/env python3

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

"""
This file holds the various JSON attribute names, keys, etc., that are used by
tools.  Rather than duplicating definitions, let's put them in a common file.
"""

# ----------------------------------------
# Common
# ----------------------------------------
ACTION_NAME = "action_name"
ACTION_PARAMETERS = "action_parameters"
ADDRESSES = "addresses"
BIT_INDEX = "bit_index"
BIT_WIDTH = "bit_width"
BUILD_DATE = "build_date"
CLOTS = "clots"
COMPILER_VERSION = "compiler_version"
CONTAINERS = "containers"
CONTAINER_TYPE = "container_type"
EGRESS = "egress"
ENTRIES_PER_TABLE_WORD = "entries_per_table_word"
ENTRY_NUMBER = "entry_number"
FIELD_INFO = "field_info"
FIELD_NAME = "field_name"
FIELD_SLICE = "field_slice"
FIELDS = "fields"
FORMAT_TYPE = "format_type"
GRESS = "gress"
INGRESS = "ingress"
LOCATION = "location"
LSB = "lsb"
MEMORY_TYPE = "memory_type"
MEMORY_WORD_WIDTH = "memory_word_width"
MSB = "msb"
NAME = "name"
PHV_NUMBER = "phv_number"
PROGRAM_NAME = "program_name"
RUN_ID = "run_id"
SCHEMA_VERSION = "schema_version"
SIZE = "size"
SLICE_INFO = "slice_info"
STAGE = "stage"
STAGE_NUMBER = "stage_number"
START_BIT = "start_bit"
TABLES = "tables"
TABLE_TYPE = "table_type"
TABLE_WORD_WIDTH = "table_word_width"
TYPE = "type"
WORD_BIT_WIDTH = "word_bit_width"


# ----------------------------------------
# Context Keys
# ----------------------------------------
ACTION_DATA_TABLE_REFS = "action_data_table_refs"
ACTION_FORMAT = "action_format"
ACTION_HANDLE = "action_handle"
ACTIONS = "actions"
ATCAM_TABLE = "atcam_table"
COND = "cond"
CONDITION_FIELDS = "condition_fields"
CONDITION_HI = "condition_hi"
CONDITION_LO = "condition_lo"
DEST_WIDTH = "dest_width"
DIRECTION = "direction"
DST = "dst"
ENTRIES = "entries"
FIELD_WIDTH = "field_width"
HANDLE = "handle"
HASH_INPUTS = "hash_inputs"
HEADER_NAME = "header_name"
IDX = "idx"
IMMEDIATE_FIELDS = "immediate_fields"
IS_POV = "is_pov"
LIVE_END = "live_end"
LIVE_START = "live_start"
LSB_MEM_WORD_IDX = "lsb_mem_word_idx"
LSB_MEM_WORD_OFFSET = "lsb_mem_word_offset"
MATCH_ATTRIBUTES = "match_attributes"
MATCH_KEY_FIELDS = "match_key_fields"
MATCH_TYPE = "match_type"
MEMORY_RESOURCE_ALLOCATION = "memory_resource_allocation"
MEMORY_UNITS = "memory_units"
MEMORY_UNITS_AND_VPNS = "memory_units_and_vpns"
METER_TABLE_REFS = "meter_table_refs"
MSB_MEM_WORD_IDX = "msb_mem_word_idx"
MSB_MEM_WORD_OFFSET = "msb_mem_word_offset"
NUMBER_MEMORY_UNITS_PER_TABLE_WORD = "number_memory_units_per_table_word"
OPERAND_1_TYPE = "operand_1_type"
OPERAND_1_VALUE = "operand_1_value"
OPERAND_2_TYPE = "operand_2_type"
OPERAND_2_VALUE = "operand_2_value"
OUTPUT_DST = "output_dst"
OUTPUT_PREDICATE = "output_predicate"
OUTPUT_VALUE = "output_value"
P4_PARAMETERS = "p4_parameters"
PACK_FORMAT = "pack_format"
PHV_ALLOCATION = "phv_allocation"
POV_HEADERS = "pov_headers"
PRE_CLASSIFIER = "pre_classifier"
PRIMITIVES = "primitives"
SELECTION_TABLE_REFS = "selection_table_refs"
SOURCE = "source"
SPARE_BANK_MEMORY_UNIT = "spare_bank_memory_unit"
SRC1 = "src1"
SRC2 = "src2"
SRC3 = "src3"
STAGE_TABLE_TYPE = "stage_table_type"
STAGE_TABLES = "stage_tables"
STATEFUL_ALU_DETAILS = "stateful_alu_details"
STATEFUL_TABLE_REFS = "stateful_table_refs"
STATISTICS_TABLE_REFS = "statistics_table_refs"
TARGET_KEY = "target"
TERNARY_INDIRECTION_STAGE_TABLE = "ternary_indirection_stage_table"
UNITS = "units"
UPDATE_LO_1_PREDICATE = "update_lo_1_predicate"
UPDATE_LO_1_VALUE = "update_lo_1_value"
UPDATE_LO_2_PREDICATE = "update_lo_2_predicate"
UPDATE_LO_2_VALUE = "update_lo_2_value"
UPDATE_HI_1_PREDICATE = "update_hi_1_predicate"
UPDATE_HI_1_VALUE = "update_hi_1_value"
UPDATE_HI_2_PREDICATE = "update_hi_2_predicate"
UPDATE_HI_2_VALUE = "update_hi_2_value"
WAYS = "ways"

ALL_REF_TYPES = [ACTION_DATA_TABLE_REFS, METER_TABLE_REFS,
                 SELECTION_TABLE_REFS, STATEFUL_TABLE_REFS, STATISTICS_TABLE_REFS]


# ----------------------------------------
# MAU Keys
# ----------------------------------------
ACTION_DATA_SLOT_SIZE = "action_data_slot_size"
ACTION_FORMATS = "action_formats"
ACTION_SLOT_NUMBER = "action_slot_number"
ENTRIES_ALLOCATED = "entries_allocated"
ENTRIES_REQUESTED = "entries_requested"
ENTRY_BIT_WIDTH_REQUESTED = "entry_bit_width_requested"
ENTRY_BIT_WIDTH_ALLOCATED = "entry_bit_width_allocated"
IDEAL_ENTRIES_PER_TABLE_WORD = "ideal_entries_per_table_word"
IDEAL_TABLE_WORD_BIT_WIDTH = "ideal_table_word_bit_width"
IMM_BIT_WIDTH_IN_OVERHEAD_REQUESTED = "imm_bit_width_in_overhead_requested"
IMM_BIT_WIDTH_IN_OVERHEAD_ALLOCATED = "imm_bit_width_in_overhead_allocated"
LOOKUP_TYPES = "lookup_types"
MATCH_FIELDS = "match_fields"
MATCH_FORMAT = "match_format"
MEMORIES = "memories"
MEMORY_START_BIT = "memory_start_bit"
NUM_MEMORIES = "num_memories"
OVERHEAD_FIELDS = "overhead_fields"
PARAMETERS = "parameters"
PARAMETER_MAP = "parameter_map"
STAGE_ALLOCATION = "stage_allocation"


# ----------------------------------------
# PHV Keys
# ----------------------------------------
GROUP_TYPE = "group_type"
FIELD_CLASS = "field_class"
ORDERED_FIELDS = "ordered_fields"
POV_BIT_INDEX = "pov_bit_index"
POV_BIT_NAME = "pov_bit_name"
POV_STRUCTURE = "pov_structure"
READS = "reads"
STRUCTURES = "structures"
TYPE = "type"
WRITES = "writes"

# ----------------------------------------
# Power Keys
# ----------------------------------------
TOTAL_LATENCY = "total_latency"
TOTAL_POWER = "total_power"


# ----------------------------------------
# Resources Keys
# ----------------------------------------
ACTION_BUS_BYTES = "action_bus_bytes"
ACTION_SLOTS = "action_slots"
BIT_WIDTH = "bit_width"
BITS = "bits"
BYTE_TYPE = "byte_type"
BYTES = "bytes"
CLOT_ELIGIBLE_FIELDS = "clot_eligible_fields"
COLOR_USAGES = "color_usages"
DARK = "dark"
EXACT_SIZE = "exact_size"
EXM_SEARCH_BUSES = "exm_search_buses"
EXM_RESULT_BUSES = "exm_result_buses"
FDE_ENTRIES = "fde_entries"
FIELDS = "fields"
GATEWAYS = "gateways"
HASH_BITS = "hash_bits"
HASH_DISTRIBUTION_UNITS = "hash_distribution_units"
IDS = "ids"
INSTRUCTIONS = "instructions"
IS_CHECKSUM = "is_checksum"
IS_MODIFIED = "is_modified"
IS_READONLY = "is_readonly"
LOGICAL_TABLES = "logical_tables"
MAPRAMS = "maprams"
MAP_RAMS = "map_rams"
MAU = "mau"
MAU_STAGES = "mau_stages"
MAXIMUM_SLOTS = "maximum_slots"
METERS = "meters"
METER_ALUS = "meter_alus"
MOCHA = "mocha"
NALUS = "nAlus"
NBITS = "nBits"
NCOLUMNS = "nColumns"
NFUNCTIONS = "nFunctions"
NHASHIDS = "nHashIds"
NORMAL = "normal"
NROWS = "nRows"
NSTAGES = "nStages"
NUM_BITS_IN_CLOTS = "num_bits_in_clots"
NUM_BITS_IN_PHVS = "num_bits_in_phvs"
NUMBER_USED = "number_used"
NUNITIDS = "nUnitIds"
NUNITS = "nUnits"
PARSERS = "parsers"
PHASE0 = "phase0"
PHV_CONTAINERS = "phv_containers"
PIPE_ID = "pipe_id"
PIPES = "pipes"
POV = "pov"
POV_BITS = "pov_bits"
RAMS = "rams"
RESOURCES = "resources"
SLICES = "slices"
SLOT_BIT_WIDTH = "slot_bit_width"
SRAMS = "srams"
STASHES = "stashes"
STATES = "states"
STATISTICS_ALUS = "statistic_alus"
STATS = "stats"
TABLE_NAME = "table_name"
TCAMS = "tcams"
TERNARY_SIZE = "ternary_size"
TIND_RESULT_BUSES = "tind_result_buses"
USAGES = "usages"
USED_BY = "used_by"
USED_BY_TABLE = "used_by_table"
USED_BY_TABLES = "used_by_tables"
VLIW = "vliw"
WIDTH = "width"
XBAR_BYTES = "xbar_bytes"


# ----------------------------------------
# Metrics Keys
# ----------------------------------------
COMPILATION_TIME = "compilation_time"
CYCLES = "cycles"
EXACT_CROSSBAR_BYTES = "exact_crossbar_bytes"
ESTIMATE = "estimate"
LATENCY = "latency"
PARSER = "parser"
POWER = "power"
TERNARY_CROSSBAR_BYTES = "ternary_crossbar_bytes"
