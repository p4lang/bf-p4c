import sys, os.path
from string import maketrans
import logging
import traceback
import unittest
import random
from ptf import config
from ptf.testutils import *

import ptf.testutils as testutils

from p4 import p4runtime_pb2
from p4.tmp import p4config_pb2
from p4.config import p4info_pb2

from base_test import P4RuntimeTest
from base_test import stringify

from stf_parser import STFParser


def protobuf_enum(type_name, protobuf_enum_type):
    enums = dict(protobuf_enum_type.items())
    reverse = dict((value, key) for key, value in enums.iteritems())
    # enums['reverse_mapping'] = reverse

    @staticmethod
    def to_str(x):
        return reverse[x].capitalize()
    enums['to_str'] = to_str

    @staticmethod
    def from_str(x):
        return enums[x.upper()]
    enums['from_str'] = from_str

    return type(type_name, (), enums)

MatchType = protobuf_enum('MatchType', p4info_pb2.MatchField.MatchType)

def match_ternary(expected, received):
    if len(expected) > len(received):
        logging.debug("Received packet length %d shorter than expected %d", len(received), len(expected))
        return False;
    for (e, r) in zip(expected, str(received)):
        if e != '*' and e != r:
            return False
    return True

def check_packet(test, pkt, port_id):
    """
    Check that an expected packet is received
    port_id can either be a single integer (port_number on default device 0)
    or a tuple of 2 integers (device_number, port_number)
    The packet matching is customized to compare against ternaries
    """
    device, port = port_to_tuple(port_id)
    logging.debug("Checking for pkt on device %d, port %d", device, port)
    (rcv_device, rcv_port, rcv_pkt, pkt_time) = dp_poll(
        test, device_number=device, port_number=port, timeout=2, exp_pkt=None)
    if pkt is not None and rcv_pkt is not None and not match_ternary(pkt, rcv_pkt):
        rcv_pkt = None
    test.assertTrue(rcv_pkt != None, "Did not receive expected pkt on device %d, port %r" % (device, port))


