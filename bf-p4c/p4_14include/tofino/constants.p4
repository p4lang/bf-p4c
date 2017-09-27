/*
Copyright (c) 2015-2017 Barefoot Networks, Inc.

All Rights Reserved.

NOTICE: All information contained herein is, and remains the property of
Barefoot Networks, Inc. and its suppliers, if any. The intellectual and
technical concepts contained herein are proprietary to Barefoot Networks, Inc.
and its suppliers and may be covered by U.S. and Foreign Patents, patents in
process, and are protected by trade secret or copyright law. Dissemination of
this information or reproduction of this material is strictly forbidden unless
prior written permission is obtained from Barefoot Networks, Inc.

No warranty, explicit or implicit is provided, unless granted under a written
agreement with Barefoot Networks, Inc.
*/

// This file is to be kept in precise sync with constants.py

#ifndef TOFINO_LIB_CONSTANTS
#define TOFINO_LIB_CONSTANTS 1

/////////////////////////////////////////////////////////////
// Parser hardware error codes
#define PARSER_ERROR_OK             0x0000
#define PARSER_ERROR_NO_TCAM        0x0001
#define PARSER_ERROR_PARTIAL_HDR    0x0002
#define PARSER_ERROR_CTR_RANGE      0x0004
#define PARSER_ERROR_TIMEOUT_USER   0x0008
#define PARSER_ERROR_TIMEOUT_HW     0x0010
#define PARSER_ERROR_SRC_ERR        0x0020
#define PARSER_ERROR_DST_ERR        0x0040
#define PARSER_ERROR_PIPE_OWNER     0x0080
#define PARSER_ERROR_MULTIWRITE     0x0100
#define PARSER_ERROR_CTR_RAM        0x0200
#define PARSER_ERROR_ACTION_RAM     0x0400
#define PARSER_ERROR_CHKSUM_RAM     0x0800
#define PARSER_ERROR_FCS            0x1000

#define PARSER_ERROR_ARRAY_OOB      0xC000
/////////////////////////////////////////////////////////////

/////////////////////////////////////////////////////////////
// Digest receivers
#define FLOW_LRN_DIGEST_RCVR    0

#define RECIRCULATE_DIGEST_RCVR 90
#define RESUBMIT_DIGEST_RCVR    91
#define CLONE_I2I_DIGEST_RCVR   92
#define CLONE_E2I_DIGEST_RCVR   93
#define CLONE_I2E_DIGEST_RCVR   94
#define CLONE_E2E_DIGEST_RCVR   95
/////////////////////////////////////////////////////////////

/////////////////////////////////////////////////////////////
// Clone soruces
// (to be used with eg_intr_md_from_parser_aux.clone_src)
#define NOT_CLONED              0
#define CLONED_FROM_INGRESS     1
#define CLONED_FROM_EGRESS      3
#define COALESCED               5
/////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////
// Default priorities
#define PARSER_DEF_PRI     0
#define PARSER_THRESH_PRI  3

#endif
