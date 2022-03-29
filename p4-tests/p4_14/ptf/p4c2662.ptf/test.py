# Copyright 2013-present Barefoot Networks, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

"""
Simple PTF test for p4c2662
"""
import pdb
import pd_base_tests

from ptf import config
from ptf.packet import *
from ptf.mask import *
from ptf.testutils import *
from ptf.thriftutils import *
from p4testutils.misc_utils import mask_set_do_not_care_packet

# Change the line below, using the name of your program
from p4c2662.p4_pd_rpc.ttypes import *
from res_pd_rpc.ttypes import *

# Additional imports for this test
from ipaddress import ip_address

class TestBase(pd_base_tests.ThriftInterfaceDataPlane):
    def __init__(self):
        # Change the line below, using the name of your program
        pd_base_tests.ThriftInterfaceDataPlane.__init__(self, ["p4c2662"])

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

        print("\n")
        print("Test Setup")
        print("==========")
        print("    Connected to Device %d, Session %d" % (
            self.dev, self.sess_hdl))

        # Create a list of all ports available on the device
        self.swports = []
        for (device, port, ifname) in config['interfaces']:
            self.swports.append(port)
        self.swports.sort()

        #
        # This is an optional default setup that is used by the teardown()
        # method.
        # Every time you add an entry to a table "t" append its handle to
        # self.entries["t"].
        # Every time you add a member to an action profile "p" append
        # its handle to self.members["p"]
        # Every time you create a new group in action selector "s", append
        # its handle to self.groups["s"]
        self.entries={}
        self.groups={}
        self.members={}

        # Initialize tables
        self.entries["ipv4_host"] = []

        self.cleanUp()

        # Always make sure the programming gets dow to the HW
        self.conn_mgr.complete_operations(self.sess_hdl)
        print

    # Use cleanUp() method to return the DUT to the initial state by cleaning
    # all the configuration and clearing up the connection
    def cleanUp(self):
        print("\n")
        print("Test Cleanup:")
        print("=============")
        try:
            print("  Clearing Table Entries")
            for table in self.entries.keys():
                delete_func = "self.client." + table + "_table_delete"
                for entry in self.entries[table]:
                    exec(delete_func + "(self.sess_hdl, self.dev, entry)")

            print("  Clearing Selector Groups")
            for selector in self.groups.keys():
                delete_func="self.client." + selector + "_del_group"
                for group in self.groups[selector]:
                    exec(delete_func + "(self.sess_hdl, self.dev, group)")

            print("  Clearing Action Profile Members")
            for action_profile in self.members.keys():
                delete_func="self.client." + action_profile + "_del_member"
                for member in self.members[action_profile]:
                    exec(delete_func + "(self.sess_hdl, self.dev, member)")

            # Ideally you should add more code, to clear counters and meters,
            # reset the registers and also clear the fixed-function components

        except:
            print("  Error while cleaning up. ")
            print("  You might need to restart the driver")
        finally:
            self.conn_mgr.complete_operations(self.sess_hdl)

    # Use tearDown() method to return the DUT to the initial state by cleaning
    # all the configuration and clearing up the connection
    def tearDown(self):
        self.cleanUp()
        self.conn_mgr.client_cleanup(self.sess_hdl)
        print("  Closed Session %d" % self.sess_hdl)
        pd_base_tests.ThriftInterfaceDataPlane.tearDown(self)

#
# Individual tests can now be subclassed from TestBase
#

############################################################################
################# I N D I V I D U A L    T E S T S #########################
############################################################################

