#copied the tna_digest test 

import logging
import os

import pdb

from ptf import config
import ptf.testutils as testutils
from p4testutils.misc_utils import *
from bfruntime_client_base_tests import BfRuntimeTest
import bfrt_grpc.client as gc

pkt_len = int(test_param_get('pkt_size'))
logger = get_logger()


swports = get_sw_ports()


class PACRouteTest(BfRuntimeTest):
    """@brief Setup digests then send a packet
    """

    def setUp(self):
        client_id = 0
        p4_name = "PAC_Route_main"
        BfRuntimeTest.setUp(self, client_id, p4_name)

    def runTest(self):
        ''' Simple test to check if a digest is received after sending a packet. '''
        ig_port = swports[2]
        smac = '00:01:02:03:04:05'
        dmac = '00:06:07:08:09:0a'

        if int(ig_port) == 0:
            print("Need a port other then 0 so using swports[1]")
            ig_port = swports[1]

        pkt = testutils.simple_tcp_packet(pktlen=pkt_len, eth_dst=dmac, eth_src=smac)
        
        # Get bfrt_info and set it as part of the test
        bfrt_info = self.interface.bfrt_info_get("PAC_Route_main")
        target = gc.Target(device_id=0)

        # The learn object can be retrieved using a lesser qualified name on the condition
        # that it is unique
        learn_filter = bfrt_info.learn_get("vlan_digest")
        
        
        logger.info("Setting default action on port %d to learn(Send digest)", ig_port)
        table = bfrt_info.table_get("port_rules_table")
        table.info.key_field_annotation_add("ig_intr_md.ingress_port", "port")
        table.info.key_field_annotation_add("ig_md.vlan_0.vid", "vlan")

        logger.info("About to set port %d to learn", ig_port)

        key_list = None
        # Add entries to the dmac table to generate digests.
        try:
                key_list = [table.make_key([gc.KeyTuple('ig_intr_md.ingress_port', ig_port),gc.KeyTuple('ig_md.vlan_0.vid', 0, 0)])]
                print(table.entry_add(
                        target,
                        key_list,
                        [table.make_data([gc.DataTuple('learn_port', 1)],'PAC_Route_Ingress.port_drop')]))
        except Exception as e:
                print("Rule already exists:")
                print(e)
                
        layer2_table = bfrt_info.table_get("layer2_table")
        action_data = layer2_table.make_data(
            action_name="PAC_Route_Ingress.layer2_digest",
            data_field_list_in=[]
        )                
        
        layer2_table.default_entry_set(target,action_data)
                
        

        logger.info("Sending packet on port %d", ig_port)
        testutils.send_packet(self, ig_port, pkt)

        logger.info("Packet is expected to get dropped.")
        testutils.verify_no_other_packets(self)
        
        table.entry_del(target, key_list)

        digest = self.interface.digest_get()
        
        #if you want to print the raw from the switch
        #print(digest)

        recv_target = digest.target
        self.assertTrue(
            recv_target.device_id == self.device_id,
            "Error! Recv device id = %d does not match expected = %d" % (recv_target.device_id, self.device_id))
        exp_pipe_id = (ig_port >> 7) & 0x3
        self.assertTrue(
            recv_target.pipe_id == exp_pipe_id,
            "Error! Recv pipe id = %d does not match expected = %d" % (recv_target.pipe_id, exp_pipe_id))

        data_list = learn_filter.make_data_list(digest)
        data_dict = data_list[0].to_dict()
        
        self.assertTrue( data_dict["og_port"] == ig_port, "Error digest port(%d) != ig_port(%d)" %(data_dict["og_port"],ig_port) )



class PACRouteTestMPLSTwo(BfRuntimeTest):
    """@brief Setup digests then send a packet
    """

    def setUp(self):
        client_id = 0
        p4_name = "PAC_Route_main"
        BfRuntimeTest.setUp(self, client_id, p4_name)

    def runTest(self):
        ''' Simple test to check if a digest is received after sending a packet. '''
        ig_port = swports[2]
        smac = 'A0:01:02:03:04:05'
        dmac = 'B0:06:07:08:09:0a'
        
        if int(ig_port) == 0:
            print("Need a port other then 0 so using swports[1]")
            ig_port = swports[1]

        pkt = testutils.simple_mpls_packet(pktlen=pkt_len, eth_dst=dmac, eth_src=smac,mpls_tags=[ {"label":232},{"label":121}])
        
        # Get bfrt_info and set it as part of the test
        bfrt_info = self.interface.bfrt_info_get("PAC_Route_main")
        target = gc.Target(device_id=0)

        # The learn object can be retrieved using a lesser qualified name on the condition
        # that it is unique
        learn_filter = bfrt_info.learn_get("mpls_2_digest")
        
        
        logger.info("Setting default action on port %d to learn(Send digest)", ig_port)
        table = bfrt_info.table_get("port_rules_table")
        table.info.key_field_annotation_add("ig_intr_md.ingress_port", "port")
        table.info.key_field_annotation_add("ig_md.vlan_0.vid", "vlan")

        logger.info("About to set port %d to learn", ig_port)

        # Add entries to the dmac table to generate digests.
        key_list = None
        try:
                key_list = [table.make_key([gc.KeyTuple('ig_intr_md.ingress_port', ig_port),gc.KeyTuple('ig_md.vlan_0.vid', 0, 0)])]
        
                print(table.entry_add(
                        target,
                        key_list,
                        [table.make_data([gc.DataTuple('learn_port', 1)],'PAC_Route_Ingress.port_drop')]))
        except Exception as e:
                print("Rule already exists:")
                print(e)
                
        layer2_table = bfrt_info.table_get("layer2_table")
        action_data = layer2_table.make_data(
            action_name="PAC_Route_Ingress.layer2_digest",
            data_field_list_in=[]
        )                
        
        layer2_table.default_entry_set(target,action_data)
                
        

        logger.info("Sending packet on port %d", ig_port)
        testutils.send_packet(self, ig_port, pkt)

        logger.info("Packet is expected to get dropped.")
        testutils.verify_no_other_packets(self)

        table.entry_del(target, key_list)

        digest = self.interface.digest_get()
        
        #if you want to print the raw from the switch
        #print(digest)

        recv_target = digest.target
        self.assertTrue(
            recv_target.device_id == self.device_id,
            "Error! Recv device id = %d does not match expected = %d" % (recv_target.device_id, self.device_id))
        exp_pipe_id = (ig_port >> 7) & 0x3
        self.assertTrue(
            recv_target.pipe_id == exp_pipe_id,
            "Error! Recv pipe id = %d does not match expected = %d" % (recv_target.pipe_id, exp_pipe_id))

        data_list = learn_filter.make_data_list(digest)
        data_dict = data_list[0].to_dict()
        
        self.assertTrue( data_dict["og_port"] == ig_port, "Error digest port(%d) != ig_port(%d)" %(data_dict["og_port"],ig_port) )



