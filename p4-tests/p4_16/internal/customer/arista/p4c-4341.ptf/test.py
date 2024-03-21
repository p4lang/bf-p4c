from bfruntime_base_tests import BfRuntimeTest

class TestAtcamNumberPartitions(BfRuntimeTest):
    def setUp(self):
        BfRuntimeTest.setUp(self, 0, 'p4c_4341')

    def runTest(self):
        self.set_bfrt_info(self.parse_bfrt_info(self.get_bfrt_info('p4c_4341')))
        dev_id = 0
        target = self.Target(device_id=dev_id, pipe_id=0xffff)

        table_size = 4096
        for i in range(1, table_size): # starts at 1 because of a default action
            self.insert_table_entry(target,
                                    'pipe.DeRidder',
                                    [self.KeyField('Tofte.Osyka', self.to_bytes(i % 512, 2)),
                                     self.KeyField('Swifton.Commack', self.to_bytes(i, 16), prefix_len=128)],
                                    'Rhodell',
                                    [self.DataField('Calabash', self.to_bytes(i, 2))])
