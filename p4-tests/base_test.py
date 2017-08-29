# Copyright 2013-present Barefoot Networks, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

#
# Antonin Bas (antonin@barefootnetworks.com)
#
#

import sys

import ptf
from ptf.base_tests import BaseTest
from ptf import config
import ptf.testutils as testutils

import grpc

from p4 import p4runtime_pb2
from p4.tmp import p4config_pb2
from p4.config import p4info_pb2
import google.protobuf.text_format

# Convert integer (with length) to binary byte string
# Equivalent to Python 3.2 int.to_bytes
# See
# https://stackoverflow.com/questions/16022556/has-python-3-to-bytes-been-back-ported-to-python-2-7
def stringify(n, length):
    h = '%x' % n
    s = ('0'*(len(h) % 2) + h).zfill(length*2).decode('hex')
    return s

# This code is common to all tests. setUp() is invoked at the beginning of the
# test and tearDown is called at the end, no matter whether the test passed /
# failed / errored.
class P4RuntimeTest(BaseTest):
    def setUp(self):
        BaseTest.setUp(self)
        self.device_id = 0

        # Setting up PTF dataplane
        self.dataplane = ptf.dataplane_instance
        self.dataplane.flush()

        self.channel = grpc.insecure_channel('localhost:50051')
        self.stub = p4runtime_pb2.P4RuntimeStub(self.channel)

        proto_txt_path = testutils.test_param_get("p4info")
        print "Importing p4info proto from", proto_txt_path
        self.p4info = p4info_pb2.P4Info()
        with open(proto_txt_path, "rb") as fin:
            google.protobuf.text_format.Merge(fin.read(), self.p4info)

    def tearDown(self):
        BaseTest.tearDown(self)

    def get_id(self, name, attr):
        for o in getattr(self.p4info, attr):
            pre = o.preamble
            if pre.name == name:
                return pre.id

    def get_table_id(self, name):
        return self.get_id(name, "tables")

    def get_ap_id(self, name):
        return self.get_id(name, "action_profiles")

    def get_action_id(self, name):
        return self.get_id(name, "actions")

    def get_counter_id(self, name):
        return self.get_id(name, "counters")

    def get_direct_counter_id(self, name):
        return self.get_id(name, "direct_counters")

    def get_param_id(self, action_name, name):
        for a in self.p4info.actions:
            pre = a.preamble
            if pre.name == action_name:
                for p in a.params:
                    if p.name == name:
                        return p.id

    def get_mf_id(self, table_name, name):
        for t in self.p4info.tables:
            pre = t.preamble
            if pre.name == table_name:
                for mf in t.match_fields:
                    if mf.name == name:
                        return mf.id

    # These are attempts at convenience functions aimed at making writing
    # P4Runtime PTF tests easier.

    class MF(object):
        def __init__(self, name):
            self.name = name

    class Exact(MF):
        def __init__(self, name, v):
            logging.debug("Adding Exact match (%s, %s)", name, v)
            super(P4RuntimeTest.Exact, self).__init__(name)
            self.v = v

        def add_to(self, mf_id, mk):
            mf = mk.add()
            mf.field_id = mf_id
            mf.exact.value = self.v

    class Lpm(MF):
        def __init__(self, name, v, pLen):
            super(P4RuntimeTest.Lpm, self).__init__(name)
            self.v = v
            self.pLen = pLen

        def add_to(self, mf_id, mk):
            mf = mk.add()
            mf.field_id = mf_id
            mf.lpm.prefix_len = self.pLen
            mf.lpm.value = self.v

    class Ternary(MF):
        def __init__(self, name, v, mask):
            super(P4RuntimeTest.Ternary, self).__init__(name)
            self.v = v
            self.mask = mask

        def add_to(self, mf_id, mk):
            mf = mk.add()
            mf.field_id = mf_id
            mf.ternary.mask = self.mask
            mf.ternary.value = self.v

    # Sets the match key for a p4::TableEntry object. mk needs to be an iterable
    # object of MF instances.
    def set_match_key(self, table_entry, t_name, mk):
        for mf in mk:
            mf_id = self.get_mf_id(t_name, mf.name)
            mf.add_to(mf_id, table_entry.match)

    def set_action(self, action, a_name, params):
        action.action_id = self.get_action_id(a_name)
        for p_name, v in params:
            param = action.params.add()
            param.param_id = self.get_param_id(a_name, p_name)
            param.value = v

    # Sets the action & action data for a p4::TableEntry object. params needs to
    # be an iterable object of 2-tuples (<param_name>, <value>).
    def set_action_entry(self, table_entry, a_name, params):
        self.set_action(table_entry.action.action, a_name, params)

    # iterates over all requests; if they are INSERT updates, replay them as
    # DELETE updates; this is a convenient way to clean-up a lot of switch state
    def undo_write_requests(self, reqs):
        updates = []
        for req in reqs:
            for i in xrange(len(req.updates)):
                update = req.updates.pop()
                if update.type == p4runtime_pb2.Update.INSERT:
                    updates.append(update)
        new_req = p4runtime_pb2.WriteRequest()
        new_req.device_id = self.device_id
        for update in updates:
            update.type = p4runtime_pb2.Update.DELETE
            new_req.updates.add().CopyFrom(update)
        rep = self.stub.Write(new_req)
