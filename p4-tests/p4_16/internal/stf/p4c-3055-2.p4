#include <core.p4>
#include <tna.p4>
header operation_h {
    bit<16> selection;
    bit<16> shift;
}

@pa_container_size("ingress", "hdr.shift_16_to_64.res", 16, 16, 16, 16)
header shift_16_to_64_h {
    bit<16> a;
    bit<16> b;
    bit<64> res;
}
@pa_container_size("ingress", "hdr.shift_32_to_64.res", 32, 32)
header shift_32_to_64_h {
    bit<32> a;
    bit<32> b;
    bit<64> res;
}
struct headers_t {
    operation_h operation;
    shift_16_to_64_h shift_16_to_64;
    shift_32_to_64_h shift_32_to_64;
}

struct metadata_t {
}

const bit<16> SEL_SHIFT_LEFT_16_64  = 16w0x1002;
const bit<16> SEL_SHIFT_LEFT_32_64  = 16w0x1003;

const bit<16> SEL_SHIFT_SRIGHT_16_64  = 16w0x2002;
const bit<16> SEL_SHIFT_SRIGHT_32_64  = 16w0x2003;

const bit<16> SEL_SHIFT_URIGHT_16_64  = 16w0x3002;
const bit<16> SEL_SHIFT_URIGHT_32_64  = 16w0x3003;

parser IgParser(packet_in packet,
                out headers_t hdr,
                out metadata_t meta,
                out ingress_intrinsic_metadata_t ig_intr_md) {
    state start {
        packet.extract(ig_intr_md);
        packet.advance(PORT_METADATA_SIZE);
	packet.extract(hdr.operation);
        transition select(hdr.operation.selection) {
	    0x0002 &&& 0x00FF: parse_16_64;
	    0x0003 &&& 0x00FF: parse_32_64;
            /* drop others for simplicity */
        }
    }
    state parse_16_64 {
	packet.extract(hdr.shift_16_to_64);
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
    action send_back() {
        ig_intr_tm_md.ucast_egress_port = ig_intr_md.ingress_port;
    }

    apply {
        // Only shift value of 4, 8, 10 supported.
	// Only shift value of 4, 20, 32, 40 supported.
	if(hdr.shift_16_to_64.isValid()) {
	    bit<64> tmp0 = 0;
	    if ((hdr.operation.selection & 0xFF00) == 0x1000) {
		tmp0[31:16] = hdr.shift_16_to_64.a;
	        tmp0[15:0] = hdr.shift_16_to_64.b;
	        if(hdr.operation.shift == 4) {
	            hdr.shift_16_to_64.res = tmp0 << 4;
	        } else if(hdr.operation.shift == 20) {
	            hdr.shift_16_to_64.res = tmp0 << 20;
	        } else if(hdr.operation.shift == 32) {
	            hdr.shift_16_to_64.res = tmp0 << 32;
	        } else if(hdr.operation.shift == 40) {
	            hdr.shift_16_to_64.res = tmp0 << 40;
	        }
	    } else if ((hdr.operation.selection & 0xFF00) == 0x2000) {
		tmp0[63:48] = hdr.shift_16_to_64.a;
	        tmp0[47:32] = hdr.shift_16_to_64.b;
	        if(hdr.operation.shift == 4) {
	            hdr.shift_16_to_64.res = tmp0 >> 4;
	        } else if(hdr.operation.shift == 20) {
	            hdr.shift_16_to_64.res = tmp0 >> 20;
	        } else if(hdr.operation.shift == 32) {
	            hdr.shift_16_to_64.res = tmp0 >> 32;
	        } else if(hdr.operation.shift == 40) {
	            hdr.shift_16_to_64.res = tmp0 >> 40;
	        }
	    } else if ((hdr.operation.selection & 0xFF00) == 0x3000) {
	        int<64> tmp1 = 0;
		tmp1[63:48] = hdr.shift_16_to_64.a;
	        tmp1[47:32] = hdr.shift_16_to_64.b;
	        if(hdr.operation.shift == 4) {
	            hdr.shift_16_to_64.res = (bit<64>)(tmp1 >> 4);
	        } else if(hdr.operation.shift == 20) {
	            hdr.shift_16_to_64.res = (bit<64>)(tmp1 >> 20);
	        } else if(hdr.operation.shift == 32) {
	            hdr.shift_16_to_64.res = (bit<64>)(tmp1 >> 32);
	        } else if(hdr.operation.shift == 40) {
	            hdr.shift_16_to_64.res = (bit<64>)(tmp1 >> 40);
	        }
	    }
	// Only shift value of 20, 32, 40 supported.
	} else if(hdr.shift_32_to_64.isValid()) {
	    bit<64> tmp0 = 0;
	    if ((hdr.operation.selection & 0xFF00) == 0x1000) {
		tmp0[63:32] = hdr.shift_32_to_64.a;
	        tmp0[31:0] = hdr.shift_32_to_64.b;
	        if(hdr.operation.shift == 20) {
	            hdr.shift_32_to_64.res = tmp0 << 20;
	        } else if(hdr.operation.shift == 32) {
	            hdr.shift_32_to_64.res = tmp0 << 32;
	        } else if(hdr.operation.shift == 40) {
	            hdr.shift_32_to_64.res = tmp0 << 40;
	        }
	    } else if ((hdr.operation.selection & 0xFF00) == 0x2000) {
		tmp0[63:32] = hdr.shift_32_to_64.a;
	        tmp0[31:0] = hdr.shift_32_to_64.b;
	        if(hdr.operation.shift == 20) {
	            hdr.shift_32_to_64.res = tmp0 >> 20;
	        } else if(hdr.operation.shift == 32) {
	            hdr.shift_32_to_64.res = tmp0 >> 32;
	        } else if(hdr.operation.shift == 40) {
	            hdr.shift_32_to_64.res = tmp0 >> 40;
	        }
	    } else if ((hdr.operation.selection & 0xFF00) == 0x3000) {
	        int<64> tmp1 = 0;
		tmp1[63:32] = hdr.shift_32_to_64.a;
	        tmp1[31:0] = hdr.shift_32_to_64.b;
	        if(hdr.operation.shift == 20) {
	            hdr.shift_32_to_64.res = (bit<64>)(tmp1 >> 20);
	        } else if(hdr.operation.shift == 32) {
	            hdr.shift_32_to_64.res = (bit<64>)(tmp1 >> 32);
	        } else if(hdr.operation.shift == 40) {
	            hdr.shift_32_to_64.res = (bit<64>)(tmp1 >> 40);
	        }
	    }
	}
        send_back();
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
