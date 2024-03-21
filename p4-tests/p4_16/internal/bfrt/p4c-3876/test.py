################################################################################
# BAREFOOT NETWORKS CONFIDENTIAL & PROPRIETARY
#
# Copyright (c) 2018-2019 Barefoot Networks, Inc.

# All Rights Reserved.
#
# NOTICE: All information contained herein is, and remains the property of
# Barefoot Networks, Inc. and its suppliers, if any. The intellectual and
# technical concepts contained herein are proprietary to Barefoot Networks,
# Inc.
# and its suppliers and may be covered by U.S. and Foreign Patents, patents in
# process, and are protected by trade secret or copyright law.
# Dissemination of this information or reproduction of this material is
# strictly forbidden unless prior written permission is obtained from
# Barefoot Networks, Inc.
#
# No warranty, explicit or implicit is provided, unless granted under a
# written agreement with Barefoot Networks, Inc.
#
#
###############################################################################


"""
Simple PTF test for simple_l3_mirror
"""


######### STANDARD MODULE IMPORTS ########
import logging
import grpc
import pdb
import copy
import re
from scapy.all import *

######### PTF modules for BFRuntime Client Library APIs #######
import ptf
from ptf.testutils import *
from ptf.dataplane import *
from ptf.mask      import *

from bfruntime_client_base_tests import BfRuntimeTest
import bfrt_grpc.bfruntime_pb2 as bfruntime_pb2
import bfrt_grpc.client as gc

######## PTF modules for Fixed APIs (Thrift) ######
import pd_base_tests
from ptf.thriftutils        import *
from res_pd_rpc.ttypes      import *   # Common data types
from mirror_pd_rpc.ttypes   import *   # Mirror-specific data types

from scapy.all import *

