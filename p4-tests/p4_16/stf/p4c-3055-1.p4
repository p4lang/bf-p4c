#include <core.p4>
#include <tna.p4>
header operation_h {
    bit<16> selection;
    bit<16> shift;
}

@pa_container_size("ingress", "hdr.shift_8_to_16.res", 8, 8)
header shift_8_to_16_h {
    bit<8>  a;
    bit<8>  b;
    bit<16> res;
}
// Let the compiler decide
header shift_32_to_128_h {
    bit<32>  a;
    bit<32>  b;
    bit<128> res;
}
struct headers_t {
    operation_h operation;
    shift_8_to_16_h shift_8_to_16;
    shift_32_to_128_h shift_32_to_128;
}

struct metadata_t {
}

const bit<16> SEL_SHIFT_LEFT_8_16   = 16w0x1001;
const bit<16> SEL_SHIFT_LEFT_32_128 = 16w0x1004;

const bit<16> SEL_SHIFT_SRIGHT_8_16   = 16w0x2001;
const bit<16> SEL_SHIFT_SRIGHT_32_128 = 16w0x2004;

const bit<16> SEL_SHIFT_URIGHT_8_16   = 16w0x3001;
const bit<16> SEL_SHIFT_URIGHT_32_128 = 16w0x3004;

