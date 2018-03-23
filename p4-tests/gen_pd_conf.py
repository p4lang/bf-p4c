#!/usr/bin/env python2

import argparse
import json
import os.path

def get_parser():
    parser = argparse.ArgumentParser(description='PD conf file generator')
    parser.add_argument('--testdir', help='Location of test outputs',
                        type=str, action='store', required=True)
    parser.add_argument('--name', help='Name of P4 program under test',
                        type=str, action='store', required=True)
    parser.add_argument('--device', help='Target device',
                        choices=['tofino', 'jbay'], default='tofino',
                        type=str, action='store', required=True)
    return parser


def main():
    args = get_parser().parse_args()
    base_conf_name = os.path.join(os.path.dirname(os.path.realpath(__file__)),
                                  args.device + '.conf')
    base_conf = json.load(open(base_conf_name, 'r'))
    base_conf["id"] = args.name + ".csv"
    p4_info = base_conf["p4_program_list"][0]
    p4_info["path"] = args.testdir
    p4_info["program-name"] = args.name
    libpath = os.path.join(args.testdir, 'lib', args.device+'pd', args.name)
    p4_info["pd"] = os.path.join(libpath, 'libpd.so')
    p4_info["pd-thrift"] = os.path.join(libpath, 'libpdthrift.so')
    share_path = os.path.join(args.testdir, 'share', args.device+'pd', args.name)
    p4_info["table-config"] = os.path.join(share_path, 'context.json')
    p4_info["tofino-bin"] = os.path.join(share_path, args.device + '.bin')
    p4_info["with_pi"] = False
    p4_info["id"] = args.testdir + ':' + args.name + '-0'
    conf_name = os.path.join(args.testdir, args.name + '.conf')
    json.dump(base_conf, open(conf_name, 'w'))

if __name__ == '__main__':
    main()