########## Basic Initialization ############
class BaseProgramTest(BfRuntimeTest):

    #
    # This is a special class that will provide us with the interface to
    # the fixed APIs via the corresponding Thrift bindings. This particular
    # class can be used to provide access to all fixed APIs, but
    # we use it just for mirror session objects here
    #
    class FixedAPIs(pd_base_tests.ThriftInterfaceDataPlane):
        def __init__(self, p4names):
            pd_base_tests.ThriftInterfaceDataPlane.__init__(self, p4names)

        def setUp(self):
            pd_base_tests.ThriftInterfaceDataPlane.setUp(self)
            self.dev = 0
            self.dev_tgt  = DevTarget_t(self.dev, -1)
            self.sess_hdl = self.conn_mgr.client_init()
            print("Opened Connection Mgr  Session {:#08x}".
                  format(self.sess_hdl))

        def cleanUp(self):
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
            self.conn_mgr.complete_operations(self.sess_hdl)
            self.conn_mgr.client_cleanup(self.sess_hdl)
            print("  Closed ConnMgr Session {}".format(self.sess_hdl))
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
    #     ipv4_host
    #     ipv4_lpm
    def setUp(self):
        self.client_id = 0
        self.dev      = 0
        self.dev_tgt  = gc.Target(self.dev, pipe_id=0xFFFF)

        self.p4_name = "p4c_3876"

        print("\n")
        print("Test Setup")
        print("==========")

        BfRuntimeTest.setUp(self, self.client_id, self.p4_name)
        self.bfrt_info = self.interface.bfrt_info_get()

        print("    Connected to Device: {}, Program: {}, ClientId: {}".format(
            self.dev, self.p4_name, self.client_id))

        # Create a list of all ports available on the device
        self.swports = []
        for (device, port, ifname) in ptf.config['interfaces']:
            self.swports.append(port)
        self.swports.sort()
        # print("Interfaces:", ptf.config['interfaces'])
        print("    SWPorts:", self.swports)

        # Understand what are we running on
        self.arch   = test_param_get('arch')
        self.target = test_param_get('target')

        if self.arch == 'tofino':
            config_table = re.compile('tf1\..*device_configuration')
            self.dev_config = {
                'num_pipes'         : 4,
                'eth_cpu_port_list' : [64, 65, 66, 67],
                'pcie_cpu_port'     : 320
            }
        elif self.arch == 'tofino2':
            config_table = re.compile('tf2\..*device_configuration')
            self.dev_config = {
                'num_pipes'         : 4,
                'eth_cpu_port_list' : [2, 3, 4, 5],
                'pcie_cpu_port'     : 0
            }

        try:
            self.dev_conf_tbl = self.bfrt_info.table_get('device_configuration')
            # Check that there is no mismatch
            if config_table.match(self.dev_conf_tbl.info.name) == None:
                print("""
                      ERROR: You requested to run the test on '{}',
                             but the device {} only has '{}' tables in it.

                             Add '--arch {}' parameter to the command line.
                      """.format(config_table.split('.')[0],
                                 self.dev,
                                 self.dev_conf_tbl.info.name.split('.')[0],
                                 {'tf1':'tofino', 'tf2':'tofino2'}[
                                     self.dev_conf_tbl.info.name.split('.')[0]]))
                self.assertTrue(False)

            # Get the device configuration (default entry)
            resp = self.dev_conf_tbl.default_entry_get(self.dev_tgt)
            for data, _ in resp:
                self.dev_config = data.to_dict()
                break
        except KeyError:
            # Older SDE (before 9.5.0)
            pass

        self.cpu_eth_port = self.dev_config['eth_cpu_port_list'][0]

        # print('Device Configuration:')
        # for k in self.dev_config:
        #    print('{:>40s} : {}'.format(k, self.dev_config[k]))

        # Since this class is not a test per se, we can use the setup method
        # for common setup. For example, we can have our tables and annotations
        # ready
        self.ipv4_host = self.bfrt_info.table_get("Ingress.ipv4_host")
        self.ipv4_host.info.key_field_annotation_add(
            "hdr.ipv4.dst_addr", "ipv4")

        self.ipv4_lpm = self.bfrt_info.table_get("Ingress.ipv4_lpm")
        self.ipv4_lpm.info.key_field_annotation_add(
            "hdr.ipv4.dst_addr", "ipv4")

        self.ipv6_host = self.bfrt_info.table_get("Ingress.ipv6_host")
        self.ipv6_host.info.key_field_annotation_add(
            "hdr.ipv6.dst_addr", "ipv6")

        self.ipv6_lpm = self.bfrt_info.table_get("Ingress.ipv6_lpm")
        self.ipv6_lpm.info.key_field_annotation_add(
            "hdr.ipv6.dst_addr", "ipv6")

        self.nexthop     = self.bfrt_info.table_get("Ingress.nexthop")
        self.nexthop.info.data_field_annotation_add(
            "new_mac_da", "Ingress.l3_switch", "mac")
        self.nexthop.info.data_field_annotation_add(
            "new_mac_sa", "Ingress.l3_switch", "mac")

        self.ing_port_acl= self.bfrt_info.table_get("Ingress.port_acl")

        self.egr_port_acl= self.bfrt_info.table_get("Egress.port_acl")

        self.mirror_dest = self.bfrt_info.table_get("Egress.mirror_dest")
        self.mirror_dest.info.data_field_annotation_add(
            "dst_mac", "Egress.send_to_cpu_ing_mirror", "mac")
        self.mirror_dest.info.data_field_annotation_add(
            "src_mac", "Egress.send_to_cpu_ing_mirror", "mac")
        self.mirror_dest.info.data_field_annotation_add(
            "dst_mac", "Egress.send_to_cpu_egr_mirror", "mac")
        self.mirror_dest.info.data_field_annotation_add(
            "src_mac", "Egress.send_to_cpu_egr_mirror", "mac")

        self.mirror_cfg  = self.bfrt_info.table_get("$mirror.cfg")

        self.tables = [
            # Ingress
            self.ipv4_host, self.ipv4_lpm,
            self.ipv6_host, self.ipv6_lpm,
            self.nexthop,
            self.ing_port_acl,
            # Egress
            self.egr_port_acl,
            self.mirror_dest,
            # Fixed
            self.mirror_cfg
        ]

        # Create a list of all ports available on the device
        self.swports = []
        for (device, port, ifname) in ptf.config['interfaces']:
            self.swports.append(port)
        self.swports.sort()

        ###### FIXED API SETUP #########
        self.fixed = self.FixedAPIs([self.p4_name])
        self.fixed.setUp()

        # Optional, but highly recommended
        self.cleanUp()

    # Use Cleanup Method to clear the tables before and after the test starts
    # (the latter is done as a part of tearDown()
    def cleanUp(self):
        print("\n")
        print("Table Cleanup:")
        print("==============")

        try:
            for t in self.tables:
                print("  Clearing Table {}".format(t.info.name_get()))
                keys = []
                for (d, k) in t.entry_get(self.dev_tgt):
                    if k is not None:
                        keys.append(k)
                t.entry_del(self.dev_tgt, keys)
                # Not all tables support default entry
                try:
                    t.default_entry_reset(self.dev_tgt)
                except:
                    pass
        except Exception as e:
            print("Error cleaning up: {}".format(e))

        # CleanUp Fixed API objects
        self.fixed.cleanUp()

    # Use tearDown() method to return the DUT to the initial state by cleaning
    # all the configuration and clearing up the connection
    def tearDown(self):
        print("\n")
        print("Test TearDown:")
        print("==============")

        self.cleanUp()

        # Call the Parent tearDown
        BfRuntimeTest.tearDown(self)
        self.fixed.tearDown()

