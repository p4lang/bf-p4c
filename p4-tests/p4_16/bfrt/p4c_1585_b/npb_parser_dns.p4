/* -*- P4_16 -*- */

// *****************************************************************************
// * PARSER - DNS **************************************************************
// *****************************************************************************

/* The DNS parser is a proof-of-concept design developed to help learn the
   capabilities of the P4-16 language. It does not support the full DNS
   protocol. An incomplete list of it's features and limitations is below:

   - Extractss the base header from all DNS messages.

   - Extracts the domain name (QNAME) from the question section of all
     DNS responses. Due to the lack of P4 support for stacks of headers
     that contain variable length bit-strings, there's a limitation
     on the number of labels that will be extracted (max=8).

   - Extracts the IPv4/6 address returned from a DNS Address (A/AAAA)
     query. It only extracts a single address (from the first answer
     in the response).

   - Assumes there will be no compression when extracting QNAME since
     it's the first name in message. Parser will handle (skipping over)
     compression fields (in the answer's name field) when trying to get
     at the IP address in the response.

   - Max domain name size is 255Bytes (or 2040 bits). This will fit in the
     Tofino's 4K PHV.

   Possible use case: Could the extracted IP Address and/or domain name be
   used as the key (hashed) into a local threat cache such that an alert
   can be triggered on a hit? 

*/

