// experimental P4_16 tofino stateful alu extern

#if !defined(_V1_MODEL_P4_)
extern register;  // "forward" declaration -- so parser recognizes it as a type name
#endif /* !_V1_MODEL_P4_ */

extern stateful_params<T> {
    stateful_params();
    stateful_params(T value);
    stateful_params(T v1, T v2);
    stateful_params(T v1, T v2, T v3);
    stateful_params(T v1, T v2, T v3, T v4);
    T read(bit<2> index);
}

extern stateful_alu<T, U> {
    stateful_alu(register<T> reg);
    abstract void function(inout T value, @optional out U rv, @optional stateful_params<U> params);
    U execute(@optional in bit<32> index); /* {
        U rv;
        T value = reg.read(index);
        function(value, rv);
        reg.write(index, value);
        return rv;
    } */
}
