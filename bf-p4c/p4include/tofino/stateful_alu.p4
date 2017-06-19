// experimental P4_16 tofino stateful alu extern

#if !defined(_V1_MODEL_P4_)
extern register;  // "forward" declaration -- so parser recognizes it as a type name
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

extern register_action<T, U> {
    register_action(register<T> reg);
    abstract void apply(inout T value, @optional out U rv, @optional register_params<U> params);
    U execute(@optional in bit<32> index); /* {
        U rv;
        T value = reg.read(index);
        apply(value, rv);
        reg.write(index, value);
        return rv;
    } */
}