parser IgParser(packet_in packet,
                out headers_t hdr,
                out metadata_t meta,
                out ingress_intrinsic_metadata_t ig_intr_md) {
    state start {
        packet.extract(ig_intr_md);
        packet.advance(PORT_METADATA_SIZE);
	packet.extract(hdr.operation);
        transition select(hdr.operation.selection) {
            0x0001 &&& 0x00FF: parse_8_16;
	    0x0004 &&& 0x00FF: parse_32_128;
            /* drop others for simplicity */
        }
    }
    state parse_8_16 {
	packet.extract(hdr.shift_8_to_16);
	transition accept;
    }
    state parse_32_128 {
	packet.extract(hdr.shift_32_to_128);
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
        // Only shift value of 4, 8, 10 supported.
        if(hdr.shift_8_to_16.isValid()) {
	    bit<16> tmp0 = 0;
	    tmp0[15:8] = hdr.shift_8_to_16.a;
	    tmp0[7:0] = hdr.shift_8_to_16.b;
	    if ((hdr.operation.selection & 0xFF00) == 0x1000) {
	        if(hdr.operation.shift == 4) {
	            hdr.shift_8_to_16.res = tmp0 << 4;
	        } else if(hdr.operation.shift == 10) {
	            hdr.shift_8_to_16.res = tmp0 << 10;
	        } else if(hdr.operation.shift == 8) {
	            hdr.shift_8_to_16.res = tmp0 << 8;
	        }
	    } else if ((hdr.operation.selection & 0xFF00) == 0x2000) {
	        if(hdr.operation.shift == 4) {
	            hdr.shift_8_to_16.res = tmp0 >> 4;
	        } else if(hdr.operation.shift == 10) {
	            hdr.shift_8_to_16.res = tmp0 >> 10;
	        } else if(hdr.operation.shift == 8) {
	            hdr.shift_8_to_16.res = tmp0 >> 8;
	        }
	    } else if ((hdr.operation.selection & 0xFF00) == 0x3000) {
	        int<16> tmp1 = 0;
		tmp1[15:8] = hdr.shift_8_to_16.a;
	        tmp1[7:0] = hdr.shift_8_to_16.b;
	        if(hdr.operation.shift == 4) {
	            hdr.shift_8_to_16.res = (bit<16>)(tmp1 >> 4);
	        } else if(hdr.operation.shift == 10) {
	            hdr.shift_8_to_16.res = (bit<16>)(tmp1 >> 10);
	        } else if(hdr.operation.shift == 8) {
	            hdr.shift_8_to_16.res = (bit<16>)(tmp1 >> 8);
	        }
	    }
	// Only shift value of 20, 32, 40, 80 supported.
	} else if(hdr.shift_32_to_128.isValid()) {
	    bit<128> tmp0 = 0;
	    if ((hdr.operation.selection & 0xFF00) == 0x1000) {
		tmp0[63:32] = hdr.shift_32_to_128.a;
	        tmp0[31:0] = hdr.shift_32_to_128.b;
	        if(hdr.operation.shift == 20) {
	            hdr.shift_32_to_128.res = tmp0 << 20;
	        } else if(hdr.operation.shift == 32) {
	            hdr.shift_32_to_128.res = tmp0 << 32;
	        } else if(hdr.operation.shift == 40) {
	            hdr.shift_32_to_128.res = tmp0 << 40;
	        } else if(hdr.operation.shift == 80) {
	            hdr.shift_32_to_128.res = tmp0 << 80;
	        }
	    } else if ((hdr.operation.selection & 0xFF00) == 0x2000) {
		tmp0[127:96] = hdr.shift_32_to_128.a;
	        tmp0[95:64] = hdr.shift_32_to_128.b;
	        if(hdr.operation.shift == 20) {
	            hdr.shift_32_to_128.res = tmp0 >> 20;
	        } else if(hdr.operation.shift == 32) {
	            hdr.shift_32_to_128.res = tmp0 >> 32;
	        } else if(hdr.operation.shift == 40) {
	            hdr.shift_32_to_128.res = tmp0 >> 40;
	        } else if(hdr.operation.shift == 80) {
	            hdr.shift_32_to_128.res = tmp0 >> 80;
	        }
	    } else if ((hdr.operation.selection & 0xFF00) == 0x3000) {
	        int<128> tmp1 = 0;
		tmp1[127:96] = hdr.shift_32_to_128.a;
	        tmp1[95:64] = hdr.shift_32_to_128.b;
	        if(hdr.operation.shift == 20) {
	            hdr.shift_32_to_128.res = (bit<128>)(tmp1 >> 20);
	        } else if(hdr.operation.shift == 32) {
	            hdr.shift_32_to_128.res = (bit<128>)(tmp1 >> 32);
	        } else if(hdr.operation.shift == 40) {
	            hdr.shift_32_to_128.res = (bit<128>)(tmp1 >> 40);
	        } else if(hdr.operation.shift == 80) {
	            hdr.shift_32_to_128.res = (bit<128>)(tmp1 >> 80);
	        }
	    }
	}
	egress_port = ig_intr_md.ingress_port;
	@pa_container_size("ingress", "shift_src8_0", 8, 8)
	bit<11> shift_src8 = 0;
	bit<11> shift_dst8 = 0;
	if(hdr.shift_8_to_16.isValid()) {
	    if(hdr.shift_8_to_16.res & 0xFF == 0x98) {
	        shift_src8 = 0x98;
	    } else if(hdr.shift_8_to_16.res & 0xFF == 0x76) {
	        shift_src8 = 0x76;
	    } else {
	        shift_src8 = 0;
	    }
	    shift_dst8 = shift_src8 << 4;
	}
	if(hdr.shift_8_to_16.isValid()) {
	    if(shift_dst8 == 0x180) {
	        egress_port = 1;
	    } else if(shift_dst8 == 0x760) {
	        egress_port = 2;
	    }
	}

	@pa_container_size("ingress", "shift_src32_0", 32)
	bit<15> shift_src32 = 0;
	bit<15> shift_dst32 = 0;
	if(hdr.shift_8_to_16.isValid()) {
	    if(hdr.shift_8_to_16.res & 0xFF == 0x54) {
	        shift_src32 = 0x543;
	    } else if(hdr.shift_8_to_16.res & 0xFF == 0x32) {
	        shift_src32 = 0x321;
	    } else {
	        shift_src32 = 0;
	    }
	    shift_dst32 = shift_src32 >> 4;
	}
	if(hdr.shift_8_to_16.isValid()) {
	    if(shift_dst32 == 0x54) {
	        egress_port = 3;
	    } else if(shift_dst32 == 0x32) {
	        egress_port = 4;
	    }
	}
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
