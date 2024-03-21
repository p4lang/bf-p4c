
import unittest
import logging 
import grpc   
import pdb
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

from collections import namedtuple

p4_program_name = "p4c-2602"

logger = logging.getLogger('L47')
logger.addHandler(logging.StreamHandler())

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
        self.port_metadata = self.bfrt_info.table_get("IngressParser.$PORT_METADATA")
        self.l23port = self.bfrt_info.table_get("Ingress.setEgPortTbl")
        self.mirrorTbl = self.bfrt_info.table_get("Ingress.ingressMirrorTbl")
        self.captureTbl = self.bfrt_info.table_get("Ingress.setCaptureTbl")
        self.tables = [self.port_metadata, self.l23port, self.mirrorTbl, self.captureTbl]
       

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

