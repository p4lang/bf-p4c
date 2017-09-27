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

enum hash_algorithm_t {
    CRC16
}

extern checksum<W> {
    checksum(hash_algorithm_t algorithm);
    void add<T>(in T data);
    bool verify();
    void update<T>(in T data, out W csum, @optional in W residul_csum);
    W residual_checksum<T>(in T data);
}
