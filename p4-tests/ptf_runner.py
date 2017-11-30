#!/usr/bin/env python2

import argparse
from collections import OrderedDict
import errno
from functools import wraps
import logging
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

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("PTF runner")

def error(msg, *args, **kwargs):
    logger.error(msg, *args, **kwargs)

def warn(msg, *args, **kwargs):
    logger.warn(msg, *args, **kwargs)

def info(msg, *args, **kwargs):
    logger.info(msg, *args, **kwargs)

def get_parser():
    parser = argparse.ArgumentParser(description='PTF Test Runner for Harlyn')
    parser.add_argument('--testdir', help='Location of test outputs',
                        type=str, action='store', required=True)
    parser.add_argument('--name', help='Name of P4 program under test',
                        type=str, action='store', required=True)
    parser.add_argument('--ptfdir', help='Directory containing PTF tests',
                        type=str, action="store", required=False)
    parser.add_argument('--top-builddir', help='Build directory root',
                        type=str, action="store", required=False)
    parser.add_argument('--stftest', help='STF file',
                        type=str, action="store", default=None)
    parser.add_argument('--grpc-addr', help='Address to use to connect to '
                        'P4Runtime gRPC server',
                        type=str, action="store",
                        default='localhost:50051')
    parser.add_argument('--keep-logs', help='Keep logs even if test passes',
                        action='store_true', default=False)
    parser.add_argument('--update-config-only',
                        help='Only push the config to bf_switchd',
                        action='store_true', default=False)
    parser.add_argument('--test-only', help='Only run the PTF tests',
                        action='store_true', default=False)
    parser.add_argument('--port-map',
                        help='Use provided port mapping (in Harlyn format); '
                        'when this file is provided, this script will not '
                        'create the default veth ifaces and all the ifaces '
                        'listed in the file must exist and be up',
                        type=str, action='store', required=False)
    return parser

NUM_IFACES = 8

def check_ifaces(ifaces):
    ifconfig_out = subprocess.check_output(['ifconfig'])
    iface_list = re.findall(r'^(\S+)', ifconfig_out, re.S | re.M)
    present_ifaces = set(iface_list)
    ifaces = set(ifaces)
    return ifaces <= present_ifaces

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

    warn("Some veth interfaces missing, creating them")
    veth_setup_path = os.path.join(os.path.dirname(os.path.abspath(__file__)),
                                   'tools', 'veth_setup.sh')
    try:
        subprocess.check_call([veth_setup_path, str((NUM_IFACES + 1) * 2)])
    except subprocess.CalledProcessError:
        error("Failed to create veth interfaces")
        sys.exit(1)

def findbin(cmake_dir, varname):
    '''Find the value of a variable in the CMake cache'''
    try:
        out = subprocess.check_output(['cmake', '-L', '-N', cmake_dir])
    except subprocess.CalledProcessError:
        error("Unable to access CMake cache")
        sys.exit(1)
    m = re.search('^{}:FILEPATH=(.*)$'.format(varname), out, re.MULTILINE)
    if m is None:
        error("Unable to locate {} in CMake cache".format(varname))
        sys.exit(1)
    return m.group(1)

def update_config(name, grpc_addr, p4info_path, tofino_bin_path, cxt_json_path):
    channel = grpc.insecure_channel(grpc_addr)
    stub = p4runtime_pb2.P4RuntimeStub(channel)

    info("Sending P4 config")
    request = p4runtime_pb2.SetForwardingPipelineConfigRequest()
    request.device_id = 0
    config = request.config
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
    except Exception as e:
        error("Error when trying to push config to bf_switchd")
        error(str(e))
        return False
    return True

