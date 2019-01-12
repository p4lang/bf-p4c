import sys, os.path
from string import maketrans
import logging
import math
import random
import re
import time
import traceback
import unittest
from ptf import config
from ptf.testutils import *
from ptf.mask import Mask

import ptf.testutils as testutils

from p4.v1 import p4runtime_pb2
from p4.tmp import p4config_pb2
from p4.config.v1 import p4info_pb2

from p4runtime_base_tests import P4RuntimeTest
from p4runtime_base_tests import stringify

from stf_parser import STFParser
from stf_runner import STFRunner, STFNamedEntry

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

class STF2ptf(P4RuntimeTest, STFRunner):

    def setUp(self):
        logging.info("p4info: %s", testutils.test_param_get("p4info"))
        logging.info("stftest: %s", testutils.test_param_get("stftest"))
        self._requests = []
        self._hasPadding = False
        self._hasByteCounters = False
        self._tern2zero = maketrans('*','0')


        P4RuntimeTest.setUp(self)
        stftest = testutils.test_param_get("stftest")
        testname, ext = os.path.splitext(os.path.basename(stftest))
        parser = STFParser()
        ast, errs = parser.parse(filename=stftest)
        if errs != 0:
            sys.exit(1)
        STFRunner.__init__(self, ast, testname)


    def runTest(self):
        STFRunner.runTest(self)

    def testEnd(self):
        testutils.verify_no_other_packets(self)

    def testCleanup(self):
        if self._hasPadding and self._hasByteCounters:
            self._logger.warning("Mixing small packets and byte-counters produce incorrect results.\n" \
                                 + "Please increase the size of your packets to be > 15 bytes")
        self.undo_write_requests(self._requests)

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
        table_size = self.get_table_size(table)
        needs_priority = self.table_has_ternary_match(table)
        # The P4Runtime server will complain if a non-zero (i.e. non-default)
        # priority value is provided for non-ternary match tables (i.e. a match
        # table with no Ternary or Range match fields)
        table_entry.priority = 0
        if needs_priority and priority is not None:
            table_entry.priority = int(priority, base=10)
            # STF defines priorities as higher numbers mean higher priorities.
            # However, the current bf-driver implementation interprets lower
            # numbers as higher priorities.
            table_entry.priority = table_size - table_entry.priority
        elif (not needs_priority) and (priority is not None):
            self._logger.warning("Priority value provided for non-ternary table will be discarded")
        self.set_match_key(table_entry, table, self.genMatchKey(table, match_list))
        self.set_action_entry(table_entry, action,
                              self.genActionParamList(action, action_params))
        # self._logger.debug("req: %s", str(req))
        reply = self._write(req)
        self._requests.append(req)

        # bookeeping for aliases (mainly used to name counters)
        if entry[5] is not None:
            match_name, match, mask, hasMask = self.match2spec(table, match_list[0][0], match_list[0][1])
            self._namedEntries[entry[5]] = STFNamedEntry(table, match_name, match, mask, table_entry.priority)

    def genMatchKey(self, table, match_list):
        """
            Generate the match_spec
        """
        matches = []
        for match_spec in match_list:
            match_name, match, mask, hasMask = self.match2spec(table, match_spec[0], match_spec[1])
            matches.append(self.get_mf_match(table, match_name, match, mask))
        return matches

    def genActionParamList(self, action, action_params):
        """
            generate action_spec_t with values for action params
        """
        params = []
        for ap in action_params:
            name, val, mask, hasMask = self.match2spec(None, ap[0], ap[1])
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
        self.set_action(table_entry.action.action, action,
                        self.genActionParamList(action, action_params))
        table_entry.is_default_action = True
        reply = self._write(req)
        # resetting default actions is not supported in P4Runtime
        # self._requests.append(req)

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
            # testutils.verify_packet(self, None, port)
            testutils.count_matched_packets_all_ports(self, None, [port])
            return
        elif orig_packet is None:
            packet = payload.translate(self._tern2zero)
            p = int(packet, base=16)
            pLen = len(packet)/2 + (len(packet) % 2)
            expected = Mask(stringify(p, pLen), ignore_extra_bytes=True)
            if '*' in payload:
                offset = 0
                for x in payload:
                    if x == '*': expected.set_do_not_care(offset, 4)
                    offset += 4
        else:
            expected = self.encodePacket(self.setExpectTern(payload, orig_packet[2]), padIt = False)
        testutils.verify_packet(self, expected, port)
        self._logger.info("Expected packet {} received on port {}".format(payload, port))

    def genCheckCounter(self, chk):
        """
           Generate a check counter request and verify
        """
        isDirect = True
        counterName = chk[1]
        if str(chk[2]).startswith('$'):
            varName = chk[2][1:]
            assert varName in self._namedEntries, "Invalid named entry " + chk[2]
            table = self._namedEntries[varName]._tableName
            counterIndex = self._namedEntries[varName]._value
            isDirect = True
        else:
            counterIndex = int(chk[2])
            isDirect = False

        self._logger.info("check_counter %s(%s)", counterName, counterIndex)
        rr = p4runtime_pb2.ReadRequest()
        rr.device_id = self.device_id
        reqCounter = rr.entities.add()
        counterId = None
        if isDirect:
            counter_entry = reqCounter.direct_counter_entry
            counter_entry.table_entry.table_id = self.get_table_id(table)
            self.set_match_key(counter_entry.table_entry, table,
                               [self.get_mf_match(table,
                                                  self._namedEntries[varName]._fieldName,
                                                  self._namedEntries[varName]._value,
                                                  self._namedEntries[varName]._mask)])
            counter_entry.table_entry.priority = self._namedEntries[varName]._priority
        else:
            counter_entry = reqCounter.counter_entry
            counterId = self.get_counter_id(counterName)
            counter_entry.counter_id = counterId
            counter_entry.index.index = counterIndex
        try:
            foundCounter = False
            count_mode = chk[3][0]
            received = -1
            if count_mode is not None:
                compare_op = chk[3][1]
                expected_val = int(chk[3][2])
                if count_mode != 'packets':
                    self._hasByteCounters = True
            else:
                # the default test is 'packets == 0'
                count_mode = 'packets'
                compare_op = "=="
                expected_val = 0

            condition = "False"
            iteration = 0
            while (iteration < 20):

                self._logger.info("iteration %d, received %d", iteration, received)

                if iteration > 0:
                    time.sleep(1)

                for rep in self.stub.Read(rr):
                    for entity in rep.entities:
                        counter = None
                        if isDirect:
                            counter = entity.direct_counter_entry
                            if counter.table_entry.SerializeToString() != counter_entry.table_entry.SerializeToString():
                                continue
                        else:
                            counter = entity.counter_entry
                            if counter.counter_id != counterId or counter.index.index != counterIndex:
                                continue

                        foundCounter = True
                        if count_mode == 'packets':
                            received = counter.data.packet_count
                        else:
                            received = counter.data.byte_count

                if foundCounter:
                    condition = "{} {} {}".format(received, compare_op, expected_val)
                    if eval(condition): # success!
                        break
                else:
                    # no use to repeatedly count if we couldn't find the counter the first time
                    break

                iteration += 1

            if not foundCounter:
                self.fail("Failed to retrieve counter {}".format(counterName))

            self.assertTrue(eval(condition),
                            "{}: wrong {} count: expected {} not {}".format(counterName,
                                                                            count_mode,
                                                                            expected_val,
                                                                            received))

        except Exception as e:
            self._logger.exception(e)
            self.fail("Failed to read counter:\n %s" % traceback.format_exc())


    def genWaitStmt(self):
        """
        Generate a wait stmt
        """
        time.sleep(1)
        return

    def match2spec(self, table_name, match_name, match):
        """
            Turns a match into (escaped name, value, mask, hasMask)
            Returning a hasMask = False means there were no don't care symbols in the value
        """
        name = match_name.translate(self._transTable)
        # STF also allows stacks to be expressed as name$index
        def replStackIndex(matchobj):
            if matchobj.group(2) is not None:
                return matchobj.group(1) + '[' + matchobj.group(2) + ']' + matchobj.group(3)
        name = re.sub(r"(\w+)\$(\d+)(.*)", replStackIndex, name)
        # The latest P4runtime serialization uses data.$valid$, so we convert
        # $valid into $valid$
        if re.match("[\.\w]+\$valid$", name):
            name += "$"

        # check that the name exists in p4info,
        # and rename with fully qualified name or fail
        if table_name is not None:
            found = False
            t = self.get_table(table_name)
            if t is not None:
                field_names = [ mf.name for mf in t.match_fields ]
                if name not in field_names:
                    for x in field_names:
                        if x.endswith(name) or x == name + ".$valid$":
                            name = x
                            found = True
                else:
                    found = True
            self.assertTrue(found, "Invalid match name %s for table %s" % \
                            (match_name, table_name))

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
        isLpm = table_name is not None and \
                self.get_mf_match_type(table_name, name) == MatchType.LPM
        if isLpm:
            lpmLen = bin(int(mask, base=0)).count('1')
        if lpmLen != -1:
            mask = lpmLen
        return name, val, mask, hasMask

    def match2int(self, val):
        return int(val, base=0)

    def byteLength(self, val):
        value = self.match2int(val)
        if value == 0:
            return 1
        else:
            return int(math.ceil(value.bit_length()/8.0))


    def encodePacket(self, packet, padIt = True):
        if packet is None:
            return None
        p = int(packet, base=16)
        pLen = len(packet)/2 + (len(packet) % 2)
        pad = 0
        if padIt and pLen < 20:
            # Pad the packet so that it is sent by the Linux kernel (15 bytes min size)
            pad = 20 - pLen
            self._hasPadding = True
        self._logger.debug("encodePacket: 0x%x (%d len + %d padding)", p, pLen, pad)
        return str(stringify(p, pLen) + '0'*pad)
        # return ''.join('\\x' + x.encode('hex') for x in packet.decode('hex'))
        # return str(''.join(x for x in packet.decode('hex')))
        # return str(('0'*(len(packet) % 2) + packet).decode('hex'))


    def get_table_size(self, table_name):
        t = self.get_table(table_name)
        return 1024 if t is None else int(t.size)

    def table_has_ternary_match(self, table_name):
        t = self.get_table(table_name)
        if t is not None:
            for mf in t.match_fields:
                if mf.match_type in {MatchType.TERNARY, MatchType.RANGE}:
                    return True
        return False

    def get_mf_match_type(self, table_name, field):
        t = self.get_table(table_name)
        if t is not None:
            for mf in t.match_fields:
                if mf.name == field:
                    return mf.match_type
        return MatchType.UNSPECIFIED

    def get_mf_bitwidth(self, table_name, field):
        t = self.get_table(table_name)
        if t is not None:
            for mf in t.match_fields:
                if mf.name == field:
                    return mf.bitwidth
        return 0

    def get_ap_bytewidth(self, action_name, param):
        a = self.get_action(action_name)
        if a is not None:
            for p in a.params:
                if p.name == param:
                    return (p.bitwidth + 7) / 8
        return 0

    def get_mf_match(self, table_name, field, value, length_or_mask):
        std_metadata = ["ingress_port", "egress_spec", "egress_port",
                        "clone_spec", "instance_type", "drop",
                        "recirculate_port", "packet_length"
        ]
        match_type = self.get_mf_match_type(table_name, field)
        # try as metadata if the field was not found
        if match_type == MatchType.UNSPECIFIED and field in std_metadata:
            field = "standard_metadata." + field
            match_type = self.get_mf_match_type(table_name, field)

        val = self.match2int(value)
        valLen = int(math.ceil(self.get_mf_bitwidth(table_name, field)/8.0))
        if match_type == MatchType.EXACT:
            self._logger.debug("self.Exact({0}, stringify(0x{1:x}, {2}))".format(field, val, valLen))
            return self.Exact(field, stringify(val, valLen))
        if match_type == MatchType.LPM:
            self._logger.debug("self.LPM({}, stringify(0x{:x}, {}), {})".format(field, val, valLen, length_or_mask))
            return self.Lpm(field, stringify(val, valLen), length_or_mask)
        if match_type == MatchType.TERNARY:
            self._logger.debug("self.Ternary({}, stringify(0x{:x}, {}), stringify(0x{:x}, {}))".format(field, val, valLen, self.match2int(length_or_mask), valLen))
            return self.Ternary(field, stringify(val, valLen),
                                stringify(self.match2int(length_or_mask), valLen))
        self.fail("Unsupported match type %s for field %s in table %s" % \
                  (MatchType.to_str(match_type), field, table_name))
