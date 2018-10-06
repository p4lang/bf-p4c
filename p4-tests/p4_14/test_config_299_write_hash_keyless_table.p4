
/* Sample P4 program */
header_type pkt_t {
    fields {
        field_a_32 : 32;
        field_b_32 : 32;

        field_e_16 : 16;
        field_f_16 : 16;

        field_i_8 : 8;
        field_j_8 : 8;
    }
}

parser start {
    return parse_ethernet;
}

header pkt_t pkt;

parser parse_ethernet {
    extract(pkt);
    return ingress;
}

field_list field_list_1 {
      pkt.field_f_16;
}

field_list_calculation hash_1 {
   input {
       field_list_1;
   }
   algorithm : identity;
   output_width : 16;
}

action action_0(){
    modify_field_with_hash_based_offset(pkt.field_e_16, 0, hash_1, 65536);
}

table table_0 {
    actions {
        action_0;
    }
    default_action : action_0;
}


control ingress {
    //if (valid(pkt)){
    apply(table_0);
    //}
}