# ATTENTION:
# ----------
# ToCpu Header Definition (it must match simple_l3_mirror.p4). If you modified
# the header or the ethertype, you need change this definition as well.
from scapy.all import *

class ToCpu(Packet):
    name = "to_cpu header from simple_l3_mirror.p4"
    header_type_enum = { 0xA: "resubmit",       0xB: "Bridge",
                         0xC: "Ingress Mirror", 0xD: "Egress Mirror" }

    fields_desc = [ BitEnumField("header_type",       0,  4, header_type_enum),
                    BitField("header_info",           0,  4),

                    BitField("ingress_port",          0, 16),
                    BitField("egress_port",           0, 16),
                    BitField("mirror_session",        0, 16),

                    BitField("pkt_length",            0, 16),
                    BitField("ingress_mac_tstamp",    0, 48),
                    BitField("ingress_global_tstamp", 0, 48),
                    BitField("egress_global_tstamp",  0, 48),
                    BitField("mirror_global_tstamp",  0, 48),

                    BitField("pad3",                  0,  5),
                    BitField("enq_qdepth",            0, 19),
                    BitField("pad4",                  0,  6),
                    BitField("enq_congest_stat",      0,  2),

                    BitField("pad6",                  0,  5),
                    BitField("deq_qdepth",            0, 19),
                    BitField("pad7",                  0,  6),
                    BitField("deq_congest_stat",      0,  2),

                    BitField("app_pool_congest_stat", 0,  8),

                    BitField("pad8",                  0, 14),
                    BitField("deq_timedelta",         0, 18),

                    BitField("pad9",                  0,  3),
                    BitField("egress_qid",            0,  5),

                    BitField("pad10",                 0,  5),
                    BitField("egress_cos",            0,  3),

                    BitField("pad11",                 0,  7),
                    BitField("deflection_flag",       0,  1)
    ]

bind_layers(Ether, ToCpu, type=0xBF01)
bind_layers(ToCpu, Ether)

########################################################################
########    Running Multiple Tests with the same setup   ###############
########################################################################

