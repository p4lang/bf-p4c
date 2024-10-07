#!/usr/bin/env python3

import os
import subprocess
import sys
import threading

class RunCmd:
    def __init__(self, cmd, timeout):
        threading.Thread.__init__(self)
        self.cmd = cmd
        self.timeout = timeout
        self.return_code = None
        self.out = None
        self.err = None
        self.run()

    def run(self):
        try:
            result = subprocess.run(self.cmd, shell=True, capture_output=True,
                                    encoding="utf-8", timeout=self.timeout)
            self.out = result.stdout
            self.err = result.stderr
            self.return_code = result.returncode
        except subprocess.TimeoutExpired as to:
            print("Timeout, process killed")
            if to.stdout is not None:
                print("stdout:\n", to.stdout)
            if to.stderr is not None:
                print("stderr:\n", to.stderr)
            raise
