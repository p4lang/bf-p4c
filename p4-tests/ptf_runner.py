#!/usr/bin/env python2

import argparse
from collections import OrderedDict
import errno
from functools import wraps
import logging
import os
import pexpect
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
from p4.v1 import p4runtime_pb2
from p4.config.v1 import p4info_pb2
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

def debug(msg, *args, **kwargs):
    logger.debug(msg, *args, **kwargs)

def get_parser():
    parser = argparse.ArgumentParser(description='PTF Test Runner for Harlyn')
    parser.add_argument('--testdir', help='Location of test outputs',
                        type=str, action='store', required=True)
    parser.add_argument('--name', help='Name of P4 program under test',
                        type=str, action='store', required=True)
    parser.add_argument('--ptfdir', help='Directory containing PTF tests',
                        type=str, action="store", required=False)
    parser.add_argument('--pdtest', help='Directory containing the PD conf file',
                        type=str, action="store", required=False, default=None)
    parser.add_argument('--port_map_file', help='Directory containing the PD SAI portmap file',
                        type=str, action="store", required=False, default=None)
    parser.add_argument('--test_port', help='Test port number for some PD tests',
                        type=str, action="store", required=False, default=None)
    # mutually exclusive with --pdtest
    parser.add_argument('--bfrt-test', help='Directory containing the BFRT conf file',
                        type=str, action="store", required=False, default=None)
    # This is needed because the existing p4-16 v1model tests are written for PI,
    # despite that the conf file is generated with bfrt syntax, as a result,
    # we cannot rely on the conf file information to infer the test type.
    parser.add_argument('--run-bfrt-as-pi', help='Run test with bfrt conf as PI',
                        type=str, action='store', default=None, nargs="+")
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
    parser.add_argument('--verbose-model-log', help='Dump verbose model log',
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
    parser.add_argument('--platform',
                        help='String identifying the target platform on which '
                        'tests are run',
                        type=str, action='store', required=False)
    parser.add_argument('--device', help='Target device',
                         choices=['tofino', 'tofino2'], default='tofino',
                         type=str, action='store', required=False)
    parser.add_argument('--xml-output', action='store_true', required=False,
                        help='Generate output in JUnit XML format')
    parser.add_argument('--enable-model-logging', action='store_true', default=False,
                        help='Enable model logging for debug purposes')
    return parser

DEFAULT_NUM_IFACES = 16
DEFAULT_IFACES = ["veth{}".format(i) for i in xrange((DEFAULT_NUM_IFACES + 1) * 2)]
# Add Ethernet CPU port
DEFAULT_IFACES += ["veth250", "veth251"]

def check_ifaces(ifaces):
    ifconfig_out = subprocess.check_output(['ifconfig'])
    iface_list = re.findall(r'^(\S+)', ifconfig_out, re.S | re.M)
    present_ifaces = set(iface_list)
    ifaces = set(ifaces)
    return ifaces <= present_ifaces

def check_and_add_ifaces():
    if check_ifaces(DEFAULT_IFACES):
        return

    warn("Some veth interfaces missing, creating them")
    veth_setup_path = os.path.join(os.path.dirname(os.path.abspath(__file__)),
                                   'p4testutils', 'veth_setup.sh')
    try:
        subprocess.check_call([veth_setup_path, str((DEFAULT_NUM_IFACES + 1) * 2)])
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

def update_config(name, grpc_addr, p4info_path, bin_path, cxt_json_path):
    channel = grpc.insecure_channel(grpc_addr)
    stub = p4runtime_pb2.P4RuntimeStub(channel)

    info("Sending P4 config")
    request = p4runtime_pb2.SetForwardingPipelineConfigRequest()
    request.device_id = 0
    config = request.config
    with open(p4info_path, 'r') as p4info_f:
        google.protobuf.text_format.Merge(p4info_f.read(), config.p4info)
    device_config = p4config_pb2.P4DeviceConfig()
    with open(bin_path, 'rb') as bin_f:
        with open(cxt_json_path, 'r') as cxt_json_f:
            device_config.device_data = ""
            prog_name = name
            device_config.device_data += struct.pack("<i", len(prog_name))
            device_config.device_data += prog_name
            bin = bin_f.read()
            device_config.device_data += struct.pack("<i", len(bin))
            device_config.device_data += bin
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

def run_pi_ptf_tests(PTF, grpc_addr, ptfdir, p4info_path, port_map, stftest,
                  platform, verbose_model_log, extra_args=[]):
    if verbose_model_log:
        enable_verbose_model_log()

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
    if platform is not None:
        test_params += ';pltfm=\'{}\''.format(platform)
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

def run_pd_ptf_tests(PTF, device, p4name, config_file, ptfdir, testdir, platform, port_map,
                     verbose_model_log, extra_args=[], port_map_file=None, test_port=None, 
                     installdir="/usr/local"):
    if verbose_model_log:
        enable_verbose_model_log()

    ifaces = []
    # find p4ptfutils
    ptfutils = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'p4testutils')
    if 'PYTHONPATH' in os.environ:
        os.environ['PYTHONPATH'] += ":" + ptfutils
    else:
        os.environ['PYTHONPATH'] = ptfutils
    # find pd generated python files
    site_pkg = os.path.join('lib', 'python2.7', 'site-packages')
    # for switchapi
    os.environ['PYTHONPATH'] += ":" + os.path.join(testdir, site_pkg)
    # for pdfixed
    os.environ['PYTHONPATH'] += ":" + os.path.join(testdir, site_pkg, device+'pd')
    # res_pd_rpc -- bf-drivers still uses tofino to install res_pd_rpc: 'tofino' should be device
    if installdir == "/usr/local":
        res_pd_rpc = os.path.join(installdir, 'lib', 'python2.7', 'dist-packages', 'tofino')
    else:
        res_pd_rpc = os.path.join(installdir, 'lib', 'python2.7', 'site-packages', 'tofino')
    os.environ['PYTHONPATH'] += ":" + res_pd_rpc
    debug('PYTHONPATH={}'.format(os.environ['PYTHONPATH']))

    if port_map_file is None:
        for iface_idx, iface_name in port_map.items():
            ifaces.extend(['-i', '{}@{}'.format(iface_idx, iface_name)])
    cmd = [PTF]
    cmd.extend(['--test-dir', ptfdir])
    cmd.extend(ifaces)
    cmd.extend(['--socket-recv-size', '10240'])
    test_params = 'arch=\'{}\''.format(device)
    test_params += ';target=\'asic-model\''
    test_params += ';config_file=\'{}\''.format(config_file)
    test_params += ';num_pipes=4'
    test_params += ';thrift_server=\'localhost\''
    test_params += ';use_pi=\'False\''
    test_params += ';test_seed=\'None\''
    
    if test_port is not None:
        test_params += ';test_port={}'.format(test_port)
  
    if port_map_file is not None:
        test_params += ';port_map_file=\'{}\''.format(port_map_file)

    if platform is not None:
        test_params += ';pltfm=\'{}\''.format(platform)
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

