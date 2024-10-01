#ifdef __TARGET_TOFINO__
#include <tofino/constants.p4>
#include <tofino/intrinsic_metadata.p4>
#include <tofino/primitives.p4>
#else
#include "includes/tofino.p4"
#endif

header_type ethernet_t {
    fields {
        dstAddr   : 48;
        srcAddr   : 48;
        ethertype : 16;
    }
}

header ethernet_t ethernet;

header_type vlan_tag_t {
    fields {
        pri       : 3;
        cfi       : 1;
        vid       : 12;
        ethertype : 16;
    }
}

header vlan_tag_t vlan_tag[2];

parser start {
    extract(ethernet);
    return select(latest.ethertype) {
        0x8100 : parse_vlan_tag;
        default : ingress;
    }
}

parser parse_vlan_tag {
    extract(vlan_tag[next]);
    return select(latest.ethertype) {
        0x8100 : parse_vlan_tag;
        default : ingress;
    }
}


header_type metadata_t {
    fields {
        new_outer_tpid    : 16;
        new_outer_pri     : 3;
        new_outer_cfi     : 1;
        new_outer_vid     : 12;

        new_inner_tpid    : 16;
        new_inner_pri     : 3;
        new_inner_cfi     : 1;
        new_inner_vid     : 12;

        new_outer_tpid_en : 1;
        new_outer_pri_en  : 1;
        new_outer_cfi_en  : 1;
        new_outer_vid_en  : 1;
        new_inner_tpid_en : 1;
        new_inner_pri_en  : 1;
        new_inner_cfi_en  : 1;
        new_inner_vid_en  : 1;
    }
}

metadata metadata_t meta;

action nop() {
}

/*
 * Independent fundamental actions 
 */
action do_new_outer_tpid() {
    modify_field(ethernet.ethertype, meta.new_outer_tpid);
}
table new_outer_tpid { actions {do_new_outer_tpid;} }

action do_new_outer_pri() {
    modify_field(vlan_tag[0].pri, meta.new_outer_pri);
}
table new_outer_pri { actions {do_new_outer_pri;} }

action do_new_outer_cfi() {
    modify_field(vlan_tag[0].cfi, meta.new_outer_cfi);
}
table new_outer_cfi { actions {do_new_outer_cfi;} }

action do_new_outer_vid() {
    modify_field(vlan_tag[0].vid, meta.new_outer_vid);
}
table new_outer_vid { actions {do_new_outer_vid;} }


action do_new_inner_tpid() {
    modify_field(vlan_tag[0].ethertype, meta.new_inner_tpid);
}
table new_inner_tpid { actions {do_new_inner_tpid;} }

action do_new_inner_pri() {
    modify_field(vlan_tag[1].pri, meta.new_inner_pri);
}
table new_inner_pri { actions {do_new_inner_pri;} }

action do_new_inner_cfi() {
    modify_field(vlan_tag[1].cfi, meta.new_inner_cfi);
}
table new_inner_cfi { actions {do_new_inner_cfi;} }

action do_new_inner_vid() {
    modify_field(vlan_tag[1].vid, meta.new_inner_vid);
}
table new_inner_vid { actions {do_new_inner_vid;} }

/*
 * Main Translation Table
 */
action rewrite_tags(
        new_outer_tpid, new_outer_tpid_en,
        new_outer_pri,  new_outer_pri_en,
        new_outer_cfi,  new_outer_cfi_en,
        new_outer_vid,  new_outer_vid_en,
        new_inner_tpid, new_inner_tpid_en,
        new_inner_pri,  new_inner_pri_en,
        new_inner_cfi,  new_inner_cfi_en,
        new_inner_vid,  new_inner_vid_en)
{
    modify_field(meta.new_outer_tpid,    new_outer_tpid);
    modify_field(meta.new_outer_tpid_en, new_outer_tpid_en);
    modify_field(meta.new_outer_pri,     new_outer_pri);
    modify_field(meta.new_outer_pri_en,  new_outer_pri_en);
    modify_field(meta.new_outer_cfi,     new_outer_cfi);
    modify_field(meta.new_outer_cfi_en,  new_outer_cfi_en);
    modify_field(meta.new_outer_vid,     new_outer_vid);
    modify_field(meta.new_outer_vid_en,  new_outer_vid_en);

    modify_field(meta.new_inner_tpid,    new_inner_tpid);
    modify_field(meta.new_inner_tpid_en, new_inner_tpid_en);
    modify_field(meta.new_inner_pri,     new_inner_pri);
    modify_field(meta.new_inner_pri_en,  new_inner_pri_en);
    modify_field(meta.new_inner_cfi,     new_inner_cfi);
    modify_field(meta.new_inner_cfi_en,  new_inner_cfi_en);
    modify_field(meta.new_inner_vid,     new_inner_vid);
    modify_field(meta.new_inner_vid_en,  new_inner_vid_en);
}

table vlan_xlate {
    reads {
        vlan_tag[0]                   : valid;
        vlan_tag[0].vid               : exact;
        vlan_tag[1]                   : valid;
        vlan_tag[1].vid               : exact;
    }
    actions {
        nop;
        rewrite_tags;
    }
}
control ingress {
    apply(vlan_xlate);

    if (meta.new_outer_tpid_en == 1) {
        apply(new_outer_tpid);
    }
    
    if (meta.new_outer_pri_en == 1) {
        apply(new_outer_pri);
    }

    if (meta.new_outer_cfi_en == 1) {
        apply(new_outer_cfi);
    }
          
    if (meta.new_outer_vid_en == 1) {
        apply(new_outer_vid);
    }

    if (meta.new_inner_tpid_en == 1) {
        apply(new_inner_tpid);
    }
    
    if (meta.new_inner_pri_en == 1) {
        apply(new_inner_pri);
    }
    
    if (meta.new_inner_cfi_en == 1) {
        apply(new_inner_cfi);
    }
    
    if (meta.new_inner_vid_en == 1) {
        apply(new_inner_vid);
    }

}


control egress {
}
