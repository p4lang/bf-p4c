################################################################################
# This is eagle simple ptf test.
# Please make sure the setup part can run on real hardware
#
################################################################################

"""
Functional test that use fixed API ( multicast and mirror ) for the program eagle.p4
"""
from eagle_base import *
import codecs
class L23ClassTest(P4ProgramTest):
    def setUp(self):
        P4ProgramTest.setUp(self)

        # program the port metadata table, setup np and front panel poorts
        """ PORTS """
        #self.l23_ports = [3, 4, 5]
        #self.fp_ports = [10, 11, 12]
        #self.np_ports = [1]
        self.l23_ports = [8, 9, 10]
        self.fp_ports = [11, 12, 13]
        self.np_ports = [20]
        self.cpu_port = [64]
        for port in self.fp_ports:
            self.assign_port_type(port, 1)
        for port in self.l23_ports:
            self.assign_port_type(port, 2)
        for port in self.np_ports:
            self.assign_port_type(port, 3)
        self.ports = self.np_ports + self.fp_ports + self.l23_ports

    def wait_for_pkt(self, port, pkt, exp_port):
        print("Send from port {}".format(port))
        send_packet(self, port, pkt)
        print("Receiving packets...")
        found = True
        new_packet = Ether()
        while found:
            # Receive a packet using a lower-level routine
            result = dp_poll(self, self.dev, timeout=1)
            if isinstance(result, self.dataplane.PollSuccess):
                rcv_pkt = result.packet
                new_packet = Ether(rcv_pkt)
                rcv_port = result.port
                print("Received packet on port {}".format(rcv_port))
                # Check if the packet was expected (is in the list)
                if exp_port == rcv_port:
                    found = False
                    break
            else:
                break
        return new_packet

class BasicTest(L23ClassTest):
    """
    Verifies that packet that do not match L23 or L47 routes to cpu and designated L47 node
    """
    def runTest(self):
        engine_id = 0
        #fp_port = 68 #special recirculate port (hardwired loopback)
        fp_port = self.fp_ports[0]
        l23_port = self.l23_ports[0]
        #for l23_port in self.l23_ports:
        self.assign_l23_eg_port(engine_id=engine_id, egPort=fp_port, ingress_port = l23_port, porttype=2, ins_timestamp=1)
        #for l23_port, engine_id in zip(self.l23_ports, engines):
        print("UDP packet")
        pkt = Ether()/IP()/UDP()/pp_utils.L23Payload(Signature=0xC0DEFACE, sig_bot=0xCA, engine_id=engine_id )
        new_pkt = self.wait_for_pkt(l23_port, pkt, fp_port)
        final_pkt = self.wait_for_pkt(fp_port, new_pkt, l23_port)
        rx_timestamp = 0
        tx_timestamp = 0
        pkt_bytes = bytes(final_pkt)
        for i in range(0,4):
            rx_timestamp = rx_timestamp <<8 | pkt_bytes[40+i+8]
            tx_timestamp = tx_timestamp <<8 | pkt_bytes[48+i+8]
        print("rx = {} tx = {}".format(hex(rx_timestamp), hex(tx_timestamp)))
        self.assertFalse(rx_timestamp == 0)
        self.assertFalse(rx_timestamp == 0x10)
        self.assertFalse(tx_timestamp == 0)
        pkt = Ether()/IP()/TCP()/pp_utils.L23Payload(Signature=0xC0DEFACE, sig_bot=0xCA, engine_id=engine_id )
        new_pkt = self.wait_for_pkt(l23_port, pkt, fp_port)
        final_pkt = self.wait_for_pkt(fp_port, new_pkt, l23_port)
        rx_timestamp = 0
        tx_timestamp = 0
        pkt_bytes = bytes(final_pkt)
        for i in range(0,4):
            rx_timestamp = rx_timestamp <<8 | pkt_bytes[52+i+8]
            tx_timestamp = tx_timestamp <<8 | pkt_bytes[60+i+8]
        print("rx = {} tx = {}".format(hex(rx_timestamp), hex(tx_timestamp)))
        self.assertFalse(rx_timestamp == 0)
        self.assertFalse(rx_timestamp == 0x10)
        self.assertFalse(tx_timestamp == 0)
        self.delete_l23_eg_port(engine_id)