# This is a setup for a group of tests that do the following:
#  -- One ipv4_host/nexthop entry that performs an l3 switching of a packet
#     (i.e. the packet will be modified so that we can see what's going on)
class BaseIPv4Group(BaseProgramTest):
    def setUp(self):
        BaseProgramTest.setUp(self)

        # This group requires just 2 test ports
        self.ingress_port   = self.swports[test_param_get("ingress_port", 0)]
        self.egress_port    = self.swports[test_param_get("egress_port",  1)]

        # Basic switching setup for a single IPv4 destination address
        self.ipv4_dst       = test_param_get("ipv4_dst",   "192.168.1.1")
        self.nexthop_id     = test_param_get("nexthop_id",  100)
        self.new_mac_da     = test_param_get("new_mac_da", "00:12:34:56:78:9A")
        self.new_mac_sa     = test_param_get("new_mac_sa", "00:00:AA:BB:CC:DD")

        print("\n")
        print("Test Setup (BaseIPv4Group)")
        print("==========================")

        #
        # Program an entry in nexthop:
        #       nexthop_id --> l3_switch(egress_port. new_mac_da, new_mac_da)
        #
        key = self.nexthop.make_key([
            gc.KeyTuple('nexthop_id', self.nexthop_id)])

        data = self.nexthop.make_data([
            gc.DataTuple('port',       self.egress_port),
            gc.DataTuple('new_mac_da', self.new_mac_da),
            gc.DataTuple('new_mac_sa', self.new_mac_sa)],
            "Ingress.l3_switch")

        self.nexthop.entry_add(self.dev_tgt, [key], [data]);
        print("  Added an entry to nexthop: {} --> l3_switch({}, {}, {})".
              format(self.nexthop_id, self.egress_port,
                     self.new_mac_da, self.new_mac_sa))

        #
        # Program an entry in IPv4: ipv4_dst --> set_nexthop(nexthop_id)
        #
        key = self.ipv4_host.make_key([
            gc.KeyTuple('hdr.ipv4.dst_addr', self.ipv4_dst)])

        data = self.ipv4_host.make_data([
            gc.DataTuple('nexthop', self.nexthop_id)], "Ingress.set_nexthop")

        self.ipv4_host.entry_add(self.dev_tgt, [key], [data])
        print("  Added an entry to ipv4_host: {} --> set_nexthop({})".
              format(self.ipv4_dst, self.nexthop_id))

# This is a setup for ingress mirroring that sends a packet with the
# Ether()/ToCpu() headers to CPU. The packet should ingress on
# mirror_ingress_port. It will be picked up by ingress port_acl table and
# mirrored to the mirror session mirror_id. Additionally, the packet might
# be truncated to egress_max_len bytes
class IngMirrorCpuGroup(BaseIPv4Group):
    def setUp(self):
        BaseIPv4Group.setUp(self)

        # This test requires two extra ports compared to Base IPv4Group
        self.mirror_ingress_port = self.swports[
            test_param_get("mirror_ingress_port", 2)]
        self.mirror_port         = self.swports[
            test_param_get("mirror_port",         3)]

        self.mirror_id           = test_param_get("mirror_id",       5)
        self.egress_max_len      = test_param_get("egress_max_len", 80)
        self.cpu_dst_mac         = test_param_get("cpu_dst_mac",
                                                  "FF:FF:FF:FF:FF:FF")
        self.cpu_src_mac         = test_param_get("cpu_src_mac",
                                                  "AA:AA:AA:AA:AA:AA")

        # These two parameters are highly program dependent !!!
        #   -- sizeInBytes(ing_port_mirror_h)
        #   -- ING_PORT_MIRROR
        self.mirror_hdr_len      = test_param_get("mirror_hdr_len", 17)
        self.header_info         = test_param_get("header_info",     3)

        #
        # Program an entry in mirror_dest to add Ether()/ToCpu() encapsulation
        #
        key = self.mirror_dest.make_key([
            gc.KeyTuple('meta.ing_mirrored',   1,  1),
            gc.KeyTuple('meta.egr_mirrored',   0,  1),
            gc.KeyTuple('meta.mirror_session', self.mirror_id)])

        data = self.mirror_dest.make_data(
            [
                gc.DataTuple('dst_mac', self.cpu_dst_mac),
                gc.DataTuple('src_mac', self.cpu_src_mac)
            ],
            "Egress.send_to_cpu_ing_mirror")

        self.mirror_dest.entry_add(self.dev_tgt, [key], [data])
        print(
            "  Added an entry to mirror_dest: {} --> send_to_cpu_ing_mirror()".
            format(self.mirror_id))

        # Calculating max_pkt_len for the mirror destination.
        #
        # The device will truncate the packet when it egresses from the TM
        # to max_pkt_len. This size inculde the mirror header (ing_port_mirror),
        # which will be stripped. Instead, the program will prepend an Ethernet
        # header and the ToCpu header to the packet.
        #
        # Thus, we have the following equation:
        #   egress_max_len = max_pkt_len - mirror_hdr_len
        #                    + len(Ether()) + len(ToCpu()) # +4 for FCS
        # From there, we have the formula to calculate max_pkt_len

        max_pkt_len = self.egress_max_len - (
            len(Ether()/ToCpu()) - self.mirror_hdr_len)

        # Tofino2 can only truncate at 4-byte boundary (DRV-4909)
        if self.arch == 'tofino2':
            self.egress_max_len -= (max_pkt_len % 4)
            max_pkt_len &= ~3

        self.fixed.mirror.mirror_session_create(
            self.fixed.sess_hdl, self.fixed.dev_tgt,
            MirrorSessionInfo_t(
                mir_type    = MirrorType_e.PD_MIRROR_TYPE_NORM,
                direction   = Direction_e.PD_DIR_INGRESS,
                mir_id      = self.mirror_id,
                egr_port    = self.mirror_port,
                egr_port_v  = True,
                max_pkt_len = max_pkt_len))

        print("  Added a mirror session {} --> port({}) (truncate at {} bytes)".
              format(self.mirror_id, self.mirror_port, max_pkt_len))

        # Add the entry to the Inress port_acl table, to mirror the packets
        # ingressing on mirror_ingress_port
        key = self.ing_port_acl.make_key([
            gc.KeyTuple('ig_intr_md.ingress_port', self.mirror_ingress_port, 0x1FF),
            gc.KeyTuple('$MATCH_PRIORITY',         1)])

        data = self.ing_port_acl.make_data([
            gc.DataTuple('mirror_session', self.mirror_id)],
            "Ingress.acl_drop_and_mirror")

        self.ing_port_acl.entry_add(self.dev_tgt, [key], [data])
        print("  Added an entry to Ingress port_acl: {} --> acl_drop_and_mirror({})".
              format(self.mirror_ingress_port, self.mirror_id))


