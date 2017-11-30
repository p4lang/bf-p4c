import ptf
import os
from ptf import config
import ptf.testutils as testutils

from p4 import p4runtime_pb2
from p4.tmp import p4config_pb2
from p4.config import p4info_pb2
import google.protobuf.text_format

from base_test import P4RuntimeTest, stringify, autocleanup

# TODO(antonin): add some PTF tests when program compiles
class DummyTest(P4RuntimeTest):
    @autocleanup
    def runTest(self):
        pass
