#ifndef BF_P4C_PARDE_DECAF_H_
#define BF_P4C_PARDE_DECAF_H_

#include "bf-p4c/mau/table_dependency_graph.h"

/*********************************************************************************
 *
 *  decaf : a deparser optimization of copy assigned fields
 *
 *                     author: zhao ma
 *  
 *  The observation is that there is a high degree of data movement in many common
 *  data-plane program patterns (e.g. tunneling, label switching), i.e. a large number
 *  of fields participate in copy assignment only. These are the fields whose final
 *  value is that of another such copied only field.
 *
 *  Based on this observation, we devise an optimization which resolves data copies
 *  directly in the deparser rather than using the MAU to move the data, costing normal
 *  PHV containers.
 *
 *
 *  Consider the program below:
 * 
 *     action a1() { modify_field(data.a, data.b); }
 *     
 *     action a2() { modify_field(data.a, 0x0800); }
 *     
 *     action a3() { modify_field(data.a, data.c); }
 *     
 *     table t1 {
 *           reads { data.m : exact; }
 *         actions { a1; a2; a3; nop; }
 *     }
 *     
 *     action a4() { modify_field(data.b, data.a); }
 *     
 *     action a5() { modify_field(data.b, 0x0866); }
 *     
 *     table t2 {
 *           reads { data.k : exact; }
 *         actions { a4; a5; nop; }
 *     }
 *     
 *     control ingress {
 *         apply(t1);
 *         apply(t2);
 *     }
 *
 *
 *  The possible values for each field (and reaching action sequence) are:
 *   
 *       data.a : v0: 0x0800:   t1.a2 -> *
 *                v1: data.b:   t1.a1 -> *
 *                v2: data.c:   t1.a3 -> *
 *                v3: data.a:  t1.nop -> *
 *   
 *       data.b : v0: 0x0800:  t1.a2 -> t2.a4
 *                v1: 0x0866:      * -> t2.a5
 *                v2: data.a: t1.nop -> t2.a4
 *                v3: data.c:  t1.c3 -> t2.a4
 *                v4: data.b:  t1.a1 -> t2.nop
 *   
 *       data.c : data.c (read-only)
 *
 *
 *  Let's assign a bit to each action, and another bit to each version for a
 *  field's final value. The function between the action bits and version bits 
 *  can be represented as a truth table.
 *
 *     a1  a2  a3  a4  a5 | a_v0 a_v1 a_v2 a_v3  b_v0 b_v1 b_v2 b_v3 b_v4
 *    -------------------------------------------------------------------
 *      1   0   0   0   0 |   0    1    0    0     0    0    0    0    1 
 *      0   1   0   0   0 |   1    0    0    0     0    0    0    0    1 
 *      0   0   1   0   0 |   0    1    0    1     0    0    0    0    1 
 *      0   1   0   1   0 |   1    0    0    0     1    0    0    0    0 
 *      0   0   0   0   1 |   0    0    0    1     0    1    0    0    0 
 *        ...    
 *        ...
 *
 *  Conveniently, the truth table can be implemented in Tofino as a match action
 *  table (using static entries). The version bits are wired to the FD as POV bits
 *  for the deparser to disambiguate which version to use for each field to reconstruct 
 *  final packet, and with each version allocated to its own FD entry. Finally, all
 *  versions of value can be parsed into tagalong containers.
 *
 **********************************************************************************/

class DeparserCopyOpt : public PassManager {
    const PhvInfo &phv;
    PhvUse &uses;
    const DependencyGraph& dg;

 public:
    DeparserCopyOpt(const PhvInfo &phv, PhvUse &uses, const DependencyGraph& dg);
};

#endif  /* BF_P4C_PARDE_DECAF_H_ */
