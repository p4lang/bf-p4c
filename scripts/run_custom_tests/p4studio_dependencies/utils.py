#!/usr/bin/python

import subprocess
import re
import os

# -----------------------------------------------------------------------------


def write_to_log(log_file, data):
    """ Write teh given data to given log file """
    log = open(log_file, 'ab')
    log.write(data.encode('utf-8'))
    log.close()


def exec_cmd(cmd, log_file=None):
    """ Execute the given command and obtain stdout and stderr """

    pipe = subprocess.Popen(str(cmd),
                            stdout=subprocess.PIPE,
                            stderr=subprocess.PIPE,
                            shell=True)
    output, err = pipe.communicate()
    
    # Write to a log file
    if log_file is not None:
        write_to_log(log_file, "\nCMD: %s \n Stdout:\n" % cmd)
        for line in output.decode('utf-8'):
            write_to_log(log_file, line)
        write_to_log(log_file, "CMD: %s \n Stderr:\n" % cmd)
        for line in err.decode('utf-8'):
            write_to_log(log_file, line)

    return (output.decode('utf-8'), err.decode('utf-8'), pipe.returncode)


def check_progress(progress_file, key, default_value=True):
    """ Check the progress file and return the status """
    if os.path.exists(progress_file):
        f = open(progress_file)
        lines = f.readlines()
        m = re.compile(key)
        sub_list = filter(m.match, lines)
        for elem in sub_list:
            first, second = elem.split(':', 1)
            if default_value:
                if first.replace(' ', '') == key and \
                    second.replace(' ', '').strip() == 'Done':
                    return True
            else:
                if first.replace(' ', '') == key:
                    return second.strip()
    else:
        return False


def update_progress(progress_file, key, value='Done'):
    write_to_log(progress_file, '\n%s : %s' % (key, value))