#
# This class simulates Tofino Math unit. Please, see BEACON-201 or similar
# course for more details
#
# Usage:
#
#  # Calculating the square of the number
#  math_unit = MathUnit(shift=1, invert=False, scale=-6,
#                       lookup=[x*x for x in range(15, -1, -1)])
#
#  result = math_unit.compute(100)
#  # Hopefully this is close to 10000 :) Should be 9216, so 7.84% error
#
class MathUnit():

    # Parameters (should be taken from your P4 program):
    #    shift  -- the same value  as the attribute math_unit_exponent_shift
    #    invert -- the same value  as the attribute math_unit_exponent_invert
    #    scale  -- the same value  as the attribute math_unit_output_scale
    #    lookup -- the same values as the attribute math_unit_lookup_table
    #    size   -- register width in bits (8, 16 or 32)
    def __init__(self, shift=0, invert=False, scale=-3,
                 lookup=range(15, -1, -1), size=32):
        if shift not in [-1, 0, 1]:
            raise ValueError("Shift can only be 0, 1 or -1")
        self.shift = shift

        if invert not in [True, False]:
            raise ValueError("Invert must be True of False")
        self.invert = invert

        self.scale  = scale

        if len(lookup) != 16:
            raise ValueError("lookup must have exactly 16 elements")
        for x in lookup:
            if not (0 <= x <= 255):
                raise ValueError("All lookup values must be between 0 and 255")
        self.lookup = lookup; self.lookup.reverse();

        if size not in [8, 16, 32]:
            raiseValueError("Size can only be 8, 16 or 32 (bits)")

        self.size = size
        self.mask = (1 << size) -1

    def compute(self, arg):
        if arg == 0:
            return 0

        # Get the exponent and mantissa
        arg1 = arg << 3               # Add 3 extra zeroes on the left
        exp1 = arg1.bit_length() - 1;

        # If we are going to calculate sqrt, we need an even exponent
        if self.shift == -1 and exp1 % 2 != 0:
            exp1 += 1

        exp  = exp1 - 3                # Compensate for the initial shift
        mantissa = (arg1 >> exp) & 0xF # First 4 bits

        # Calculate the new exponent

        # First let's do linear, square or square root
        if self.shift == -1:
            new_exp = exp >> 1
        elif self.shift == 0:
            new_exp = exp
        elif self.shift == 1:
            new_exp = exp << 1
        else:
            raise ValueError("Shift can only be 0, 1 or -1")

        # For the reciprocals the exponent is inverted
        if self.invert:
            new_exp = -new_exp

        # Finally, add the scale
        new_exp += self.scale

        new_mantissa = self.lookup[mantissa]
        if new_exp < 0:
            result = new_mantissa >> -new_exp
        else:
            result = new_mantissa << new_exp

        return result & self.mask

class Test1(TestBase):
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
        ipv4_dst     = test_param_get("ipv4_dst",     "192.168.1.1")
        ingress_port = self.swports[test_param_get("ingress_port", 0)]
        egress_port  = self.swports[test_param_get("egress_port", 0)]

        reg_val      = test_param_get("reg_val", 100)
        iterations   = test_param_get("iterations", 10)

        # The following parameters must be the same as in the program
        math_unit  = MathUnit(shift  = test_param_get("shift", 0),
                              invert = test_param_get("invert", False),
                              scale  = test_param_get("scale", -5),
                              lookup = test_param_get("lookup",
                                              [45, 42, 39, 36, 33, 30, 27, 24,
                                               21, 18, 15, 12,  9,  6,  3,  0]),
                              size   = 32)

        print("Setting the initial value in my_reg(0)")
        self.client.register_write_my_reg(
            self.sess_hdl, self.dev_tgt,
            0, hex_to_i32(reg_val))
        self.conn_mgr.complete_operations(self.sess_hdl)

        for i in range(iterations):
            print("Sending packet with IPv4 DST ADDR=%s into port %d" %
                  (ipv4_dst, ingress_port))
            pkt = simple_tcp_packet(eth_dst="00:98:76:54:32:10",
                                    eth_src='00:55:55:55:55:55',
                                    ip_dst=ipv4_dst,
                                    ip_id=101,
                                    ip_ttl=64,
                                    ip_ihl=5)
            send_packet(self, ingress_port, pkt)

            exp_pkt = pkt
            exp_pkt[IP].dst = str(ip_address(reg_val))
            mask = Mask(exp_pkt)
            mask_set_do_not_care_packet(mask, IP, "chksum")
            mask_set_do_not_care_packet(mask, TCP, "chksum")

            print("Expecting the packet on port %d with value %d" %
                  (egress_port, reg_val))
            verify_packet(self, mask, egress_port)
            print("Packet received of port %d" % egress_port)
            reg_val = math_unit.compute(reg_val)
