#ifdef __TARGET_TOFINO__
#include "tofino/constants.p4"
#include "tofino/intrinsic_metadata.p4"
#include "tofino/primitives.p4"
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

header vlan_tag_t vlan_tag;

parser start {
    extract(ethernet);
    return select(latest.ethertype) {
        0x8100 : parse_vlan_tag;
        default : ingress;
    }
}

parser parse_vlan_tag {
    extract(vlan_tag);
    return ingress;
}


header_type metadata_t {
    fields {
        new_tpid    : 16;
        new_pri     : 3;
        new_cfi     : 1;
        new_vid     : 12;

        new_tpid_en : 1;
        new_pri_en  : 1;
        new_cfi_en  : 1;
        new_vid_en  : 1;
    }
}

metadata metadata_t meta;

action nop() {
}

/*
 * Independent fundamental actions 
 */
action do_new_tpid() {
    modify_field(ethernet.ethertype, meta.new_tpid);
}
table new_tpid { actions {do_new_tpid;} }

action do_new_pri() {
    modify_field(vlan_tag.pri, meta.new_pri);
}
table new_pri { actions {do_new_pri;} }

action do_new_cfi() {
    modify_field(vlan_tag.cfi, meta.new_cfi);
}
table new_cfi { actions {do_new_cfi;} }

action do_new_vid() {
    modify_field(vlan_tag.vid, meta.new_vid);
}
table new_vid { actions {do_new_vid;} }


/*
 * Main Translation Table
 */
action rewrite_tag(new_tpid, new_tpid_en, 
                   new_pri,  new_pri_en,
                   new_cfi,  new_cfi_en,
                   new_vid,  new_vid_en)
{
    modify_field(meta.new_tpid,    new_tpid);
    modify_field(meta.new_tpid_en, new_tpid_en);
    modify_field(meta.new_pri,     new_pri);
    modify_field(meta.new_pri_en,  new_pri_en);
    modify_field(meta.new_cfi,     new_cfi);
    modify_field(meta.new_cfi_en,  new_cfi_en);
    modify_field(meta.new_vid,     new_vid);
    modify_field(meta.new_vid_en,  new_vid_en);
}

table vlan_xlate {
    reads {
        vlan_tag.vid  : exact;
    }
    actions {
        rewrite_tag;
    }
}

control ingress {
    apply(vlan_xlate) {
        rewrite_tag {
            if (meta.new_tpid_en == 1) {
                apply(new_tpid);
            }
            
            if (meta.new_pri_en == 1) {
                apply(new_pri);
            }
            
            if (meta.new_cfi_en == 1) {
                apply(new_cfi);
            }
            
            if (meta.new_vid_en == 1) {
                apply(new_vid);
            }
        }
    }
}


control egress {
}
