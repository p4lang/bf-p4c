# #################################################################################
#  INTEL CORPORATION CONFIDENTIAL & PROPRIETARY
# 
#  Copyright (c) 2020 Intel Corporation
#  All Rights Reserved.
# 
#  This software and the related documents are Intel copyrighted materials,
#  and your use of them is governed by the express license under which they
#  were provided to you ("License"). Unless the License provides otherwise,
#  you may not use, modify, copy, publish, distribute, disclose or transmit this
#  software or the related documents without Intel's prior written permission.
# 
#  This software and the related documents are provided as is, with no express or
#  implied warranties, other than those that are expressly stated in the License.
# 
# #################################################################################

import logging

import ptf.testutils as testutils
from bfruntime_client_base_tests import BfRuntimeTest
import bfrt_grpc.bfruntime_pb2 as bfruntime_pb2
import bfrt_grpc.client as client

logger = logging.getLogger('Test')
if not len(logger.handlers):
    logger.addHandler(logging.StreamHandler())

class PvsTest(BfRuntimeTest):
    def setUp(self):
        client_id = 0
        BfRuntimeTest.setUp(self, client_id)


    def runTest(self):
        logger.info("Configuring PVS ...")
        # Get bfrt_info and set it as part of the test
        # pdb.set_trace()
        bfrt_info = self.interface.bfrt_info_get()
        vs_table = bfrt_info.table_get("ParserI.pvs")

        logger.info("Set all scopes to ALL")
        target = client.Target(device_id=0, pipe_id=0xffff, direction=0xff, prsr_id=0xff)
        vs_table.attribute_entry_scope_set(target,
                                           config_gress_scope=True, predefined_gress_scope_val=bfruntime_pb2.Mode.ALL,
                                           config_pipe_scope=True, predefined_pipe_scope=True,
                                           predefined_pipe_scope_val=bfruntime_pb2.Mode.ALL, pipe_scope_args=0xff,
                                           config_prsr_scope=True, predefined_prsr_scope_val=bfruntime_pb2.Mode.ALL,
                                           prsr_scope_args=0xff)

        # # Get the table usage, it should be empty.
        usage_resp = next(vs_table.usage_get(target))
        self.assertEqual(usage_resp, 0)

        # PVS values to process
        vs_vals = [0xffaa, 0xffbb]
        for val in vs_vals:
            logger.info("Insert entry --> " + str(hex(val)))
            test_key = vs_table.make_key([
                client.KeyTuple('f', val, 0xff)])
            vs_table.entry_add(
                target,
                [test_key])

        # Get the table usage, it should have tow entries now.
        usage_resp = next(vs_table.usage_get(target))
        self.assertEqual(usage_resp, 2)

        resp = vs_table.entry_get(target, None, {"from_hw": False})
        logger.info("====================================================")
        logger.info("From HW:")
        for data, key in resp:
            logger.info(key.to_dict())
            logger.info(data.to_dict())

        # So far so good, prepare two packets and check them for identity
        logger.info("====================================================")

        # Create two packets which are modified to go through the configured PVS
        pkts = [
            testutils.simple_eth_packet(pktlen=90, eth_type=vs_vals[0]),
            testutils.simple_eth_packet(pktlen=90, eth_type=vs_vals[1]),
        ]

        ingress_port = testutils.test_param_get("ingress_port", 0)
        for pkt in pkts:
            testutils.send_packet(self, ingress_port, pkt)

        # Wait for egress and verify it
        for pkt in pkts:
            testutils.verify_packet(self, pkt, ingress_port)

        # Sending the frame which will not pass through the PVS and will be dropped
        drop_pkt = testutils.simple_eth_packet(pktlen=90)
        testutils.send_packet(self, ingress_port, drop_pkt)
        testutils.verify_no_packet(self, drop_pkt, ingress_port)
