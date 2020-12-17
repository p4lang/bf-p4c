#include <core.p4>
#include <tna.p4>
header operation_h {
    bit<16> selection;
    bit<16> shift;
}

header shift_16_h {
    bit<16>  a;
    bit<16>  b;
    bit<16>  res;
}

header shift_32_to_64_h {
    bit<32>  a;
    bit<32>  b;
    bit<64>  res;
}
struct headers_t {
    operation_h operation;
    shift_16_h shift_16;
    shift_32_to_64_h shift_32_to_64;
}

struct metadata_t {
}

// RES = A ++ B << X
const bit<16> SEL_SHIFT_LEFT_16       = 16w0x1011;
// RES = A ++ B << X
const bit<16> SEL_SHIFT_LEFT_32_64    = 16w0x1021;
// RES = 0 ++ B << X
const bit<16> SEL_SHIFT_LEFT_32_64_0  = 16w0x1022;
// B = A ++ B >> X
const bit<16> SEL_SHIFT_RIGHT_16BAB   = 16w0x3011;
// B = B ++ A >> X
const bit<16> SEL_SHIFT_RIGHT_16BBA   = 16w0x3012;
// RES = A ++ B >> X
const bit<16> SEL_SHIFT_RIGHT_16RESAB = 16w0x3013;
// RES = A ++ B >> X
const bit<16> SEL_SHIFT_RIGHT_32_64   = 16w0x3021;
// RES = 0 ++ B >> X
const bit<16> SEL_SHIFT_RIGHT_32_64_0 = 16w0x3022;

parser IgParser(packet_in packet,
                out headers_t hdr,
                out metadata_t meta,
                out ingress_intrinsic_metadata_t ig_intr_md) {
    state start {
        packet.extract(ig_intr_md);
        packet.advance(PORT_METADATA_SIZE);
	packet.extract(hdr.operation);
        transition select(hdr.operation.selection) {
            0x0010 &&& 0x00F0: parse_16;
	    0x0024 &&& 0x00F0: parse_32_64;
            /* drop others for simplicity */
        }
    }
    state parse_16 {
	packet.extract(hdr.shift_16);
	transition accept;
    }
    state parse_32_64 {
	packet.extract(hdr.shift_32_to_64);
	transition accept;
    }
}

