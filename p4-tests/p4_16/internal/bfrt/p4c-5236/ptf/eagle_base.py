################################################################################
# Eagle base class for PTF test
#
################################################################################

import unittest
import logging
import grpc
import pdb
import pp_utils
import struct

from ptf import config
from ptf.testutils import *
from ptf.dataplane import *
import ptf.mask

from bfruntime_client_base_tests import BfRuntimeTest
import bfrt_grpc.bfruntime_pb2 as bfruntime_pb2
import bfrt_grpc.client as gc

######## PTF modules for Fixed APIs (Thrift) ######
import pd_base_tests
from ptf.thriftutils   import *
from res_pd_rpc.ttypes import *       # Common data types
from mc_pd_rpc.ttypes  import *       # Multicast-specific data types
from mirror_pd_rpc.ttypes   import *   # Mirror-specific data types
from scapy.all import *
from collections import namedtuple

p4_program_name = "eagle_l47"

logger = logging.getLogger('L47')
logger.addHandler(logging.StreamHandler())

class Capture(Packet):
    name = "CaptureOV"
    fields_desc = [ XIntField("seq_no", 0),
                    XIntField("timestamp",0)
                  ]

class IpAddr():
    def __init__(self, addr, type_='Ipv6', prefix=128):
        self.addr = addr
        self.type_ = type_
        self.prefix = prefix
        if type_ == 'Ipv6':
            try:
                socket.inet_pton(socket.AF_INET6, self.addr)
            except socket.error:  # not a valid address
                logger.error("Invalid IPv6 address.")

    def netmask(self):
        ''' CIDR to netmask. '''
        return (1 << 128) - (1 << (128 - self.prefix))

    def __str__(self):
        return self.addr
#--------------------------------------------------------#

def parallel_swar(i):
    i = i - ((i >> 1) & 0x55555555)
    i = (i & 0x33333333) + ((i >> 2) & 0x33333333)
    i = (((i + (i >> 4)) & 0x0F0F0F0F) * 0x01010101) >> 24
    return int(i % 2)

