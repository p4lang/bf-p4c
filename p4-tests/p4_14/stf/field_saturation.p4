// ---------------------------------------------------------------------------
// NOTES
// ---------------------------------------------------------------------------

// Tested on Tofino, with SDE 8.9.1

// Input packet has header h populated with field s5=21, saturating.
// Action all_subs() subtracts 3 from s5 and store the result into s5.
// condition_lo in the stateful ALU checks s5>=0 and increments the value of the
// register accordingly.
// After capturing a packet processed by this program, I relised that,
// after the subtract operation, the value stored in s5 is not 18, as expected.
// Instead, s5 saturates to its minimum value, which is -1 (0xFF).
// I repeted the same experiments, after removing saturating attribute from field s5.
// In this case, everything works as expected and the new value of s5, after the
// subtraction, is 18 (0x12).
//
// - Is there anything wrong in my code?
// - I don't understand why s5 is saturating and, more specifically, why it saturates
// to its minimum value.

#include <tofino/constants.p4>
#include <tofino/intrinsic_metadata.p4>
#include <tofino/primitives.p4>
#include "tofino/stateful_alu_blackbox.p4"
// ---------------------------------------------------------------------------
// HEADERS
// ---------------------------------------------------------------------------
header_type h_t {
    fields {
      s : 8 (signed);
      s2 : 8 (signed, saturating);
      s3 : 8;
      s4 : 8 (signed, saturating);
      s5 : 8 (saturating);
      s6 : 8 (saturating);
      s7 : 8;
    }
}
header h_t h;
// ---------------------------------------------------------------------------
// METADATA
// ---------------------------------------------------------------------------
#define DPVMETA_SIZEB 16
#define DPVMETA_SIZEb (DPVMETA_SIZEB*8)
header_type dpv_meta_t {
    fields {
        field_0: 32;
        field_1: 32;
        field_2: 32;
        field_3: 32;
    }
}
metadata dpv_meta_t dpv_meta;
// ---------------------------------------------------------------------------
// P4 PROGRAM
// ---------------------------------------------------------------------------
// PORTS
#define CPU_PORT 192
#define SW_PORT 52 // PORT 10
#define DEFAULT_PORT CPU_PORT

// STATEFUL ALU
#define SZ_REGS 64
#define SZ_ALU (SZ_REGS/2)
#define NUM_REGS 1
#define INDEX 0

// ---------------------------------------------------------------------------
// PARSER
// ---------------------------------------------------------------------------
parser start {
    // @DPV opc parser begin
	extract(h);
    // @DPV opc parser end
    return ingress;
}
// ---------------------------------------------------------------------------
// MATCH ACTION
// ---------------------------------------------------------------------------
// @DPV opc setdstport begin
//  *** SET DESTINATION PORT
action set_dstport(dstport) {
    modify_field(ig_intr_md_for_tm.ucast_egress_port, dstport);
}
table tbl_dstport {
    actions {
        set_dstport;
    }
    default_action: set_dstport(DEFAULT_PORT);
    size : 1;
}
// @DPV opc setdstport end

action all_subs() {
    // @DPV opc sub_flds begin
	subtract_from_field(h.s5, h.s4);
    // @DPV opc sub_flds end
}
table sub_tbl {
    actions {
        all_subs;
    }
    default_action : all_subs;
}

// @DPV opc check_regs begin
// >>>>>>>>> CHECK REG:3
register check_reg_3 {
    width : SZ_REGS;
    instance_count : NUM_REGS;
}
blackbox stateful_alu check_alu_3 {
    reg: check_reg_3;
    initial_register_lo_value: 0;
    condition_lo: h.s5 >= 0;
    // <DPV_COND_HI>
    update_lo_1_predicate: condition_lo;
    update_lo_1_value: register_lo + 1;
}
action check_act_3() {
    check_alu_3.execute_stateful_alu(INDEX);
}
table check_tbl_3 {
    actions {check_act_3;}
    default_action : check_act_3;
    size : 1;
}
// @DPV opc check_regs end

//  *** INGRESS
control ingress {

    // @DPV opc sub begin
    apply(sub_tbl);
    // @DPV opc sub end

    // @DPV opc checks begin
	apply(check_tbl_3);
    // @DPV opc checks end

    // @DPV opc app_dstport begin
    apply(tbl_dstport);
    // @DPV opc app_dstport end

}