# This is a setup for egress mirroring that sends a packet with the
# Ether()/ToCpu() headers to CPU. The packet should ingress on
# mirror_ingress_port. It will be picked up by egress port_acl table and
# mirrored to the mirror session mirror_id. Additionally, the packet might
# be truncated to egress_max_len bytes
class EgrMirrorCpuGroup(BaseIPv4Group):
    def setUp(self):
        BaseIPv4Group.setUp(self)

        # This test requires two extra ports, compared to BaseIPv4Group
        self.mirror_ingress_port = self.swports[
            test_param_get("mirror_ingress_port",   2)]
        self.mirror_port         = self.swports[
            test_param_get("mirror_port",           3)]

        self.mirror_id           = test_param_get("mirror_id",       7)
        self.egress_max_len      = test_param_get("egress_max_len",180)
        self.cpu_dst_mac         = test_param_get("cpu_dst_mac", "FF:FF:FF:FF:FF:FF")
        self.cpu_src_mac         = test_param_get("cpu_src_mac", "CC:CC:CC:CC:CC:CC")

        # These two parameters are highly program dependent
        #   * sizeInBytes(egr_port_mirror_h) -- this one depends on
        #      -DFLEXIBLE_HEADERS and -DTOFINO_TELEMETRY. Watch out!
        #   * EGR_PORT_MIRROR
        self.mirror_hdr_len      = test_param_get("mirror_hdr_len", 27)
        self.header_info         = test_param_get("header_info",     5)

        #
        # Program an entry in mirror_dest to add Ether()/ToCpu() encapsulation
        #
        key = self.mirror_dest.make_key([
            gc.KeyTuple('meta.ing_mirrored',   0,  1),
            gc.KeyTuple('meta.egr_mirrored',   1,  1),
            gc.KeyTuple('meta.mirror_session', self.mirror_id)])

        data = self.mirror_dest.make_data(
            [
                gc.DataTuple('dst_mac', self.cpu_dst_mac),
                gc.DataTuple('src_mac', self.cpu_src_mac)
            ],
            "Egress.send_to_cpu_egr_mirror")

        self.mirror_dest.entry_add(self.dev_tgt, [key], [data])
        print("  Added an entry to mirror_dest: {} --> send_to_cpu_ing_mirror()".
              format(self.mirror_id))

        # Calculating max_pkt_len for the mirror destination.
        #
        # The device will truncate the packet when it egresses from the TM
        # to max_pkt_len. This size inculde the mirror header (ing_port_mirror),
        # which will be stripped. Instead, the program will prepend an Ethernet
        # header and the ToCpu header to the packet.
        #
        # Thus, we have the following equation:
        #   egress_max_len = max_pkt_len - mirror_hdr_len
        #                    + len(Ether()) + len(ToCpu()) # +4 for FCS
        # From there, we have the formula to calculate max_pkt_len

        max_pkt_len = self.egress_max_len - len(Ether()/ToCpu()) + self.mirror_hdr_len

        self.fixed.mirror.mirror_session_create(
            self.fixed.sess_hdl, self.fixed.dev_tgt,
            MirrorSessionInfo_t(
                mir_type    = MirrorType_e.PD_MIRROR_TYPE_NORM,
                direction   = Direction_e.PD_DIR_EGRESS,
                mir_id      = self.mirror_id,
                egr_port    = self.mirror_port,
                egr_port_v  = True,
                max_pkt_len = max_pkt_len))

        print("  Added a mirror session {} --> port({}) (truncate at {} bytes)".
              format(self.mirror_id, self.mirror_port, max_pkt_len))

        # Add the entry to the Egress port_acl table, so that packets that
        # ingressed on mirror_ingress_port are egress_mirrored
        key = self.egr_port_acl.make_key([
            gc.KeyTuple('meta.bridge.ingress_port', self.mirror_ingress_port, 0x1FF),
            gc.KeyTuple('$MATCH_PRIORITY',         1)])

        data = self.egr_port_acl.make_data([
            gc.DataTuple('mirror_session', self.mirror_id)],
            "Egress.acl_drop_and_mirror")

        self.egr_port_acl.entry_add(self.dev_tgt, [key], [data])
        print("  Added an entry to Egress port_acl: {} --> acl_drop_and_mirror({})".
              format(self.mirror_ingress_port, self.mirror_id))