class stf2ptf (P4RuntimeTest):

    def setUp(self):
        logging.info("p4info: %s", testutils.test_param_get("p4info"))
        logging.info("stftest: %s", testutils.test_param_get("stftest"))

        super(stf2ptf, self).setUp()
        stftest = testutils.test_param_get("stftest")
        testname, ext = os.path.splitext(os.path.basename(stftest))
        testNameEscapeChars = "-"
        testNameEscapes = "_"*len(testNameEscapeChars)
        self._transTable = maketrans(testNameEscapeChars,testNameEscapes)
        self._testname = testname.translate(self._transTable)
        self._logger = logging.getLogger(self._testname)
        parser = STFParser()
        ast, errs = parser.parse(filename=stftest)
        if errs != 0:
            sys.exit(1)
        self._ast = ast
        self._requests = []
        self._namedEntries = {}
        self._hasPadding = False
        self._hasByteCounters = False

    def runTest(self):
        self._logger.info("Starting STF test")
        try:
            pkt_expects = []
            pkt_pair = [None, None]
            for s in self._ast:
                self._logger.info("Processing STF statement: %s", s)
                if s[0] == 'packet':
                    if pkt_pair[0] is None:
                        pkt_pair[0] = s
                    else:
                        # we've already seen another packet without a pairing
                        # expect. Send the pair packet, and replace the pair with
                        # the new one
                        self.genSendPacket(pkt_pair[0])
                        pkt_pair[0] = s
                elif s[0] == 'expect':
                    if pkt_pair[1] is not None:
                        pkt_expects.append(s)
                    else:
                        pkt_pair[1] = s
                elif s[0] == 'add':
                    self.genAddTableEntry(s)
                elif s[0] == 'wait':
                    # cleanup the pipe
                    self.genProcessPacket(pkt_pair)
                    for e in pkt_expects:
                        self.genExpectPacket(e, pkt_pair[0])
                    pkt_expects = []
                    pkt_pair = [None, None]
                    self.genWaitStmt()
                elif s[0] == 'setdefault':
                    self.genAddDefaultAction(s)
                elif s[0] == 'check_counter':
                    self.genCheckCounter(s)
                elif s[0] == 'remove':
                    self._logger.info("Flushing table entries")
                    self.undo_write_requests(self._requests)
                else:
                    assert False, "Unknown statement %s" % s[0]

                if pkt_pair[0] is not None and pkt_pair[1] is not None:
                    self.genProcessPacket(pkt_pair)
                    pkt_pair = [None, None]

        except Exception as e:
            self._logger.exception(e)
            print >> sys.stderr, traceback.format_exc()
        else:
            testutils.verify_no_other_packets(self)

        finally:
            if self._hasPadding and self._hasByteCounters:
                self._logger.warning("Mixing small packets and byte-counters produce incorrect results.\n" \
                                     + "Please increase the size of your packets to be > 15 bytes")
            self._logger.info("Cleanup")
            self.undo_write_requests(self._requests)
            self._logger.info("End STF Test")

    def genAddTableEntry(self, entry):
        """
            Generate a P4Runtime call to add a table entry

            The write request is stored in the self._requests,
            such that they can be deleted at the end of the test
        """
        table = entry[1].translate(self._transTable)
        priority = entry[2]
        match_list = entry[3]
        action = entry[4][0].translate(self._transTable)
        action_params = entry[4][1]

        self._logger.info("add entry: %s %s", table, str(match_list))
        req = p4runtime_pb2.WriteRequest()
        req.device_id = self.device_id
        update = req.updates.add()
        update.type = p4runtime_pb2.Update.INSERT
        table_entry = update.entity.table_entry
        table_entry.table_id = self.get_table_id(table)
        if priority is not None: table_entry.priority = int(priority, base=10)
        self.set_match_key(table_entry, table, self.genMatchKey(table, match_list))
        self.set_action_entry(table_entry, action, self.genActionParamList(action, action_params))
        # self._logger.debug("req: %s", str(req))
        reply = self.stub.Write(req)
        self._requests.append(req)

        # bookeeping for aliases (mainly used to name counters)
        if entry[5] is not None:
            match_name, match, mask, hasMask = self.match2spec(match_list[0][0], match_list[0][1])
            self._namedEntries[entry[5]] = (table, match_name, match, mask)

    def genMatchKey(self, table, match_list):
        """
            Generate the match_spec
        """
        matches = []
        for match_spec in match_list:
            match_name, match, mask, hasMask = self.match2spec(match_spec[0], match_spec[1])
            matches.append(self.get_mf_match(table, match_name, match, mask))
        return matches

    def genActionParamList(self, action, action_params):
        """
            generate action_spec_t with values for action params
        """
        params = []
        for ap in action_params:
            name, val, mask, hasMask = self.match2spec(ap[0], ap[1])
            value = self.match2int(val)
            valLen = self.get_ap_bytewidth(action, name)
            self._logger.debug('set_param: ("%s", stringfy(0x%x, %d))', name, value, valLen)
            params.append((name, stringify(value, valLen)))
        return params

    def genAddDefaultAction(self, set_default):
        """
            Generate a default action
        """
        table = set_default[1].translate(self._transTable)
        action = set_default[2][0].translate(self._transTable)
        action_params = set_default[2][1]

        self._logger.info("Set default action %s for table %s", action, table)
        req = p4runtime_pb2.WriteRequest()
        req.device_id = self.device_id
        update = req.updates.add()
        update.type = p4runtime_pb2.Update.INSERT
        table_entry = update.entity.table_entry
        table_entry.table_id = self.get_table_id(table)
        self.set_action(table_entry.action.action, action, self.genActionParamList(action, action_params))
        reply = self.stub.Write(req)
        self._requests.append(req)

    def genSendPacket(self, packet):
        """
            Generate a send_packet statement
        """
        port = int(packet[1])
        payload = packet[2]
        self._logger.info("Sending packet on port %d", port)
        testutils.send_packet(self, port, self.encodePacket(payload))
        self._logger.info("Packet sent")

    def genExpectPacket(self, expect, orig_packet):
        """
            Generate a check_packet statement
        """
        if (expect[1] is None):
             # expect no_packet
            self._logger.info("Expect no packet")
            testutils.verify_no_other_packets(self)
            return

        port = int(expect[1])
        payload = expect[2]
        self._logger.info("Expecting packet on port %d", port)
        if payload is None:
            testutils.verify_packet(self, None, port)
            return
        elif orig_packet is None:
            expected = self.encodePacket(payload)
        else:
            expected = self.encodePacket(self.setExpectTern(payload, orig_packet[2]))
        check_packet(self, expected, port)

    def genProcessPacket(self, pkt_pair):
        """
            Generate a send_packet/check_packet pair.
        """
        if pkt_pair[0] is not None: self.genSendPacket(pkt_pair[0])
        if pkt_pair[1] is not None: self.genExpectPacket(pkt_pair[1], pkt_pair[0])

    # currently we support only direct counters
    def genCheckCounter(self, chk):
        """
           Generate a check counter request and verify
        """
        counterName = chk[1]
        if str(chk[2]).startswith('$'):
            varName = chk[2][1:]
            assert varName in self._namedEntries, "Invalid named entry " + chk[2]
            table = self._namedEntries[varName][0]
            match_name = self._namedEntries[varName][1]
            counterIndex = self._namedEntries[varName][2]
            mask = self._namedEntries[varName][3]
        else:
            counterIndex = chk[2]

        self._logger.info("check_counter %s(%s)", counterName, counterIndex)
        rr = p4runtime_pb2.ReadRequest()
        rr.device_id = self.device_id
        reqCounter = rr.entities.add()
        counter_entry = reqCounter.direct_counter_entry
        counter_entry.counter_id = self.get_direct_counter_id(counterName)
        counter_entry.table_entry.table_id = self.get_table_id(table)
        self.set_match_key(counter_entry.table_entry, table,
                           [self.get_mf_match(table, match_name, counterIndex, mask)])
        try:
            for rep in self.stub.Read(rr):
                for entity in rep.entities:
                    counter = entity.direct_counter_entry
                    if chk[3][0] is not None:
                        count_type = chk[3][0]
                        compare = chk[3][1]
                        val = chk[3][2]
                        # FIXME: use compare for the right comparison
                        if count_type == 'packets':
                            self.assertTrue(counter.data.packet_count == val, "Wrong count of packet_count")
                        else:
                            self.assertTrue(counter.data.byte_count == val, "Wrong count of byte_count")
                            self._hasByteCounters = True
                    else:
                        self.assertTrue(counter.data.packet_count == 0, "Wrong count of packets")
        except Exception as e:
            self._logger.exception(e)
            self.assertTrue(False, "Failed to read counter:\n %s" % traceback.format_exc())


    def genWaitStmt(self):
        """
        Generate a wait stmt
        """
        # P4Runtime exposes a blocking interface, so there are no waits
        return

    def setExpectTern(self, expect, packet):
        """
            Set the expect packet don't care to packet data since
            the packet comparison looks byte-by-byte
        """
        val = ''
        for e, p in zip(expect, packet):
            if e == '*': val += p
            else: val += e
        return val

    def match2spec(self, match_name, match):
        """
            Turns a match into (escaped name, value, mask, hasMask)
            Returning a hasMask = False means there were no don't care symbols in the value
        """
        name = match_name.translate(self._transTable)
        hasMask = False
        isBinary = False
        lpmLen = -1
        if isinstance(match, tuple): # an LPM expression (match/len)
            # we don't care about the mask, so we'll return the length in it at the end
            key = match[0]
            lpmLen = int(match[1])
        else:
            key = match
        if key.startswith('0x') or key.startswith('0b'):
            val = key[0:2]
            mask = key[0:2]
            keyPtr = key[2:]
            if key.startswith('0b'):
                isBinary = True
        else:
            val = ''
            mask = '0x'
            keyPtr = key[0:]

        for c in keyPtr:
            if c == '*':
                val += '0'
                mask += '0'
                hasMask = True
            else:
                val += c
                if isBinary: mask += '1'
                else: mask += 'f'
        # print name, ',', val, ',', mask
        if lpmLen != -1:
            mask = lpmLen
        return name, val, mask, hasMask

    def match2int(self, val):
        if isinstance(val, int):
            return val
        if val.startswith('0x'):
            base=16
        elif val.startswith('0b'):
            base=2
        else:
            base=10
        return int(val, base=base)

    def byteLength(self, val):
        value = self.match2int(val)
        if value == 0:
            return 1
        else:
            return int(math.ceil(value.bit_length()/8.0))


    def encodePacket(self, packet):
        if packet is None:
            return None
        p = int(packet, base=16)
        pLen = len(packet)/2 + (len(packet) % 2)
        pad = 0
        if pLen < 20:
            # Pad the packet so that it is sent by the Linux kernel (15 bytes min size)
            pad = 20 - pLen
            self._hasPadding = True
        self._logger.debug("encodePacket: 0x%x (%d len + %d padding)", p, pLen, pad)
        return str(stringify(p, pLen) + '0'*pad)
        # return ''.join('\\x' + x.encode('hex') for x in packet.decode('hex'))
        # return str(''.join(x for x in packet.decode('hex')))
        # return str(('0'*(len(packet) % 2) + packet).decode('hex'))


    def get_mf_match_type(self, table_name, field):
        for t in self.p4info.tables:
            if t.preamble.name == table_name:
                for mf in t.match_fields:
                    if mf.name == field:
                        return mf.match_type
        return MatchType.UNSPECIFIED

    def get_mf_bitwidth(self, table_name, field):
        for t in self.p4info.tables:
            if t.preamble.name == table_name:
                for mf in t.match_fields:
                    if mf.name == field:
                        self._logger.debug("get_mf_bitwidth(%s, %s) = %d", table_name, field, mf.bitwidth)
                        return mf.bitwidth
        self._logger.debug("get_mf_bitwidth(%s, %s) = not found", table_name, field)
        return 0

    def get_ap_bytewidth(self, action, param):
        for a in self.p4info.actions:
            if a.preamble.name == action:
                for p in a.params:
                    if p.name == param:
                        self._logger.debug("get_ap_bitwidth(%s, %s) = %d", action, param, p.bitwidth)
                        return int(math.ceil(p.bitwidth/8.0))
        self._logger.debug("get_ap_bytewidth(%s, %s) = not found", action, param)
        return 0

    def get_mf_match(self, table_name, field, value, length_or_mask):
        match_type = self.get_mf_match_type(table_name, field)
        val = self.match2int(value)
        valLen = int(math.ceil(self.get_mf_bitwidth(table_name, field)/8.0))
        if match_type == MatchType.EXACT:
            self._logger.debug("self.Exact(%s, stringify(0x%x, %d))", field, val, valLen)
            return self.Exact(field, stringify(val, valLen))
        if match_type == MatchType.LPM:
            self._logger.debug("self.LPM(%s, stringify(0x%x, %d), %d)",
                               field, val, valLen, length_or_mask)
            return self.Lpm(field, stringify(val, valLen), length_or_mask)
        if match_type == MatchType.TERNARY:
            self._logger.debug("self.Ternary(%s, stringify(0x%x, %d), stringify(0x%x, %d))",
                               field, val, valLen, self.match2int(length_or_mask), valLen)
            return self.Ternary(field, stringify(val, valLen),
                                stringify(self.match2int(length_or_mask), valLen))
        self._logger.critical("Unsupported match type %s for field %s in table %s",
                              MatchType.to_str(match_type), field, table_name)
        sys.exit(1)
