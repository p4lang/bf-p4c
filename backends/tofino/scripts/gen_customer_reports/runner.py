#!/usr/bin/env python3

import os
import subprocess
import sys
import threading

class RunCmd(threading.Thread):
    def __init__(self, cmd, timeout):
        threading.Thread.__init__(self)
        self.cmd = cmd
        self.timeout = timeout
        self.return_code = None
        self.out = None
        self.err = None
        self.is_timed_out = False
        self.Run()

    def run(self):
        self.p = subprocess.Popen(self.cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
        self.out = self.p.stdout
        self.err = self.p.stderr
        self.return_code = self.p.returncode

    def Run(self):
        self.start()
        self.join(self.timeout)

        if self.is_alive():
            print ('\nTerminating process for command:', self.cmd)
            self.is_timed_out = True
            self.p.terminate()
            self.join(10)
            print ('Process terminated')
