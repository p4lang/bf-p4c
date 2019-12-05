#!/usr/bin/env python3

import os
import sys
import argparse
from time import sleep
import subprocess
import shlex

default_wait_timeout = 2400 # (40 min)

# Print to stderr
# We need to make sure that output is flushed so travis does not time out
def eprint(*args, **kwargs):
    print(*args, file=sys.stderr, **kwargs)

def main():
    parser = argparse.ArgumentParser(description='Wait for docker image to be available and pull')
    parser.add_argument('--image', help='Docker image tag to pull',
                        type=str, action='store', required=True)
    parser.add_argument('--username', help='Dockerhub username',
                        type=str, action='store', default="bfndocker", required=True)
    parser.add_argument('--password', help='Dockerhub password',
                        type=str, action='store', default=None, required=True)
    parser.add_argument('--timeout', help='Timeout to build docker image',
                        type=int, action='store', default=default_wait_timeout, required=False)
    args = parser.parse_args()

    image, tag = args.image.split(":")
    url = 'https://registry.hub.docker.com/v1/repositories'
    curl_cmd = "curl -u{}:{} {}/{}/tags".format(args.username, args.password, url, image)
    found_image = False
    elapsed_time = 0

    eprint('checking for image:', args.image)

    while elapsed_time < args.timeout:
        try:
            out = subprocess.check_output(shlex.split(curl_cmd))
            # all_tags is an list of objects:
            # {"layer": "", "name": "973d8e6050fef4a4c5b0b68c4ea679d3a95b2880"}
            # the value of name is the tag

            # print(all_tags)
            all_tags = eval(out)
            for i in all_tags:
                if i['name'] == tag:
                    found_image = True
                    break

            if found_image: break

            eprint('docker image {} not yet available'.format(tag))
            sleep(60)
            elapsed_time += 60

        except subprocess.CalledProcessError:
            eprint("Error accessing dockerhub: {}".format(all_tags))
            sys.exit(1)

    if found_image:
        eprint('Image {} available'.format(args.image))
        sys.exit(0)
    else:
        eprint('Timed out waiting for docker image to be available')
        sys.exit(1)


if __name__ == '__main__':
    main()
