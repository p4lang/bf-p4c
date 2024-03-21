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
Basic functional tests for the program mirror.p4
"""

from mirror import *
import codecs
from scapy.all import *

class Capture(Packet):
    name = "CaptureOV"
    fields_desc = [ XIntField("seq_no", 0),
                    XIntField("timestamp",0)
                  ]
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
############################################################################
################# I N D I V I D U A L    T E S T S #########################
############################################################################

class MirrorTest(P4ProgramTest):
    """
    Basic Mirror tests
    """
    
    def wait_for_pkt(self, exp_port):
        print("Receiving packets...")
        found = True
        new_packet = Ether()
        while found:
            # Receive a packet using a lower-level routine
            result = dp_poll(self, self.dev, timeout=2)
            if isinstance(result, self.dataplane.PollSuccess):
                rcv_pkt = result.packet
                new_packet = Ether(rcv_pkt)
                rcv_port = result.port
                if (rcv_port == self.resubmit_tx_port):
                    send_packet(self, self.resubmit_tx_port, new_packet)
                # if (rcv_port == 68):
                #     send_packet(self, 68, str(new_packet))
                print("Received packet on port {}".format(rcv_port))
                # Check if the packet was expected (is in the list)
                if exp_port == rcv_port:
                    found = False
                    break
            else:
                break
        self.assertFalse(found)
        return new_packet

    def configure_port(self, ingress_port, egress_port):
        print("configure {} -> {}".format(ingress_port, egress_port))
        key_list = [
            self.l23port.make_key([
                gc.KeyTuple('ig_intr_md.ingress_port', ingress_port)])
            ]

        data_list = [
            self.l23port.make_data([
                gc.DataTuple('egress_port', egress_port)], "Ingress.setEgPort")
            ]

        self.l23port.entry_add(self.dev_tgt, key_list, data_list)

    def configure_port_metadata(self, igPort, porttype, capture_port, signature=0x11223344):
        key_list = [
            self.port_metadata.make_key([
                gc.KeyTuple('ig_intr_md.ingress_port', gc.to_bytes(igPort,2))])
            ]
        data_list = [
            self.port_metadata.make_data([
                gc.DataTuple('port_type', gc.to_bytes(porttype, 1)),
                gc.DataTuple('port_signature', gc.to_bytes(0x11223344, 4)),
                gc.DataTuple('capture_port', gc.to_bytes(capture_port,1))])
            ]
        self.port_metadata.entry_add(self.dev_tgt, key_list, data_list)
        print("Assign {} port type {}".format(igPort, porttype))

    def assign_ingress_capture_session(self, port, mirror_session):
        print("Assign port {} with mirror session {}".format(port, mirror_session))
        key = self.mirrorTbl.make_key([
            gc.KeyTuple('ig_intr_md.ingress_port', gc.to_bytes(port,2))])
        data = self.mirrorTbl.make_data([
            gc.DataTuple('mirror_session', mirror_session)],
            "Ingress.set_mirror_session_capture")
        self.mirrorTbl.entry_add(self.dev_tgt, [key], [data])
    
    def assign_capture_egPort(self, capture_port, port):
        key = self.captureTbl.make_key([
            gc.KeyTuple('hdr.capture.seq_no', gc.to_bytes(capture_port,4))])
        data = self.captureTbl.make_data([
            gc.DataTuple('egress_port', gc.to_bytes(port,2))],
            "Ingress.setCaptureEgPort")
        self.captureTbl.entry_add(self.dev_tgt, [key], [data])

    def setup(self):
        # resubmit port for 68, capture ports -8,9,10,11,12
        #port 16 for L23 port
        #port 17 for front panel
        self.port_tx = 15
        #self.port_rx = [18, 17]
        self.port_rx = 9
        #self.resubmit_tx_port = 24
        self.resubmit_tx_port = 10
        self.capture_port = 8
        self.configure_port_metadata(self.resubmit_tx_port, 5, 7)
            
        self.configure_port_metadata(self.port_tx, 2, 7)
        self.configure_port_metadata(self.port_rx, 1, 7)
        self.assign_capture_egPort(capture_port=1, port=self.capture_port)
        #
        # program anything that is sent from 16 goes to 17
        #
        self.configure_port(self.port_tx, self.port_rx)
        #set up fixed multicast session, always sent to resubmit port
        self.receive_capture_session = 10
        self.fixed.sess_hdl = self.fixed.conn_mgr.client_init()
        print("Opened Connection Mgr Session {:#08x}".
                  format(self.fixed.sess_hdl))
        self.fixed.dev_tgt = DevTarget_t(self.fixed.dev, -1)
        

    def runTest(self):
        print("\n")
        print("Test Run")
        print("========")
        #
        # Send a test packet
        #
        self.setup()
        egress_max_len = 1516
        self.fixed.mirror.mirror_session_create(
            self.fixed.sess_hdl, self.fixed.dev_tgt,
            MirrorSessionInfo_t(
                mir_type    = MirrorType_e.PD_MIRROR_TYPE_NORM,
                direction   = Direction_e.PD_DIR_INGRESS,
                mir_id      = self.receive_capture_session,
                egr_port    = self.resubmit_tx_port,
                egr_port_v  = True,
                max_pkt_len = egress_max_len ))
        print("  Added a mirror session {} --> port({}) (truncate at {} bytes)".
              format(self.receive_capture_session, self.resubmit_tx_port, egress_max_len))
        self.assign_ingress_capture_session(self.port_tx, self.receive_capture_session)
        
        overhead = Ether()
        pkt = overhead/IP(dst="10.0.0.1")
        pkt = pkt/"{}".format("".join([chr(x) for x in range(100 - len(pkt))]))
        print("sending packet from port {}".format(self.port_tx))
        #pkt.show()
        send_packet(self, self.port_tx, pkt)

        new_pkt = self.wait_for_pkt(self.resubmit_tx_port)
        mirror_pkt = Capture(seq_no=1)/pkt
        #mirror_pkt.show()

        self.assertTrue(match_exp_pkt(new_pkt, mirror_pkt))
