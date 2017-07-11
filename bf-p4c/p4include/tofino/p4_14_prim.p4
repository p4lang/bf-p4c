/* primitives supported by tofino and not supported by v1model.p4 */

#if !defined(_V1_MODEL_P4_)
extern CloneType;  // "forward" declaration -- so parser recognizes it as a type name
#endif /* !_V1_MODEL_P4_ */

extern void bypass_egress();

extern void invalidate<T>(in T field);
extern void invalidate_raw(in bit<9> field);

extern void sample3(in CloneType type, in bit<32> session, in bit<32> length);
extern void sample4<T>(in CloneType type, in bit<32> session, in bit<32> length, in T data);