class Ipv4OptionTest(L23ClassTest):
    """
    Verifies that packet that do not match L23 or L47 routes to cpu and designated L47 node
    """
    def runTest(self):
        engine_id = 0
        #fp_port = 68 #special recirculate port (hardwired loopback)
        fp_port = self.fp_ports[0]
        l23_port = self.l23_ports[0]
        #for l23_port in self.l23_ports:
        self.assign_l23_eg_port(engine_id=engine_id, egPort=fp_port, ingress_port = l23_port, porttype=2, ins_timestamp=1)
        #for l23_port, engine_id in zip(self.l23_ports, engines):
        option = '\x83\x03\x10' 
        options = [option]
        offset = 0
        for pkts in range(0,10):
            pkt = Ether()/IP(proto=255, options = options)/pp_utils.L23Payload(Signature=0xC0DEFACE, sig_bot=0xCA, engine_id=engine_id )
            new_pkt = self.wait_for_pkt(l23_port, pkt, fp_port)
            final_pkt = self.wait_for_pkt(fp_port, new_pkt, l23_port)
            options.append(option)
            rx_timestamp = 0
            tx_timestamp = 0
            pkt_bytes = bytes(final_pkt)
            for i in range(0,4):
                rx_timestamp = rx_timestamp <<8 | pkt_bytes[44+i+offset]
                tx_timestamp = tx_timestamp <<8 | pkt_bytes[52+i+offset]
            print("rx = {} tx = {}".format(hex(rx_timestamp), hex(tx_timestamp)))
            #self.assertFalse(rx_timestamp == 0)
            self.assertFalse(rx_timestamp == 0x10)
            self.assertFalse(tx_timestamp == 0)
            offset = offset + 4
        self.delete_l23_eg_port(engine_id)

class Ipv4OptionTcpTest(L23ClassTest):
    """
    Verifies that packet that do not match L23 or L47 routes to cpu and designated L47 node
    """
    def runTest(self):
        engine_id = 0
        #fp_port = 68 #special recirculate port (hardwired loopback)
        fp_port = self.fp_ports[0]
        l23_port = self.l23_ports[0]
        #for l23_port in self.l23_ports:
        self.assign_l23_eg_port(engine_id=engine_id, egPort=fp_port, ingress_port = l23_port, porttype=2, ins_timestamp=1)
        #for l23_port, engine_id in zip(self.l23_ports, engines):
        option = '\x83\x03\x10' 
        options = [option]
        offset = 0
        for pkts in range(0,10):
            pkt = Ether()/IP(options = options)/TCP()/pp_utils.L23Payload(Signature=0xC0DEFACE, sig_bot=0xCA, engine_id=engine_id )
            new_pkt = self.wait_for_pkt(l23_port, pkt, fp_port)
            final_pkt = self.wait_for_pkt(fp_port, new_pkt, l23_port)
            options.append(option)
            rx_timestamp = 0
            tx_timestamp = 0
            pkt_bytes = bytes(final_pkt)
            for i in range(0,4):
                rx_timestamp = rx_timestamp <<8 | pkt_bytes[64+i+offset]
                tx_timestamp = tx_timestamp <<8 | pkt_bytes[72+i+offset]
            print("rx = {} tx = {}".format(hex(rx_timestamp), hex(tx_timestamp)))
            #self.assertFalse(rx_timestamp == 0)
            self.assertFalse(rx_timestamp == 0x10)
            self.assertFalse(tx_timestamp == 0)
            offset = offset + 4
        self.delete_l23_eg_port(engine_id)
            
class Ipv4OptionUdpTest(L23ClassTest):
    """
    Verifies that packet that do not match L23 or L47 routes to cpu and designated L47 node
    """
    def runTest(self):
        engine_id = 0
        #fp_port = 68 #special recirculate port (hardwired loopback)
        fp_port = self.fp_ports[0]
        l23_port = self.l23_ports[0]
        #for l23_port in self.l23_ports:
        self.assign_l23_eg_port(engine_id=engine_id, egPort=fp_port, ingress_port = l23_port, porttype=2, ins_timestamp=1)
        #for l23_port, engine_id in zip(self.l23_ports, engines):
        option = '\x83\x03\x10' 
        options = [option]
        offset = 0
        for pkts in range(0,10):
            hdr = Ether()/IP(options = options)/UDP()/pp_utils.L23Payload(Signature=0xC0DEFACE, sig_bot=0xCA, engine_id=engine_id)
            payload = codecs.decode("".join(["%02x"%(0) for x in range( (80 + offset)- len(hdr))]), "hex")
            pkt = hdr/payload
            new_pkt = self.wait_for_pkt(l23_port, pkt, fp_port)
            final_pkt = self.wait_for_pkt(fp_port, new_pkt, l23_port)
            options.append(option)
            rx_timestamp = 0
            tx_timestamp = 0
            pkt_bytes = bytes(final_pkt)
            for i in range(0,4):
                rx_timestamp = rx_timestamp <<8 | pkt_bytes[52+i+offset]
                tx_timestamp = tx_timestamp <<8 | pkt_bytes[60+i+offset]
            print("rx = {} tx = {}".format(hex(rx_timestamp), hex(tx_timestamp)))
            #self.assertFalse(rx_timestamp == 0)
            self.assertFalse(rx_timestamp == 0x10)
            self.assertFalse(tx_timestamp == 0)
            offset = offset + 4
        self.delete_l23_eg_port(engine_id)
