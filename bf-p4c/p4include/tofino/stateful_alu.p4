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

extern math_unit<T, U> {
    math_unit(bool invert, int<2> shift, int<6> scale, U data);
    T execute(in T x);
}

extern RegisterAction<T, I, U> {
    RegisterAction(register<T> reg);
    abstract void apply(inout T value, @optional out U rv);
    U execute(in I index);
    U execute_log(); /* execute at an index that increments each time */
}

extern DirectRegisterAction<T, U> {
    DirectRegisterAction(register<T> reg);
    abstract void apply(inout T value, @optional out U rv);
    U execute();
}

extern selector_action {
    selector_action(action_selector sel);
    abstract void apply(inout bit<1> value, @optional out bit<1> rv);
    bit<1> execute(@optional in bit<32> index);
}
