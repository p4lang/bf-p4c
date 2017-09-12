#include "tofino/intrinsic_metadata.p4"

#define TCAM_TABLE_SIZE          12288

/* Sample P4 program */
header_type ethernet_t {
    fields {
        etherType : 16;
        exm_key1 : 904;
        exm_key2 : 520;
        tcam_key1 : 40;
    }
}

parser start {
    return parse_ethernet;
}


parser parse_ethernet {
    extract(ethernet);
    return select(ethernet.etherType) {
        default: ingress;
    }
}

header ethernet_t ethernet;

action do_nothing(){}

action egr_eq_ing_action (port) {
    modify_field(ig_intr_md_for_tm.ucast_egress_port, port);
}

table eg_port{
      reads {
        ig_intr_md.ingress_port: exact;
      }
      actions {
        egr_eq_ing_action;
      }
}

@pragma stage 0
@pragma ways 5

table exm_table0_0{
      reads {
        ethernet.exm_key2 : exact;
      }
      actions {
        do_nothing;
      }
      size : 5120;
}

@pragma stage 0
@pragma ways 5
table exm_table0_1{
      reads {
        ethernet.exm_key2 : exact;
      }
      actions {
        do_nothing;
      }
      size : 5120;
}

@pragma stage 0
table tcam_table0{
      reads {
        ethernet.tcam_key1 : ternary;
      }
      actions {
        do_nothing;
      }
      size: TCAM_TABLE_SIZE;
}

@pragma stage 1
@pragma ways 5
@pragma pack 8
table exm_table1_0{
      reads {
        ethernet.exm_key1 : exact;
      }
      actions {
        do_nothing;
      }
      size : 5120;
}

@pragma stage 1
@pragma ways 5
@pragma pack 8
table exm_table1_1{
      reads {
        ethernet.exm_key1 : exact;
      }
      actions {
        do_nothing;
      }
      size : 5120;
}

@pragma stage 1
table tcam_table1{
      reads {
        ethernet.tcam_key1 : ternary;
      }
      actions {
        do_nothing;
      }
      size: TCAM_TABLE_SIZE;
}
@pragma stage 2
@pragma ways 5
@pragma pack 8
table exm_table2_0{
      reads {
        ethernet.exm_key1 : exact;
      }
      actions {
        do_nothing;
      }
      size : 5120;
}

@pragma stage 2
@pragma ways 5
@pragma pack 8
table exm_table2_1{
      reads {
        ethernet.exm_key1 : exact;
      }
      actions {
        do_nothing;
      }
      size : 5120;
}

@pragma stage 2
table tcam_table2{
      reads {
        ethernet.tcam_key1 : ternary;
      }
      actions {
        do_nothing;
      }
      size: TCAM_TABLE_SIZE;
}
@pragma stage 3
@pragma ways 5
@pragma pack 8
table exm_table3_0{
      reads {
        ethernet.exm_key1 : exact;
      }
      actions {
        do_nothing;
      }
      size : 5120;
}

@pragma stage 3
@pragma ways 5
@pragma pack 8
table exm_table3_1{
      reads {
        ethernet.exm_key1 : exact;
      }
      actions {
        do_nothing;
      }
      size : 5120;
}

@pragma stage 3
table tcam_table3{
      reads {
        ethernet.tcam_key1 : ternary;
      }
      actions {
        do_nothing;
      }
      size: TCAM_TABLE_SIZE;
}
@pragma stage 4
@pragma ways 5
@pragma pack 8
table exm_table4_0{
      reads {
        ethernet.exm_key1 : exact;
      }
      actions {
        do_nothing;
      }
      size : 5120;
}

@pragma stage 4
@pragma ways 5
@pragma pack 8
table exm_table4_1{
      reads {
        ethernet.exm_key1 : exact;
      }
      actions {
        do_nothing;
      }
      size : 5120;
}

@pragma stage 4
table tcam_table4{
      reads {
        ethernet.tcam_key1 : ternary;
      }
      actions {
        do_nothing;
      }
      size: TCAM_TABLE_SIZE;
}
@pragma stage 5
@pragma ways 5
@pragma pack 8
table exm_table5_0{
      reads {
        ethernet.exm_key1 : exact;
      }
      actions {
        do_nothing;
      }
      size : 5120;
}

@pragma stage 5
@pragma ways 5
@pragma pack 8
table exm_table5_1{
      reads {
        ethernet.exm_key1 : exact;
      }
      actions {
        do_nothing;
      }
      size : 5120;
}

@pragma stage 5
table tcam_table5{
      reads {
        ethernet.tcam_key1 : ternary;
      }
      actions {
        do_nothing;
      }
      size: TCAM_TABLE_SIZE;
}
@pragma stage 6
@pragma ways 5
@pragma pack 8
table exm_table6_0{
      reads {
        ethernet.exm_key1 : exact;
      }
      actions {
        do_nothing;
      }
      size : 5120;
}

