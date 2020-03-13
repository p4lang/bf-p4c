/*
 * Copyright (c) 2015-2020 Barefoot Networks, Inc.
 *
 * All Rights Reserved.

 * NOTICE: All information contained herein is, and remains the property of
 * Barefoot Networks, Inc. and its suppliers, if any. The intellectual and
 * technical concepts contained herein are proprietary to Barefoot Networks, Inc.
 * and its suppliers and may be covered by U.S. and Foreign Patents, patents in
 * process, and are protected by trade secret or copyright law. Dissemination of
 * this information or reproduction of this material is strictly forbidden unless
 * prior written permission is obtained from Barefoot Networks, Inc.

 * No warranty, explicit or implicit is provided, unless granted under a written
 * agreement with Barefoot Networks, Inc.
 *
 */

// Fixed function blocks in Tofino are configured by bf_runtime through a
// table-based API. Each table requires a unique name that is not used by the
// user-defined table in P4 program. These fixed function blocks are
// instantiated as a top level extern instances. Their names are reserved at
// top level and used by bf_runtime.
//
// These extern constructs are NOT to be used in any P4 programs.

extern PacketReplicationEngine {
    PacketReplicationEngine();
}

PacketReplicationEngine() pre;

extern MirrorEngine {
    MirrorEngine();
}

MirrorEngine() mirror;

extern PortConfigrationEngine {
    PortConfigrationEngine();
}

PortConfigrationEngine() port;

extern TrafficManager {
    TrafficManager();
}

TrafficManager() tm;

extern PacketGenerationEngine {
    PacketGenerationEngine();
}

PacketGenerationEngine() pktgen;

