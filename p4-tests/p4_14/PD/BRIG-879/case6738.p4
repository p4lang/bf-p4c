#include <tofino/intrinsic_metadata.p4>
#include <tofino/constants.p4>
#include <tofino/primitives.p4>

header_type global_meta_t {
    fields {
    	padding: 8;
        len: 16;
    }
}
metadata global_meta_t global_meta;

header_type ethernet_t {
    fields {
        dstAddr : 48;
        srcAddr : 48;
        etherType : 16;
    }
}
header ethernet_t ethernet;
parser start {
    extract(ethernet);
    return select(latest.etherType) {
        0x8100, 0x88A8: parse_vlan;
        default: ingress;
    }
}

header_type vlan_tag_t {
    fields {
        pcp : 3;
        cfi : 1;
        vid : 12;
        etherType : 16;
    }
}
header vlan_tag_t vlan_tag[3];
parser parse_vlan {
    extract(vlan_tag[next]);
    return select(latest.etherType) {
        0x8100, 0x88A8 : parse_vlan;
        default : ingress;
    }
}


action set_output(port){
	modify_field(ig_intr_md_for_tm.ucast_egress_port, port);
}
table set_output{
	actions {
		set_output;
	}
}
control ingress
{
	apply(set_output);
}


action push_vlan(){
    push(vlan_tag, 1);
    modify_field(vlan_tag[0].vid, eg_intr_md.pkt_length);
    modify_field(global_meta.len, eg_intr_md.pkt_length);
    modify_field(vlan_tag[0].etherType, ethernet.etherType);
    modify_field(ethernet.etherType, 0x8100);    
}
table push_vlan{
	actions{
		push_vlan;
	}
}
control egress
{
    apply(push_vlan);
    if (eg_intr_md_from_parser_aux.clone_src == NOT_CLONED)
    {
        apply(clone);
    }
}

#define CASE_FIX
#ifdef CASE_FIX
field_list clone_list {
    global_meta.len;
}

action clone(clone_sess)
{        
    clone_e2e(clone_sess, clone_list);
}
#else
action clone(clone_sess)
{        
    clone_e2e(clone_sess);
}
#endif
table clone {
    actions {
        clone;
    }
}
