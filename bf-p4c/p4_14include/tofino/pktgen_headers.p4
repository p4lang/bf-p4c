/*
Copyright (c) 2015-2019 Barefoot Networks, Inc.

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


/********************************************************************************
 *                   Packet Generator Header Definition for Tofino              *
 *******************************************************************************/

#ifndef TOFINO_LIB_PKTGEN_HEADERS
#define TOFINO_LIB_PKTGEN_HEADERS 1

header_type pktgen_generic_header_t {
    fields {
        _pad0     :  3;
        pipe_id   :  2;
        app_id    :  3;
        key_msb   :  8; // Only valid for recirc triggers.
        batch_id  : 16; // Overloaded to port# or lsbs of key for port down and
                        // recirc triggers.
        packet_id : 16;
    }
}
header pktgen_generic_header_t pktgen_generic;

header_type pktgen_timer_header_t {
    fields {
        _pad0     :  3;
        pipe_id   :  2;
        app_id    :  3;
        _pad1     :  8;
        batch_id  : 16;
        packet_id : 16;
    }
}
header pktgen_timer_header_t pktgen_timer;

header_type pktgen_port_down_header_t {
    fields {
        _pad0     :  3;
        pipe_id   :  2;
        app_id    :  3;
        _pad1     : 15;
        port_num  :  9;
        packet_id : 16;
    }
}
header pktgen_port_down_header_t pktgen_port_down;

header_type pktgen_recirc_header_t {
    fields {
        _pad0     :  3;
        pipe_id   :  2;
        app_id    :  3;
        key       : 24;
        packet_id : 16;
    }
}
header pktgen_recirc_header_t pktgen_recirc;

#endif
