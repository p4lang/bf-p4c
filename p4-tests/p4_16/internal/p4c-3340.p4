/* -*- P4_16 -*- */
#include <core.p4>
#include <tna.p4>       /* TOFINO1_ONLY */

#ifdef USE_STAGE
#define STAGE(n) @stage(n)
#else
#define STAGE(n)
#endif

/*************************************************************************
 ************* C O N S T A N T S    A N D   T Y P E S  *******************
*************************************************************************/

#define NUM_EGRESS_PORTS    512
#define NUM_CLUSTERS        4

/*************************************************************************
 ***********************  H E A D E R S  *********************************
 *************************************************************************/

header ethernet_h {
    bit<48> dst_addr;
    bit<48> src_addr;
    bit<16> ether_type;
}

header ipv4_h {
    bit<4>  version;
    bit<4>  ihl;
    bit<8>  diffserv;
    bit<16> len;
    bit<16> id;
    bit<3>  flags;
    bit<13> frag_offset;
    bit<8>  ttl;
    bit<8>  proto;
    bit<16> hdr_checksum;
    bit<32> src_addr;
    bit<32> dst_addr;
}

header transport_h {
    bit<16> src_port;
    bit<16> dst_port;
}

header resubmit_h {
    bit<16> cluster_id;
}

/*************************************************************************
 **************  I N G R E S S   P R O C E S S I N G   *******************
 *************************************************************************/

/* All the headers we plan to process in the ingress */
struct my_ingress_headers_t {
    ethernet_h ethernet;
    ipv4_h ipv4;
    transport_h  transport;
}

/* All intermediate results that need to be available 
 * to all P4-programmable components in ingress
 */
struct my_ingress_metadata_t { // We will have to initialize them

    // Clustering
    bit<16> cluster_id;

    /* Cluster 1 */
    bit<16> cluster1_len_distance;  
    bit<16> cluster1_ttl_distance;
    bit<16> cluster1_proto_distance;
    bit<16> cluster1_id_distance;

    /* Cluster 2 */
    bit<16> cluster2_len_distance;  
    bit<16> cluster2_ttl_distance;
    bit<16> cluster2_proto_distance;
    bit<16> cluster2_id_distance;

    /* Cluster 3 */
    bit<16> cluster3_len_distance;  
    bit<16> cluster3_ttl_distance;
    bit<16> cluster3_proto_distance;
    bit<16> cluster3_id_distance;

    /* Cluster 4 */
    bit<16> cluster4_len_distance;  
    bit<16> cluster4_ttl_distance;
    bit<16> cluster4_proto_distance;
    bit<16> cluster4_id_distance;

    // Distance helpers
    bit<16> min_d1_d2;
    bit<16> min_d3_d4;
    bit<16> min_d1_d2_d3_d4;
}

parser MyIngressParser(packet_in      pkt,
    out my_ingress_headers_t          hdr, 
    out my_ingress_metadata_t         meta, 
    out ingress_intrinsic_metadata_t  ig_intr_md) {

    state start {
        
        /* Mandatory code required by Tofino Architecture */
        pkt.extract(ig_intr_md);

        /* Metadata initialization */
        meta.cluster_id = 0;

        /* Cluster 1 */
        meta.cluster1_len_distance = 0;
        meta.cluster1_ttl_distance = 0;
        meta.cluster1_proto_distance = 0;
        meta.cluster1_id_distance = 0;

        /* Cluster 2 */
        meta.cluster2_len_distance = 0;
        meta.cluster2_ttl_distance = 0;
        meta.cluster2_proto_distance = 0;
        meta.cluster2_id_distance = 0;

        /* Cluster 3 */
        meta.cluster3_len_distance = 0;
        meta.cluster3_ttl_distance = 0;
        meta.cluster3_proto_distance = 0;
        meta.cluster3_id_distance = 0;

        /* Cluster 4 */
        meta.cluster4_len_distance = 0;
        meta.cluster4_ttl_distance = 0;
        meta.cluster4_proto_distance = 0;
        meta.cluster4_id_distance = 0;

        // Distance helpers
        meta.min_d1_d2 = 0;
        meta.min_d3_d4 = 0;
        meta.min_d1_d2_d3_d4 = 0;

        /* Parser start point */
        transition select(ig_intr_md.resubmit_flag) {
            0: parse_port_metadata;
            1: parse_resubmit;
        }
    }

    state parse_port_metadata {
        /* Mandatory code required by Tofino Architecture */
        pkt.advance(PORT_METADATA_SIZE);
        transition parse_ethernet;
    }

    state parse_resubmit {
        resubmit_h rh;
        pkt.extract(rh); // Extracted 16 bits into metadata
        meta.cluster_id = rh.cluster_id;
        pkt.advance(PORT_METADATA_SIZE - 16); // 16 is size of esubmit header
        transition parse_ethernet;
    }

    state parse_ethernet {
        pkt.extract(hdr.ethernet);
        transition select(hdr.ethernet.ether_type) {
            0x0800:  parse_ipv4;
            default: accept;
        }
    }

    /* We only parse layer 4 if the packet is a first fragment (frag_offset == 0) and if ipv4 header contains no options (ihl == 5) */
    state parse_ipv4 {
        pkt.extract(hdr.ipv4);
        transition select(hdr.ipv4.frag_offset, hdr.ipv4.proto, hdr.ipv4.ihl) {
            (0, 6, 5)  : parse_transport;
            (0, 17, 5) : parse_transport;
            default : accept;
        }
    }

    state parse_transport {
        pkt.extract(hdr.transport);
        transition accept;
    }
}