########## Basic Initialization ############
class P4ProgramTest(BfRuntimeTest):
     #
    # This is a special class that will provide us with the interface to
    # the fixed APIs via the corresponding Thrift bindings. This particular
    # class provides access to all fixed APIs, but the cleanup routine is
    # implemented for multicast objects only
    #
    class FixedAPIs(pd_base_tests.ThriftInterfaceDataPlane):
        def __init__(self, p4names):
            pd_base_tests.ThriftInterfaceDataPlane.__init__(self, p4names)

        def setUp(self):
            pd_base_tests.ThriftInterfaceDataPlane.setUp(self)
            self.dev = 0
            self.mc_sess  = self.mc.mc_create_session()
            print("Opened MC Session {:#08x}".format(self.mc_sess))

        def cleanUp(self):
            try:
                print("  Deleting Multicast Groups")
                mgrp_count = self.mc.mc_mgrp_get_count(self.mc_sess, self.dev)
                if mgrp_count > 0:
                    mgrp_list  = [self.mc.mc_mgrp_get_first(self.mc_sess, self.dev)]
                    if mgrp_count > 1:
                        mgrp_list.extend(self.mc.mc_mgrp_get_next_i(
                            self.mc_sess, self.dev,
                            mgrp_list[-1], mgrp_count - 1))

                    for mgrp in mgrp_list:
                        self.mc.mc_mgrp_destroy(self.mc_sess, self.dev, mgrp)

                print("  Deleting Multicast ECMP Entries")
                ecmp_count = self.mc.mc_ecmp_get_count(self.mc_sess, self.dev)
                if ecmp_count > 0:
                    ecmp_list  = [self.mc.mc_ecmp_get_first(self.mc_sess, self.dev)]
                    if ecmp_count > 1:
                        ecmp_list.extend(self.mc.mc_ecmp_get_next_i(
                            self.mc_sess, self.dev,
                            ecmp_list[-1], ecmp_count - 1))

                    for ecmp in ecmp_list:
                        self.mc.mc_ecmp_destroy(self.mc_sess, self.dev, ecmp)

                print("  Deleting Multicast Nodes")
                node_count = self.mc.mc_node_get_count(self.mc_sess, self.dev)
                if node_count > 0:
                    node_list  = [self.mc.mc_node_get_first(self.mc_sess, self.dev)]
                    if node_count > 1:
                        node_list.extend(self.mc.mc_node_get_next_i(
                            self.mc_sess, self.dev,
                            node_list[-1], node_count - 1))

                    for node in node_list:
                        self.mc.mc_node_destroy(self.mc_sess, self.dev, node)

                print("  Clearing Multicast LAGs")
                for lag in range(0, 255):
                    self.mc.mc_set_lag_membership(
                        self.mc_sess, self.dev,
                        hex_to_byte(lag), devports_to_mcbitmap([]))

                print("  Clearing Port Pruning Table")
                for yid in range(0, 288):
                    self.mc.mc_update_port_prune_table(
                        self.mc_sess, self.dev,
                        hex_to_i16(yid), devports_to_mcbitmap([]));

            except:
                print("  Error while cleaning up multicast objects. ")
                print("  You might need to restart the driver")
            finally:
                self.mc.mc_complete_operations(self.mc_sess)

             # Here we show how to clear all Mirror sessions
            print("  Clearing mirror sessions")
            try:
                while True:
                    result = self.mirror.mirror_session_get_first(
                        self.sess_hdl, self.dev_tgt)
                    self.mirror.mirror_session_delete(
                        self.sess_hdl, self.dev_tgt, result.info.mir_id)
            except InvalidPipeMgrOperation:
                pass # No more mirror destinations to clear
            except Exception as e:
                print(e)
                print("  Error while cleaning up mirror object. ")
                print("  You might need to restart the driver")
            finally:
                self.conn_mgr.complete_operations(self.sess_hdl)

        def runTest(self):
            pass

        def tearDown(self):
            self.mc.mc_destroy_session(self.mc_sess)
            print("  Closed MC Session %#08x" % self.mc_sess)
            pd_base_tests.ThriftInterfaceDataPlane.tearDown(self)
    # The setUp() method is used to prepare the test fixture. Typically
    # you would use it to establich connection to the gRPC Server
    #
    # You can also put the initial device configuration there. However,
    # if during this process an error is encountered, it will be considered
    # as a test error (meaning the test is incorrect),
    # rather than a test failure
    #
    # Here is the stuff we set up that is ready to use
    #  client_id
    #  p4_name
    #  bfrt_info
    #  dev
    #  dev_tgt
    #  allports
    #  tables    -- the list of tables
    #     Individual tables of the program with short names
    #
    def setUp(self):
        self.client_id = 0
        self.p4_name = p4_program_name     # Specialization
        self.dev      = 0
        self.dev_tgt  = gc.Target(self.dev, pipe_id=0xFFFF)

        print("\n")
        print("Test Setup")
        print("==========")

        BfRuntimeTest.setUp(self, self.client_id, self.p4_name)

        # This is the simple case when you run only one program on the target.
        # Otherwise, you might have to retrieve multiple bfrt_info objects and
        # in that case you will need to specify program name as a parameter
        self.bfrt_info = self.interface.bfrt_info_get()

        print("    Connected to Device: {}, Program: {}, ClientId: {}".format(
            self.dev, self.p4_name, self.client_id))

        # Create a list of all ports available on the device
        self.swports = []
        for (device, port, ifname) in ptf.config['interfaces']:
            self.swports.append(port)
        self.swports.sort()

        ###### FIXED API SETUP #########
        self.fixed = self.FixedAPIs([self.p4_name])
        self.fixed.setUp()

        # Since this class is not a test per se, we can use the setup method
        # for common setup. For example, we can have our tables and annotations
        # ready

        # Program-specific customization
        # port metadata is special
        self.port_metadata = self.bfrt_info.table_get("SxIngParser.$PORT_METADATA")
        # stats table
        #self.latency_stat = self.bfrt_info.table_get("SxIngPipeline.latency_stat.l47_latencyB.data_storage")
        #self.flow_stat = self.bfrt_info.table_get("SxIngPipeline.latency_stat.store_pktB")
        #self.stat_tbl = self.bfrt_info.table_get("SxIngPipeline.countl47Table")
        #self.min_latency_stat = self.bfrt_info.table_get("SxIngPipeline.latency_stat.store_lat_minB")
        #self.max_latency_stat = self.bfrt_info.table_get("SxIngPipeline.latency_stat.store_lat_maxB")

        #programmable tables
        #self.l23_outbound = self.bfrt_info.table_get("SxIngPipeline.L23OutboundTbl")
        #self.l23_signature = self.bfrt_info.table_get("SxIngPipeline.checkSignatureTbl")
        self.l23_outbound = self.bfrt_info.table_get("SxIngPipeline.presetOutboundTbl")
        #this is deleted and inserted within the test
        self.l47_portconfig = self.bfrt_info.table_get("SxIngPipeline.ingress_metadata_map.FrontPanelConfigTbl")
        self.l47_inbound_v4 = self.bfrt_info.table_get("SxIngPipeline.inbound_l47_gen_lookup.EgressRangeCnTbl")
        self.l47_egress_table = self.bfrt_info.table_get("SxIngPipeline.inbound_l47_gen_lookup.EgressTernaryTbl")
        self.l47_mac_table = self.bfrt_info.table_get("SxIngPipeline.inbound_l47_gen_lookup.EgressMacRangeCnTbl")
        self.l47_range_compare = self.bfrt_info.table_get("SxIngPipeline.inbound_l47_gen_lookup.EgressRangecompare")
        #self.l47_map_address = self.bfrt_info.table_get("SxIngPipeline.inbound_l47_gen_lookup.MapAddressTbl")
        self.remove_vlan_table = self.bfrt_info.table_get("SxIngPipeline.removeVlanTbl")
        self.tables = [self.l23_outbound, self.l47_inbound_v4, self.port_metadata, self.l47_mac_table,
                        self.l47_egress_table, self.l47_portconfig, self.l47_range_compare] 
        self.l47_range_register = self.bfrt_info.table_get("SxIngPipeline.inbound_l47_gen_lookup.range_reg")
        self.l47_mac_range_register = self.bfrt_info.table_get("SxIngPipeline.inbound_l47_gen_lookup.mac_range_reg")
        self.l47_egress_cmp_table = self.bfrt_info.table_get("SxIngPipeline.inbound_l47_gen_lookup.EgressRangecompare")
        
        #capture
        self.overheadTbl = self.bfrt_info.table_get("SxEgrPipeline.insertOverheadTbl")
        self.ingressMirror = self.bfrt_info.table_get("SxIngPipeline.ingressCaptureTbl")
        self.egressCaptureGroup = self.bfrt_info.table_get("SxIngPipeline.set_egress_group")
        self.egressCapture = self.bfrt_info.table_get("SxEgrPipeline.captureTbl")
        self.tables = self.tables + [self.ingressMirror, self.egressCapture, self.egressCaptureGroup ]
        self.tables = self.tables + [self.overheadTbl]
                      
        #ping pong registers 
        self.ping_pong_name = ["ping_reg", "pong_reg", "ping_egress_reg", "pong_egress_reg"]
        self.ping_pong_registers = []
        for name in self.ping_pong_name: 
            reg = self.bfrt_info.table_get(name)
            self.ping_pong_registers.append(reg)
        self.rx_sequence_number_reg_name = "SxIngPipeline.sequence_no"
        self.rx_sequence_number_reg = self.bfrt_info.table_get(self.rx_sequence_number_reg_name)
        self.tx_sequence_number_reg_name = "SxEgrPipeline.sequence_no"
        self.tx_sequence_number_reg = self.bfrt_info.table_get(self.tx_sequence_number_reg_name)
       # Optional, but highly recommended
        self.cleanUp()


    # Use tearDown() method to return the DUT to the initial state by cleaning
    # all the configuration and clearing up the connection
    def tearDown(self):
        print("\n")
        print("Test TearDown:")
        print("==============")
        #self.cleanUp()

        # Call the Parent tearDown
        BfRuntimeTest.tearDown(self)
        self.fixed.tearDown()


    # Use Cleanup Method to clear the tables before and after the test starts
    # (the latter is done as a part of tearDown()
    def cleanUp(self):
        print("\n")
        print("Table Cleanup:")
        print("==============")
        for t in self.tables:
            #if self.l47_inbound_v4 == t:
            #    continue
            try:
                print("  Clearing Table {}".format(t.info.name_get()))
                keys = []
                for (d, k) in t.entry_get(self.dev_tgt):
                    if k is not None:
                        keys.append(k)
                t.entry_del(self.dev_tgt, keys)
                # Not all tables support default entry
                if t != self.port_metadata:
                    try:
                        t.default_entry_reset(self.dev_tgt)
                    except:
                        pass
            except Exception as e:
                print("Error cleaning up: {}".format(e))

    #
    # This is a simple helper method that takes a list of entries and programs
    # them in a specified table
    #
    # Each entry is a tuple, consisting of 3 elements:
    #  key         -- a list of tuples for each element of the key
    #  action_name -- the action to use. Must use full name of the action
    #  data        -- a list (may be empty) of the tuples for each action
    #                 parameter
    #
    def programTable(self, table, entries, target=None):
        if target is None:
            target = self.dev_tgt

        key_list=[]
        data_list=[]
        for k, a, d in entries:
            key_list.append(table.make_key([gc.KeyTuple(*f)   for f in k]))
            data_list.append(table.make_data([gc.DataTuple(*p) for p in d], a))
        table.entry_add(target, key_list, data_list)

    def assign_hash_order(self):
        return
        # if diffDig == 0 ( exact), then compare diffPort (msb). If msb = 1, means
        # swap, else no swap. If diffDig msb = 1, then, swap
        #0 means don't care, '1' means match
        # entry order define match first (or we can specify the match priority..)
        key_list = [
            self.hash_order.make_key([
                #mask of 1 for a single bit means don't care
                gc.KeyTuple('diffPort[15:15]', gc.to_bytes(1, 1), mask=0),
                gc.KeyTuple('diffDig0', value=gc.to_bytes(0x80000000, 4), mask=0x80000000)])
            ]
        data_list = [
            self.hash_order.make_data([],
                'SxIngPipeline.calculate_hash.swapOrder')
            ]
        self.hash_order.entry_add(self.dev_tgt, key_list, data_list)
        key_list = [
            self.hash_order.make_key([
                #mask of 1 for a single bit means don't care
                gc.KeyTuple('diffPort[15:15]', gc.to_bytes(0, 1), mask=0x1),
                gc.KeyTuple('diffDig0', value=gc.to_bytes(0, 4), mask=0xFFFFFFFF)])
            ]
        data_list = [
            self.hash_order.make_data([],
                'SxIngPipeline.calculate_hash.noSwapOrder')
            ]
        self.hash_order.entry_add(self.dev_tgt, key_list, data_list)
        key_list = [
            self.hash_order.make_key([
                #mask of 1 for a single bit means don't care
                gc.KeyTuple('diffPort[15:15]', gc.to_bytes(1, 1), mask=0x1),
                gc.KeyTuple('diffDig0', value=gc.to_bytes(0, 4), mask=0xFFFFFFFF)])
            ]
        data_list = [
            self.hash_order.make_data([],
                'SxIngPipeline.calculate_hash.swapOrder')
            ]
        self.hash_order.entry_add(self.dev_tgt, key_list, data_list)
        key_list = [
            self.hash_order.make_key([
                #mask of 1 for a single bit means don't care
                gc.KeyTuple('diffPort[15:15]', gc.to_bytes(1, 1), mask=0),
                gc.KeyTuple('diffDig0', value=gc.to_bytes(0x00000000, 4), mask=0x80000000)])
            ]
        data_list = [
            self.hash_order.make_data([],
                'SxIngPipeline.calculate_hash.noSwapOrder')
            ]
        self.hash_order.entry_add(self.dev_tgt, key_list, data_list)

    # def assign_stat_index(self, igPort, index):
    #     key_list = [
    #         self.stat_tbl.make_key([
    #             gc.KeyTuple('ig_intr_md.ingress_port', gc.to_bytes(igPort,2)),
    #             gc.KeyTuple('stat_index', index)])
    #         ]
    #     data_list = [
    #         self.stat_tbl.make_data([
    #             gc.DataTuple('index', index)],
    #             'SxIngPipeline.count_latency_stats')]
    #     self.stat_tbl.entry_add(self.dev_tgt, key_list, data_list)
    def remove_vlan(self):
        key_list = [
            self.remove_vlan_table.make_key([
                gc.KeyTuple('meta.port_properties.port_type', 3),
                gc.KeyTuple('hdr.vlan_tag_0.vlan_top', 0xf),
                gc.KeyTuple('hdr.vlan_tag_0.vlan_bot', 0xff)
            ])
        ]
        data_list = [
            self.remove_vlan_table.make_data([],
                'SxIngPipeline.removeVlan')
        ]
        self.remove_vlan_table.entry_add(self.dev_tgt, key_list, data_list)
    
    def clear_remove_vlan_table(self):
        key_list = [
            self.remove_vlan_table.make_key([
                gc.KeyTuple('meta.port_properties.port_type', 3),
                gc.KeyTuple('hdr.vlan_tag_0.vlan_top', 0xf),
                gc.KeyTuple('hdr.vlan_tag_0.vlan_bot', 0xff)
            ])
        ]
        self.remove_vlan_table.entry_del(self.dev_tgt, key_list)
        
        key_list = [
            self.l47_egress_cmp_table.make_key( [
                gc.KeyTuple('range_result_2', 1),
                gc.KeyTuple('hdr.vlan_tag_0.$valid', 1)])
            ]
        self.l47_egress_cmp_table.entry_del(self.dev_tgt, key_list)
        key_list = [
            self.l47_egress_cmp_table.make_key( [
                gc.KeyTuple('range_result_2', 1),
                gc.KeyTuple('hdr.vlan_tag_0.$valid', 0)])
            ]
        self.l47_egress_cmp_table.entry_del(self.dev_tgt, key_list)

    def assign_port_type(self, igPort, porttype, capture_group=0):
        key_list = [
            self.port_metadata.make_key([
                gc.KeyTuple('ig_intr_md.ingress_port', gc.to_bytes(igPort,2))])
            ]
        data_list = [
            self.port_metadata.make_data([
                gc.DataTuple('port_type', gc.to_bytes(porttype, 1)),
                gc.DataTuple('capture_group', gc.to_bytes(capture_group,1))])
            ]
        self.port_metadata.entry_add(self.dev_tgt, key_list, data_list)
        print("Assign {} port type {}".format(igPort, porttype))
        
    def assign_l47_egressport(self, igPort, prio, egPort):
        print("Assign np port {} l47 cos {} -> actual fp Port {}".format(igPort, prio, egPort))
        pcp_cfi = prio << 1
        pcp_cfi_tstamp = prio << 1 |1 
        key_list = [ self.l23_outbound.make_key([
                gc.KeyTuple('hdr.vlan_tag_0.pcp_cfi', value=pcp_cfi_tstamp, mask= 0xf),
                gc.KeyTuple('hdr.vlan_tag_0.$valid', value=1, mask= 0x1),
                gc.KeyTuple('hdr.vlan_tag_1.$valid', value=0, mask= 0x1),
                gc.KeyTuple('ig_intr_md.ingress_port', value=gc.to_bytes(igPort,2), mask=0x1ff),
                gc.KeyTuple('meta.port_properties.port_type', value=3, mask=0x3),
                gc.KeyTuple('meta.engine_id', value = 0, mask = 0), 
                gc.KeyTuple('hdr.first_payload.signature_top', value=0x0101800a, mask=0xffffffff),
                gc.KeyTuple('hdr.first_payload.signature_bot',value=0, mask=0), 
                ]) ]
        data_list = [
            self.l23_outbound.make_data([
                gc.DataTuple('egPort', gc.to_bytes(egPort, 2))],
                'SxIngPipeline.setL47OutboundEgPortInsertTimestamp')]
        self.l23_outbound.entry_add(self.dev_tgt, key_list, data_list)
        key_list = [ self.l23_outbound.make_key([
                gc.KeyTuple('hdr.vlan_tag_0.pcp_cfi', value=pcp_cfi, mask= 0xf),
                gc.KeyTuple('hdr.vlan_tag_0.$valid', value=1, mask= 0x1),
                gc.KeyTuple('hdr.vlan_tag_1.$valid', value=0, mask= 0x1),
                gc.KeyTuple('ig_intr_md.ingress_port', value=gc.to_bytes(igPort,2), mask=0x1ff),
                gc.KeyTuple('meta.port_properties.port_type', value=3, mask=0x3),
                gc.KeyTuple('meta.engine_id', value = 0, mask = 0), 
                gc.KeyTuple('hdr.first_payload.signature_top', value=0, mask=0),
                gc.KeyTuple('hdr.first_payload.signature_bot',value=0, mask=0), 
                ]) ]
        data_list = [
            self.l23_outbound.make_data([
                gc.DataTuple('egPort', gc.to_bytes(egPort, 2))],'SxIngPipeline.setL47OutboundEgPort')]
        self.l23_outbound.entry_add(self.dev_tgt, key_list, data_list)
    
        key_list = [ self.l23_outbound.make_key([
                gc.KeyTuple('hdr.vlan_tag_0.pcp_cfi', value=pcp_cfi_tstamp, mask= 0xf),
                gc.KeyTuple('hdr.vlan_tag_0.$valid', value=1, mask= 0x1),
                gc.KeyTuple('hdr.vlan_tag_1.$valid', value=1, mask= 0x1),
                gc.KeyTuple('ig_intr_md.ingress_port', value=gc.to_bytes(igPort,2), mask=0x1ff),
                gc.KeyTuple('meta.port_properties.port_type', value=3, mask=0x3),
                gc.KeyTuple('meta.engine_id', value = 0, mask = 0), 
                gc.KeyTuple('hdr.first_payload.signature_top', value=0x0101800a, mask=0xffffffff),
                gc.KeyTuple('hdr.first_payload.signature_bot',value=0, mask=0), 
                ]) ]
        data_list = [
            self.l23_outbound.make_data([
                gc.DataTuple('egPort', gc.to_bytes(egPort, 2))],
                'SxIngPipeline.setL47InnerVlanOutboundEgPortInsertTimestamp')]
        self.l23_outbound.entry_add(self.dev_tgt, key_list, data_list)
        key_list = [ self.l23_outbound.make_key([
                gc.KeyTuple('hdr.vlan_tag_0.pcp_cfi', value=pcp_cfi, mask= 0xf),
                gc.KeyTuple('hdr.vlan_tag_0.$valid', value=1, mask= 0x1),
                gc.KeyTuple('hdr.vlan_tag_1.$valid', value=1, mask= 0x1),
                gc.KeyTuple('ig_intr_md.ingress_port', value=gc.to_bytes(igPort,2), mask=0x1ff),
                gc.KeyTuple('meta.port_properties.port_type', value=3, mask=0x3),
                gc.KeyTuple('meta.engine_id', value = 0, mask = 0), 
                gc.KeyTuple('hdr.first_payload.signature_top', value=0, mask=0),
                gc.KeyTuple('hdr.first_payload.signature_bot',value=0, mask=0), 
                ]) ]
        data_list = [
            self.l23_outbound.make_data([
                gc.DataTuple('egPort', gc.to_bytes(egPort, 2))],'SxIngPipeline.setL47InnerVlanOutboundEgPort')]
        self.l23_outbound.entry_add(self.dev_tgt, key_list, data_list)
    
    def delete_l47_egressport(self, igPort, prio, egPort):
        pcp_cfi = prio << 1
        pcp_cfi_tstamp = prio << 1 |1 
        key_list = [ self.l23_outbound.make_key([
                gc.KeyTuple('hdr.vlan_tag_0.pcp_cfi', value=pcp_cfi_tstamp, mask= 0xf),
                gc.KeyTuple('hdr.vlan_tag_0.$valid', value=1, mask= 0x1),
                gc.KeyTuple('hdr.vlan_tag_1.$valid', value=0, mask= 0x1),
                gc.KeyTuple('ig_intr_md.ingress_port', value=gc.to_bytes(igPort,2), mask=0x1ff),
                gc.KeyTuple('meta.port_properties.port_type', value=3, mask=0x3),
                gc.KeyTuple('meta.engine_id', value = 0, mask = 0), 
                gc.KeyTuple('hdr.first_payload.signature_top', value=0x0101800a, mask=0xffffffff),
                gc.KeyTuple('hdr.first_payload.signature_bot',value=0, mask=0), 
                ]) ]
        self.l23_outbound.entry_del(self.dev_tgt, key_list)
        key_list = [ self.l23_outbound.make_key([
                gc.KeyTuple('hdr.vlan_tag_0.pcp_cfi', value=pcp_cfi, mask= 0xf),
                gc.KeyTuple('hdr.vlan_tag_0.$valid', value=1, mask= 0x1),
                gc.KeyTuple('hdr.vlan_tag_1.$valid', value=0, mask= 0x1),
                gc.KeyTuple('ig_intr_md.ingress_port', value=gc.to_bytes(igPort,2), mask=0x1ff),
                gc.KeyTuple('meta.port_properties.port_type', value=3, mask=0x3),
                gc.KeyTuple('meta.engine_id', value = 0, mask = 0), 
                gc.KeyTuple('hdr.first_payload.signature_top', value=0, mask=0),
                gc.KeyTuple('hdr.first_payload.signature_bot',value=0, mask=0), 
                ]) ]
        self.l23_outbound.entry_del(self.dev_tgt, key_list)
        key_list = [ self.l23_outbound.make_key([
                gc.KeyTuple('hdr.vlan_tag_0.pcp_cfi', value=pcp_cfi_tstamp, mask= 0xf),
                gc.KeyTuple('hdr.vlan_tag_0.$valid', value=1, mask= 0x1),
                gc.KeyTuple('hdr.vlan_tag_1.$valid', value=1, mask= 0x1),
                gc.KeyTuple('ig_intr_md.ingress_port', value=gc.to_bytes(igPort,2), mask=0x1ff),
                gc.KeyTuple('meta.port_properties.port_type', value=3, mask=0x3),
                gc.KeyTuple('meta.engine_id', value = 0, mask = 0), 
                gc.KeyTuple('hdr.first_payload.signature_top', value=0x0101800a, mask=0xffffffff),
                gc.KeyTuple('hdr.first_payload.signature_bot',value=0, mask=0), 
                ]) ]
        self.l23_outbound.entry_del(self.dev_tgt, key_list)
        key_list = [ self.l23_outbound.make_key([
                gc.KeyTuple('hdr.vlan_tag_0.pcp_cfi', value=pcp_cfi, mask= 0xf),
                gc.KeyTuple('hdr.vlan_tag_0.$valid', value=1, mask= 0x1),
                gc.KeyTuple('hdr.vlan_tag_1.$valid', value=1, mask= 0x1),
                gc.KeyTuple('ig_intr_md.ingress_port', value=gc.to_bytes(igPort,2), mask=0x1ff),
                gc.KeyTuple('meta.port_properties.port_type', value=3, mask=0x3),
                gc.KeyTuple('meta.engine_id', value = 0, mask = 0), 
                gc.KeyTuple('hdr.first_payload.signature_top', value=0, mask=0),
                gc.KeyTuple('hdr.first_payload.signature_bot',value=0, mask=0), 
                ]) ]
        self.l23_outbound.entry_del(self.dev_tgt, key_list)
    
    def assign_l47_mac_mask(self, igPort, egPort, vlan, vlan_mask, mac, mac_mask, mac_high, index):
        print("Assign np port {} l47 {} vlan {}vlan_mask -> actual fp Port {}".format(igPort, vlan, vlan_mask, egPort))
        (vid_top, vid_bot) = self.split_vlan(vlan)
        range_7_mac = mac & 0xffff
        range_6_mac = (mac >>16) & 0xffff
        range_5_mac = (mac>>32) & 0xffff
        range_7_mac_mask = mac_mask & 0xffff
        range_6_mac_mask = (mac_mask >>16) & 0xffff
        range_5_mac_mask = (mac_mask >>32) & 0xffff
        if vlan > 0:
            vlan_exist = 1
        else:
            vlan_exist = 0
        key_list = [
            self.l47_mac_table.make_key([
                gc.KeyTuple('ig_intr_md.ingress_port', gc.to_bytes(igPort,2)),
                gc.KeyTuple('meta.vid_bot', value=gc.to_bytes(vid_bot, 1)),
                gc.KeyTuple('meta.vid_top', value=gc.to_bytes(vid_top, 1)),
                gc.KeyTuple('hdr.vlan_tag_0.$valid', vlan_exist ),
                gc.KeyTuple('ig_intr_md.ingress_port', gc.to_bytes(igPort, 2)),
                gc.KeyTuple('hdr.ethernet.dst_addr[47:32]', value=gc.to_bytes(range_5_mac, 2)),
                gc.KeyTuple('hdr.ethernet.dst_addr[31:16]', value=gc.to_bytes(range_6_mac, 2), mask=range_6_mac_mask),
                gc.KeyTuple('hdr.ethernet.dst_addr[15:0]', value=gc.to_bytes(range_7_mac, 2), mask=range_7_mac_mask)
                ])
            ]
        data_list = [
            self.l47_mac_table.make_data([
                gc.DataTuple('egPort', gc.to_bytes(egPort, 2)), gc.DataTuple('match_index', gc.to_bytes(index, 1))],
                'SxIngPipeline.inbound_l47_gen_lookup.setMacRangePort')]
        self.l47_mac_table.entry_add(self.dev_tgt, key_list, data_list)
        addr_low = (mac & 0xffffffff)
        addr_high = (mac_high & 0xffffffff)
        key_list = [
                self.l47_mac_range_register.make_key([
                    gc.KeyTuple('$REGISTER_INDEX', index)])
            ]
        data_list = [
                self.l47_mac_range_register.make_data([
                    gc.DataTuple("SxIngPipeline.inbound_l47_gen_lookup.mac_range_reg.start", addr_low ),
                    gc.DataTuple("SxIngPipeline.inbound_l47_gen_lookup.mac_range_reg.end", addr_high )
                    ])
            ]
        self.l47_mac_range_register.entry_add(self.dev_tgt, key_list, data_list)

    def delete_l47_egressport_mask(self, igPort, vlan, vlan_mask, mac, mac_mask, index):
        (vid_top, vid_bot) = self.split_vlan(vlan)
        range_7_mac = mac & 0xffff
        range_6_mac = (mac >>16) & 0xffff
        range_5_mac = (mac>>32) & 0xffff
        range_7_mac_mask = mac_mask & 0xffff
        range_6_mac_mask = (mac_mask >>16) & 0xffff
        range_5_mac_mask = (mac_mask >>32) & 0xffff
        if vlan > 0:
            vlan_exist = 1
        else:
            vlan_exist = 0
        key_list = [
            self.l47_mac_table.make_key([
                gc.KeyTuple('ig_intr_md.ingress_port', gc.to_bytes(igPort,2)),
                gc.KeyTuple('meta.vid_bot', value=gc.to_bytes(vid_bot, 1)),
                gc.KeyTuple('meta.vid_top', value=gc.to_bytes(vid_top, 1)),
                gc.KeyTuple('hdr.vlan_tag_0.$valid', vlan_exist ),
                gc.KeyTuple('ig_intr_md.ingress_port', gc.to_bytes(igPort, 2)),
                gc.KeyTuple('hdr.ethernet.dst_addr[47:32]', value=gc.to_bytes(range_5_mac, 2)),
                gc.KeyTuple('hdr.ethernet.dst_addr[31:16]', value=gc.to_bytes(range_6_mac, 2), mask=range_6_mac_mask),
                gc.KeyTuple('hdr.ethernet.dst_addr[15:0]', value=gc.to_bytes(range_7_mac, 2), mask=range_7_mac_mask)
                ])
            ]
        self.l47_mac_table.entry_del(self.dev_tgt, key_list)
        key_list = [
                self.l47_mac_range_register.make_key([
                    gc.KeyTuple('$REGISTER_INDEX', index)])
            ]
        data_list = [
                self.l47_mac_range_register.make_data([
                    gc.DataTuple("SxIngPipeline.inbound_l47_gen_lookup.mac_range_reg.start", 0),
                    gc.DataTuple("SxIngPipeline.inbound_l47_gen_lookup.mac_range_reg.end", 0 )
                    ])
            ]
        self.l47_mac_range_register.entry_add(self.dev_tgt, key_list, data_list)

    def assign_l47_port_config(self, igPort, inner_vlan, inner_ip):
        key_list = [
             self.l47_portconfig.make_key([
                gc.KeyTuple('ig_intr_md.ingress_port', gc.to_bytes(igPort,2))
                ])
            ]
        data_list = [
             self.l47_portconfig.make_data([
                gc.DataTuple('cfg_vlan', inner_vlan), 
                gc.DataTuple('cfg_ip',   inner_ip)],
                'SxIngPipeline.ingress_metadata_map.setIpVlanMode')]
        self.l47_portconfig.entry_add(self.dev_tgt, key_list, data_list)
        print("Assign FP port {} inner_ip {} inner_vlan {}".format(igPort, inner_ip, inner_vlan))

    def assign_l23_eg_port(self, egPort, engine_id, ingress_port, porttype, ins_timestamp):
        """ assign L23 egress port wrt ingress port """
        if porttype == 2:
            signature_top = 0xC0DEFACE
            signature_bot = 0xCA000000
            mask_top = 0xffffffff
            mask_bot = 0xff000000
            key_list = [ self.l23_outbound.make_key([
                gc.KeyTuple('meta.port_properties.port_type', value=2, mask=0x3),
                gc.KeyTuple('meta.engine_id', value = gc.to_bytes(engine_id, 1), mask = 0xf), 
                gc.KeyTuple('hdr.first_payload.signature_top', value=signature_top, mask=mask_top),
                gc.KeyTuple('hdr.first_payload.signature_bot',value=signature_bot, mask=mask_bot), 
                ]) ]
            if ins_timestamp:
                data_list = [
                    self.l23_outbound.make_data([
                        gc.DataTuple('egPort', gc.to_bytes(egPort, 2)),
                        gc.DataTuple('queue', 0)],
                        'SxIngPipeline.setL23OutboundInsertEgPort')
                    ]
            else:
                data_list = [
                    self.l23_outbound.make_data([
                        gc.DataTuple('egPort', gc.to_bytes(egPort, 2)),
                        gc.DataTuple('queue', 0)],
                        'SxIngPipeline.setL23OutboundEgPort')
                    ]
            self.l23_outbound.entry_add(self.dev_tgt, key_list, data_list)
            print("Assign engine id {}, igPort {} -> {}".format(engine_id, ingress_port, egPort))
            #automatically program the egress side as well
            key_list = [
                self.l23_outbound.make_key([
                gc.KeyTuple('meta.port_properties.port_type', value=1, mask=0x3),
                gc.KeyTuple('meta.engine_id', value = gc.to_bytes(engine_id, 1), mask = 0xf), 
                gc.KeyTuple('hdr.first_payload.signature_top', value=signature_top, mask=mask_top),
                gc.KeyTuple('hdr.first_payload.signature_bot', value=signature_bot, mask=mask_bot) 
            ]) 
            ]
            if ins_timestamp:
                data_list = [
                    self.l23_outbound.make_data([
                        gc.DataTuple('egPort', gc.to_bytes(ingress_port, 2)),
                        gc.DataTuple('queue', 0)],
                        'SxIngPipeline.setL23InboundInsertEgPort')]
            else:
                data_list = [
                    self.l23_outbound.make_data([
                        gc.DataTuple('egPort', gc.to_bytes(ingress_port, 2)),
                        gc.DataTuple('queue', 0)],
                        'SxIngPipeline.setL23OutboundEgPort')]
            self.l23_outbound.entry_add(self.dev_tgt, key_list, data_list)
            print("Assign engine id {}, igPort {} -> {}".format(engine_id, egPort, ingress_port))
        else:
            print("not supported porttype {}", porttype )
    
    def delete_l23_eg_port(self, engine_id):
        """ assign L23 egress port wrt ingress port """
        signature_top = 0xC0DEFACE
        signature_bot = 0xCA000000
        mask_top = 0xffffffff
        mask_bot = 0xff000000
        key_list = [ self.l23_outbound.make_key([
            gc.KeyTuple('meta.port_properties.port_type', value=2, mask=0x3),
            gc.KeyTuple('meta.engine_id', value = gc.to_bytes(engine_id, 1), mask = 0xf), 
            gc.KeyTuple('hdr.first_payload.signature_top', value=signature_top, mask=mask_top),
            gc.KeyTuple('hdr.first_payload.signature_bot',value=signature_bot, mask=mask_bot), 
            ]) ]
        self.l23_outbound.entry_del(self.dev_tgt, key_list)
       
        #automatically program the egress side as well
        key_list = [
            self.l23_outbound.make_key([
            gc.KeyTuple('meta.port_properties.port_type', value=1, mask=0x3),
            gc.KeyTuple('meta.engine_id', value = gc.to_bytes(engine_id, 1), mask = 0xf), 
            gc.KeyTuple('hdr.first_payload.signature_top', value=signature_top, mask=mask_top),
            gc.KeyTuple('hdr.first_payload.signature_bot', value=signature_bot, mask=mask_bot) 
        ]) 
        ]
        self.l23_outbound.entry_del(self.dev_tgt, key_list)
           

    # def setup_signature(self, signature_top=0x11223344, signature_bot=0):
    #     key_list = [
    #         self.l23_signature.make_key([
    #             gc.KeyTuple('hdr.first_payload.signature_top', signature_top, mask=0xffffffff),
    #             gc.KeyTuple('hdr.first_payload.signature_bot', signature_bot, mask=0xffffffff),
    #             gc.KeyTuple('meta.port_properties.port_type', 1 )])
    #         ]
    #     data_list = [
    #             self.l23_signature.make_data([],
    #                 'SxIngPipeline.match_signature')
    #         ]
    #     self.l23_signature.entry_add(self.dev_tgt, key_list, data_list)
    #     key_list = [
    #         self.l23_signature.make_key([
    #             gc.KeyTuple('hdr.first_payload.signature_top', signature_top, mask=0xffffffff),
    #             gc.KeyTuple('hdr.first_payload.signature_bot', signature_bot, mask=0xffffffff),
    #             gc.KeyTuple('meta.port_properties.port_type', 2)])
    #         ]
    #     data_list = [
    #             self.l23_signature.make_data([],
    #                 'SxIngPipeline.match_signature')
    #         ]
    #     self.l23_signature.entry_add(self.dev_tgt, key_list, data_list)
    
    # def setup_signature_port_type(self, porttype):
    #     if porttype == 3:
    #         # Support to insert timestamp for l47 not required
    #         # key_list = [
    #         # self.l23_signature.make_key([
    #         #     gc.KeyTuple('hdr.first_payload.signature_top', 0x0101080a, 0xffffffff),
    #         #     gc.KeyTuple('hdr.first_payload.signature_bot', 0, 0xffffffff),
    #         #     gc.KeyTuple('meta.port_properties.port_type', porttype )])
    #         # ]
    #         # data_list = [
    #         #         self.l23_signature.make_data([],
    #         #             'SxIngPipeline.insert_timestamp')
    #         #     ]
    #         # self.l23_signature.entry_add(self.dev_tgt, key_list, data_list)
    #         key_list = [ self.l23_signature.make_key([
    #             gc.KeyTuple('hdr.first_payload.signature_top', 0,0),
    #             gc.KeyTuple('hdr.first_payload.signature_bot', 0,0),
    #             gc.KeyTuple('meta.port_properties.port_type', porttype )])
    #         ]
    #         data_list = [
    #                 self.l23_signature.make_data([],
    #                     'SxIngPipeline.l47_mark')
    #             ]
    #         self.l23_signature.entry_add(self.dev_tgt, key_list, data_list)

    # def delete_signature_port_type(self, porttype):
    #     # key_list = [
    #     #     self.l23_signature.make_key([
    #     #         gc.KeyTuple('hdr.first_payload.signature_top', 0x0101080a, 0xffffffff),
    #     #         gc.KeyTuple('hdr.first_payload.signature_bot', 0, 0xffffffff),
    #     #         gc.KeyTuple('meta.port_properties.port_type', 3 )])
    #     #     ]
    #     # self.l23_signature.entry_del(self.dev_tgt, key_list)
    #     key_list = [
    #         self.l23_signature.make_key([
    #             gc.KeyTuple('hdr.first_payload.signature_top', 0,0),
    #             gc.KeyTuple('hdr.first_payload.signature_bot', 0,0),
    #             gc.KeyTuple('meta.port_properties.port_type', 3 )])
    #         ]
    #     self.l23_signature.entry_del(self.dev_tgt, key_list)

    def assign_queue_lookup(self, maxRange):
        output = 0
        for queue in range(0, 256):
            key_list = [ self.queue_mod.make_key([
                    gc.KeyTuple('sel_hash', value=gc.to_bytes(queue, 1), mask=0xff),
                    gc.KeyTuple('l47_match', gc.to_bytes(1, 1)),
                    gc.KeyTuple('prog_mod', gc.to_bytes(maxRange, 1))]) ]
            data_list = [
                self.queue_mod.make_data([
                    gc.DataTuple('output_queue', gc.to_bytes(output, 1))],
                    'SxIngPipeline.lookup_queue')
            ]
            output = output + 1
            if (output == maxRange):
                output = 0
            self.queue_mod.entry_add(self.dev_tgt, key_list, data_list)

    def delete_queue_lookup(self, maxRange=0x3f):
        for queue in range(0, 256):
            key_list = [ self.queue_mod.make_key([
                    gc.KeyTuple('sel_hash', value =gc.to_bytes(queue, 1), mask=0xff),
                    gc.KeyTuple('l47_match', gc.to_bytes(1, 1)),
                    gc.KeyTuple('prog_mod', gc.to_bytes(maxRange, 1))
                ]) ]
            self.queue_mod.entry_del(self.dev_tgt, key_list)

    # def delete_stat_index(self, igPort, index):
    #     key_list = [
    #         self.stat_tbl.make_key([
    #             gc.KeyTuple('ig_intr_md.ingress_port', gc.to_bytes(igPort,2)),
    #             gc.KeyTuple('stat_index', index)])
    #         ]
    #     self.stat_tbl.entry_del(self.dev_tgt, key_list)

    def split_vlan(self, vlan_id):
        vlan_id_top = vlan_id >>8
        vlan_id_bot = vlan_id & 0xff
        return(vlan_id_top, vlan_id_bot)

    def gen_address_range(self, address, tolerance):
        addr = 0
        for i in address:
            addr = addr << 8 | i
        top_16 = ((addr + tolerance) >> 16) & 0xffff
        compare = (addr >> 16) & 0xffff
        if top_16 > compare:
            addr_high = (addr >>16) << 16
            addr_high = addr_high | 0xffff
        else:
            addr_high = addr + tolerance
        if addr > tolerance:
            addr_low = addr - tolerance
        else:
            addr_low = 0
        print("addr={} tol ={} high={} low={}".format(hex(addr), tolerance, hex(addr_high), hex(addr_low)))
        return (addr_high, addr_low)
    
    def assign_l47_inbound(self, index, vid, igPort, priority, egPort, range_high, range_low, v6, ts, stats_index):
        print("Port {}-> Port {} cos {}".format(igPort, egPort, priority))
        (vid_top, vid_bot) = self.split_vlan(vid)
        if vid > 0:
            vlan_exist = 1
        else:
            vlan_exist = 0
        addr_0 = ( range_low >> 112 ) & 0xffff
        addr_1 = ( range_low >> 96) & 0xffff
        addr_2 = ( range_low >> 80 ) & 0xffff
        addr_3 = ( range_low >> 64 ) & 0xffff
        addr_4 = ( range_low >> 48 ) & 0xffff
        addr_5 = ( range_low >> 32 ) & 0xffff
        #EgressTernaryTbl
        addr_6 = ( range_low >> 16 ) & 0xffff
        addr_low = range_low & 0xffffffff
        addr_high = range_high & 0xffffffff
        xor_addr = (addr_low ^ addr_high)
        print("xor_addr {} addr_low {} addr_high {}".format(hex(xor_addr), hex(addr_low), hex(addr_high)))
        msb = xor_addr & 0x80000000
        ternary_mask = 0
        shift = 0
        while msb == 0 and shift < 32:
            ternary_mask = 0x80000000 | (ternary_mask >> 1)
            xor_addr = xor_addr << 1
            msb = xor_addr & 0x80000000
            shift = shift + 1
        print("ternary_mask = {}".format(hex(ternary_mask)))
        print("index:{} low:{} high:{}".format(index, hex(addr_low), hex(addr_high)))
        key_list = [
            self.l47_egress_table.make_key( [
                gc.KeyTuple('remap_addr_6', value = gc.to_bytes(addr_6, 2), mask=((ternary_mask>> 16) & 0xffff)),
                gc.KeyTuple('remap_addr_7', value = gc.to_bytes((range_low& 0xffff), 2), mask =(ternary_mask& 0xffff)),
                gc.KeyTuple('hdr.vlan_tag_0.$valid', vlan_exist ),
                gc.KeyTuple('ig_intr_md.ingress_port', gc.to_bytes(igPort, 2))
                ])
        ]
        data_list =  [
            self.l47_egress_table.make_data( [
                gc.DataTuple('match_index', index)
                ],
                'SxIngPipeline.inbound_l47_gen_lookup.map_ternary')]
        self.l47_egress_table.entry_add(self.dev_tgt, key_list, data_list)
        key_list = [
                self.l47_range_register.make_key([
                    gc.KeyTuple('$REGISTER_INDEX', index)])
            ]
        data_list = [
                self.l47_range_register.make_data([
                    gc.DataTuple("SxIngPipeline.inbound_l47_gen_lookup.range_reg.start", addr_low ),
                    gc.DataTuple("SxIngPipeline.inbound_l47_gen_lookup.range_reg.end", addr_high )
                    ])
            ]
       
        self.l47_range_register.entry_add(self.dev_tgt, key_list, data_list)

        key_list = [
            self.l47_inbound_v4.make_key( [
                gc.KeyTuple('meta.vid_top', gc.to_bytes(vid_top, 1)),
                gc.KeyTuple('meta.vid_bot', gc.to_bytes(vid_bot, 1)),
                gc.KeyTuple('remap_addr_0', gc.to_bytes(addr_0, 2)),
                gc.KeyTuple('remap_addr_1', gc.to_bytes(addr_1, 2)),
                gc.KeyTuple('remap_addr_2', gc.to_bytes(addr_2, 2)),
                gc.KeyTuple('remap_addr_3', gc.to_bytes(addr_3, 2)),
                gc.KeyTuple('remap_addr_4', gc.to_bytes(addr_4, 2)),
                gc.KeyTuple('remap_addr_5', gc.to_bytes(addr_5, 2)),
                gc.KeyTuple('ternary_match_6', index ),
                gc.KeyTuple('ig_intr_md.ingress_port', gc.to_bytes(igPort, 2))
                ])
            ]
        pcp_cfi = priority<<1
        data_list = [
            self.l47_inbound_v4.make_data( [
                gc.DataTuple('pfc_cos', gc.to_bytes((pcp_cfi), 1)),
                gc.DataTuple('timestamp_ext', gc.to_bytes(ts, 1)),
                gc.DataTuple('stats_index', stats_index),
                gc.DataTuple('egPort', gc.to_bytes(egPort, 2))
                ],
                'SxIngPipeline.inbound_l47_gen_lookup.setRangePort')
        ]
        self.l47_inbound_v4.entry_add(self.dev_tgt, key_list, data_list)
        
    def setup_l47_compare(self, delete=False):
        key_list = [ self.l47_range_compare.make_key( [
                gc.KeyTuple('range_result_2', 1),
                gc.KeyTuple('hdr.vlan_tag_0.$valid', 0)
                ])]
        data_list = [
                     self.l47_range_compare.make_data([],
                         'SxIngPipeline.inbound_l47_gen_lookup.matchRangeInsertVlan')
                 ]
        if ( delete ):
            self.l47_range_compare.entry_del(self.dev_tgt, key_list)
        else:
            self.l47_range_compare.entry_add(self.dev_tgt, key_list, data_list)
        key_list = [ self.l47_range_compare.make_key( [
                gc.KeyTuple('range_result_2', 1),
                gc.KeyTuple('hdr.vlan_tag_0.$valid', 1)
                ])]
        data_list = [
                     self.l47_range_compare.make_data([],
                         'SxIngPipeline.inbound_l47_gen_lookup.matchRangeWithVlan')
                 ]
        if ( delete ):
            self.l47_range_compare.entry_del(self.dev_tgt, key_list)
        else:
            self.l47_range_compare.entry_add(self.dev_tgt, key_list, data_list)
    

    def delete_l47_inbound(self, index, vid, igPort, range_high, range_low, v6):
        (vid_top, vid_bot) = self.split_vlan(vid)
        if vid > 0:
            vlan_exist = 1
        else:
            vlan_exist = 0
        addr_0 = ( range_low >> 112 ) & 0xffff
        addr_1 = ( range_low >> 96) & 0xffff
        addr_2 = ( range_low >> 80 ) & 0xffff
        addr_3 = ( range_low >> 64 ) & 0xffff
        addr_4 = ( range_low >> 48 ) & 0xffff
        addr_5 = ( range_low >> 32 ) & 0xffff
        addr_6 = ( range_low >> 16 ) & 0xffff
        addr_low = range_low & 0xffffffff
        addr_high = range_high & 0xffffffff
        xor_addr = (addr_low ^ addr_high)
        print("xor_addr {} addr_low {} addr_high {}".format(hex(xor_addr), hex(addr_low), hex(addr_high)))
        msb = xor_addr & 0x80000000
        ternary_mask = 0
        shift = 0
        while msb == 0 and shift < 32:
            ternary_mask = 0x80000000 | (ternary_mask >> 1)
            xor_addr = xor_addr << 1
            msb = xor_addr & 0x80000000
            shift = shift + 1
        print("ternary_mask = {}".format(hex(ternary_mask)))
        key_list = [
            self.l47_egress_table.make_key( [
                gc.KeyTuple('remap_addr_6', value = gc.to_bytes(addr_6, 2), mask=((ternary_mask>> 16) & 0xffff)),
                gc.KeyTuple('remap_addr_7', value = gc.to_bytes((range_low& 0xffff), 2), mask =(ternary_mask& 0xffff)),
                gc.KeyTuple('hdr.vlan_tag_0.$valid', vlan_exist ),
                gc.KeyTuple('ig_intr_md.ingress_port', gc.to_bytes(igPort, 2))
                ])
        ]
        self.l47_egress_table.entry_del(self.dev_tgt, key_list)
        key_list = [
            self.l47_inbound_v4.make_key( [
                gc.KeyTuple('meta.vid_top', gc.to_bytes(vid_top, 1)),
                gc.KeyTuple('meta.vid_bot', gc.to_bytes(vid_bot, 1)),
                gc.KeyTuple('remap_addr_0', gc.to_bytes(addr_0, 2)),
                gc.KeyTuple('remap_addr_1', gc.to_bytes(addr_1, 2)),
                gc.KeyTuple('remap_addr_2', gc.to_bytes(addr_2, 2)),
                gc.KeyTuple('remap_addr_3', gc.to_bytes(addr_3, 2)),
                gc.KeyTuple('remap_addr_4', gc.to_bytes(addr_4, 2)),
                gc.KeyTuple('remap_addr_5', gc.to_bytes(addr_5, 2)),
                gc.KeyTuple('ternary_match_6', index ),
                gc.KeyTuple('ig_intr_md.ingress_port', gc.to_bytes(igPort, 2))
                ])
            ]
        self.l47_inbound_v4.entry_del(self.dev_tgt, key_list)

    def insert_cn_tables_ip(self, index, vlan, fp_port, priority, np_port, range_high, range_low, v6, ts, statindex):
        self.assign_l47_inbound(index, vlan, fp_port, priority, np_port, range_high, range_low, v6, \
                                  ts, statindex)

    def delete_cn_tables_ip(self, index, vlan, fp_port, range_high, range_low, v6):
        self.delete_l47_inbound(index, vlan, fp_port, range_high, range_low, v6)

    def assign_multicast_group(self, igPort, multicast_group):
        key_list = [
            self.multicast.make_key([
                gc.KeyTuple('ig_intr_md.ingress_port', gc.to_bytes(igPort,2)),
                gc.KeyTuple('l47_match',0)])
            ]
        data_list = [
            self.multicast.make_data([
                gc.DataTuple('mcg', gc.to_bytes(multicast_group, 2))],
                'SxIngPipeline.set_mcast_grp')
            ]
        self.multicast.entry_add(self.dev_tgt, key_list, data_list)
        print("Assign {} mcast {}".format(igPort, multicast_group))

    def assign_mirror_session(self, igPort, mirror_session, l47_port):
        key = self.multicast.make_key([
            gc.KeyTuple('ig_intr_md.ingress_port', gc.to_bytes(igPort,2)),
            gc.KeyTuple('ig_intr_prsr_md.parser_err', value=gc.to_bytes(2,2), mask=0x0002),
            gc.KeyTuple('l47_match', value=gc.to_bytes(0,1), mask=0x1),
            gc.KeyTuple('l23_match', value=gc.to_bytes(0,0), mask=0x1)]
            )
        data = self.multicast.make_data([
            gc.DataTuple('mirror_session', mirror_session),
            gc.DataTuple('l47_port', gc.to_bytes(l47_port,1))],
            "SxIngPipeline.set_mirror_session")
        self.multicast.entry_add(self.dev_tgt, [key], [data])

    def assign_ingress_capture_session(self, port, capture_group, rich_register, mirror_session):
        '''sets up which port to mirror and capture group + rich register -> mirror session'''
        print("Assign port {} with capture_group {}".format(port, capture_group))
        key = self.ingressMirror.make_key([
            gc.KeyTuple('ig_intr_md.ingress_port', gc.to_bytes(port,2)),
            gc.KeyTuple('meta.port_properties.capture_group', gc.to_bytes(capture_group,1)),
            gc.KeyTuple('rich_register', gc.to_bytes(rich_register,1)),   
            ])
        data = self.ingressMirror.make_data([
            gc.DataTuple('mirror_session', mirror_session)],
            "SxIngPipeline.set_capture_mirror_session")
        self.ingressMirror.entry_add(self.dev_tgt, [key], [data])

    def delete_ingress_capture_session(self, port, capture_group, rich_register):
        '''delete port to mirror and capture group + rich register -> mirror session'''
        print("delete port {} with capture group {}".format(port, capture_group))
        key = self.ingressMirror.make_key([
            gc.KeyTuple('ig_intr_md.ingress_port', gc.to_bytes(port,2)),
            gc.KeyTuple('meta.port_properties.capture_group', gc.to_bytes(capture_group,1)),
            gc.KeyTuple('rich_register', gc.to_bytes(rich_register,1)),   
            ])
        self.ingressMirror.entry_del(self.dev_tgt, [key])

    def assign_egress_capture_group(self, port, capture_group):
        key = self.egressCaptureGroup.make_key([
            gc.KeyTuple('ig_intr_tm_md.ucast_egress_port', gc.to_bytes(port,2))
        ])
        data = self.egressCaptureGroup.make_data([gc.DataTuple('group', capture_group)],
            "SxIngPipeline.do_set_egress_group")
        self.egressCaptureGroup.entry_add(self.dev_tgt, [key], [data])

    def delete_egress_capture_group(self, port, capture_group):
        key = self.egressCaptureGroup.make_key([
            gc.KeyTuple('ig_intr_tm_md.ucast_egress_port', gc.to_bytes(port,2))
        ])
        self.egressCaptureGroup.entry_del(self.dev_tgt, [key])

    def assign_egress_capture_session(self, port, capture_group, rich_register, mirror_session):
        print("Assign port {} with capture_group {}".format(port, capture_group))
        key = self.egressCapture.make_key([
            gc.KeyTuple('eg_intr_md.egress_port', gc.to_bytes(port,2)),
            gc.KeyTuple('eg_md.bridge.capture_group', gc.to_bytes(capture_group,1)),
            gc.KeyTuple('rich_register', gc.to_bytes(rich_register,1)),   
            ])
        data = self.egressCapture.make_data([
            gc.DataTuple('mirror_session', mirror_session)],
            "SxEgrPipeline.set_capture_mirror_session")
        self.egressCapture.entry_add(self.dev_tgt, [key], [data])

    def delete_egress_capture_session(self, port, capture_group, rich_register):
        print("Delete port {} with capture group {}".format(port, capture_group))
        key = self.egressCapture.make_key([
            gc.KeyTuple('eg_intr_md.egress_port', gc.to_bytes(port,2)),
            gc.KeyTuple('eg_md.bridge.capture_group', gc.to_bytes(capture_group,1)),
            gc.KeyTuple('rich_register', gc.to_bytes(rich_register,1)),   
            ])
        self.egressCapture.entry_del(self.dev_tgt, [key])

    def get_latency(self, index):
        latency_lo = 0
        latency_hi = 0
        for bank_index in [index]:
            index_key = [
               self.latency_stat.make_key([
                    gc.KeyTuple('$REGISTER_INDEX', bank_index)])
                ]
            data, _ = next(self.latency_stat.entry_get(
                    self.dev_tgt,
                    index_key,
                    flags = {"from_hw": True}))
            
            for i in range(0,4):
                lat_lo = int(data.to_dict()["SxIngPipeline.latency_stat.l47_latencyB.data_storage.lo"][i])
                lat_hi = int(data.to_dict()["SxIngPipeline.latency_stat.l47_latencyB.data_storage.hi"][i])
                latency_lo =  latency_lo + lat_lo
                latency_hi =  latency_hi + lat_hi
                print("Counter {}:{} sum_lo:{}".format(i,  lat_lo, latency_lo))
                print("Counter {}:{} sum_hi:{}".format(i,  lat_hi, latency_hi))
        return (latency_hi , latency_lo)

    def get_min_latency(self, index):
        latency = 0
        for bank_index in [index]:
            index_key = [
               self.min_latency_stat.make_key([
                    gc.KeyTuple('$REGISTER_INDEX', bank_index)])
                ]
            data, _ = next(self.min_latency_stat.entry_get(
                    self.dev_tgt,
                    index_key,
                    flags = {"from_hw": True}))
            
            for i in range(0,4):
                lat = int(data.to_dict()["SxIngPipeline.latency_stat.store_lat_minB.f1"][i])
                if ( latency == 0 or latency > lat):
                    latency = lat
                print("Counter {}:{} sum:{}".format(i,  lat, latency))
        return latency

    def get_max_latency(self, index):
        latency = 0
        for bank_index in [index]:
            index_key = [
               self.max_latency_stat.make_key([
                    gc.KeyTuple('$REGISTER_INDEX', bank_index)])
                ]
            data, _ = next(self.max_latency_stat.entry_get(
                    self.dev_tgt,
                    index_key,
                    flags = {"from_hw": True}))
            for i in range(0,4):
                lat = int(data.to_dict()["SxIngPipeline.latency_stat.store_lat_maxB.f1"][i])
                if (latency < lat):
                    latency = lat
                print("Counter {}:{} sum:{}".format(i,  lat, latency))
        return latency

    def get_flow(self, index):
        pkt_count = 0
        for bank_index in [index]:
            counter_key = [
                self.flow_stat.make_key([
                    gc.KeyTuple('$REGISTER_INDEX', bank_index)])
                ]
            data, _ = next(self.flow_stat.entry_get(
                    self.dev_tgt,
                    counter_key,
                    flags = {"from_hw": True}))
            
            for i in range(0,4):
                count =  int(data.to_dict()["SxIngPipeline.latency_stat.store_pktB.f1"][i])
                pkt_count = pkt_count + count
                print("Counter {}:{} sum:{}".format(i, count, pkt_count))
        return pkt_count


    def gen_parity_lookup(self):
        self.capture_parity_lookup = [parallel_swar(i) for i in range(2048)]

    def parity_lookup(self, v):
        v ^= v >> 16
        v ^= v >> 8
        return self.capture_parity_lookup[v & 0xff]

    def program_parity(self):
        self.gen_parity_lookup()
        for i in range(0, 2048):
            calculated_ov = (i& 0x7ff)<<1 
            calculated_ov |= self.parity_lookup(i)
            key = self.overheadTbl.make_key([
                gc.KeyTuple('eg_md.ing_port_mirror.capture_seq_no', gc.to_bytes(i,2))])
            data = self.overheadTbl.make_data([
                gc.DataTuple('calculated', gc.to_bytes(calculated_ov,2))],
                "SxEgrPipeline.insert_capture_parity")
            self.overheadTbl.entry_add(self.dev_tgt, [key], [data])

    def verify_checksum(self, pkt, protocol):
        """
        Input pkt has to be a scapy packet ,protocol can be either UDP or TCP
        """
        if isinstance(pkt, scapy.packet.Packet):
            # Dissect this packet as if it were an instance of
            # the expected packet's class.
            scapy.packet.ls(pkt)
            originalChecksum = pkt[protocol].chksum
            del pkt[protocol].chksum
            pkt = Ether(bytes(pkt))
            #scapy.packet.ls(pkt)
            #recompute not recalculated !!!
            recomputedChecksum = pkt[protocol].chksum
            self.assertTrue(recomputedChecksum == originalChecksum)

    """CAPTURE PING PONG"""        
    def update_ping_pong_reg(self, register_index, value):
        for register, name in zip(self.ping_pong_registers, self.ping_pong_name):
            key = [
                register.make_key([
                    gc.KeyTuple('$REGISTER_INDEX', register_index)])
            ]
            data_name = "{}.f1".format(name)
            data = [
                register.make_data([
                    gc.DataTuple(data_name, value)
                    ])
            ]
            print("Add {} data {} index {} value {}".format(name, data_name, \
                register_index, value))
            register.entry_add(self.dev_tgt, key, data)

    def get_ping_pong_reg(self, register_index):
        for register, name in zip(self.ping_pong_registers, self.ping_pong_name):
            index_key = [
               register.make_key([
                    gc.KeyTuple('$REGISTER_INDEX', register_index)])
                ]
            data, _ = next(register.entry_get(
                    self.dev_tgt,
                    index_key,
                    flags = {"from_hw": True}))
            data_name = "{}.f1".format(name)
            for i in range(0, 4):
                queue = int(data.to_dict()[data_name][i])
                #print("{} pipe {}, index {}, queue depth {}".format(name, i, register_index, queue))

    
    def read_ping_pong_tables(self, pipe_id, queue_id):
        for table, action in zip(self.ping_pong_tables, self.ping_pong_action):
            key = [
               table.make_key([
                    gc.KeyTuple('g_intr_md.pipe_id', pipe_id), 
                    gc.KeyTuple('g_intr_md.qid', queue_id)])
                ]
            print("{}".format(action))
            data = table.make_data([gc.DataTuple("idx")], action_name=action, get=True)
            resp = table.entry_get(self.dev_tgt, key, {"from_hw": False}, \
                   data)
            data_dict = next(resp)[0].to_dict()
            #print("{}".format(data_dict))

    def update_rx_capture_seq_no_reg(self, capture_group, sequence_no):
        key = [
            self.rx_sequence_number_reg.make_key([
                gc.KeyTuple('$REGISTER_INDEX', capture_group)])
        ]
        data_name = "{}.f1".format(self.rx_sequence_number_reg_name)
        data = [
            self.rx_sequence_number_reg.make_data([
                gc.DataTuple(data_name, sequence_no)
                ])
        ]
        print("Add {} data {} index {} value {}".format(name, data_name, \
                capture_group, sequence_no))
        self.rx_sequence_number_reg.entry_add(self.dev_tgt, key, data)

    def update_tx_capture_seq_no_reg(self, capture_group, sequence_no):
        key = [
            self.tx_sequence_number_reg.make_key([
                gc.KeyTuple('$REGISTER_INDEX', capture_group)])
        ]
        data_name = "{}.f1".format(self.tx_sequence_number_reg_name)
        data = [
            self.tx_sequence_number_reg.make_data([
                gc.DataTuple(data_name, sequence_no)
                ])
        ]
        print("Add {} data {} index {} value {}".format(name, data_name, \
                capture_group, sequence_no))
        self.tx_sequence_number_reg.entry_add(self.dev_tgt, key, data)


    def match_exp_pkt(exp_pkt, pkt):
        """
        Compare the string value of pkt with the string value of exp_pkt,
        and return True iff they are identical.  If the length of exp_pkt is
        less than the minimum Ethernet frame size (60 bytes), then padding
        bytes in pkt are ignored.
        """
        if isinstance(exp_pkt, mask.Mask):
            if not exp_pkt.is_valid():
                return False
            return exp_pkt.pkt_match(pkt)
        e = str(exp_pkt)
        p = str(pkt)
        if len(e) < 60:
            p = p[:len(e)]
        return e == p