############################################################################
################# I N D I V I D U A L    T E S T S #########################
############################################################################

# A helper function, replacing verify_packet() until it is fixed
def verify_packet_with_result(test, pkt, port_id, timeout=2):
    """
    Check that an expected packet is received
    port_id can either be a single integer (port_number on default device 0)
    or a tuple of 2 integers (device_number, port_number)
    """
    if timeout==None:
        timeout=2
    device, port = port_to_tuple(port_id)
    logging.debug("Checking for pkt on device %d, port %d", device, port)
    result = dp_poll(test, device_number=device, port_number=port,
                     timeout=timeout, exp_pkt=pkt)
    if isinstance(result, test.dataplane.PollFailure):
        test.fail("Expected packet was not received on device %d, port %r.\n%s"
                    % (device, port, result.format()))
    return result

class IPv4ToCpuIng(IngMirrorCpuGroup):
    def runTest(self):
        pktlen = test_param_get("pktlen", 200)

        print("\n")
        print("Test Run")
        print("========")

        encap_len = len(Ether()/ToCpu())

        send_pkt = simple_tcp_packet(eth_dst="00:98:76:54:32:10",
                                     eth_src='00:55:55:55:55:55',
                                     ip_dst=self.ipv4_dst,
                                     ip_id=101,
                                     ip_ttl=64,
                                     ip_ihl=5,
                                     pktlen=pktlen)

        # Create the modified packet with the cpu_ethernet and to_cpu headers
        exp_pkt = copy.deepcopy(send_pkt)
        exp_pkt = Ether() / ToCpu() / exp_pkt
        exp_pkt[Ether].dst = self.cpu_dst_mac
        exp_pkt[Ether].src = self.cpu_src_mac
        exp_pkt[ToCpu].header_type    = "Ingress Mirror"
        exp_pkt[ToCpu].header_info    = self.header_info
        exp_pkt[ToCpu].pad0           = 0
        exp_pkt[ToCpu].ingress_port   = self.mirror_ingress_port
        exp_pkt[ToCpu].pad0           = 0
        exp_pkt[ToCpu].egress_port    = 0 # We do not know it for ingress mirroring
        exp_pkt[ToCpu].pad2           = 0
        exp_pkt[ToCpu].mirror_session = self.mirror_id

        if pktlen + encap_len > self.egress_max_len:
            exp_pkt = Ether(bytes(exp_pkt)[0:self.egress_max_len])
        exp_pkt[ToCpu].pkt_length     = 0 # We do not know it for ingress mirroring

        # Mask out the timestamps -- we do not know what they will be
        exp_pkt = Mask(exp_pkt)
        exp_pkt.set_do_not_care_scapy(ToCpu, "ingress_mac_tstamp")
        exp_pkt.set_do_not_care_scapy(ToCpu, "ingress_global_tstamp")
        exp_pkt.set_do_not_care_scapy(ToCpu, "egress_global_tstamp")
        exp_pkt.set_do_not_care_scapy(ToCpu, "mirror_global_tstamp")

        # Note that we didn't set don't care on padding -- they should be 0
        exp_pkt.set_do_not_care_scapy(ToCpu, "enq_qdepth")
        exp_pkt.set_do_not_care_scapy(ToCpu, "enq_congest_stat")
        exp_pkt.set_do_not_care_scapy(ToCpu, "deq_qdepth")
        exp_pkt.set_do_not_care_scapy(ToCpu, "deq_congest_stat")
        exp_pkt.set_do_not_care_scapy(ToCpu, "app_pool_congest_stat")
        exp_pkt.set_do_not_care_scapy(ToCpu, "deq_timedelta")
        exp_pkt.set_do_not_care_scapy(ToCpu, "egress_qid")
        exp_pkt.set_do_not_care_scapy(ToCpu, "egress_cos")

        # We know that deflection flag should be 0
        # exp_pkt.set_do_not_care_scapy(ToCpu, "deflection_flag")

        #
        # Send a test packet
        #
        print("  Sending packet with IPv4 DST ADDR={} into port {}"
              .format(self.ipv4_dst, self.mirror_ingress_port))

        send_packet(self, self.mirror_ingress_port, send_pkt)

        #
        # Wait for the egress packet and verify it
        #
        print("  Expecting the modified packet to be mirrored to port {}"
              .format(self.mirror_port))

        result = verify_packet_with_result(self, exp_pkt, self.mirror_port)
        print("  Received the modified packet on port {}"
              .format(self.mirror_port))

        rcv_pkt = Ether(result.packet)
        to_cpu  = rcv_pkt[ToCpu]
        print("      Ingress port: {}".format(rcv_pkt[ToCpu].ingress_port))
        print("     Packet length: {} / {} bytes of the original packet"
              .format(len(rcv_pkt), len(rcv_pkt) - len(Ether()/ToCpu())))
        print("        Timestamps: {} + {} + ??"
              .format(to_cpu.ingress_mac_tstamp,
                      to_cpu.ingress_global_tstamp - to_cpu.ingress_mac_tstamp
                      ))