control MyIngress(
    inout my_ingress_headers_t                       hdr,
    inout my_ingress_metadata_t                      meta,
    in    ingress_intrinsic_metadata_t               ig_intr_md,
    in    ingress_intrinsic_metadata_from_parser_t   ig_prsr_md,
    inout ingress_intrinsic_metadata_for_deparser_t  ig_dprsr_md,
    inout ingress_intrinsic_metadata_for_tm_t        ig_tm_md) {   

    /* Define variables, actions and tables here */
    action send(PortId_t port) {
        ig_tm_md.ucast_egress_port = port;
    }

    /* The ingress deparser will drop this packet,
       so it will not even go to the traffic manager */
    action drop() {
        ig_dprsr_md.drop_ctl = 1;
    }
    
#if 0
    table ipv4_host {
        key = {
            hdr.ipv4.dst_addr : exact;
        }
        actions = {
            send;
            drop;
        }
        default_action = drop;
        size = 131072; // Number of entries = 128k
    }

    table ipv4_lpm {
        key = {
            hdr.ipv4.dst_addr : lpm;
        }
        actions = {
            send;
            drop;
        }
        default_action = send(64); // On Tofino, port 64 is often connected
                                   // to the CPU. If we have a miss, we send
                                   // the packet to the CPU.
        size = 12288;
    }
#endif
    
    action set_qid(QueueId_t qid) {
        ig_tm_md.qid = qid;
    }

    table cluster_to_prio {
        key = {
            meta.cluster_id : exact;
        }
        actions = {
            set_qid;
        }
        default_action = set_qid(0); // Lowest-priority queue.
        size = NUM_CLUSTERS;
    }

    /****/
    /**** Clustering control registers */
    /****/

    /* Cluster 1 */
    /* IP len (bit<16>)*/
    Register<bit<16>, PortId_t>(NUM_EGRESS_PORTS) cluster1_len_min;
    RegisterAction<bit<16>, PortId_t, bit<16>>(cluster1_len_min) 
    distance_cluster1_len_min = {
        void apply(inout bit<16> data, out bit<16> distance) {
            distance = 0;
            if (hdr.ipv4.len < data) {
                distance = data - hdr.ipv4.len;
            }
        }
    };
    RegisterAction<bit<16>, PortId_t, bit<16>>(cluster1_len_min) 
    update_cluster1_len_min = {
        void apply(inout bit<16> data) {
            if (meta.cluster_id == 1) {
                if (hdr.ipv4.len < data) {
                    data = hdr.ipv4.len;
                }
            }
        }
    };

    Register<bit<16>, PortId_t>(NUM_EGRESS_PORTS) cluster1_len_max;
    RegisterAction<bit<16>, PortId_t, bit<16>>(cluster1_len_max) 
    distance_cluster1_len_max = {
        void apply(inout bit<16> data, out bit<16> distance) {
            distance = 0;
            if (hdr.ipv4.len > data) {
                distance = hdr.ipv4.len - data;
            }
        }
    };
    RegisterAction<bit<16>, PortId_t, bit<16>>(cluster1_len_max) 
    update_cluster1_len_max = {
        void apply(inout bit<16> data) {
            if (meta.cluster_id == 1) {
                if (hdr.ipv4.len > data) {
                    data = hdr.ipv4.len;
                }
            }
        }
    };

    /* IP ttl (bit<8>)*/
    Register<bit<16>, PortId_t>(NUM_EGRESS_PORTS) cluster1_ttl_min;
    RegisterAction<bit<16>, PortId_t, bit<16>>(cluster1_ttl_min) 
    distance_cluster1_ttl_min = {
        void apply(inout bit<16> data, out bit<16> distance) {
            distance = 0;
            if ((bit<16>)hdr.ipv4.ttl < data) {
                distance = data - (bit<16>)hdr.ipv4.ttl;
            }
        }
    };
    RegisterAction<bit<16>, PortId_t, bit<16>>(cluster1_ttl_min) 
    update_cluster1_ttl_min = {
        void apply(inout bit<16> data) {
            if (meta.cluster_id == 1) {
                if ((bit<16>)hdr.ipv4.ttl < data) {
                    data = (bit<16>)hdr.ipv4.ttl;
                }
            }
        }
    };

    Register<bit<16>, PortId_t>(NUM_EGRESS_PORTS) cluster1_ttl_max;
    RegisterAction<bit<16>, PortId_t, bit<16>>(cluster1_ttl_max) 
    distance_cluster1_ttl_max = {
        void apply(inout bit<16> data, out bit<16> distance) {
            distance = 0;
            if ((bit<16>)hdr.ipv4.ttl > data) {
                distance = (bit<16>)hdr.ipv4.ttl - data;
            }
        }
    };
    RegisterAction<bit<16>, PortId_t, bit<16>>(cluster1_ttl_max) 
    update_cluster1_ttl_max = {
        void apply(inout bit<16> data) {
            if (meta.cluster_id == 1) {
                if ((bit<16>)hdr.ipv4.ttl > data) {
                    data = (bit<16>)hdr.ipv4.ttl;
                }
            }
        }
    };

    /* IP proto (bit<8>)*/
    Register<bit<16>, PortId_t>(NUM_EGRESS_PORTS) cluster1_proto_min;
    RegisterAction<bit<16>, PortId_t, bit<16>>(cluster1_proto_min) 
    distance_cluster1_proto_min = {
        void apply(inout bit<16> data, out bit<16> distance) {
            distance = 0;
            if ((bit<16>)hdr.ipv4.proto < data) {
                distance = data - (bit<16>)hdr.ipv4.proto;
            }
        }
    };
    RegisterAction<bit<16>, PortId_t, bit<16>>(cluster1_proto_min) 
    update_cluster1_proto_min = {
        void apply(inout bit<16> data) {
            if (meta.cluster_id == 1) {
                if ((bit<16>)hdr.ipv4.proto < data) {
                    data = (bit<16>)hdr.ipv4.proto;
                }
            }
        }
    };

    Register<bit<16>, PortId_t>(NUM_EGRESS_PORTS) cluster1_proto_max;
    RegisterAction<bit<16>, PortId_t, bit<16>>(cluster1_proto_max) 
    distance_cluster1_proto_max = {
        void apply(inout bit<16> data, out bit<16> distance) {
            distance = 0;
            if ((bit<16>)hdr.ipv4.proto > data) {
                distance = (bit<16>)hdr.ipv4.proto - data;
            }
        }
    };
    RegisterAction<bit<16>, PortId_t, bit<16>>(cluster1_proto_max) 
    update_cluster1_proto_max = {
        void apply(inout bit<16> data) {
            if (meta.cluster_id == 1) {
                if ((bit<16>)hdr.ipv4.proto > data) {
                    data = (bit<16>)hdr.ipv4.proto;
                }
            }
        }
    };

    /* IP id (bit<16>)*/
    Register<bit<16>, PortId_t>(NUM_EGRESS_PORTS) cluster1_id_min;
    RegisterAction<bit<16>, PortId_t, bit<16>>(cluster1_id_min) 
    distance_cluster1_id_min = {
        void apply(inout bit<16> data, out bit<16> distance) {
            distance = 0;
            if (hdr.ipv4.id < data) {
                distance = data - hdr.ipv4.id;
            }
        }
    };
    RegisterAction<bit<16>, PortId_t, bit<16>>(cluster1_id_min) 
    update_cluster1_id_min = {
        void apply(inout bit<16> data) {
            if (meta.cluster_id == 1) {
                if (hdr.ipv4.id < data) {
                    data = hdr.ipv4.id;
                }
            }
        }
    };

    Register<bit<16>, PortId_t>(NUM_EGRESS_PORTS) cluster1_id_max;
    RegisterAction<bit<16>, PortId_t, bit<16>>(cluster1_id_max) 
    distance_cluster1_id_max = {
        void apply(inout bit<16> data, out bit<16> distance) {
            distance = 0;
            if (hdr.ipv4.id > data) {
                distance = hdr.ipv4.id - data;
            }
        }
    };
    RegisterAction<bit<16>, PortId_t, bit<16>>(cluster1_id_max) 
    update_cluster1_id_max = {
        void apply(inout bit<16> data) {
            if (meta.cluster_id == 1) {
                if (hdr.ipv4.id > data) {
                    data = hdr.ipv4.id;
                }
            }
        }
    };

    /* Cluster 2 */
    /* IP len (bit<16>)*/
    Register<bit<16>, PortId_t>(NUM_EGRESS_PORTS) cluster2_len_min;
    RegisterAction<bit<16>, PortId_t, bit<16>>(cluster2_len_min) 
    distance_cluster2_len_min = {
        void apply(inout bit<16> data, out bit<16> distance) {
            distance = 0;
            if (hdr.ipv4.len < data) {
                distance = data - hdr.ipv4.len;
            }
        }
    };
    RegisterAction<bit<16>, PortId_t, bit<16>>(cluster2_len_min) 
    update_cluster2_len_min = {
        void apply(inout bit<16> data) {
            if (meta.cluster_id == 2) {
                if (hdr.ipv4.len < data) {
                    data = hdr.ipv4.len;
                }
            }
        }
    };

    Register<bit<16>, PortId_t>(NUM_EGRESS_PORTS) cluster2_len_max;
    RegisterAction<bit<16>, PortId_t, bit<16>>(cluster2_len_max) 
    distance_cluster2_len_max = {
        void apply(inout bit<16> data, out bit<16> distance) {
            distance = 0;
            if (hdr.ipv4.len > data) {
                distance = hdr.ipv4.len - data;
            }
        }
    };
    RegisterAction<bit<16>, PortId_t, bit<16>>(cluster2_len_max) 
    update_cluster2_len_max = {
        void apply(inout bit<16> data) {
            if (meta.cluster_id == 2) {
                if (hdr.ipv4.len > data) {
                    data = hdr.ipv4.len;
                }
            }
        }
    };

    /* IP ttl (bit<8>)*/
    Register<bit<16>, PortId_t>(NUM_EGRESS_PORTS) cluster2_ttl_min;
    RegisterAction<bit<16>, PortId_t, bit<16>>(cluster2_ttl_min) 
    distance_cluster2_ttl_min = {
        void apply(inout bit<16> data, out bit<16> distance) {
            distance = 0;
            if ((bit<16>)hdr.ipv4.ttl < data) {
                distance = data - (bit<16>)hdr.ipv4.ttl;
            }
        }
    };
    RegisterAction<bit<16>, PortId_t, bit<16>>(cluster2_ttl_min) 
    update_cluster2_ttl_min = {
        void apply(inout bit<16> data) {
            if (meta.cluster_id == 2) {
                if ((bit<16>)hdr.ipv4.ttl < data) {
                    data = (bit<16>)hdr.ipv4.ttl;
                }
            }
        }
    };

    Register<bit<16>, PortId_t>(NUM_EGRESS_PORTS) cluster2_ttl_max;
    RegisterAction<bit<16>, PortId_t, bit<16>>(cluster2_ttl_max) 
    distance_cluster2_ttl_max = {
        void apply(inout bit<16> data, out bit<16> distance) {
            distance = 0;
            if ((bit<16>)hdr.ipv4.ttl > data) {
                distance = (bit<16>)hdr.ipv4.ttl - data;
            }
        }
    };
    RegisterAction<bit<16>, PortId_t, bit<16>>(cluster2_ttl_max) 
    update_cluster2_ttl_max = {
        void apply(inout bit<16> data) {
            if (meta.cluster_id == 2) {
                if ((bit<16>)hdr.ipv4.ttl > data) {
                    data = (bit<16>)hdr.ipv4.ttl;
                }
            }
        }
    };

    /* IP proto (bit<8>)*/
    Register<bit<16>, PortId_t>(NUM_EGRESS_PORTS) cluster2_proto_min;
    RegisterAction<bit<16>, PortId_t, bit<16>>(cluster2_proto_min) 
    distance_cluster2_proto_min = {
        void apply(inout bit<16> data, out bit<16> distance) {
            distance = 0;
            if ((bit<16>)hdr.ipv4.proto < data) {
                distance = data - (bit<16>)hdr.ipv4.proto;
            }
        }
    };
    RegisterAction<bit<16>, PortId_t, bit<16>>(cluster2_proto_min) 
    update_cluster2_proto_min = {
        void apply(inout bit<16> data) {
            if (meta.cluster_id == 2) {
                if ((bit<16>)hdr.ipv4.proto < data) {
                    data = (bit<16>)hdr.ipv4.proto;
                }
            }
        }
    };

    Register<bit<16>, PortId_t>(NUM_EGRESS_PORTS) cluster2_proto_max;
    RegisterAction<bit<16>, PortId_t, bit<16>>(cluster2_proto_max) 
    distance_cluster2_proto_max = {
        void apply(inout bit<16> data, out bit<16> distance) {
            distance = 0;
            if ((bit<16>)hdr.ipv4.proto > data) {
                distance = (bit<16>)hdr.ipv4.proto - data;
            }
        }
    };
    RegisterAction<bit<16>, PortId_t, bit<16>>(cluster2_proto_max) 
    update_cluster2_proto_max = {
        void apply(inout bit<16> data) {
            if (meta.cluster_id == 2) {
                if ((bit<16>)hdr.ipv4.proto > data) {
                    data = (bit<16>)hdr.ipv4.proto;
                }
            }
        }
    };

    /* IP id (bit<16>)*/
    Register<bit<16>, PortId_t>(NUM_EGRESS_PORTS) cluster2_id_min;
    RegisterAction<bit<16>, PortId_t, bit<16>>(cluster2_id_min) 
    distance_cluster2_id_min = {
        void apply(inout bit<16> data, out bit<16> distance) {
            distance = 0;
            if (hdr.ipv4.id < data) {
                distance = data - hdr.ipv4.id;
            }
        }
    };
    RegisterAction<bit<16>, PortId_t, bit<16>>(cluster2_id_min) 
    update_cluster2_id_min = {
        void apply(inout bit<16> data) {
            if (meta.cluster_id == 2) {
                if (hdr.ipv4.id < data) {
                    data = hdr.ipv4.id;
                }
            }
        }
    };

    Register<bit<16>, PortId_t>(NUM_EGRESS_PORTS) cluster2_id_max;
    RegisterAction<bit<16>, PortId_t, bit<16>>(cluster2_id_max) 
    distance_cluster2_id_max = {
        void apply(inout bit<16> data, out bit<16> distance) {
            distance = 0;
            if (hdr.ipv4.id > data) {
                distance = hdr.ipv4.id - data;
            }
        }
    };
    RegisterAction<bit<16>, PortId_t, bit<16>>(cluster2_id_max) 
    update_cluster2_id_max = {
        void apply(inout bit<16> data) {
            if (meta.cluster_id == 2) {
                if (hdr.ipv4.id > data) {
                    data = hdr.ipv4.id;
                }
            }
        }
    };

    /* Cluster 3 */
    /* IP len (bit<16>)*/
    Register<bit<16>, PortId_t>(NUM_EGRESS_PORTS) cluster3_len_min;
    RegisterAction<bit<16>, PortId_t, bit<16>>(cluster3_len_min) 
    distance_cluster3_len_min = {
        void apply(inout bit<16> data, out bit<16> distance) {
            distance = 0;
            if (hdr.ipv4.len < data) {
                distance = data - hdr.ipv4.len;
            }
        }
    };
    RegisterAction<bit<16>, PortId_t, bit<16>>(cluster3_len_min) 
    update_cluster3_len_min = {
        void apply(inout bit<16> data) {
            if (meta.cluster_id == 3) {
                if (hdr.ipv4.len < data) {
                    data = hdr.ipv4.len;
                }
            }
        }
    };

    Register<bit<16>, PortId_t>(NUM_EGRESS_PORTS) cluster3_len_max;
    RegisterAction<bit<16>, PortId_t, bit<16>>(cluster3_len_max) 
    distance_cluster3_len_max = {
        void apply(inout bit<16> data, out bit<16> distance) {
            distance = 0;
            if (hdr.ipv4.len > data) {
                distance = hdr.ipv4.len - data;
            }
        }
    };
    RegisterAction<bit<16>, PortId_t, bit<16>>(cluster3_len_max) 
    update_cluster3_len_max = {
        void apply(inout bit<16> data) {
            if (meta.cluster_id == 3) {
                if (hdr.ipv4.len > data) {
                    data = hdr.ipv4.len;
                }
            }
        }
    };

    /* IP ttl (bit<8>)*/
    Register<bit<16>, PortId_t>(NUM_EGRESS_PORTS) cluster3_ttl_min;
    RegisterAction<bit<16>, PortId_t, bit<16>>(cluster3_ttl_min) 
    distance_cluster3_ttl_min = {
        void apply(inout bit<16> data, out bit<16> distance) {
            distance = 0;
            if ((bit<16>)hdr.ipv4.ttl < data) {
                distance = data - (bit<16>)hdr.ipv4.ttl;
            }
        }
    };
    RegisterAction<bit<16>, PortId_t, bit<16>>(cluster3_ttl_min) 
    update_cluster3_ttl_min = {
        void apply(inout bit<16> data) {
            if (meta.cluster_id == 3) {
                if ((bit<16>)hdr.ipv4.ttl < data) {
                    data = (bit<16>)hdr.ipv4.ttl;
                }
            }
        }
    };

    Register<bit<16>, PortId_t>(NUM_EGRESS_PORTS) cluster3_ttl_max;
    RegisterAction<bit<16>, PortId_t, bit<16>>(cluster3_ttl_max) 
    distance_cluster3_ttl_max = {
        void apply(inout bit<16> data, out bit<16> distance) {
            distance = 0;
            if ((bit<16>)hdr.ipv4.ttl > data) {
                distance = (bit<16>)hdr.ipv4.ttl - data;
            }
        }
    };
    RegisterAction<bit<16>, PortId_t, bit<16>>(cluster3_ttl_max) 
    update_cluster3_ttl_max = {
        void apply(inout bit<16> data) {
            if (meta.cluster_id == 3) {
                if ((bit<16>)hdr.ipv4.ttl > data) {
                    data = (bit<16>)hdr.ipv4.ttl;
                }
            }
        }
    };

    /* IP proto (bit<8>)*/
    Register<bit<16>, PortId_t>(NUM_EGRESS_PORTS) cluster3_proto_min;
    RegisterAction<bit<16>, PortId_t, bit<16>>(cluster3_proto_min) 
    distance_cluster3_proto_min = {
        void apply(inout bit<16> data, out bit<16> distance) {
            distance = 0;
            if ((bit<16>)hdr.ipv4.proto < data) {
                distance = data - (bit<16>)hdr.ipv4.proto;
            }
        }
    };
    RegisterAction<bit<16>, PortId_t, bit<16>>(cluster3_proto_min) 
    update_cluster3_proto_min = {
        void apply(inout bit<16> data) {
            if (meta.cluster_id == 3) {
                if ((bit<16>)hdr.ipv4.proto < data) {
                    data = (bit<16>)hdr.ipv4.proto;
                }
            }
        }
    };

    Register<bit<16>, PortId_t>(NUM_EGRESS_PORTS) cluster3_proto_max;
    RegisterAction<bit<16>, PortId_t, bit<16>>(cluster3_proto_max) 
    distance_cluster3_proto_max = {
        void apply(inout bit<16> data, out bit<16> distance) {
            distance = 0;
            if ((bit<16>)hdr.ipv4.proto > data) {
                distance = (bit<16>)hdr.ipv4.proto - data;
            }
        }
    };
    RegisterAction<bit<16>, PortId_t, bit<16>>(cluster3_proto_max) 
    update_cluster3_proto_max = {
        void apply(inout bit<16> data) {
            if (meta.cluster_id == 3) {
                if ((bit<16>)hdr.ipv4.proto > data) {
                    data = (bit<16>)hdr.ipv4.proto;
                }
            }
        }
    };

    /* IP id (bit<16>)*/
    Register<bit<16>, PortId_t>(NUM_EGRESS_PORTS) cluster3_id_min;
    RegisterAction<bit<16>, PortId_t, bit<16>>(cluster3_id_min) 
    distance_cluster3_id_min = {
        void apply(inout bit<16> data, out bit<16> distance) {
            distance = 0;
            if (hdr.ipv4.id < data) {
                distance = data - hdr.ipv4.id;
            }
        }
    };
    RegisterAction<bit<16>, PortId_t, bit<16>>(cluster3_id_min) 
    update_cluster3_id_min = {
        void apply(inout bit<16> data) {
            if (meta.cluster_id == 3) {
                if (hdr.ipv4.id < data) {
                    data = hdr.ipv4.id;
                }
            }
        }
    };

    Register<bit<16>, PortId_t>(NUM_EGRESS_PORTS) cluster3_id_max;
    RegisterAction<bit<16>, PortId_t, bit<16>>(cluster3_id_max) 
    distance_cluster3_id_max = {
        void apply(inout bit<16> data, out bit<16> distance) {
            distance = 0;
            if (hdr.ipv4.id > data) {
                distance = hdr.ipv4.id - data;
            }
        }
    };
    RegisterAction<bit<16>, PortId_t, bit<16>>(cluster3_id_max) 
    update_cluster3_id_max = {
        void apply(inout bit<16> data) {
            if (meta.cluster_id == 3) {
                if (hdr.ipv4.id > data) {
                    data = hdr.ipv4.id;
                }
            }
        }
    };

    /* Cluster 4 */
    /* IP len (bit<16>)*/
    Register<bit<16>, PortId_t>(NUM_EGRESS_PORTS) cluster4_len_min;
    RegisterAction<bit<16>, PortId_t, bit<16>>(cluster4_len_min) 
    distance_cluster4_len_min = {
        void apply(inout bit<16> data, out bit<16> distance) {
            distance = 0;
            if (hdr.ipv4.len < data) {
                distance = data - hdr.ipv4.len;
            }
        }
    };
    RegisterAction<bit<16>, PortId_t, bit<16>>(cluster4_len_min) 
    update_cluster4_len_min = {
        void apply(inout bit<16> data) {
            if (meta.cluster_id == 4) {
                if (hdr.ipv4.len < data) {
                    data = hdr.ipv4.len;
                }
            }
        }
    };

    Register<bit<16>, PortId_t>(NUM_EGRESS_PORTS) cluster4_len_max;
    RegisterAction<bit<16>, PortId_t, bit<16>>(cluster4_len_max) 
    distance_cluster4_len_max = {
        void apply(inout bit<16> data, out bit<16> distance) {
            distance = 0;
            if (hdr.ipv4.len > data) {
                distance = hdr.ipv4.len - data;
            }
        }
    };
    RegisterAction<bit<16>, PortId_t, bit<16>>(cluster4_len_max) 
    update_cluster4_len_max = {
        void apply(inout bit<16> data) {
            if (meta.cluster_id == 4) {
                if (hdr.ipv4.len > data) {
                    data = hdr.ipv4.len;
                }
            }
        }
    };

    /* IP ttl (bit<8>)*/
    Register<bit<16>, PortId_t>(NUM_EGRESS_PORTS) cluster4_ttl_min;
    RegisterAction<bit<16>, PortId_t, bit<16>>(cluster4_ttl_min) 
    distance_cluster4_ttl_min = {
        void apply(inout bit<16> data, out bit<16> distance) {
            distance = 0;
            if ((bit<16>)hdr.ipv4.ttl < data) {
                distance = data - (bit<16>)hdr.ipv4.ttl;
            }
        }
    };
    RegisterAction<bit<16>, PortId_t, bit<16>>(cluster4_ttl_min) 
    update_cluster4_ttl_min = {
        void apply(inout bit<16> data) {
            if (meta.cluster_id == 4) {
                if ((bit<16>)hdr.ipv4.ttl < data) {
                    data = (bit<16>)hdr.ipv4.ttl;
                }
            }
        }
    };

    Register<bit<16>, PortId_t>(NUM_EGRESS_PORTS) cluster4_ttl_max;
    RegisterAction<bit<16>, PortId_t, bit<16>>(cluster4_ttl_max) 
    distance_cluster4_ttl_max = {
        void apply(inout bit<16> data, out bit<16> distance) {
            distance = 0;
            if ((bit<16>)hdr.ipv4.ttl > data) {
                distance = (bit<16>)hdr.ipv4.ttl - data;
            }
        }
    };
    RegisterAction<bit<16>, PortId_t, bit<16>>(cluster4_ttl_max) 
    update_cluster4_ttl_max = {
        void apply(inout bit<16> data) {
            if (meta.cluster_id == 4) {
                if ((bit<16>)hdr.ipv4.ttl > data) {
                    data = (bit<16>)hdr.ipv4.ttl;
                }
            }
        }
    };

    /* IP proto (bit<8>)*/
    Register<bit<16>, PortId_t>(NUM_EGRESS_PORTS) cluster4_proto_min;
    RegisterAction<bit<16>, PortId_t, bit<16>>(cluster4_proto_min) 
    distance_cluster4_proto_min = {
        void apply(inout bit<16> data, out bit<16> distance) {
            distance = 0;
            if ((bit<16>)hdr.ipv4.proto < data) {
                distance = data - (bit<16>)hdr.ipv4.proto;
            }
        }
    };
    RegisterAction<bit<16>, PortId_t, bit<16>>(cluster4_proto_min) 
    update_cluster4_proto_min = {
        void apply(inout bit<16> data) {
            if (meta.cluster_id == 4) {
                if ((bit<16>)hdr.ipv4.proto < data) {
                    data = (bit<16>)hdr.ipv4.proto;
                }
            }
        }
    };

    Register<bit<16>, PortId_t>(NUM_EGRESS_PORTS) cluster4_proto_max;
    RegisterAction<bit<16>, PortId_t, bit<16>>(cluster4_proto_max) 
    distance_cluster4_proto_max = {
        void apply(inout bit<16> data, out bit<16> distance) {
            distance = 0;
            if ((bit<16>)hdr.ipv4.proto > data) {
                distance = (bit<16>)hdr.ipv4.proto - data;
            }
        }
    };
    RegisterAction<bit<16>, PortId_t, bit<16>>(cluster4_proto_max) 
    update_cluster4_proto_max = {
        void apply(inout bit<16> data) {
            if (meta.cluster_id == 4) {
                if ((bit<16>)hdr.ipv4.proto > data) {
                    data = (bit<16>)hdr.ipv4.proto;
                }
            }
        }
    };

    /* IP id (bit<16>)*/
    Register<bit<16>, PortId_t>(NUM_EGRESS_PORTS) cluster4_id_min;
    RegisterAction<bit<16>, PortId_t, bit<16>>(cluster4_id_min) 
    distance_cluster4_id_min = {
        void apply(inout bit<16> data, out bit<16> distance) {
            distance = 0;
            if (hdr.ipv4.id < data) {
                distance = data - hdr.ipv4.id;
            }
        }
    };
    RegisterAction<bit<16>, PortId_t, bit<16>>(cluster4_id_min) 
    update_cluster4_id_min = {
        void apply(inout bit<16> data) {
            if (meta.cluster_id == 4) {
                if (hdr.ipv4.id < data) {
                    data = hdr.ipv4.id;
                }
            }
        }
    };

    Register<bit<16>, PortId_t>(NUM_EGRESS_PORTS) cluster4_id_max;
    RegisterAction<bit<16>, PortId_t, bit<16>>(cluster4_id_max) 
    distance_cluster4_id_max = {
        void apply(inout bit<16> data, out bit<16> distance) {
            distance = 0;
            if (hdr.ipv4.id > data) {
                distance = hdr.ipv4.id - data;
            }
        }
    };
    RegisterAction<bit<16>, PortId_t, bit<16>>(cluster4_id_max) 
    update_cluster4_id_max = {
        void apply(inout bit<16> data) {
            if (meta.cluster_id == 4) {
                if (hdr.ipv4.id > data) {
                    data = hdr.ipv4.id;
                }
            }
        }
    };

    /****/
    /**** Actions to compute distances */
    /****/

    /* Cluster 1 */
    action compute_distance_cluster1_len_min() {
        meta.cluster1_len_distance   = distance_cluster1_len_min.execute(ig_tm_md.ucast_egress_port);
    }
    action compute_distance_cluster1_len_max() {
        meta.cluster1_len_distance   = distance_cluster1_len_max.execute(ig_tm_md.ucast_egress_port);
    }
    action compute_distance_cluster1_ttl_min() {
        meta.cluster1_ttl_distance   = distance_cluster1_ttl_min.execute(ig_tm_md.ucast_egress_port);
    }
    action compute_distance_cluster1_ttl_max() {
        meta.cluster1_ttl_distance   = distance_cluster1_ttl_max.execute(ig_tm_md.ucast_egress_port);
    }

    action compute_distance_cluster1_proto_min() {
        meta.cluster1_proto_distance   = distance_cluster1_proto_min.execute(ig_tm_md.ucast_egress_port);
    }
    action compute_distance_cluster1_proto_max() {
        meta.cluster1_proto_distance   = distance_cluster1_proto_max.execute(ig_tm_md.ucast_egress_port);
    }

    action compute_distance_cluster1_id_min() {
        meta.cluster1_id_distance   = distance_cluster1_id_min.execute(ig_tm_md.ucast_egress_port);
    }
    action compute_distance_cluster1_id_max() {
        meta.cluster1_id_distance   = distance_cluster1_id_max.execute(ig_tm_md.ucast_egress_port);
    }

    /* Cluster 2 */
    action compute_distance_cluster2_len_min() {
        meta.cluster2_len_distance   = distance_cluster2_len_min.execute(ig_tm_md.ucast_egress_port);
    }
    action compute_distance_cluster2_len_max() {
        meta.cluster2_len_distance   = distance_cluster2_len_max.execute(ig_tm_md.ucast_egress_port);
    }

    action compute_distance_cluster2_ttl_min() {
        meta.cluster2_ttl_distance   = distance_cluster2_ttl_min.execute(ig_tm_md.ucast_egress_port);
    }
    action compute_distance_cluster2_ttl_max() {
        meta.cluster2_ttl_distance   = distance_cluster2_ttl_max.execute(ig_tm_md.ucast_egress_port);
    }

    action compute_distance_cluster2_proto_min() {
        meta.cluster2_proto_distance   = distance_cluster2_proto_min.execute(ig_tm_md.ucast_egress_port);
    }
    action compute_distance_cluster2_proto_max() {
        meta.cluster2_proto_distance   = distance_cluster2_proto_max.execute(ig_tm_md.ucast_egress_port);
    }

    action compute_distance_cluster2_id_min() {
        meta.cluster2_id_distance   = distance_cluster2_id_min.execute(ig_tm_md.ucast_egress_port);
    }
    action compute_distance_cluster2_id_max() {
        meta.cluster2_id_distance   = distance_cluster2_id_max.execute(ig_tm_md.ucast_egress_port);
    }

    /* Cluster 3 */
    action compute_distance_cluster3_len_min() {
        meta.cluster3_len_distance   = distance_cluster3_len_min.execute(ig_tm_md.ucast_egress_port);
    }
    action compute_distance_cluster3_len_max() {
        meta.cluster3_len_distance   = distance_cluster3_len_max.execute(ig_tm_md.ucast_egress_port);
    }

    action compute_distance_cluster3_ttl_min() {
        meta.cluster3_ttl_distance   = distance_cluster3_ttl_min.execute(ig_tm_md.ucast_egress_port);
    }
    action compute_distance_cluster3_ttl_max() {
        meta.cluster3_ttl_distance   = distance_cluster3_ttl_max.execute(ig_tm_md.ucast_egress_port);
    }

    action compute_distance_cluster3_proto_min() {
        meta.cluster3_proto_distance   = distance_cluster3_proto_min.execute(ig_tm_md.ucast_egress_port);
    }
    action compute_distance_cluster3_proto_max() {
        meta.cluster3_proto_distance   = distance_cluster3_proto_max.execute(ig_tm_md.ucast_egress_port);
    }

    action compute_distance_cluster3_id_min() {
        meta.cluster3_id_distance   = distance_cluster3_id_min.execute(ig_tm_md.ucast_egress_port);
    }
    action compute_distance_cluster3_id_max() {
        meta.cluster3_id_distance   = distance_cluster3_id_max.execute(ig_tm_md.ucast_egress_port);
    }

    /* Cluster 4 */
    action compute_distance_cluster4_len_min() {
        meta.cluster4_len_distance   = distance_cluster4_len_min.execute(ig_tm_md.ucast_egress_port);
    }
    action compute_distance_cluster4_len_max() {
        meta.cluster4_len_distance   = distance_cluster4_len_max.execute(ig_tm_md.ucast_egress_port);
    }

    action compute_distance_cluster4_ttl_min() {
        meta.cluster4_ttl_distance   = distance_cluster4_ttl_min.execute(ig_tm_md.ucast_egress_port);
    }
    action compute_distance_cluster4_ttl_max() {
        meta.cluster4_ttl_distance   = distance_cluster4_ttl_max.execute(ig_tm_md.ucast_egress_port);
    }

    action compute_distance_cluster4_proto_min() {
        meta.cluster4_proto_distance   = distance_cluster4_proto_min.execute(ig_tm_md.ucast_egress_port);
    }
    action compute_distance_cluster4_proto_max() {
        meta.cluster4_proto_distance   = distance_cluster4_proto_max.execute(ig_tm_md.ucast_egress_port);
    }

    action compute_distance_cluster4_id_min() {
        meta.cluster4_id_distance   = distance_cluster4_id_min.execute(ig_tm_md.ucast_egress_port);
    }
    action compute_distance_cluster4_id_max() {
        meta.cluster4_id_distance   = distance_cluster4_id_max.execute(ig_tm_md.ucast_egress_port);
    }

    /****/
    /**** Actions to merge distances and compute min distance */
    /****/
    action merge_ttl_to_len() {
        meta.cluster1_len_distance = meta.cluster1_len_distance + meta.cluster1_ttl_distance;
        meta.cluster2_len_distance = meta.cluster2_len_distance + meta.cluster2_ttl_distance;
        meta.cluster3_len_distance = meta.cluster3_len_distance + meta.cluster3_ttl_distance;
        meta.cluster4_len_distance = meta.cluster4_len_distance + meta.cluster4_ttl_distance;
    }
    action merge_id_to_len() {
        meta.cluster1_len_distance = meta.cluster1_len_distance + meta.cluster1_id_distance;
        meta.cluster2_len_distance = meta.cluster2_len_distance + meta.cluster2_id_distance;
        meta.cluster3_len_distance = meta.cluster3_len_distance + meta.cluster3_id_distance;
        meta.cluster4_len_distance = meta.cluster4_len_distance + meta.cluster4_id_distance;
    }

    action merge_proto_to_len() {
        meta.cluster1_len_distance = meta.cluster1_len_distance + meta.cluster1_proto_distance;
        meta.cluster2_len_distance = meta.cluster2_len_distance + meta.cluster2_proto_distance;
        meta.cluster3_len_distance = meta.cluster3_len_distance + meta.cluster3_proto_distance;
        meta.cluster4_len_distance = meta.cluster4_len_distance + meta.cluster4_proto_distance;
    }

    action compute_min_first() {
        meta.min_d1_d2 = min(meta.cluster1_len_distance, meta.cluster2_len_distance);
        meta.min_d3_d4 = min(meta.cluster3_len_distance, meta.cluster4_len_distance);
    }

    action compute_min_second() {
        meta.min_d1_d2_d3_d4 = min(meta.min_d1_d2, meta.min_d3_d4);
    }

    /****/
    /**** Actions to update ranges */
    /****/

    /* Cluster 1 */
    action do_update_distance_cluster1_len_min() {
        update_cluster1_len_min.execute(ig_tm_md.ucast_egress_port);
    }
    action do_update_cluster1_len_max() {
        update_cluster1_len_max.execute(ig_tm_md.ucast_egress_port);
    }

    action do_update_cluster1_ttl_min() {
        update_cluster1_ttl_min.execute(ig_tm_md.ucast_egress_port);
    }
    action do_update_cluster1_ttl_max() {
        update_cluster1_ttl_max.execute(ig_tm_md.ucast_egress_port);
    }

    action do_update_cluster1_proto_min() {
        update_cluster1_proto_min.execute(ig_tm_md.ucast_egress_port);
    }
    action do_update_cluster1_proto_max() {
        update_cluster1_proto_max.execute(ig_tm_md.ucast_egress_port);
    }

    action do_update_cluster1_id_min() {
        update_cluster1_id_min.execute(ig_tm_md.ucast_egress_port);
    }
    action do_update_cluster1_id_max() {
        update_cluster1_id_max.execute(ig_tm_md.ucast_egress_port);
    }

    /* Cluster 2 */
    action do_update_distance_cluster2_len_min() {
        update_cluster2_len_min.execute(ig_tm_md.ucast_egress_port);
    }
    action do_update_cluster2_len_max() {
        update_cluster2_len_max.execute(ig_tm_md.ucast_egress_port);
    }

    action do_update_cluster2_ttl_min() {
        update_cluster2_ttl_min.execute(ig_tm_md.ucast_egress_port);
    }
    action do_update_cluster2_ttl_max() {
        update_cluster2_ttl_max.execute(ig_tm_md.ucast_egress_port);
    }

    action do_update_cluster2_proto_min() {
        update_cluster2_proto_min.execute(ig_tm_md.ucast_egress_port);
    }
    action do_update_cluster2_proto_max() {
        update_cluster2_proto_max.execute(ig_tm_md.ucast_egress_port);
    }

    action do_update_cluster2_id_min() {
        update_cluster2_id_min.execute(ig_tm_md.ucast_egress_port);
    }
    action do_update_cluster2_id_max() {
        update_cluster2_id_max.execute(ig_tm_md.ucast_egress_port);
    }

    /* Cluster 3 */
    action do_update_distance_cluster3_len_min() {
        update_cluster3_len_min.execute(ig_tm_md.ucast_egress_port);
    }
    action do_update_cluster3_len_max() {
        update_cluster3_len_max.execute(ig_tm_md.ucast_egress_port);
    }

    action do_update_cluster3_ttl_min() {
        update_cluster3_ttl_min.execute(ig_tm_md.ucast_egress_port);
    }
    action do_update_cluster3_ttl_max() {
        update_cluster3_ttl_max.execute(ig_tm_md.ucast_egress_port);
    }

    action do_update_cluster3_proto_min() {
        update_cluster3_proto_min.execute(ig_tm_md.ucast_egress_port);
    }
    action do_update_cluster3_proto_max() {
        update_cluster3_proto_max.execute(ig_tm_md.ucast_egress_port);
    }

    action do_update_cluster3_id_min() {
        update_cluster3_id_min.execute(ig_tm_md.ucast_egress_port);
    }
    action do_update_cluster3_id_max() {
        update_cluster3_id_max.execute(ig_tm_md.ucast_egress_port);
    }

    /* Cluster 4 */
    action do_update_distance_cluster4_len_min() {
        update_cluster4_len_min.execute(ig_tm_md.ucast_egress_port);
    }
    action do_update_cluster4_len_max() {
        update_cluster4_len_max.execute(ig_tm_md.ucast_egress_port);
    }

    action do_update_cluster4_ttl_min() {
        update_cluster4_ttl_min.execute(ig_tm_md.ucast_egress_port);
    }
    action do_update_cluster4_ttl_max() {
        update_cluster4_ttl_max.execute(ig_tm_md.ucast_egress_port);
    }

    action do_update_cluster4_proto_min() {
        update_cluster4_proto_min.execute(ig_tm_md.ucast_egress_port);
    }
    action do_update_cluster4_proto_max() {
        update_cluster4_proto_max.execute(ig_tm_md.ucast_egress_port);
    }

    action do_update_cluster4_id_min() {
        update_cluster4_id_min.execute(ig_tm_md.ucast_egress_port);
    }
    action do_update_cluster4_id_max() {
        update_cluster4_id_max.execute(ig_tm_md.ucast_egress_port);
    }


    /* Define the processing algorithm here */
    apply {

        // If all headers are valid and metadata ready, we run the clustering algorithm
        if (hdr.ipv4.isValid()) {
            
            /* We can remove it to reduce stages */
            //if (ipv4_host.apply().miss) {
            //    ipv4_lpm.apply();
            //} 

            if (ig_intr_md.resubmit_flag == 0){ 
                
                // Initial (non-resubmitted) packet

                /* Stage 0 */
                STAGE(0) {
                    compute_distance_cluster1_len_min();
                    compute_distance_cluster2_len_min();
                    compute_distance_cluster3_len_min();
                    compute_distance_cluster4_len_min();
                }

                /* Stage 1 */
                STAGE(1) {
                    compute_distance_cluster1_ttl_min();
                    compute_distance_cluster2_ttl_min();
                    compute_distance_cluster3_ttl_min();
                    compute_distance_cluster4_ttl_min();
                }
                
                /* Stage 2 */
                STAGE(2) {
                    compute_distance_cluster1_id_min();
                    compute_distance_cluster2_id_min();
                    compute_distance_cluster3_id_min();
                    compute_distance_cluster4_id_min();
                }
                
                /* Stage 3 */
                STAGE(3) {
                    compute_distance_cluster1_proto_min();
                    compute_distance_cluster2_proto_min();
                    compute_distance_cluster3_proto_min();
                    compute_distance_cluster4_proto_min();
                }
                
                /* Stage 4 */
                STAGE(4) {
                    if (meta.cluster1_len_distance == 0) {
                        compute_distance_cluster1_len_max();
                    }
                    if (meta.cluster2_len_distance == 0) {
                        compute_distance_cluster2_len_max();
                    }
                    if (meta.cluster3_len_distance == 0) {
                        compute_distance_cluster3_len_max();
                    }
                    if (meta.cluster4_len_distance == 0) {
                        compute_distance_cluster4_len_max();
                    }
                }
                
                /* Stage 5 */
                STAGE(5) {
                    if (meta.cluster1_ttl_distance == 0) {
                        compute_distance_cluster1_ttl_max();
                    }
                    if (meta.cluster2_ttl_distance == 0) {
                        compute_distance_cluster2_ttl_max();
                    }
                    if (meta.cluster3_ttl_distance == 0) {
                        compute_distance_cluster3_ttl_max();
                    }
                    if (meta.cluster4_ttl_distance == 0) {
                        compute_distance_cluster4_ttl_max();
                    }
                }
                
                /* Stage 6 */
                STAGE(6) {
                    if (meta.cluster1_id_distance == 0) {
                        compute_distance_cluster1_id_max();
                    }            
                    if (meta.cluster2_id_distance == 0) {
                        compute_distance_cluster2_id_max();
                    }
                    if (meta.cluster3_id_distance == 0) {
                        compute_distance_cluster3_id_max();
                    }
                    if (meta.cluster4_id_distance == 0) {
                        compute_distance_cluster4_id_max();
                    }
                    merge_ttl_to_len();
                }
                
                /* Stage 7 */
                STAGE(7) {
                    if (meta.cluster1_proto_distance == 0) {
                        compute_distance_cluster1_proto_max();
                    }
                    if (meta.cluster2_proto_distance == 0) {
                        compute_distance_cluster2_proto_max();
                    }
                    if (meta.cluster3_proto_distance == 0) {
                        compute_distance_cluster3_proto_max();
                    }
                    if (meta.cluster4_proto_distance == 0) {
                        compute_distance_cluster4_proto_max();
                    }
                    merge_id_to_len();
                }
                
                /* Stage 8 */
                merge_proto_to_len();

                /* Stage 9 */
                compute_min_first();

                /* Stage 10 */
                compute_min_second();

                /* Stage 11 */
                if (meta.min_d1_d2_d3_d4 == meta.cluster1_len_distance) {
                    /* We select cluster 1. Get prio from cluster 1 */
                    meta.cluster_id = 1;
                } else if (meta.min_d1_d2_d3_d4 == meta.cluster2_len_distance) {
                    /* We select cluster 2. Get prio from cluster 2 */
                    meta.cluster_id = 2;
                } else if (meta.min_d1_d2_d3_d4 ==  meta.cluster3_len_distance) {
                    /* We select cluster 3. Get prio from cluster 3 */
                    meta.cluster_id = 3;
                } else if (meta.min_d1_d2_d3_d4 ==  meta.cluster4_len_distance) {
                    /* We select cluster 4. Get prio from cluster 4 */
                    meta.cluster_id = 4;
                }
                ig_dprsr_md.resubmit_type = 1;

            } else {

                // Resubmitted packet

                /* Stage 0 */
                STAGE(0) { 
                    do_update_distance_cluster1_len_min();
                    do_update_distance_cluster2_len_min();
                    do_update_distance_cluster3_len_min();
                    do_update_distance_cluster4_len_min();
                }
                
                /* Stage 1 */
                STAGE(1) {
                    do_update_cluster1_ttl_min();
                    do_update_cluster2_ttl_min();
                    do_update_cluster3_ttl_min();
                    do_update_cluster4_ttl_min();
                }
                
                /* Stage 2 */
                STAGE(2) {
                    do_update_cluster1_id_min();
                    do_update_cluster2_id_min();
                    do_update_cluster3_id_min();
                    do_update_cluster4_id_min();
                }
                
                /* Stage 3 */
                STAGE(3) {
                    do_update_cluster1_proto_min();
                    do_update_cluster2_proto_min();
                    do_update_cluster3_proto_min();
                    do_update_cluster4_proto_min();      
                }
                
                /* Stage 4 */
                STAGE(4) {
                    do_update_cluster1_len_max();
                    do_update_cluster2_len_max();
                    do_update_cluster3_len_max();
                    do_update_cluster4_len_max();
                }
                
                /* Stage 5 */
                STAGE(5) {
                    do_update_cluster1_ttl_max();
                    do_update_cluster2_ttl_max();
                    do_update_cluster3_ttl_max();
                    do_update_cluster4_ttl_max();
                }
                
                /* Stage 6 */
                STAGE(6) {
                    do_update_cluster1_id_max();
                    do_update_cluster2_id_max();
                    do_update_cluster3_id_max();
                    do_update_cluster4_id_max();
                }
                
                /* Stage 7 */
                STAGE(7) {
                    do_update_cluster1_proto_max();
                    do_update_cluster2_proto_max();
                    do_update_cluster3_proto_max();
                    do_update_cluster4_proto_max();
                }
                
                /* Stage 8: Get the priority and forward the resubmitted packet */
                cluster_to_prio.apply();
            }
        }
    }
}