#
# Helper functions for Tofino. We could've put them into a separate file, but
# that would complicate shipping. If their number grows, we'll do something
#
def to_devport(pipe, port):
    """
    Convert a (pipe, port) combination into a 9-bit (devport) number
    NOTE: For now this is a Tofino-specific method
    """
    return pipe << 7 | port

def to_pipeport(dp):
    """
    Convert a physical 9-bit (devport) number into (pipe, port) pair
    NOTE: For now this is a Tofino-specific method
    """
    return (dp >> 7, dp & 0x7F)

def devport_to_mcport(dp):
    """
    Convert a physical 9-bit (devport) number to the index that is used by
    MC APIs (for bitmaps mostly)
    NOTE: For now this is a Tofino-specific method
    """
    (pipe, port) = to_pipeport(dp)
    return pipe * 72 + port

def mcport_to_devport(mcport):
    """
    Convert a MC port index (mcport) to devport
    NOTE: For now this is a Tofino-specific method
    """
    return to_devport(mcport / 72, mcport % 72)

def devports_to_mcbitmap(devport_list):
    """
    Convert a list of devports into a Tofino-specific MC bitmap
    """
    bit_map = [0] * int((288 + 7) / 8)
    for dp in devport_list:
        mc_port = devport_to_mcport(dp)
        bit_map[int(mc_port / 8)] |= (1 << (mc_port % 8))
    return bytes_to_string(bit_map)

def mcbitmap_to_devports(mc_bitmap):
    """
    Convert a MC bitmap of mcports to a list of devports
    """
    bit_map = string_to_bytes(mc_bitmap)
    devport_list = []
    for i in range(0, len(bit_map)):
        for j in range(0, 8):
            if bit_map[i] & (1 << j) != 0:
                devport_list.append(mcport_to_devport(i * 8 + j))
    return devport_list

def lags_to_mcbitmap(lag_list):
    """
    Convert a list of LAG indices to a MC bitmap
    """
    bit_map = [0] * int((256 + 7) / 8)
    for lag in lag_list:
        bit_map[int(lag / 8)] |= (1 << (lag % 8))
    return bytes_to_string(bit_map)

def mcbitmap_to_lags(mc_bitmap):
    """
    Convert an MC bitmap into a list of LAG indices
    """
    bit_map = string_to_bytes(mc_bitmap)
    lag_list = []
    for i in range(0, len(bit_map)):
        for j in range(0, 8):
            if bit_map[i] & (1 << j) != 0:
                devport_list.append(i * 8 + j)
    return lag_list