def run_ptf_tests(PTF, grpc_addr, ptfdir, p4info_path, port_map, stftest,
                  extra_args=[]):
    ifaces = []
    # find base_test.py
    pypath = os.path.dirname(os.path.abspath(__file__))
    if 'PYTHONPATH' in os.environ:
        os.environ['PYTHONPATH'] += ":" + pypath
    else:
        os.environ['PYTHONPATH'] = pypath
    for iface_idx, iface_name in port_map.items():
        ifaces.extend(['-i', '{}@{}'.format(iface_idx, iface_name)])
    cmd = [PTF]
    cmd.extend(['--test-dir', ptfdir])
    cmd.extend(ifaces)
    test_params = 'p4info=\'{}\''.format(p4info_path)
    test_params += ';grpcaddr=\'{}\''.format(grpc_addr)
    if stftest is not None:
        test_params += ';stftest=\'{}\''.format(stftest)
    cmd.append('--test-params={}'.format(test_params))
    cmd.extend(extra_args)
    info("Executing PTF command: {}".format(' '.join(cmd)))

    try:
        # we want the ptf output to be sent to stdout
        p = subprocess.Popen(cmd)
        p.wait()
    except:
        error("Error when running PTF tests")
        return False
    return p.returncode == 0

def start_model(model, out=None, lookup_json=None, port_map_path=None):
    cmd = [model]
    if lookup_json is not None:
        cmd.extend(['-l', lookup_json])
    if port_map_path is not None:
        cmd.extend(['-f', port_map_path])
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
                error("Model is not running")
                return False
            if switchd_p.poll() is not None:
                error("Switchd is not running")
                return False
            if poll_device(status_port):
                return True
            time.sleep(1)
    try:
        return wait()
    except TimeoutError:
        error("Timed out while waiting for switchd to be ready")
        return False
    return True

def sanitize_args(args):
    if os.path.split(args.name)[1] != args.name:
        error("Invalid 'name' argument in PTF runner")
        sys.exit(1)
    if args.test_only and args.update_config_only:
        error("Cannot use --test-only and --update-config-only")
        sys.exit(1)
    if (not args.update_config_only) and (args.ptfdir is None):
        error("Missing --ptfdir")
        sys.exit(1)
    if args.top_builddir is not None and not os.path.exists(args.top_builddir):
        error("Invalid --top-builddir")
        sys.exit(1)

