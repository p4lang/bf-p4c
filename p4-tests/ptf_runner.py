#!/usr/bin/env python2

import argparse
import errno
from functools import wraps
import os
import re
import shutil
import signal
import socket
import subprocess
import stat
import struct
import sys
import tempfile
import time

import grpc
from p4 import p4runtime_pb2
from p4.config import p4info_pb2
from p4.tmp import p4config_pb2
import google.protobuf.text_format

def get_parser():
    parser = argparse.ArgumentParser(description='PTF Test Runner for Harlyn')
    parser.add_argument('--testdir', help='Location of test outputs',
                        type=str, action='store', required=True)
    parser.add_argument('--name', help='Name of P4 program under test',
                        type=str, action='store', required=True)
    parser.add_argument('--ptfdir', help='Directory containing PTF tests',
                        type=str, action="store", required=True)
    parser.add_argument('--top-builddir', help='Build directory root',
                        type=str, action="store", required=True)
    parser.add_argument('--grpc-addr', help='Address to use to connect to '
                        'P4Runtime gRPC server',
                        type=str, action="store",
                        default='localhost:50051')
    return parser

NUM_IFACES = 4

def check_and_add_ifaces():
    ifconfig_out = subprocess.check_output(['ifconfig'])
    iface_list = re.findall(r'^(\S+)', ifconfig_out, re.S | re.M)
    ifaces = set(iface_list)
    found = True
    for i in xrange((NUM_IFACES + 1) * 2):
        iface_name = "veth" + str(i)
        if iface_name not in ifaces:
            found = False
            break

    if found:
        return

    print >> sys.stderr, "Some veth interfaces missing, creating them"
    veth_setup_path = os.path.join(os.path.dirname(os.path.abspath(__file__)),
                                   'tools', 'veth_setup.sh')
    try:
        subprocess.check_call([veth_setup_path])
    except subprocess.CalledProcessError:
        print >> sys.stderr, "Failed to create veth interfaces"
        sys.exit(1)

def findbin(cmake_dir, varname):
    '''Find the value of a variable in the CMake cache'''
    try:
        out = subprocess.check_output(['cmake', '-L', '-N', cmake_dir])
    except subprocess.CalledProcessError:
        print >> sys.stderr, "Unable to access CMake cache"
        sys.exit(1)
    m = re.search('^{}:FILEPATH=(.*)$'.format(varname), out, re.MULTILINE)
    if m is None:
        print >> sys.stderr, "Unable to locate" , varname, "in CMake cache"
        sys.exit(1)
    return m.group(1)

def update_config(name, grpc_addr, p4info_path, tofino_bin_path, cxt_json_path):
    channel = grpc.insecure_channel('localhost:50051')
    stub = p4runtime_pb2.P4RuntimeStub(channel)

    print "Sending P4 config"
    request = p4runtime_pb2.SetForwardingPipelineConfigRequest()
    config = request.configs.add()
    with open(p4info_path, 'r') as p4info_f:
        google.protobuf.text_format.Merge(p4info_f.read(), config.p4info)
    device_config = p4config_pb2.P4DeviceConfig()
    with open(tofino_bin_path, 'rb') as tofino_bin_f:
        with open(cxt_json_path, 'r') as cxt_json_f:
            device_config.device_data = ""
            prog_name = name
            device_config.device_data += struct.pack("<i", len(prog_name))
            device_config.device_data += prog_name
            tofino_bin = tofino_bin_f.read()
            device_config.device_data += struct.pack("<i", len(tofino_bin))
            device_config.device_data += tofino_bin
            cxt_json = cxt_json_f.read()
            device_config.device_data += struct.pack("<i", len(cxt_json))
            device_config.device_data += cxt_json
    config.p4_device_config = device_config.SerializeToString()
    request.action = p4runtime_pb2.SetForwardingPipelineConfigRequest.VERIFY_AND_COMMIT
    try:
        response = stub.SetForwardingPipelineConfig(request)
    except:
        print >> sys.stderr, "Error when trying to push config to bf_switchd"
        # TODO: uncomment when tests enabled
        # return False
    return True

def run_ptf_tests(PTF, ptfdir, p4info_path):
    ifaces = []
    # find base_test.py
    os.environ['PYTHONPATH'] = os.path.dirname(os.path.abspath(__file__))
    for i in xrange(NUM_IFACES):
        iface_idx = i + 1
        ifaces.extend(['-i', '{}@veth{}'.format(iface_idx, 2 * iface_idx + 1)])
    cmd = [PTF]
    cmd.extend(['--test-dir', ptfdir])
    cmd.extend(ifaces)
    cmd.append('--test-params=p4info=\'{}\''.format(p4info_path))
    try:
        # we want the ptf output to be sent to stdout
        p = subprocess.Popen(cmd)
        p.wait()
    except:
        print >> sys.stderr, "Error when running PTF tests"
        return 1
    return p.returncode == 0

def start_model(model, out=None, lookup_json=None):
    cmd = [model]
    if lookup_json is not None:
        cmd.extend(['-l', lookup_json])
    return subprocess.Popen(cmd, stdout=out, stderr=out)

