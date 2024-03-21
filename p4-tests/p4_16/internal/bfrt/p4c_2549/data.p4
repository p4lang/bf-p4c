/*******************************************************************************
 the data file
 include struct definition
 
 ******************************************************************************/

#ifndef _DATA_
#define _DATA_


//type define
typedef bit<24> nsh_spi_t;
typedef bit<8> nsh_si_t;


/* port list
0, 1, 2, 3, 4, 5, 6, 7, 8, 64
*/


//config define
#define DEFAULT_FORWARD_PORT 0//transparent forward
#define EXCEPTION_REPORT_PORT 64//exception packet forward

#define IPV4_FORWARD_TABLE_SIZE 1024//table size
#define IPV6_FORWARD_TABLE_SIZE 1024
#define NSH_FORWARD_TABLE_SIZE 1024
#define PORT_MAC_TAHBLE_SIZE 128

#define DEFAULT_MAC_ADDR 48w0x001122334455//default mac


//used header
struct header_t {
	//outer header
	ethernet_h outer_ethernet;//only valid when exist nsh header
	nsh_base_h nsh_base;
	nsh_type1_context_h nsh_type1_context;
	
	//ethernet_h debug;//debug

	//regular header
    ethernet_h ethernet;//when parse the nsh header, the ehternet move to outer_ethernet
    vlan_tag_h vlan_tag;
    ipv6_h ipv6;
    ipv4_h ipv4;
    tcp_h tcp;
    udp_h udp;

    // Add more headers here.
}

//used data
struct ingress_metadata_t {
    bool checksum_err;//ipv4 checksum error
	bool nsh_form_err;//nsh header form err 
	bool nsh_ttl_err;//nsh ttl change to zero
	bool bAddNsh;//add nsh header flag, and add outer_ethernet
	bool bChangeNsh;//change nsh header flag
	bool bRemoveNsh;//remove nsh flag, and remove ethernet
}

struct egress_metadata_t {

}







#endif /* _DATA */
