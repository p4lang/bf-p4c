header_type ethernet_t {
    fields {
        dstAddr : 48;
        srcAddr : 48;
        etherType : 16;
    }
}

header_type ipv4_t {
    fields {
        version : 4;
        ihl : 4;
        diffserv : 8;
        totalLen : 16;
        identification : 16;
        flags : 3;
        fragOffset : 13;
        ttl : 8;
        protocol : 8;
        hdrChecksum : 16;
        srcAddr : 32;
        dstAddr: 32;
    }
}

//@pragma pa_solitary ingress ing_md.vrf
//@pragma pa_fragment ingress vlan_tag_.vid
//@pragma pa_atomic ingress ing_md.partition_index

header_type ing_md_t {
   fields {
      fib_result : 16;

      field1 : 1;
      field4 : 1;
      field2 : 14;

      field3 : 12;
      barHit : 1;
      partition_index : 11;
      vrf : 12;
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

header ethernet_t ethernet;
header ipv4_t ipv4;
header vlan_tag_t vlan_tag_;
metadata ing_md_t ing_md;

parser start {
    return parse_ethernet;
}

parser parse_ethernet {
    extract(ethernet);
    return select(latest.etherType) {
        0x0800: parse_ipv4;
        0x8100: parse_vlan;
    }
}

parser parse_ipv4 {
    extract(ipv4);
    return select(latest.fragOffset, latest.ihl, latest.protocol) {
        default: ingress;
    }
}


parser parse_vlan {
    extract(vlan_tag_);
        return select(latest.etherType) {
                0x0800: parse_ipv4;
    }
}


action set_partition_index(index) {
   modify_field(ing_md.partition_index, index);
}

table partition {
   reads {
      ing_md.vrf : exact;  
      ipv4.dstAddr mask 0xFFFFFF00 : lpm ;
   }
   actions {
      set_partition_index;
   }
   size : 1024;
}

action setBar () {
    modify_field( ing_md.barHit, 1);
}

table bar1 {
    reads {
    ing_md.field1 : exact;
    ing_md.field2 : ternary;
    vlan_tag_.vid : ternary;
    //ing_md.field3 : ternary; // If you use this instead, it somehow uses correct number of tcams
    ing_md.field4 : exact;
    }
    actions {
      setBar;
   }
   size : 4096;
}

action set_fib_result(res) {
   modify_field( ing_md.fib_result, res);
}

@pragma atcam_partition_index ing_md.partition_index
@pragma ways 5
table fib {
   reads {
      ing_md.partition_index : exact;
      ing_md.vrf : exact;
      ipv4.dstAddr : lpm ;
   }
   actions {
      set_fib_result;
   }
   size : 16384;
}

control ingress {
   apply(partition);
   apply(bar1);
   apply(fib);
}

control egress {
}
