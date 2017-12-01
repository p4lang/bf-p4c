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

// experimental P4_16 tofino stateful alu extern

#if !defined(_V1_MODEL_P4_)
extern register;  // "forward" declaration -- so parser recognizes it as a type name
extern action_selector;
#endif /* !_V1_MODEL_P4_ */

extern register_params<T> {
    // FIXME -- make this part of register for tofino?
    register_params();
    register_params(T value);
    register_params(T v1, T v2);
    register_params(T v1, T v2, T v3);
    register_params(T v1, T v2, T v3, T v4);
    T read(bit<2> index);
}

extern math_unit<T, U> {
    math_unit(bool invert, int<2> shift, int<6> scale, U data);
    T execute(in T x);
}

extern register_action<T, U> {
    register_action(register<T> reg, @optional math_unit<U, _> math,
                                     @optional register_params<U> params);
    abstract void apply(inout T value, @optional out U rv, @optional register_params<U> params);
    U execute(@optional in bit<32> index); /* {
        U rv;
        T value = reg.read(index);
        apply(value, rv);
        reg.write(index, value);
        return rv;
    } */
    U execute_log(); /* execute at an index that increments each time */
}

extern selector_action {
    selector_action(action_selector sel);
    abstract void apply(inout bit<1> value, @optional out bit<1> rv);
    bit<1> execute(@optional in bit<32> index);
}