# model uses the context json to lookup names when logging
def start_model(model, out=None, context_json=None, port_map_path=None, 
                device=None, extra_ptf_args=None, disable_logging=None):
    cmd = [model]
    if context_json is not None:
        cmd.extend(['-l', context_json])
    if port_map_path is not None:
        cmd.extend(['-f', port_map_path])
        if '2pipe' in port_map_path:
            cmd.extend(['--int-port-loop=0xa'])
    if device is not None and 'tofino2' in device:
        cmd.extend(['--chip-type=4']) # default CHIPTYPE=4 for Jbay
    else:
        cmd.extend(['--chip-type=2']) # default CHIPTYPE=2 for TofinoB0

    if '_dod' in extra_ptf_args or 'DoD' in extra_ptf_args:
        cmd.extend(['--dod-test-mode'])
    if disable_logging:
	cmd.extend(['--logs-disable'])

    info("Starting model: {}".format(' '.join(cmd)))
    return subprocess.Popen(cmd, stdout=out, stderr=out)

def start_switchd(switchd, status_port, conf_path, with_pd = None,
                  out=None, device=None, installdir="/usr/local"):
    cmd = [switchd]
    cmd.extend(['--install-dir', installdir])
    cmd.extend(['--conf-file', conf_path])
    if device is not None and 'tofino2' in device:
        cmd.extend(['--skip-hld', 'krt'])
    cmd.extend(['--status-port', str(status_port)])
    if with_pd is None:
        cmd.append('--skip-p4')
    else:
        cmd.extend(['--no-pi'])
        cmd.extend(['--init-mode', 'cold'])
    cmd.append('--background')
    info("Starting switchd: {}".format(' '.join(cmd)))
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