control MyIngressDeparser(packet_out                 pkt,    
    inout my_ingress_headers_t                       hdr,
    in    my_ingress_metadata_t                      meta,
    in    ingress_intrinsic_metadata_for_deparser_t  ig_dprsr_md) {

        Resubmit() do_resubmit;
        apply {
            if (ig_dprsr_md.resubmit_type == 1) {
                do_resubmit.emit<resubmit_h>({meta.cluster_id});
            }
            pkt.emit(hdr); // If the header is valid, will emit it. If not valid, will just jump to the next one.
        }
    }



/*************************************************************************
 ****************  E G R E S S   P R O C E S S I N G   *******************
 *************************************************************************/

/* Since we don't want to do any egress processing, we keep the egress headers and metadata empty */
struct my_egress_headers_t {
    ethernet_h ethernet;
    ipv4_h ipv4;
    transport_h  transport;
}

struct my_egress_metadata_t {}

parser MyEgressParser(packet_in      pkt,
    out my_egress_headers_t          hdr,
    out my_egress_metadata_t         meta,
    out egress_intrinsic_metadata_t  eg_intr_md) {

        state start {
            pkt.extract(eg_intr_md);
            transition accept;
        }
    }

control MyEgress(
    inout my_egress_headers_t                          hdr,
    inout my_egress_metadata_t                         meta,
    in    egress_intrinsic_metadata_t                  eg_intr_md,
    in    egress_intrinsic_metadata_from_parser_t      eg_prsr_md,
    inout egress_intrinsic_metadata_for_deparser_t     eg_dprsr_md,
    inout egress_intrinsic_metadata_for_output_port_t  eg_dport_md) {


    DirectCounter<bit<32>>(CounterType_t.PACKETS) packet_counter;
    DirectCounter<bit<32>>(CounterType_t.BYTES) bytes_counter;

    action packet_count() {
        packet_counter.count();
    }
    action bytes_count() {
        bytes_counter.count();
    }

    table do_packet_count {
        key = {
            eg_intr_md.egress_qid: exact @name("queue_id");
        }
        actions = { 
            packet_count; 
        }
        size = 32;
        counters = packet_counter;
        default_action = packet_count();
    }

    table do_bytes_count {
        key = {
            eg_intr_md.egress_qid: exact @name("queue_id");
        }
        actions = { 
            bytes_count; 
        }
        size = 32;
        counters = bytes_counter;
        default_action = bytes_count();
    }

    apply {

        /* Stages 8 - 11 */
        /* We can extract statistics of each cluster (e.g., throughput and pps) */
        /* These statistics will be used by the controller to allocate the priorities */
        if (hdr.ipv4.isValid()) {
            do_packet_count.apply();
            do_bytes_count.apply();
        }
    }

    }

control MyEgressDeparser(packet_out pkt,
    inout my_egress_headers_t                       hdr, 
    in    my_egress_metadata_t                      meta,
    in    egress_intrinsic_metadata_for_deparser_t  eg_dprsr_md) {

        apply {
            pkt.emit(hdr); // We do not emit eg_intr_md so that it does not go into the wire
        }
    }

/*************************************************************************
 ****************  F I N A L  P A C K A G E    ***************************
 *************************************************************************/
 
Pipeline(
    MyIngressParser(), MyIngress(), MyIngressDeparser(),
    MyEgressParser(), MyEgress(), MyEgressDeparser()
 ) pipe;

Switch(pipe) main; 
