################################################################################
# BAREFOOT NETWORKS CONFIDENTIAL & PROPRIETARY
#
# Copyright (c) 2019-present Barefoot Networks, Inc.
#
# All Rights Reserved.
#
# NOTICE: All information contained herein is, and remains the property of
# Barefoot Networks, Inc. and its suppliers, if any. The intellectual and
# technical concepts contained herein are proprietary to Barefoot Networks, Inc.
# and its suppliers and may be covered by U.S. and Foreign Patents, patents in
# process, and are protected by trade secret or copyright law.  Dissemination of
# this information or reproduction of this material is strictly forbidden unless
# prior written permission is obtained from Barefoot Networks, Inc.
#
# No warranty, explicit or implicit is provided, unless granted under a written
# agreement with Barefoot Networks, Inc.
#
################################################################################

import logging

from ptf import config
import ptf.testutils as testutils
from bfruntime_client_base_tests import BfRuntimeTest
import bfrt_grpc.client as gc

dev_id = 0
p4_program_name = "p4c_3479"

logger = logging.getLogger('Test')
if not len(logger.handlers):
    logger.addHandler(logging.StreamHandler())

swports = []
for device, port, ifname in config["interfaces"]:
    swports.append(port)
swports.sort()


class Test(BfRuntimeTest):
    """@brief Verify if the program parses packets correctly.
    """

    def setUp(self):
        client_id = 0
        BfRuntimeTest.setUp(self, client_id, p4_program_name)
        self.bfrt_info = self.interface.bfrt_info_get(p4_program_name)

    def runTest(self):
        pkt_in = testutils.simple_ip_packet(eth_dst='51:62:73:84:95:A6',
                                            eth_src='00:11:22:33:44:55')
        pkt_out = pkt_in.copy()
        pkt_out[Ether].type = 0xABCD

        testutils.send_packet(self, 8, pkt_in)
        testutils.verify_packet(self, pkt_out, 8)
        testutils.verify_no_other_packets(self)
