//-----------------------------------------------------------------------------
// Network Service Header Parser
//-----------------------------------------------------------------------------

parser NshParser(packet_in pkt, inout npb_switch_header_t hdr) {

    bit<12> bytes_remaining;
    
    state start {
#ifdef NSH_ENABLE
        transition parse_nsh;
#else
        transition reject;
#endif
    }

    // ================================================================
	// Base
	// ================================================================
    //  0                   1 1 1 1 1 1 1 1 1 1 2 2 2 2 2 2 2 2 2 2 3 3 
    //  0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
    // +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    // |Ver|O|U|   TTL     |   Length  |U|U|U|U|MD Type| Next Protocol |
    // +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+

    // ================================================================
	// Service Path Header
	// ================================================================
    //  0                   1 1 1 1 1 1 1 1 1 1 2 2 2 2 2 2 2 2 2 2 3 3 
    //  0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
    // +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    // |          Service Path Identifier (SPI)        | Service Index |
    // +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+

    state parse_nsh {

        bytes_remaining = (
            (4 * (bit<12>)(pkt.lookahead<nsh_base_h>().len)) - 8);

        pkt.extract(hdr.nsh_base);
        pkt.extract(hdr.nsh_svc_path);

        transition select(hdr.nsh_base.md_type) {
            1: parse_nsh_md1;
            2: parse_nsh_md2_opaque;
            default: accept;
        }
    }



// Check next protocol field and trap non-ethernet (see Glenn's email)
// Add a parse_nsh_md2_EXTREME case where we extract a fixed (20B) header.
// Create two md2 parse states - one for blob/opaque extraction and one for TLV (walking).
//    only call the opaque one in our code.    
//  accept versus reject...?
//  copy the bare-bones implementation into the main parser (since sub-parsers are not supported)
    
    
    // ================================================================
	// MD Type 0x1
	// ================================================================
    //  0                   1 1 1 1 1 1 1 1 1 1 2 2 2 2 2 2 2 2 2 2 3 3 
    //  0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
    // +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    // |                                                               |
    // |                 Fixed-Length Context Header                   |
    // |                        (16 Bytes)                             |
    // |                                                               |
    // +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+    
    
    // RFC 8300 - An SF that does not know the format of the
    // MD-1 context header MUST discard the packet and MUST
    // log the event
    state parse_nsh_md1 {
        pkt.extract(hdr.nsh_md1_context);
        transition accept;
    }


    // ================================================================
	// MD Type 0x2
	// ================================================================
    //  0                   1 1 1 1 1 1 1 1 1 1 2 2 2 2 2 2 2 2 2 2 3 3 
    //  0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
    // +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    // |              Variable-Length Context Headers                  |
    // |                        (optional)                             |
    // +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+    

    // ================================================================
	// Variable Length Context Header
	// ================================================================
    //  0                   1 1 1 1 1 1 1 1 1 1 2 2 2 2 2 2 2 2 2 2 3 3 
    //  0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
    // +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    // |         Metadata Class        |     Type      |U|   Length    |
    // +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    // |                  Variable-Length Metadata                     |
    // +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+

    // Simplified version of type md2 that just processes the whole
    // thing as a single opaque header using total length from base hdr.
    state parse_nsh_md2_opaque {
		pkt.extract(hdr.nsh_md2_context_1, (bit<32>)(8 * bytes_remaining));
        transition accept;
    }

    // TLV version of type md2 that walks each variable length header,
    // and extract each one into their own (opaque) header.

    
    state parse_nsh_md2_tlv_1 {

        bit<11> varlen_bytes = (
            (bit<11>) (pkt.lookahead<nsh_md2_context_fixed_h>().len));

		pkt.extract(hdr.nsh_md2_context_1, (bit<32>) (8 * (4 + varlen_bytes)));
        pkt.advance((bit<32>)(varlen_bytes % 4));
        bytes_remaining = (bytes_remaining
                           - 4
                           - (bit<12>)varlen_bytes
                           - (bit<12>)varlen_bytes % 4);

        transition select(bytes_remaining != 0) {
            true : parse_nsh_md2_tlv_2;
            false: accept;
        }    
    }

    state parse_nsh_md2_tlv_2 {
        // bit<11> varlen_bytes = (
        //     (bit<11>) (pkt.lookahead<nsh_md2_context_fixed_h>().len));
        // 
		// pkt.extract(hdr.nsh_md2_context_2, (bit<32>) (8 * (4 + varlen_bytes)));
        // pkt.advance((bit<32>)(varlen_bytes % 4));
        // bytes_remaining = (bytes_remaining
        //                    - 4
        //                    - (bit<12>)varlen_bytes
        //                    - (bit<12>)varlen_bytes % 4);
        // 
        // transition select(bytes_remaining != 0) {
        //     true : parse_nsh_md2_tlv_3;
        //     false: accept;
        // }    
        transition reject;
    }

}