def start_switchd(switchd, status_port, conf_path, out=None):
    cmd = [switchd]
    cmd.extend(['--status-port', str(status_port)])
    cmd.extend(['--install-dir', '/usr/local'])
    cmd.extend(['--conf-file', conf_path])
    cmd.append('--skip-p4')
    cmd.append('--background')
    return subprocess.Popen(cmd, stdout=out, stderr=out)

# From
# https://stackoverflow.com/questions/2281850/timeout-function-if-it-takes-too-long-to-finish
class TimeoutError(Exception):
    pass
def timeout(seconds=10, error_message=os.strerror(errno.ETIME)):
    def decorator(func):
        def _handle_timeout(signum, frame):
            raise TimeoutError(error_message)

        def wrapper(*args, **kwargs):
            signal.signal(signal.SIGALRM, _handle_timeout)
            signal.alarm(seconds)
            try:
                result = func(*args, **kwargs)
            finally:
                signal.alarm(0)
            return result

        return wraps(func)(wrapper)

    return decorator

def poll_device(status_port):
    s = None
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        s.connect( ('localhost', status_port) )
        s.sendall('0')
        r = s.recv(1)
        if r == '1':
            return True
        else:
            return False
    except:
        return False
    finally:
        if s is not None:
            s.close()

def wait_for_switchd(model_p, switchd_p, status_port, timeout_s=100):
    @timeout(timeout_s)
    def wait():
        while True:
            if model_p.poll() is not None:
                return False
            if switchd_p.poll() is not None:
                return False
            if poll_device(status_port):
                return True
            time.sleep(1)
    try:
        return wait()
    except TimeoutError:
        return False
    return True

def sanitize_args(args):
    if os.path.split(args.name)[1] != args.name:
        print >> sys.stderr, "Invalid 'name' argument in PTF runner"
        sys.exit(1)

def main():
    args = get_parser().parse_args()

    sanitize_args(args)

    PTF = findbin(args.top_builddir, 'PTF')
    BF_SWITCHD = findbin(args.top_builddir, 'BF_SWITCHD')
    HARLYN_MODEL = findbin(args.top_builddir, 'HARLYN_MODEL')

    p4info_path = os.path.join(args.testdir, '{}.out'.format(args.name),
                               'p4info.proto.txt')
    if not os.path.exists(p4info_path):
        print >> sys.stderr, "P4Info file", p4info_path, " not found"
        sys.exit(1)

    tofino_bin_path = os.path.join(args.testdir, '{}.out'.format(args.name),
                                   'tofino.bin')
    if not os.path.exists(tofino_bin_path):
        print >> sys.stderr, "Binary config file", tofino_bin_path, " not found"
        sys.exit(1)

    cxt_json_path = os.path.join(args.testdir, '{}.out'.format(args.name),
                                 'tbl-cfg')
    if not os.path.exists(cxt_json_path):
        print >> sys.stderr, "Context json file", cxt_json_path, " not found"
        sys.exit(1)

    check_and_add_ifaces()

    dirname = tempfile.mkdtemp(prefix=args.name)
    os.chmod(dirname, stat.S_IROTH | stat.S_IWOTH | stat.S_IXOTH)
    model_log_path = os.path.join(dirname, 'model.log')
    switchd_log_path = os.path.join(dirname, 'switchd.log')

    # TODO(antonin): in the future, do not restart model and switchd between
    # tests to speed-up testing
    processes = []
    def run():
        with open(model_log_path, 'w') as model_out, \
             open(switchd_log_path, 'w') as switchd_out:
            model_p = start_model(HARLYN_MODEL, out=model_out)
            processes.append(model_p)

            conf_path = os.path.join(
                os.path.dirname(os.path.realpath(__file__)), 'dummy.conf')
            assert(os.path.exists(conf_path))

            switchd_status_port = 6789
            switchd_p = start_switchd(
                BF_SWITCHD, switchd_status_port, conf_path, out=switchd_out)
            processes.append(switchd_p)

            success = wait_for_switchd(model_p, switchd_p, switchd_status_port)
            if not success:
                print >> sys.stderr, "Error when starting model & switchd"
                return False

            success = update_config(args.name, args.grpc_addr,
                                    p4info_path, tofino_bin_path, cxt_json_path)
            if not success:
                print >> sys.stderr, "Error when pushing P4 config to switchd"
                return False

            success = run_ptf_tests(PTF, args.ptfdir, p4info_path)
            if not success:
                print >> sys.stderr, "Error when running PTF tests"
                return False
        return True

    success = run()
    for f in os.listdir(dirname):
        os.chmod(os.path.join(dirname, f), stat.S_IROTH | stat.S_IWOTH)
    for p in processes:
        p.terminate()
    if not success:
        print >> sys.stderr, "See logfiles under", dirname
        sys.exit(1)
    else:
        print "SUCCESS"
        shutil.rmtree(dirname)
        sys.exit(0)

if __name__ == '__main__':
    main()
