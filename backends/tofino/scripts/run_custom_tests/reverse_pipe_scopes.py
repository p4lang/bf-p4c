#! /usr/bin/env python3

import os
import sys
import json
import argparse

def get_parser():
    parser = argparse.ArgumentParser(description='Reverse pipe scopes in given conf file')
    parser.add_argument('--conf', help='Location of config file',
                        type=str, action='store', required=True)
    return parser

def main():
    args = get_parser().parse_args()
    
    # Read config file
    with open(args.conf, 'r') as jsonConf:
        content = json.load(jsonConf)

    # Reverse pipe scopes
    pipe_scopes = []
    for p4_pipe in content["p4_devices"][0]["p4_programs"][0]["p4_pipelines"]:
        pipe_scopes.append(p4_pipe["pipe_scope"][0])
    pipe_scopes_updated = reversed(pipe_scopes)

    for pipe_id, pipe_scope in enumerate(pipe_scopes_updated):
        content["p4_devices"][0]["p4_programs"][0]["p4_pipelines"][pipe_id]["pipe_scope"][0] = pipe_scope

    # Write updated config file
    with open(args.conf, 'w') as jsonConf:
        json.dump(content, jsonConf, indent=4, separators=(',', ':'))
        jsonConf.write('\n')

if __name__ == "__main__":
    main()
