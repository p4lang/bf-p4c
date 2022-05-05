from bfruntime_client_base_tests import BfRuntimeTest
from ptf import config
import ptf.testutils as testutils

import pd_base_tests
from res_pd_rpc.ttypes import *
from mirror_pd_rpc.ttypes import *
import bfrt_grpc.client as grpccli

from .table import Table
from .port import Port
class TestRuntime(BfRuntimeTest):
    def __init__(self):
        BfRuntimeTest.__init__(self)
        self._fixed = None
        self._client = None
        self._device_map = {}
        self._port_map = {}
        self._tables = {}
        self._registered_mirrors = []

    def createPort(self, device, port):
        '''
        Create port object

        Parameters:
        -----------
        device: int
            zero based index of the device
        port: int
            zero based index of the device's port
        '''    
        return Port.createPort(device, port)
    
    def _convertLogicalDevice(self, device):
        return self._device_map[device]

    def _convertLogicalPort(self, port):
        port = Port(port)
        if port not in self._port_map:
            raise ValueError("Invalid port {}".format(port))
        return self._port_map[port]

    def getTable(self, tablename, device = None):
        '''
        Get specified table

        Parameters:
        -----------
        tablename: string
            Unique name of the table (P4 name of the table)
        device: int
            Number of the device the table belongs to
        '''
        if tablename not in self._tables:
            if device is None:
                device = 0
            target = grpccli.Target(self._convertLogicalDevice(device), pipe_id = 0xffff)
            self._tables[tablename] = Table(
                tablename, target, self.bfrt_info.table_get(tablename))
        return self._tables[tablename]

    def createTableEntryBuilder(self, tablename, action, device = None):
        '''
        Create the entry builder for a table
        
        Parameters:
        -----------
        tablename: string
            Unique name of the table (P4 table name)
        action: string
            Name of the entry action
        device: int
            Number of the device the table belongs to
        '''
        return self.getTable(tablename, device).createEntryBuilder(action)

    def registerIngressMirrorSession(self, mirror_id, egr_port, max_pkt_len):
        '''
        Register a session mirroring from an ingress pipeline to an egress pipeline

        Parameters:
        -----------
        mirror_id: int
            A unique ID of the session
        egr_port: int | Port
            Zero based index of the egress port of the zero device or a Port object
        max_pkt_len: int
            Maximal size of the mirrored packet
        '''
        device, port = self._convertLogicalPort(egr_port)
        device_target = DevTarget_t(device, -1)
        self._fixed.mirror.mirror_session_create(
            self._client,
            device_target,
            MirrorSessionInfo_t(
                mir_type = MirrorType_e.PD_MIRROR_TYPE_NORM,
                direction = Direction_e.PD_DIR_INGRESS,
                mir_id = mirror_id,
                egr_port = port,
                egr_port_v = True,
                max_pkt_len = (max_pkt_len + 3) & ~3  # -- alignment with 4 bytes blocks needed by Tofino
            ))
        self._registered_mirrors.append((mirror_id, device_target))
    
    def sendPacket(self, ingress_port, packet):
        '''
        Send a packet

        Parameters:
        -----------
        ingress_port: int | Port
            zero based index of the ingress port of the zero device or a Port object
        packet: Packet
            the sent packet
        '''
        testutils.send_packet(self, self._convertLogicalPort(ingress_port), packet)
    
    def verifyPacket(self, egress_port, packet):
        '''
        Verify incoming packet

        Parameters:
        -----------
        egress_port: int | Port
            zero based index of the egress port of the zero device or a Port object
        packet: Packet
            expected packet
        '''
        testutils.verify_packet(self, packet, self._convertLogicalPort(egress_port))
    
    def verifyNoOtherPackets(self):
        '''
        Verify that all incoming packets are consumed
        '''
        testutils.verify_no_other_packets(self)

    def setUp(self, client_id = 0, p4_name = None):
        BfRuntimeTest.setUp(self, client_id, p4_name)

        # -- read configuration of the switch ports
        port_list = []
        for device, port, ifname in config["interfaces"]:
            port_list.append((device, port))
        port_list.sort()
        last_device = -1
        logical_device = -1
        logical_port = 0
        for device, port in port_list:
            if device != last_device:
                last_device = device
                logical_device += 1
                logical_port = 0
                self._device_map[logical_device] = device
            self._port_map[Port(logical_port, logical_device)] = (device, port)
            logical_port += 1

        # -- create the fixed interface
        self._fixed = pd_base_tests.ThriftInterfaceDataPlane([self.p4_name])
        self._fixed.setUp()
        self._client = self._fixed.conn_mgr.client_init()
    
    def tearDown(self):
        # -- destroy registered mirroring sessions
        for mirror_id, dev_target in self._registered_mirrors:
            self._fixed.mirror.mirror_session_delete(self._client, dev_target, mirror_id)
        
        # -- clean all table entries
        for table in self._tables.values():
            table.cleanEntries()

        self._fixed.tearDown()
        BfRuntimeTest.tearDown(self)
