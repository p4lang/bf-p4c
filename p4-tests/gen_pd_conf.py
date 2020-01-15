#!/usr/bin/env python3

import argparse
import json
import os.path

template="""
{
    "chip_list": [
        {
            "id": "asic-0",
            "chip_family": "",
            "instance": 0,
            "pcie_sysfs_prefix": "/sys/devices/pci0000:00/0000:00:03.0/0000:05:00.0",
            "pcie_domain": 0,
            "pcie_bus": 5,
            "pcie_fn": 0,
            "pcie_dev": 0,
            "pcie_int_mode": 1,
            "sds_fw_path": "share/tofino_sds_fw/avago/firmware"
        }
    ],
    "id": "dummy.csv",
    "instance": 0,
    "p4_program_list": [
        {
            "id": "pgm-0",
            "instance": 0,
            "path": "dummy",
            "program-name": "dummy",
            "pd": "",
            "pd-thrift": "",
            "table-config": "",
            "tofino-bin": "",
            "with_pi" : true,
            "agent0": "lib/libpltfm_mgr.so"
        }
    ]
}
"""

def get_parser():
    parser = argparse.ArgumentParser(description='PD conf file generator')
    parser.add_argument('--testdir', help='Location of test outputs',
                        type=str, action='store', required=True)
    parser.add_argument('--name', help='Name of P4 program under test',
                        type=str, action='store', required=True)
    parser.add_argument('--device', help='Target device',
                        choices=['tofino', 'tofino2', 'tofino3'], default='tofino',
                        type=str, action='store', required=True)
    parser.add_argument('--switch-api', help='API to use for switch',
                        choices=['switchapi', 'switchsai'], default=None,
                        type=str, action='store', required=False)
    parser.add_argument('--pipe', help='Pipeline Names',
                        default='', nargs="+",
                        type=str, required=False)
    return parser


def main():
    args = get_parser().parse_args()
    base_conf = json.loads(template)
    base_conf["id"] = args.name + ".csv"
    # assume one chip
    chip = base_conf["chip_list"][0]
    if args.device == 'tofino2':
        chip["chip_family"] = 'Tofino2'
    elif args.device == 'tofino3':
        chip["chip_family"] = 'Tofino3'
    else:
        chip["chip_family"] = 'Tofino'
    p4_info = base_conf["p4_program_list"][0]
    p4_info["program-name"] = args.name
    libpath = os.path.join(args.testdir, 'lib', args.device+'pd', args.name)
    p4_info["path"] = os.path.join(args.testdir, 'lib')

    p4_info["pd"] = os.path.join(libpath, 'libpd.so')
    p4_info["pd-thrift"] = os.path.join(libpath, 'libpdthrift.so')

    if len(args.pipe) > 0:
        print(args.pipe[0])
        share_path = os.path.join(args.testdir, 'share', args.device+'pd', args.name, args.pipe[0])
    else:
        share_path = os.path.join(args.testdir, 'share', args.device+'pd', args.name)

    p4_info["table-config"] = os.path.join(share_path, 'context.json')
    p4_info["tofino-bin"] = os.path.join(share_path, args.device + '.bin')
    p4_info["with_pi"] = False
    p4_info["id"] = args.testdir + ':' + args.name + '-0'
    p4_info["cpu_port"] = "veth251"

    if args.switch_api == "switchapi":
        p4_info["switchapi"] = os.path.join(args.testdir, "lib", "libswitchapi.so")
        p4_info["agent0"] = os.path.join(args.testdir, "lib", "libpltfm_mgr.so")

    if args.switch_api == "switchsai":
        p4_info["switchapi"] = os.path.join(args.testdir, "lib", "libswitchapi.so")
        p4_info["switchsai"] = os.path.join(args.testdir, "lib", "libswitchsai.so")
        p4_info["agent0"] = os.path.join(args.testdir, "lib", "libpltfm_mgr.so")

    conf_name = os.path.join(args.testdir, args.name + '.conf')
    with open(conf_name, 'w') as fconf:
        json.dump(base_conf, fconf, indent=4, separators=(',', ': '))
        fconf.write('\n')

if __name__ == '__main__':
    main()
