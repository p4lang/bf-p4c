/*!
 * @file inbound_l47.p4
 * @brief lookup table for queue range, queue offset and queue mask
 */
#if __TARGET_TOFINO__ == 2
#include <t2na.p4>
#else
#include <tna.p4>
#endif
#include "headers.p4"


control capture_filter( inout header_t hdr, 
                        in ingress_intrinsic_metadata_t ig_intr_md,
                        in ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md,
                        inout ingress_metadata_t meta, 
                        in bit<1> capture_match,
                        in bit<1> l23_match, in bit<1> l47_match
        ) {

  bit<8>  sa_match_no = 0;
  bit<8>  da_match_no = 0;
  bit<4>  partition_id;
  bit<20> mpls_label; 
  bit<1>  mpls_valid;
  bit<1>  vlan_valid;
  bit<16> vlan_label;
  bit<8>  mpls_match_no;
  bit<8>  vlan_match_no;
  bit<1>  v6_match;
  bit<96> v6_sa_top;
  bit<96> v6_da_top;
  bit<1>  v4_match;
  bit<32> source_ip;
  bit<32> destination_ip;
  bit<8>  ip_sa_match_no;
  bit<8>  ip_da_match_no;
  bit<16> src_port;
  bit<16> dst_port;
 
  bit<8> sport_match_no;
  bit<8> dport_match_no;
  //reserve 0 for non-match


/********************************/  
    action ethernet_da_match(bit<8> entry)
    {
        da_match_no = entry;
    }  

    table ethernet_da_tbl {
    key = {
        hdr.ethernet.dst_addr : ternary;
    }
    actions = {
        ethernet_da_match;
        NoAction;
    }
    default_action = NoAction;
    size = 32;
    }

/********************************/
    action ethernet_sa_match(bit<8> entry)
    {
        sa_match_no = entry;
    }  

    table ethernet_sa_tbl {
    key = {
        hdr.ethernet.src_addr : ternary;
    }
    actions = {
        ethernet_sa_match;
        NoAction;
    }
    default_action = NoAction;
    size = 32;
    }

/********************************/
    action mpls_match(bit<8> entry)
    {
        mpls_match_no = entry;
    } 

    action vlan_match(bit<8> entry)
    {
        vlan_match_no = entry;
    }  

    table vlan_mpls_tbl {
    key = {
        hdr.mpls_0.label  : ternary;
        hdr.vlan_tag_0.vlan_top  : exact;
        hdr.vlan_tag_0.vlan_bot  : range;
        hdr.vlan_tag_1.vlan_top  : exact;
        hdr.vlan_tag_1.vlan_bot  : range;
        hdr.mpls_0.isValid()     : exact;
        hdr.vlan_tag_0.isValid() : exact;
        hdr.vlan_tag_1.isValid() : exact;
    }
    actions = {
        vlan_match;
        mpls_match;
        NoAction;
    }
    default_action = NoAction;
    size = 32;
    }

/********************************/
    action ip_sa_match(bit<8> entry)
    {
        ip_sa_match_no = entry;
    }

    action ip_da_match(bit<8> entry)
    {
        ip_da_match_no = entry;
    }
    @atcam_partition_index("partition_id")
    @atcam_number_partitions(16)
    table ip_sa_tbl {
        key = {
            partition_id        : exact;
            meta.map_v4         : exact;
            meta.map_v6         : exact;
            meta.ip_src_31_0    : ternary;
            meta.ipv6_src_63_32 : exact;
            meta.ipv6_src_95_64 : exact;
            meta.ipv6_src_127_96: exact; 
        }
        actions = {
            ip_sa_match;
            NoAction;
        }
        default_action = NoAction;
        size = 32;
    }
    @atcam_partition_index("partition_id")
    @atcam_number_partitions(16)
    table ip_da_tbl {
        key = {
            partition_id        : exact;
            meta.map_v4         : exact;
            meta.map_v6         : exact;
            meta.ip_dst_31_0    : ternary;
            meta.ipv6_dst_63_32 : exact;
            meta.ipv6_dst_95_64 : exact;
            meta.ipv6_dst_127_96: exact; 
        }
        actions = {
            ip_da_match;
            NoAction;
        }
        default_action = NoAction;
        size = 32;
    }

    /********/
    action dport_match(bit<8> entry)
    {
        dport_match_no = entry;
    }
    
    action sport_match(bit<8> entry)
    {
        sport_match_no = entry;
    }
    
    table src_port_tbl {
        key = {
            meta.src_port  : range;
        }
        actions = {
            sport_match;
            NoAction;
        }
        default_action = NoAction;
        size = 32;
    }

    table dst_port_tbl {
        key = {
            meta.dst_port  : range;
        }
        actions = {
            dport_match;
            NoAction;
        }
        default_action = NoAction;
        size = 32;
    }

    action trigger_match()
    {
        meta.mirror.filter = 1w0;
        meta.mirror.trigger = 1w1;
        hdr.bridge.filter = 1w0;
        hdr.bridge.trigger = 1w1;
    }

    action trigger_and_filter_match()
    {
        meta.mirror.filter = 1w1;
        meta.mirror.trigger = 1w1;
        hdr.bridge.filter = 1w1;
        hdr.bridge.trigger = 1w1;
    }

    action filter_match()
    {
        meta.mirror.filter = 1w1;
        meta.mirror.trigger = 1w0;
        hdr.bridge.filter = 1w1;
        hdr.bridge.trigger = 1w0;
    }


    table capture_matchers_ingress_tbl {
        key = {
            sport_match_no  : exact;
            dport_match_no  : exact;
            ip_sa_match_no  : exact;
            ip_da_match_no  : exact;
            sa_match_no     : exact;
            da_match_no     : exact;
            mpls_match_no   : exact;
            vlan_match_no   : exact;
            l23_match       : exact;
            l47_match       : exact;
            ig_intr_md.ingress_port : exact;
        }
        actions = {
            trigger_match;
            trigger_and_filter_match;
            filter_match;
            NoAction;
        }
        default_action = NoAction;
        size = 512;
    }

    table capture_matchers_egress_tbl {
        key = {
            sport_match_no  : exact;
            dport_match_no  : exact;
            ip_sa_match_no  : exact;
            ip_da_match_no  : exact;
            sa_match_no     : exact;
            da_match_no     : exact;
            mpls_match_no   : exact;
            vlan_match_no   : exact;
            l23_match       : exact;
            l47_match       : exact;
            ig_intr_tm_md.ucast_egress_port : exact;
        }
        actions = {
            trigger_match;
            trigger_and_filter_match;
            filter_match;
            NoAction;
        }
        default_action = NoAction;
        size = 512;
    }
 
/******************************/
apply 
{
    ethernet_sa_tbl.apply();
    ethernet_da_tbl.apply();
    vlan_mpls_tbl.apply();
    ip_da_tbl.apply();
    ip_sa_tbl.apply();
    dst_port_tbl.apply();
    src_port_tbl.apply();
    if (capture_match == 1w1)
        capture_matchers_ingress_tbl.apply();
    else
        capture_matchers_egress_tbl.apply();
}

}