@pragma stage 6
@pragma ways 5
@pragma pack 8
table exm_table6_1{
      reads {
        ethernet.exm_key1 : exact;
      }
      actions {
        do_nothing;
      }
      size : 5120;
}

@pragma stage 6
table tcam_table6{
      reads {
        ethernet.tcam_key1 : ternary;
      }
      actions {
        do_nothing;
      }
      size: TCAM_TABLE_SIZE;
}
@pragma stage 7
@pragma ways 5
@pragma pack 8
table exm_table7_0{
      reads {
        ethernet.exm_key1 : exact;
      }
      actions {
        do_nothing;
      }
      size : 5120;
}

@pragma stage 7
@pragma ways 5
@pragma pack 8
table exm_table7_1{
      reads {
        ethernet.exm_key1 : exact;
      }
      actions {
        do_nothing;
      }
      size : 5120;
}

@pragma stage 7
table tcam_table7{
      reads {
        ethernet.tcam_key1 : ternary;
      }
      actions {
        do_nothing;
      }
      size: TCAM_TABLE_SIZE;
}
@pragma stage 8
@pragma ways 5
@pragma pack 8
table exm_table8_0{
      reads {
        ethernet.exm_key1 : exact;
      }
      actions {
        do_nothing;
      }
      size : 5120;
}

@pragma stage 8
@pragma ways 5
@pragma pack 8
table exm_table8_1{
      reads {
        ethernet.exm_key1 : exact;
      }
      actions {
        do_nothing;
      }
      size : 5120;
}

@pragma stage 8
table tcam_table8{
      reads {
        ethernet.tcam_key1 : ternary;
      }
      actions {
        do_nothing;
      }
      size: TCAM_TABLE_SIZE;
}
@pragma stage 9
@pragma ways 5
@pragma pack 8
table exm_table9_0{
      reads {
        ethernet.exm_key1 : exact;
      }
      actions {
        do_nothing;
      }
      size : 5120;
}

@pragma stage 9
@pragma ways 5
@pragma pack 8
table exm_table9_1{
      reads {
        ethernet.exm_key1 : exact;
      }
      actions {
        do_nothing;
      }
      size : 5120;
}

@pragma stage 9
table tcam_table9{
      reads {
        ethernet.tcam_key1 : ternary;
      }
      actions {
        do_nothing;
      }
      size: TCAM_TABLE_SIZE;
}
@pragma stage 10
@pragma ways 5
@pragma pack 8
table exm_table10_0{
      reads {
        ethernet.exm_key1 : exact;
      }
      actions {
        do_nothing;
      }
      size : 5120;
}

@pragma stage 10
@pragma ways 5
@pragma pack 8
table exm_table10_1{
      reads {
        ethernet.exm_key1 : exact;
      }
      actions {
        do_nothing;
      }
      size : 5120;
}

@pragma stage 10
table tcam_table10{
      reads {
        ethernet.tcam_key1 : ternary;
      }
      actions {
        do_nothing;
      }
      size: TCAM_TABLE_SIZE;
}
@pragma stage 11
@pragma ways 5
@pragma pack 8
table exm_table11_0{
      reads {
        ethernet.exm_key1 : exact;
      }
      actions {
        do_nothing;
      }
      size : 5120;
}

@pragma stage 11
@pragma ways 5
@pragma pack 8
table exm_table11_1{
      reads {
        ethernet.exm_key1 : exact;
      }
      actions {
        do_nothing;
      }
      size : 5120;
}

@pragma stage 11
table tcam_table11{
      reads {
        ethernet.tcam_key1 : ternary;
      }
      actions {
        do_nothing;
      }
      size: TCAM_TABLE_SIZE;
}

control ingress {
  apply(eg_port);
  apply(exm_table0_0);
  apply(exm_table0_1);
  apply(tcam_table0);
  apply(exm_table1_0);
  apply(exm_table1_1);
  apply(tcam_table1);
  apply(exm_table2_0);
  apply(exm_table2_1);
  apply(tcam_table2);
  apply(exm_table3_0);
  apply(exm_table3_1);
  apply(tcam_table3);
  apply(exm_table4_0);
  apply(exm_table4_1);
  apply(tcam_table4);
  apply(exm_table5_0);
  apply(exm_table5_1);
  apply(tcam_table5);
  apply(exm_table6_0);
  apply(exm_table6_1);
  apply(tcam_table6);
  apply(exm_table7_0);
  apply(exm_table7_1);
  apply(tcam_table7);
  apply(exm_table8_0);
  apply(exm_table8_1);
  apply(tcam_table8);
  apply(exm_table9_0);
  apply(exm_table9_1);
  apply(tcam_table9);
  apply(exm_table10_0);
  apply(exm_table10_1);
  apply(tcam_table10);
  apply(exm_table11_0);
  apply(exm_table11_1);
  apply(tcam_table11);
}

control egress {
}