control Ingress(inout headers_t hdr,
                inout metadata_t meta,
                in ingress_intrinsic_metadata_t ig_intr_md,
                in ingress_intrinsic_metadata_from_parser_t ig_intr_prsr_md,
                inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprsr_md,
                inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md) {
    action send_back(PortId_t port) {
        ig_intr_tm_md.ucast_egress_port = port;
    }

    apply {
        PortId_t egress_port;
        // Only shift value of 4, 8, 10, 20 supported.
        if(hdr.shift_16.isValid()) {
	    if ((hdr.operation.selection & 0xFFFF) == 0x3011) {
	        if(hdr.operation.shift == 4) {
	            hdr.shift_16.b = (bit<16>)(hdr.shift_16.a ++ hdr.shift_16.b >> 4);
	        } else if(hdr.operation.shift == 10) {
	            hdr.shift_16.b = (bit<16>)(hdr.shift_16.a ++ hdr.shift_16.b >> 10);
	        } else if(hdr.operation.shift == 8) {
	            hdr.shift_16.b = (bit<16>)(hdr.shift_16.a ++ hdr.shift_16.b >> 8);
	        }
	    } else if ((hdr.operation.selection & 0xFFFF) == 0x3012) {
	        if(hdr.operation.shift == 4) {
	            hdr.shift_16.b = (bit<16>)(hdr.shift_16.b ++ hdr.shift_16.a >> 4);
	        } else if(hdr.operation.shift == 10) {
	            hdr.shift_16.b = (bit<16>)(hdr.shift_16.b ++ hdr.shift_16.a >> 10);
	        } else if(hdr.operation.shift == 8) {
	            hdr.shift_16.b = (bit<16>)(hdr.shift_16.b ++ hdr.shift_16.a >> 8);
	        }
	    } else if ((hdr.operation.selection & 0xFFFF) == 0x3013) {
	        if(hdr.operation.shift == 4) {
	            hdr.shift_16.res = (bit<16>)(hdr.shift_16.a ++ hdr.shift_16.b >> 4);
	        } else if(hdr.operation.shift == 10) {
	            hdr.shift_16.res = (bit<16>)(hdr.shift_16.a ++ hdr.shift_16.b >> 10);
	        } else if(hdr.operation.shift == 8) {
	            hdr.shift_16.res = (bit<16>)(hdr.shift_16.a ++ hdr.shift_16.b >> 8);
	        }
	    } else if ((hdr.operation.selection & 0xFFFF) == 0x1011) {
	        if(hdr.operation.shift == 4) {
	            hdr.shift_16.res = (bit<16>)(hdr.shift_16.a ++ hdr.shift_16.b << 4);
	        } else if(hdr.operation.shift == 10) {
	            hdr.shift_16.res = (bit<16>)(hdr.shift_16.a ++ hdr.shift_16.b << 10);
	        } else if(hdr.operation.shift == 8) {
	            hdr.shift_16.res = (bit<16>)(hdr.shift_16.a ++ hdr.shift_16.b << 8);
	        } else if(hdr.operation.shift == 20) {
	            hdr.shift_16.res = (bit<16>)(hdr.shift_16.a ++ hdr.shift_16.b << 20);
	        }
	    }
	} else if (hdr.shift_32_to_64.isValid()) {
	    if ((hdr.operation.selection & 0xFFFF) == 0x1021) {
	        if(hdr.operation.shift == 4) {
	            hdr.shift_32_to_64.res = hdr.shift_32_to_64.a ++ hdr.shift_32_to_64.b << 4;
	        } else if(hdr.operation.shift == 32) {
	            hdr.shift_32_to_64.res = hdr.shift_32_to_64.a ++ hdr.shift_32_to_64.b << 32;
	        } else if(hdr.operation.shift == 24) {
	            hdr.shift_32_to_64.res = hdr.shift_32_to_64.a ++ hdr.shift_32_to_64.b << 24;
	        } else if(hdr.operation.shift == 40) {
	            hdr.shift_32_to_64.res = hdr.shift_32_to_64.a ++ hdr.shift_32_to_64.b << 40;
	        }
	    } else if ((hdr.operation.selection & 0xFFFF) == 0x3021) {
	        if(hdr.operation.shift == 4) {
	            hdr.shift_32_to_64.res = hdr.shift_32_to_64.a ++ hdr.shift_32_to_64.b >> 4;
	        } else if(hdr.operation.shift == 32) {
	            hdr.shift_32_to_64.res = hdr.shift_32_to_64.a ++ hdr.shift_32_to_64.b >> 32;
	        } else if(hdr.operation.shift == 24) {
	            hdr.shift_32_to_64.res = hdr.shift_32_to_64.a ++ hdr.shift_32_to_64.b >> 24;
	        } else if(hdr.operation.shift == 40) {
	            hdr.shift_32_to_64.res = hdr.shift_32_to_64.a ++ hdr.shift_32_to_64.b >> 40;
	        }
	    } else if ((hdr.operation.selection & 0xFFFF) == 0x3022) {
	        if(hdr.operation.shift == 4) {
	            hdr.shift_32_to_64.res = (bit<64>)(hdr.shift_32_to_64.b >> 4);
	        } else if(hdr.operation.shift == 24) {
	            hdr.shift_32_to_64.res = (bit<64>)(hdr.shift_32_to_64.b >> 24);
	        }
	    } else if ((hdr.operation.selection & 0xFFFF) == 0x1022) {
	        if(hdr.operation.shift == 4) {
	            hdr.shift_32_to_64.res = (bit<64>)(hdr.shift_32_to_64.b << 4);
	        } else if(hdr.operation.shift == 32) {
	            hdr.shift_32_to_64.res = (bit<64>)(hdr.shift_32_to_64.b << 32);
	        } else if(hdr.operation.shift == 24) {
	            hdr.shift_32_to_64.res = (bit<64>)(hdr.shift_32_to_64.b << 24);
	        } else if(hdr.operation.shift == 40) {
	            hdr.shift_32_to_64.res = (bit<64>)(hdr.shift_32_to_64.b << 40);
	        }
	    }
	}
	egress_port = ig_intr_md.ingress_port;
        send_back(egress_port);
    }
}

control IgDeparser(packet_out packet,
                   inout headers_t hdr,
                   in metadata_t meta,
                   in ingress_intrinsic_metadata_for_deparser_t standard_metadata) {
    apply {
        packet.emit(hdr);
    }

}

parser EgParser(packet_in packet,
                out headers_t hdr,
                out metadata_t md,
                out egress_intrinsic_metadata_t eg_intr_md) {
    state start {
        packet.extract(eg_intr_md);
        packet.extract(hdr.operation);
        transition accept;
    }
}

control Egress(inout headers_t hdr,
               inout metadata_t md,
               in egress_intrinsic_metadata_t eg_intr_md,
               in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_parser,
               inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
               inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport) {
    apply {}
}

control EgDeparser(packet_out packet,
                   inout headers_t hdr,
                   in metadata_t md,
                   in egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr) {

    apply {
        packet.emit(hdr);
    }
}

Pipeline(IgParser(),
        Ingress(),
        IgDeparser(),
        EgParser(),
        Egress(),
        EgDeparser()) pipe0;

Switch(pipe0) main;
