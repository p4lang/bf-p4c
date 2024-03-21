
"""
Simple PTF test for 2-bit brig-906.p4
"""

import pd_base_tests

from ptf import config
from ptf.testutils import *
from ptf.thriftutils import *

from brig906.p4_pd_rpc.ttypes import *
from res_pd_rpc.ttypes import *


class L2Test(pd_base_tests.ThriftInterfaceDataPlane):
    def __init__(self):
        pd_base_tests.ThriftInterfaceDataPlane.__init__(self,
                                                        ["brig906"])

    # The setUp() method is used to prepare the test fixture. Typically
    # you would use it to establich connection to the Thrift server.
    #
    # You can also put the initial device configuration there. However,
    # if during this process an error is encountered, it will be considered
    # as a test error (meaning the test is incorrect),
    # rather than a test failure
    def setUp(self):
        pd_base_tests.ThriftInterfaceDataPlane.setUp(self)

        self.sess_hdl = self.conn_mgr.client_init()
        self.dev      = 0
        self.dev_tgt  = DevTarget_t(self.dev, hex_to_i16(0xFFFF))

        print("\nConnected to Device %d, Session %d" % (
            self.dev, self.sess_hdl))

    # This method represents the test itself. Typically you would want to
    # configure the device (e.g. by populating the tables), send some
    # traffic and check the results.
    #
    # For more flexible checks, you can import unittest module and use
    # the provided methods, such as unittest.assertEqual()
    #
    # Do not enclose the code into try/except/finally -- this is done by
    # the framework itself
    def runTest(self):
        # Test Parameters
        ingress_port = 0
        egress_port  = 0

        self.client.register_reset_all_global_pkt_counter(
            self.sess_hdl, self.dev_tgt)
        self.conn_mgr.complete_operations(self.sess_hdl)
        
        def gen_expected_packet(cnt):
	    #cnt should be from 0 to 256
	    return simple_tcp_packet(eth_dst='ff:ff:ff:ff:ff:ff',
                                     eth_src='ff:ff:ff:ff:ff:ff',
                                     ip_dst='0.0.0.'+str(cnt),
                                     ip_src='0.0.0.'+str(cnt),
                                     ip_id=0,
                                     ip_ttl=64,
                                     ip_ihl=5)

	p0=gen_expected_packet(0)
        send_pkt = Ether(str(p0))
        
	for i in range(1,8):
	    print("Sending packet #"+str(i)+', expecting output count be the same')
            exp_pkt = gen_expected_packet(i%4)
            exp_pkt[IP].chksum=send_pkt[IP].chksum
            exp_pkt[TCP].chksum=send_pkt[TCP].chksum
            
            send_packet(self, ingress_port, send_pkt)
            verify_packets(self, exp_pkt, [egress_port])

    # Use this method to return the DUT to the initial state by cleaning
    # all the configuration and clearing up the connection
    def tearDown(self):
            self.conn_mgr.complete_operations(self.sess_hdl)
            self.conn_mgr.client_cleanup(self.sess_hdl)
            print("Closed Session %d" % self.sess_hdl)
            pd_base_tests.ThriftInterfaceDataPlane.tearDown(self)
