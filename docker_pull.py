#!/usr/bin/env python2

from __future__ import print_function
import os
import sys
import argparse
from time import sleep
from subprocess import Popen, PIPE
from threading import Timer

# Docker pull script timeeout (60 mins)
pull_timeout = 3600
# Docker pull command timeout (20 mins)
cmd_timeout = 1200

# Print to stderr
def eprint(*args, **kwargs):
    print(*args, file=sys.stderr, **kwargs)

def runner(cmd, cmd_timeout):
    m_process = Popen(cmd, stdout=PIPE, shell=True)
    m_timer = Timer(cmd_timeout, m_process.kill)
    rc = -1

    try:
        m_timer.start()
        while True:
            line = m_process.stdout.readline()
            if line == '' and m_process.poll() is not None:
                break
            if line:
                eprint(line.strip())
        rc = m_process.poll()
    finally:
        m_timer.cancel()
    
    return rc

def get_parser():
    parser = argparse.ArgumentParser(description='Wait for docker image to be available and pull')
    parser.add_argument('--image', help='Docker image tag to pull',
                        type=str, action='store', required=True)
    return parser

def main():
    args = get_parser().parse_args()
    docker_cmd = "docker pull " + args.image
    pull_success = False
    elapsed_time = 0

    eprint('docker pull command:', docker_cmd)
    
    while pull_success or elapsed_time < pull_timeout:
        rc = runner(docker_cmd, cmd_timeout)
        if rc == 0:
            pull_success = True
            break
        else:
            eprint('docker image not yet available')
        sleep(60)
        elapsed_time += 60
    
    if pull_success:
        eprint('docker pull success')
    else:
        eprint('Timed out waiting for docker image to be available')

if __name__ == '__main__':
    main()