def enable_verbose_model_log():
    child = pexpect.spawn('telnet localhost 8000')
    child.logfile = sys.stdout
    child.expect(">")
    child.sendline("rmt-set-log-flags\r")

def main():
    args, unknown_args = get_parser().parse_known_args()

    sanitize_args(args)

    if unknown_args and args.update_config_only:
        error("Extra args not supported with --update-config-only and will be ignored")
    extra_ptf_args = unknown_args
    if args.xml_output:
        extra_ptf_args.extend(['--xunit', '--xunit-dir', args.testdir])

    toolsdevice = args.device
    if args.device == 'tofino2':
        toolsdevice = 'jbay'
    if args.pdtest is not None:
        compiler_out_dir = os.path.join(args.testdir, 'share', args.device+'pd', args.name)
    else:
        compiler_out_dir = args.testdir

    if args.pdtest is not None and args.bfrt_test is not None:
        error("--pdtest and --bfrt-test cannot be specified at the same time")
        sys.exit(1)

    if os.getenv('VERBOSE_MODEL_LOG') is not None:
        args.verbose_model_log = True

    p4info_path = os.path.join(compiler_out_dir, 'p4info.proto.txt')
    if not args.pdtest and not args.bfrt_test and not os.path.exists(p4info_path):
        error("P4Info file {} not found".format(p4info_path))
        sys.exit(1)
    elif args.bfrt_test:
        info("Doesn't need P4Info file")
    else:
        info("Using P4Info file {}".format(p4info_path))

    conf_path = os.path.join(compiler_out_dir, args.name + '.conf')
    if args.bfrt_test and not os.path.exists(conf_path):
        error("Config file {} not found".format(conf_path))
        sys.exit(1)

    # some p4-16 tests uses the bfrt conf syntax, but only has PI test.
    if args.run_bfrt_as_pi is not None:
        if len(args.run_bfrt_as_pi) != 1:
            error("PI only supports one tofino.bin and context.json")
            sys.exit(1)
        compiler_out_dir = os.path.join(compiler_out_dir, args.run_bfrt_as_pi[0])

    bin_path = os.path.join(compiler_out_dir, args.device + '.bin')
    if args.bfrt_test is None and not os.path.exists(bin_path):
        error("Binary config file {} not found".format(bin_path))
        sys.exit(1)

    cxt_json_path = os.path.join(compiler_out_dir, 'context.json')
    if args.bfrt_test is None and not os.path.exists(cxt_json_path):
        error("Context json file {} not found".format(cxt_json_path))
        sys.exit(1)

    if args.stftest is not None and not os.path.exists(args.stftest):
        error("STF test {} requested and not found".format(args.stftest))
        sys.exit(1)

    port_map_path = args.port_map
    # TODO: map the ports in the test directory. Right now it gives an error:
    # Error when parsing JSON port mapping file .../emulation/ports.json
    # since those files have "PortToVeth" not "PortToIf"
    #
    # if args.pdtest is not None and args.port_map is None:
    #    port_map_path = os.path.join(args.ptfdir, 'ports.json')

    if port_map_path is not None and not os.path.exists(port_map_path):
        error("Provided port mapping file {} not found".format(port_map_path))
        sys.exit(1)

    if args.update_config_only:
        success = update_config(args.name, args.grpc_addr,
                                p4info_path, bin_path, cxt_json_path)
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
        veth_start_index = 0
        base_if_index = 0
        # Default ports for Tofino2 have offset 8
        if 'tofino2' in args.device:
            base_if_index = 8
        for iface_idx in xrange(base_if_index, base_if_index + DEFAULT_NUM_IFACES):
            port_map[iface_idx] = 'veth{}'.format(2 * veth_start_index + 1)
            veth_start_index += 1
        # Ethernet CPU port: 64 for Tofino and 2 for Tofino2
        if 'tofino2' in args.device:
            port_map[2] = "veth251"
        else:
            port_map[64] = "veth251"
        check_and_add_ifaces()
    else:
        import json
        with open(port_map_path) as port_map_f:
            try:
                noOfPortToVeth = 0
                noOfIfMap = 0
                mapNode ='PortToVeth'
                ifMapNode ='PortToIf'
                jdict = json.load(port_map_f)
                if jdict.get(mapNode):
                    noOfPortToVeth = len(jdict[mapNode])
                if jdict.get(ifMapNode):
                    noOfIfMap = len(jdict[ifMapNode])
                for count in range(0, noOfPortToVeth):
                    port = jdict[mapNode][count]['device_port']
                    veth1 = jdict[mapNode][count]['veth1']
                    veth2 = jdict[mapNode][count]['veth2']
                    port_map[port] = "veth%d" % veth2
                for count in range(0, noOfIfMap):
                    iface_idx = jdict[ifMapNode][count]['device_port']
                    iface_name = jdict[ifMapNode][count]['if']
                    port_map[iface_idx] = iface_name
            except:
                error("Error when parsing JSON port mapping file {}".format(
                    port_map_path))
                sys.exit(1)
        if not check_ifaces(port_map.values()):
            warn("Some interfaces referenced in the port mapping file don't exist")

    PTF = findbin(top_builddir, 'PTF')
    BF_SWITCHD = findbin(top_builddir, 'BF_SWITCHD')
    HARLYN_MODEL = findbin(top_builddir, 'HARLYN_MODEL')

    # Extract the tools install directory based on the install path of bf_switchd
    BFD_INSTALLDIR = os.path.dirname(os.path.dirname(BF_SWITCHD))

    debug("Using bf_switchd from: {}".format(BF_SWITCHD))
    debug("Using model from: {}".format(HARLYN_MODEL))
    debug("Tools install directory is at: {}".format(BFD_INSTALLDIR))

    if args.test_only:
        success = False
        if args.pdtest:
            success = run_pd_ptf_tests(PTF, args.device, args.name, args.pdtest, args.ptfdir,
                                       args.testdir, args.platform, port_map, args.verbose_model_log,
                                       extra_ptf_args, args.port_map_file, args.test_port, 
                                       installdir=BFD_INSTALLDIR)
        elif args.bfrt_test and not args.run_bfrt_as_pi:
            success = run_pd_ptf_tests(PTF, args.device, args.name, args.bfrt_test, args.ptfdir,
                                       args.testdir, args.platform, port_map, args.verbose_model_log,
                                       extra_ptf_args, args.port_map_file, args.test_port, 
                                       installdir=BFD_INSTALLDIR)
        else:
            success = run_pi_ptf_tests(PTF, args.grpc_addr, args.ptfdir, p4info_path,
                                    port_map, args.stftest, args.platform, args.verbose_model_log,
                                    extra_ptf_args)
        if not success:
            error("Error when running PTF tests")
            sys.exit(1)
        sys.exit(0)

    dirname = tempfile.mkdtemp(prefix=args.name)
    os.chmod(dirname, 0o777)
    model_log_path = os.path.join(dirname, 'model.log')
    switchd_log_path = os.path.join(dirname, 'switchd.log')

    # Check for running processes and kill them
    # Check for zombie processes and wait for their exit
    def wait_for_setup(process_name):
        processes_running = subprocess.Popen(["ps", "-ef"],stdout=subprocess.PIPE)
        for process in processes_running.stdout:
            if re.search(process_name, process):
                if 'defunct' not in process:
                    pid = process.split()[1]
                    debug("{0} still running: {1}, killing pid: {2}".format(process_name, process, pid))
                    os.kill(int(pid), signal.SIGTERM)
                else:
                    debug("{0} still running as defunct: {1}".format(process_name, process))
                    time.sleep(2)
                    wait_for_setup(process_name)

    # Ensure clean environment before starting the test
    def run_setup():
        procs = ['tofino-model', 'bf_switchd']
        for proc in procs:
            wait_for_setup(proc)

    # TODO(antonin): in the future, do not restart model and switchd between
    # tests to speed-up testing
    processes = {}
    def run():

        # Ensure that there are no instances of tofino-model or bf_switchd running
        run_setup()
 
        disable_model_logging = True
        if args.enable_model_logging:
	    disable_model_logging = False

        with open(model_log_path, 'w') as model_out, \
             open(switchd_log_path, 'w') as switchd_out:
            model_p = start_model(HARLYN_MODEL, out=model_out,
                                  context_json=cxt_json_path,
                                  port_map_path=port_map_path,
                                  device=args.device,
                                  extra_ptf_args=extra_ptf_args,
                                  disable_logging=disable_model_logging)
            processes["model"] = model_p

            if args.pdtest is not None:
                conf_path = args.pdtest
            elif args.bfrt_test is not None:
                conf_path = os.path.join(compiler_out_dir, args.name + '.conf')
            else:
                conf_path = os.path.join(
                    os.path.dirname(os.path.realpath(__file__)), args.device + '.conf')
            info("conf at {}".format(conf_path))
            assert(os.path.exists(conf_path))

            switchd_status_port = 6789
            pi_choice = args.pdtest
            if args.bfrt_test:
                pi_choice = args.bfrt_test
            switchd_p = start_switchd(BF_SWITCHD, switchd_status_port,
                                      conf_path, pi_choice,
                                      out=switchd_out,
                                      device=args.device,
                                      installdir=BFD_INSTALLDIR)
            processes["switchd"] = switchd_p

            success = wait_for_switchd(model_p, switchd_p, switchd_status_port)
            if not success:
                error("Error when starting model & switchd")
                return False

            if args.pdtest is not None:
                success = run_pd_ptf_tests(PTF, args.device, args.name, args.pdtest, args.ptfdir,
                                           args.testdir, args.platform, port_map, args.verbose_model_log,
                                           extra_ptf_args, args.port_map_file, args.test_port, 
                                           installdir=BFD_INSTALLDIR)
            elif args.bfrt_test and not args.run_bfrt_as_pi:
                success = run_pd_ptf_tests(PTF, args.device, args.name, args.bfrt_test, args.ptfdir,
                                           args.testdir, args.platform, port_map, args.verbose_model_log,
                                           extra_ptf_args, args.port_map_file, args.test_port, 
                                           installdir=BFD_INSTALLDIR)
            else:
                success = update_config(args.name, args.grpc_addr,
                                    p4info_path, bin_path, cxt_json_path)
                if not success:
                    error("Error when pushing P4 config to switchd")
                    return False

                success = run_pi_ptf_tests(PTF, args.grpc_addr, args.ptfdir,
                                        p4info_path, port_map,
                                        args.stftest, args.platform, args.verbose_model_log,
                                        extra_ptf_args)
            if not success:
                error("Error when running PTF tests")
                return False
        return True

    success = run()


    for pname, p in processes.items():
        try:
            # Terminate the process
            debug("Killing process: {0} with pid: {1}".format(pname, p.pid))
            p.terminate()
            # Poll for 5 seconds and exit when the process in not running anymore
            # Note that the process may still exist as <defunt> after 5 seconds
            # if the tofino-model and bf_switchd are still communicating with the
            # parent, ptf_runner.py
            start_time = time.time()
            while time.time() - start_time < 5:
                time.sleep(0.2)
                poll_status = p.poll()
                if poll_status is not None:
                    break
        except Exception as e:
            error("Error when trying to terminate {0}, error {1}".format(pname, str(e)))

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
