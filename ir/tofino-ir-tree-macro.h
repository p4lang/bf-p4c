#ifndef TOFINO_IRNODE_ALL_SUBCLASSES_AND_DIRECT_AND_INDIRECT_BASES

/* tree XMACRO for tofino-specific IR classes.  This must match the declaration in
 * ir-tree-macros.h and is pulled in there */

#define TOFINO_IRNODE_ALL_SUBCLASSES_AND_DIRECT_AND_INDIRECT_BASES(M, T, D, B, ...)             \
    M(Tofino_ParserMatch, D(Node), ##__VA_ARGS__)                                               \
    M(Tofino_ParserState, D(Node), ##__VA_ARGS__)                                               \
    M(Tofino_Parser, D(Node), ##__VA_ARGS__)                                                    \
    M(Tofino_Deparser, D(Node), ##__VA_ARGS__)                                                  \
    M(MAU_TernaryIndirect, D(Attached) B(Node), ##__VA_ARGS__)                                  \
    M(MAU_ActionData, D(Attached) B(Node), ##__VA_ARGS__)                                       \
    M(MAU_Table, D(Node), ##__VA_ARGS__)                                                        \
    M(MAU_TableSeq, D(Node), ##__VA_ARGS__)                                                     \
    M(MAU_Instruction, D(Primitive) B(Operation) B(Expression) B(Node), ##__VA_ARGS__)          \
    M(Tofino_Pipe, D(Node), ##__VA_ARGS__)                                                      \

#endif /* TOFINO_IRNODE_ALL_SUBCLASSES_AND_DIRECT_AND_INDIRECT_BASES */