def main():
    args, unknown_args = get_parser().parse_known_args()

    sanitize_args(args)

    if unknown_args and args.update_config_only:
        error("Extra args not supported with --update-config-only and will be ignored")
    extra_ptf_args = unknown_args

    compiler_out_dir = args.testdir

    p4info_path = os.path.join(compiler_out_dir, 'p4info.proto.txt')
    if not os.path.exists(p4info_path):
        error("P4Info file {} not found".format(p4info_path))
        sys.exit(1)

    tofino_bin_path = os.path.join(compiler_out_dir, 'tofino.bin')
    if not os.path.exists(tofino_bin_path):
        error("Binary config file {} not found".format(tofino_bin_path))
        sys.exit(1)

    cxt_json_path = os.path.join(compiler_out_dir, 'context.json')
    if not os.path.exists(cxt_json_path):
        error("Context json file {} not found".format(cxt_json_path))
        sys.exit(1)

    if args.stftest is not None and not os.path.exists(args.stftest):
        error("STF test {} requested and not found".format(args.stftest))
        sys.exit(1)

    lookup_json_path = os.path.join(compiler_out_dir, 'p4_name_lookup.json')
    if not os.path.exists(lookup_json_path):
        warn("Name lookup json {} not found; debugging will be harder".format(
            lookup_json_path))

    port_map_path = args.port_map
    if port_map_path is not None and not os.path.exists(port_map_path):
        error("Provided port mapping file {} not found".format(port_map_path))
        sys.exit(1)

    if args.update_config_only:
        success = update_config(args.name, args.grpc_addr,
                                p4info_path, tofino_bin_path, cxt_json_path)
        if not success:
            error("Error when pushing P4 config to switchd")
            sys.exit(1)
        sys.exit(0)

    if args.top_builddir is None:
        top_builddir = os.path.join(
            os.path.dirname(os.path.abspath(__file__)),
            os.pardir,
            'build')
        if not os.path.exists(top_builddir):
            error("Please provide --top-builddir")
            sys.exit(1)
    else:
        top_builddir = args.top_builddir

    port_map = OrderedDict()
    if port_map_path is None:
        for iface_idx in xrange(NUM_IFACES):
            port_map[iface_idx] = 'veth{}'.format(2 * iface_idx + 1)
        check_and_add_ifaces()
    else:
        import json
        with open(port_map_path) as port_map_f:
            try:
                jdict = json.load(port_map_f)
                for jentry in jdict['PortToIf']:
                    iface_idx = jentry['device_port']
                    iface_name = jentry['if']
                    port_map[iface_idx] = iface_name
            except:
                error("Error when parsing JSON port mapping file {}".format(
                    port_map_path))
                sys.exit(1)
        if not check_ifaces(port_map.values()):
            error("Some interfaces referenced in the port mapping file don't exist")
            sys.exit(1)

    PTF = findbin(top_builddir, 'PTF')

    if args.test_only:
        success = run_ptf_tests(PTF, args.grpc_addr, args.ptfdir, p4info_path,
                                port_map, args.stftest, extra_ptf_args)
        if not success:
            error("Error when running PTF tests")
            sys.exit(1)
        sys.exit(0)

    BF_SWITCHD = findbin(top_builddir, 'BF_SWITCHD')
    HARLYN_MODEL = findbin(top_builddir, 'HARLYN_MODEL')

    dirname = tempfile.mkdtemp(prefix=args.name)
    os.chmod(dirname, 0o777)
    model_log_path = os.path.join(dirname, 'model.log')
    switchd_log_path = os.path.join(dirname, 'switchd.log')

    # TODO(antonin): in the future, do not restart model and switchd between
    # tests to speed-up testing
    processes = {}
    def run():
        with open(model_log_path, 'w') as model_out, \
             open(switchd_log_path, 'w') as switchd_out:
            model_p = start_model(HARLYN_MODEL, out=model_out,
                                  lookup_json=lookup_json_path,
                                  port_map_path=port_map_path)
            processes["model"] = model_p

            conf_path = os.path.join(
                os.path.dirname(os.path.realpath(__file__)), 'dummy.conf')
            assert(os.path.exists(conf_path))

            switchd_status_port = 6789
            switchd_p = start_switchd(
                BF_SWITCHD, switchd_status_port, conf_path, out=switchd_out)
            processes["switchd"] = switchd_p

            success = wait_for_switchd(model_p, switchd_p, switchd_status_port)
            if not success:
                error("Error when starting model & switchd")
                return False

            success = update_config(args.name, args.grpc_addr,
                                    p4info_path, tofino_bin_path, cxt_json_path)
            if not success:
                error("Error when pushing P4 config to switchd")
                return False

            success = run_ptf_tests(PTF, args.grpc_addr, args.ptfdir,
                                    p4info_path, port_map,
                                    args.stftest, extra_ptf_args)
            if not success:
                error("Error when running PTF tests")
                return False
        return True

    success = run()

    for pname, p in processes.items():
        try:
            p.terminate()
        except:
            error("Error when trying to terminate {}".format(pname))

    # move bf_drivers log to log file directory
    if os.path.exists('bf_drivers.log'):
        try:
            shutil.move('bf_drivers.log', dirname)
        except:
            error("Error when copying 'bf_drivers.log'")
    else:
        error("Could not find 'bf_drivers.log' in CWD")

    if os.path.exists('ptf.log'):
        shutil.move('ptf.log', dirname)

    for f in os.listdir(dirname):
        os.chmod(os.path.join(dirname, f), 0o666)

    if not success:
        info("See logfiles under {}".format(dirname))
        sys.exit(1)
    else:
        info("SUCCESS")
        if args.keep_logs:
            info("Log files are under {}".format(dirname))
        else:
            shutil.rmtree(dirname)
        sys.exit(0)

if __name__ == '__main__':
    main()
