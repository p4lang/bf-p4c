// experimental P4_16 tofino stateful alu extern

#if !defined(_V1_MODEL_P4_)
extern register;  // "forward" declaration -- so parser recognizes it as a type name
extern action_selector;
#endif /* !_V1_MODEL_P4_ */

#if V1MODEL_VERSION >= 20200408
#define __REG_INDEX_ARG(A)  , A
#else
#define __REG_INDEX_ARG(A)
#endif /* V1MODEL_VERSION */

extern math_unit<T, U> {
    math_unit(bool invert, int<2> shift, int<6> scale, U data);
    T execute(in T x);
}

extern T max<T>(in T t1, in T t2);
extern T min<T>(in T t1, in T t2);

@noWarn("unused")
extern RegisterAction<T, I, U> {
    RegisterAction(register<_ __REG_INDEX_ARG(_)> reg);
    U execute(in I index);
    U execute_log(); /* execute at an index that increments each time */
    @synchronous(execute, execute_log)
    abstract void apply(inout T value, @optional out U rv);
    U predicate(@optional in bool cmplo,
                @optional in bool cmphi); /* return the 4-bit predicate value */
}

extern DirectRegisterAction<T, U> {
    DirectRegisterAction(register<_ __REG_INDEX_ARG(_)> reg);
    U execute();
    @synchronous(execute)
    abstract void apply(inout T value, @optional out U rv);
    U predicate(@optional in bool cmplo,
                @optional in bool cmphi); /* return the 4-bit predicate value */
}

extern SelectorAction {
    SelectorAction(action_selector sel);
    bit<1> execute(@optional in bit<32> index);
    @synchronous(execute)
    abstract void apply(inout bit<1> value, @optional out bit<1> rv);
}