parser DnsParser(
	packet_in pkt,
    out dns_base_h                         dns_base,
    out dns_label_h                        dns_qname_label_1,
    out dns_label_h                        dns_qname_label_2,
    out dns_label_h                        dns_qname_label_3,
    out dns_label_h                        dns_qname_label_4,
    out dns_label_h                        dns_qname_label_5,
    out dns_label_h                        dns_qname_label_6,
    out dns_label_h                        dns_qname_label_7,
    out dns_label_h                        dns_qname_label_8,
    out dns_question_fixed_h               dns_question_fixed,
    out dns_label_h                        dns_answer_name_trash,
    out dns_answer_fixed_h                 dns_answer_fixed,
    out dns_answer_rdata_h                 dns_answer_rdata
)
{
	state start {
		transition parse_dns_base;
	}    

    // =============================
	// Base
	// =============================
    
    state parse_dns_base {
	    pkt.extract(dns_base);
        verify(dns_base.qdcount == 1, error.DnsQuestionCountNotOne);

	    transition select(dns_base.QR,
                          dns_base.opcode,
                          dns_base.rcode,
                          dns_base.ancount>0) {

            // only process non-errored, standard query responses
            // with answers. (qdcount should always be 1)
            (1, 0, 0, true): parse_dns_qname_label_1;
            default: accept;
        }
	}

    // =============================
	// Question Section
	// =============================
    
    state parse_dns_qname_label_1 {
        // length in extract represents just the varbit length (not the whole header)
		pkt.extract(dns_qname_label_1, (bit<32>) (8 * (bit<9>) (pkt.lookahead<dns_label_fixed_h>().len)));
        verify(dns_qname_label_1.compress == 0, error.DnsUnexpectedCompression);
        //verify(dns_qname_label_1.len == 0, error.DnsUnexpectedZeroLenLabel);
        transition parse_dns_qname_label_2;
    }
    state parse_dns_qname_label_2 {
		pkt.extract(dns_qname_label_2, (bit<32>) (8 * (bit<9>) (pkt.lookahead<dns_label_fixed_h>().len)));
        transition select(dns_qname_label_2.compress == 0, dns_qname_label_2.len == 0) {
            (false, _    ): accept;  // unsupported compression - should we move this to verify and reject?
            (true,  true ): parse_dns_question_fixed;
            (true,  false): parse_dns_qname_label_3;
        }
    }
    state parse_dns_qname_label_3 {
		pkt.extract(dns_qname_label_3, (bit<32>) (8 * (bit<9>) (pkt.lookahead<dns_label_fixed_h>().len)));
        transition select(dns_qname_label_3.compress == 0, dns_qname_label_3.len == 0) {
            (false, _    ): accept;  // unsupported compression - should we move this to verify and reject?
            (true,  true ): parse_dns_question_fixed;
            (true,  false): parse_dns_qname_label_4;
        }
    }
    state parse_dns_qname_label_4 {
		pkt.extract(dns_qname_label_4, (bit<32>) (8 * (bit<9>) (pkt.lookahead<dns_label_fixed_h>().len)));
        transition select(dns_qname_label_4.compress == 0, dns_qname_label_4.len == 0) {
            (false, _    ): accept;  // unsupported compression - should we move this to verify and reject?
            (true,  true ): parse_dns_question_fixed;
            (true,  false): parse_dns_qname_label_5;
        }
    }
    state parse_dns_qname_label_5 {
		pkt.extract(dns_qname_label_5, (bit<32>) (8 * (bit<9>) (pkt.lookahead<dns_label_fixed_h>().len)));
        transition select(dns_qname_label_5.compress == 0, dns_qname_label_5.len == 0) {
            (false, _    ): accept;  // unsupported compression - should we move this to verify and reject?
            (true,  true ): parse_dns_question_fixed;
            (true,  false): parse_dns_qname_label_6;
        }
    }
    state parse_dns_qname_label_6 {
		pkt.extract(dns_qname_label_6, (bit<32>) (8 * (bit<9>) (pkt.lookahead<dns_label_fixed_h>().len)));
        transition select(dns_qname_label_6.compress == 0, dns_qname_label_6.len == 0) {
            (false, _    ): accept;  // unsupported compression - should we move this to verify and reject?
            (true,  true ): parse_dns_question_fixed;
            (true,  false): parse_dns_qname_label_7;
        }
    }
    state parse_dns_qname_label_7 {
		pkt.extract(dns_qname_label_7, (bit<32>) (8 * (bit<9>) (pkt.lookahead<dns_label_fixed_h>().len)));
        transition select(dns_qname_label_7.compress == 0, dns_qname_label_7.len == 0) {
            (false, _    ): accept;  // unsupported compression - should we move this to verify and reject?
            (true,  true ): parse_dns_question_fixed;
            (true,  false): parse_dns_qname_label_8;
        }
    }
    state parse_dns_qname_label_8 {
		pkt.extract(dns_qname_label_8, (bit<32>) (8 * (bit<9>) (pkt.lookahead<dns_label_fixed_h>().len)));
        transition select(dns_qname_label_8.compress == 0, dns_qname_label_8.len == 0) {
            (false, _    ): accept;  // unsupported compression - should we move this to verify and reject?
            (true,  true ): parse_dns_question_fixed;
            (true,  false): accept;  // expand this out to support a max-sized name (255) or cap at X labels?
        }
    }

    state parse_dns_question_fixed {
	    pkt.extract(dns_question_fixed);
	    transition select(dns_base.ancount>0,
                          dns_question_fixed.qtype,
                          dns_question_fixed.qclass) {
            (true, 1,  1): parse_dns_answer_name; // v4 internet address query (A)
            (true, 28, 1): parse_dns_answer_name; // v6 internet address query (AAAA)
            default: accept;
        }
    }    


    // =============================
	// Answer Section
	// =============================

    // Was unable to test the compression handling below due to known scapy bug.
    // When reading in a pcap w/ compression, scapy appears to un-do the compression
    // (and populate the answer with full labels). 
    // From https://scapy.net
    // "DNS packets not reassembled exactly as the original (no compression used)"
    
    state parse_dns_answer_name {
        bit<9> varlen = (pkt.lookahead<dns_label_fixed_h>().compress == 0x3) ? 8
                         : (8 * (bit<9>) (pkt.lookahead<dns_label_fixed_h>().len));
		pkt.extract(dns_answer_name_trash, (bit<32>) varlen);
        transition select(dns_answer_name_trash.len == 0) { // compress ptr will be >0
            true : parse_dns_answer_fixed;
            false: parse_dns_answer_name;
        }
    }
    
    state parse_dns_answer_fixed {
	    pkt.extract(dns_answer_fixed);
	    transition select(dns_answer_fixed.type,
                          dns_answer_fixed.class) {
            (1,  1): parse_dns_answer_addr_v4; // v4 internet address query (A)
            (28, 1): parse_dns_answer_addr_v6; // v6 internet address query (AAAA)
            default: accept;
        }
	}       

    state parse_dns_answer_addr_v4 {
        verify(dns_answer_fixed.rdLength == 4, error.DnsAnswerAddrLenErrorV4);
	    pkt.extract(dns_answer_rdata, 32);
	    transition accept;
	}       

    state parse_dns_answer_addr_v6 {
        verify(dns_answer_fixed.rdLength == 16, error.DnsAnswerAddrLenErrorV6);
	    pkt.extract(dns_answer_rdata, 128);
	    transition accept;
	}       

}


