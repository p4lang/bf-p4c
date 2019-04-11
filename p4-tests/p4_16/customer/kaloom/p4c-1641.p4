#include <tna.p4>

header ethernet_t {
    bit<48> dstAddr;
    bit<48> srcAddr;
    bit<16> etherType;
}

header ipv4_t {
    bit<4>  version;
    bit<4>  ihl;
    bit<8>  diffserv;
    bit<16> totalLen;
    bit<16> identification;
    bit<3>  flags;
    bit<13> fragOffset;
    bit<8>  ttl;
    bit<8>  protocol;
    bit<16> hdrChecksum;
    bit<32> srcAddr;
    bit<32> dstAddr;
}

header packet_out_h {
    bit<48> srcAddr;
    bit<48> dstAddr;
    bit<16> etherType;
}

struct headers_t {
    ethernet_t ethernet;
    ipv4_t     ipv4;
}

struct user_metadata_t {
    bit<9> cpu_port;
    bit<3> ring_id;
}

parser IgParser(packet_in pkt, out headers_t hdr, out user_metadata_t md, out ingress_intrinsic_metadata_t ig_intr_md) {
    state start {
	pkt.extract(ig_intr_md);
	pkt.advance(64);
        transition parse_ethernet;
    }

    state parse_ethernet {
        pkt.extract(hdr.ethernet);
        transition select(hdr.ethernet.etherType) {
	    16w5 : parse_jeju;
	}
    }

    state parse_jeju {
	pkt.extract(hdr.ipv4);
	transition accept;
    }
}

control CPUPort(out PortId_t cpu_port_id, out bit<3> ring_id) {
    const bit<32> ring_id_counter_instance_count = 1;
    Register<bit<8>, bit<1>>(ring_id_counter_instance_count, 0) ring_id_counter;
    RegisterAction<bit<8>, bit<1>, bit<3>>(ring_id_counter) generate_ring_id = {
        void apply(inout bit<8> val, out bit<3> rv) {
            if (val < 7) {
                val = val + 1;
            } else {
                val = 0;
            }
            rv = (bit<3>)val;
        }
    };

    action get_cpu_port_(PortId_t port_id, bit<1> index) {
        cpu_port_id = port_id;
        ring_id = generate_ring_id.execute(index);
    }

    table cpu_port {
        key = {}
        actions = {
            get_cpu_port_;
        }

        const default_action = get_cpu_port_(0, 0);
        size = 1;
    }

    apply {
        cpu_port.apply();
    }
}

control SwitchIngress(inout headers_t hdr, inout user_metadata_t md, in ingress_intrinsic_metadata_t ig_intr_md, in ingress_intrinsic_metadata_from_parser_t ig_intr_md_from_prsr, inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprsr_md, inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md) {
    CPUPort() cpu_port;
    action nop() {
    }
    table t {
        actions = { nop; }
        key = {
	    hdr.ethernet.srcAddr : ternary;
	    hdr.ipv4.identification: range;
	}
        size = 512;
    }
    apply {
	cpu_port.apply(md.cpu_port, md.ring_id);
        t.apply();
    }
}

control SwitchIngressDeparser(packet_out pkt, inout headers_t hdr, in user_metadata_t meta, in ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr) {
    apply {
        pkt.emit(hdr);
    }
}

parser EgParser(packet_in pkt, out headers_t hdr, out user_metadata_t md, out egress_intrinsic_metadata_t ig_intr_md) {
  state start {
    pkt.extract(hdr.ethernet);
    transition accept;
  }
}

control SwitchEgress(inout headers_t hdr, inout user_metadata_t md, in egress_intrinsic_metadata_t eg_intr_md, in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_parser, inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr, inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport) {
    apply {}
}

control SwitchEgressDeparser(packet_out pkt, inout headers_t hdr, in user_metadata_t md, in egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr) {
    apply {
        pkt.emit(hdr);
    }
}

Pipeline(IgParser(), SwitchIngress(), SwitchIngressDeparser(),
         EgParser(), SwitchEgress(), SwitchEgressDeparser()) pipe0;

Switch(pipe0) main;