class IPv4ToCpuEgr(EgrMirrorCpuGroup):
    def runTest(self):
        pktlen = test_param_get("pktlen", 200)

        print("\n")
        print("Test Run")
        print("========")

        encap_len = len(Ether()/ToCpu())

        send_pkt = simple_tcp_packet(eth_dst="00:98:76:54:32:10",
                                     eth_src='00:55:55:55:55:55',
                                     ip_dst=self.ipv4_dst,
                                     ip_id=101,
                                     ip_ttl=64,
                                     ip_ihl=5,
                                     pktlen=pktlen)

        # Create the modified packet with the cpu_ethernet and to_cpu headers
        exp_pkt = copy.deepcopy(send_pkt)
        exp_pkt[Ether].dst = self.new_mac_da
        exp_pkt[Ether].src = self.new_mac_sa
        exp_pkt[IP].ttl   -= 1

        exp_pkt = Ether() / ToCpu() / exp_pkt
        exp_pkt[Ether].dst = self.cpu_dst_mac
        exp_pkt[Ether].src = self.cpu_src_mac
        exp_pkt[ToCpu].header_type    = "Egress Mirror"
        exp_pkt[ToCpu].header_info    = self.header_info
        exp_pkt[ToCpu].pad0           = 0
        exp_pkt[ToCpu].ingress_port   = self.mirror_ingress_port
        exp_pkt[ToCpu].pad0           = 0
        exp_pkt[ToCpu].egress_port    = self.egress_port
        exp_pkt[ToCpu].pad2           = 0
        exp_pkt[ToCpu].mirror_session = self.mirror_id

        # exp_pkt[ToCpu].pkt_length is tricky, since it depends on whether
        # the packet was truncated or not
        if pktlen + encap_len > self.egress_max_len:
            exp_pkt = Ether(bytes(exp_pkt)[0:self.egress_max_len])
        exp_pkt[ToCpu].pkt_length = len(send_pkt) + 4

        # Mask out the timestamps -- we do not know what they will be
        exp_pkt = Mask(exp_pkt)
        exp_pkt.set_do_not_care_scapy(ToCpu, "ingress_mac_tstamp")
        exp_pkt.set_do_not_care_scapy(ToCpu, "ingress_global_tstamp")
        exp_pkt.set_do_not_care_scapy(ToCpu, "egress_global_tstamp")
        exp_pkt.set_do_not_care_scapy(ToCpu, "mirror_global_tstamp")

        # Note that we didn't set don't care on padding -- they should be 0
        exp_pkt.set_do_not_care_scapy(ToCpu, "enq_qdepth")
        exp_pkt.set_do_not_care_scapy(ToCpu, "enq_congest_stat")
        exp_pkt.set_do_not_care_scapy(ToCpu, "deq_qdepth")
        exp_pkt.set_do_not_care_scapy(ToCpu, "deq_congest_stat")
        exp_pkt.set_do_not_care_scapy(ToCpu, "app_pool_congest_stat")
        exp_pkt.set_do_not_care_scapy(ToCpu, "deq_timedelta")
        exp_pkt.set_do_not_care_scapy(ToCpu, "egress_qid")
        exp_pkt.set_do_not_care_scapy(ToCpu, "egress_cos")
        exp_pkt.set_do_not_care_scapy(ToCpu, "pad8")

        # We know that deflection flag should be 0
        # exp_pkt.set_do_not_care_scapy(ToCpu, "deflection_flag")

        #
        # Send a test packet
        #
        print("  Sending packet with IPv4 DST ADDR={} into port {}"
              .format(self.ipv4_dst, self.mirror_ingress_port))

        send_packet(self, self.mirror_ingress_port, send_pkt)

        #
        # Wait for the egress packet and verify it
        #
        print("  Expecting the modified packet to be mirrored to port {}"
              .format(self.mirror_port))

        result = verify_packet_with_result(self, exp_pkt, self.mirror_port)
        print("  Received the modified packet on port {}"
              .format(self.mirror_port))

        rcv_pkt = Ether(result.packet)
        to_cpu  = rcv_pkt[ToCpu]
        print("      Ingress port: {}".format(rcv_pkt[ToCpu].ingress_port))
        print("     Packet length: {} / {} bytes of the original packet"
              .format(len(rcv_pkt), to_cpu.pkt_length))
        print("        Timestamps: {} + {} + {} / Mirror: {}"
              .format(to_cpu.ingress_mac_tstamp,
                      to_cpu.ingress_global_tstamp - to_cpu.ingress_mac_tstamp,
                      to_cpu.egress_global_tstamp - to_cpu.ingress_global_tstamp,
                      to_cpu.mirror_global_tstamp - to_cpu.egress_global_tstamp
                      ))

class HostForward(BaseIPv4Group):
    def runTest(self):
        print("\n")
        print("Test Run")
        print("========")

        pkt = simple_tcp_packet(eth_dst="00:98:76:54:32:10",
                                eth_src='00:55:55:55:55:55',
                                ip_dst=self.ipv4_dst,
                                ip_id=101,
                                ip_ttl=64,
                                ip_ihl=5)

        exp_pkt = copy.deepcopy(pkt)
        exp_pkt[Ether].dst = self.new_mac_da
        exp_pkt[Ether].src = self.new_mac_sa
        exp_pkt[IP].ttl   -= 1

        print("  Sending packet with IPv4 DST ADDR=%s into port %d" %
              (self.ipv4_dst, self.ingress_port))
        send_packet(self, self.ingress_port, pkt)

        #
        # Wait for the egress packet and verify it
        #
        print("  Expecting the modified packet on port %d" % self.egress_port)
        verify_packet(self, exp_pkt, self.egress_port)
        print("  Packet received of port %d" % self.egress_port)
