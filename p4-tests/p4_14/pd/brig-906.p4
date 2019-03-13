
#include <tofino/intrinsic_metadata.p4>
#include <tofino/constants.p4>
#include <tofino/stateful_alu_blackbox.p4>

header_type ethernet_t {
    fields {
        dmac : 48;
        smac : 48;
        ethertype : 16;
    }
}
header ethernet_t ethernet;

header_type ipv4_t {
    fields {
        ver : 4;
        len : 4;
        diffserv : 8;
        totalLen : 16;
        id : 16;
        flags : 3;
        offset : 13;
        ttl : 8;
        proto : 8;
        csum : 16;
        sip : 32;
        dip : 32;
    }
}
header ipv4_t ipv4;

header_type tcp_t {
    fields {
        sPort : 16;
        dPort : 16;
        seqNo : 32;
        ackNo : 32;
        dataOffset : 4;
        res : 3;
        ecn : 3;
        ctrl : 6;
        window : 16;
        checksum : 16;
        urgentPtr : 16;
    }
}
header tcp_t tcp;

header_type udp_t {
    fields {
        sPort : 16;
        dPort : 16;
        hdr_length : 16;
        checksum : 16;
    }
}
header udp_t udp;

header_type user_metadata_t {
    fields {
		global_pkt_count: 32;
 		status_cycle: 2; // should only be 0,1,2,3
    }
}
metadata user_metadata_t md;

parser start {
    return parse_ethernet;
}

parser parse_ethernet {
    extract(ethernet);
    return select(latest.ethertype) {
        0x0800 : parse_ipv4;
    }
}
parser parse_ipv4 {
    extract(ipv4);
    return select(latest.proto) {
        6 : parse_tcp;
        17: parse_udp;
    }
}
parser parse_tcp {
    extract(tcp);
    return ingress;
}
parser parse_udp {
    extract(udp);
    return ingress;
}

register global_pkt_counter {
	width: 32;
	instance_count: 16;
}
blackbox stateful_alu global_pkt_count_incr {
	reg: global_pkt_counter;

	update_lo_1_predicate: 1;
	update_lo_1_value: register_lo + 1;

	output_value: alu_lo;
	output_dst: md.global_pkt_count;
}



action incr_global_counter(){
	global_pkt_count_incr.execute_stateful_alu(0);
}

table tb_incr_global_counter {
	actions {incr_global_counter;}
	default_action: incr_global_counter;
}

action maintain_2bit_variable(){
	shift_right(md.status_cycle, md.global_pkt_count, 0);
}
table tb_maintain_2bit_variable{
	actions {maintain_2bit_variable;}
	default_action: maintain_2bit_variable;
}

register dummy_reg_1 {
    width : 32;
    instance_count : 1;
}
blackbox stateful_alu cross_container_copy_1 {
	reg: 	dummy_reg_1;

	update_lo_1_predicate: 1;
	update_lo_1_value: md.status_cycle;

	output_dst: ipv4.sip;
	output_value: alu_lo;
}


action write_output(){
	modify_field(ipv4.dip, md.status_cycle);
	cross_container_copy_1.execute_stateful_alu(0);
}
table tb_write_output {
	actions {write_output;}
	default_action: write_output;
}

action bounce(){
	modify_field(ig_intr_md_for_tm.ucast_egress_port, ig_intr_md.ingress_port);
}
table tb_bounce{
	actions {bounce;}
	default_action: bounce;
}

control ingress{
	apply(tb_incr_global_counter);
	apply(tb_maintain_2bit_variable);
	apply(tb_write_output);

	apply(tb_bounce);
}

control egress {

}
