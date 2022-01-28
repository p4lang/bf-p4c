#!/usr/bin/env python

import yaml

class Dependencies(object):
    """ Dependencies class to manage package dependencies for each module """

    def __init__(self, dependencies_file):
        self.data = {}
        if dependencies_file.endswith('yaml') or \
            dependencies_file.endswith('yml'):
            try:
                self.data = yaml.load(open(dependencies_file),
                                      Loader=yaml.SafeLoader)
            except IOError:
                raise IOError("Unable to access file: %s" % dependencies_file)


    def get_defaults(self, os=None):
        """
        Description:
            Return a dictionary of default dependencies generic for all OSs.
            If 'os' name is provided, it returns default dependencies for
            that OS.
        """
        dependencies = self.data['OS_based']
        if os is not None:
            return dependencies[os].get('defaults')
        return dependencies.get('defaults')


    def get_os_dependencies(self, os):
        """
        Description:
            Return a dictionary of dependencies for a given OS.
        """
        dependencies = self.data['OS_based']
        return dependencies.get(os)
