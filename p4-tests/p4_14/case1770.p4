// Copyright (c) 2016 Arista Networks, Inc.  All rights reserved.
// Arista Networks, Inc. Confidential and Proprietary.
// By accepting and/or using this Arista Software, Barefoot Networks,
// Inc., ("Barefoot") agrees to use this Arista Software for the sole
// purpose of debugging Barefoot's software products only. Barefoot
// further agrees not to reverse-engineer or de-obfuscate this Arista
// Software.

#include <tofino/intrinsic_metadata.p4>

header_type EthernetHdr {
   fields {
      dmac : 48;
      smac : 48;
      etherType  : 16;
   }
}

header_type VlanHdr {
   fields {
      priority  : 3;
      cfi       : 1;
      vlanId    : 12;
      etherType : 16;
   }
}

header_type Ipv4Hdr {
   fields {
      version    : 4;
      ihl        : 4;
      diffServ   : 8;
      totalLen   : 16;
      ident      : 16;
      flags      : 3;
      fragOffset : 13;
      ttl        : 8;
      protocol   : 8;
      hdrChksum  : 16;
      sip        : 32;
      dip        : 32;
   }
}

header_type H1 {
   fields {
      f1 : 14;
      f2 : 12;
   }
}

parser start {
   return parseEthernet;
}

#define ETHERTYPE_VLAN        0x8100
#define ETHERTYPE_IPV4        0x0800

header EthernetHdr ethHdr;
header VlanHdr vlanHdr;
header Ipv4Hdr ipv4Hdr;
metadata H1 h1;

parser parseEthernet {
   extract( ethHdr );
   return select( ethHdr.etherType ) {
      ETHERTYPE_VLAN : parseVlanHdr;
      ETHERTYPE_IPV4 : parseIpv4Hdr;
      default        : ingress;
   }
}

parser parseVlanHdr {
   extract( vlanHdr );
   return select( vlanHdr.etherType ) {
      ETHERTYPE_IPV4 : parseIpv4Hdr;
      default : ingress;
   }
}

parser parseIpv4Hdr {
   extract( ipv4Hdr );
   return select(latest.fragOffset, latest.ihl, latest.protocol) {
      default : ingress;
   }
}

action a(data) {
   modify_field(h1.f2, data);
}

@pragma atcam_partition_index h1.f1
@pragma atcam_number_partitions 16384
table t {
   reads {
      h1.f1 : exact;
      // works
      ethHdr.dmac mask 0xfffffff00000 : lpm;
      ethHdr.dmac mask 0x000000ffffff : lpm;

      // does not work
      //ethHdr.dmac mask 0x00000fffffff : lpm;
   }

   actions {
      a;
   }
   size : 131072;
}

action b() {
   modify_field(h1.f1, 1);
}

table f {
   actions {
      b;
   }
   size : 1;
}

action do_forward(port) {
    modify_field(ig_intr_md_for_tm.ucast_egress_port, port);
}

table forward {
    reads {
        h1.f2 : ternary;
    }
    actions {
        do_forward;
    }
}

control ingress {
   apply(f);
   apply(t);
   apply(forward);
}

