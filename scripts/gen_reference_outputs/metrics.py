#! /usr/bin/env python3

import os
import sys
from collections import OrderedDict
from prettytable import PrettyTable

# Convert value to int or float number
def convert_to_number(value):
    if isinstance(value, int):
        # integer
        return value
    else:
        # assume string/float
        try:
            # float
            return round(float(value), 1)
        except:
            # other string
            return 0.0  # 0 represents no value, compare/delta result will be 0 (i.e. PASS)

def get_metric(metrics_info, metric):
    cum_metric = 0
    is_cumulative = False
    if len(metrics_info) > 1:
        for sub_info in metrics_info:
            # Check if the metric has sub info and accumulate
            if metric in sub_info and isinstance(sub_info, dict):
                cum_metric += convert_to_number(sub_info[metric])
                if not is_cumulative:
                    is_cumulative = True
        # If the metric has sub-fields but not cumulative
        # get the field of interest
        if not is_cumulative:
            cum_metric = metrics_info[metric]
    # If there is no sub-info, get the field of interest
    else:
        cum_metric = metrics_info[metric]
    return cum_metric


# Determine delta/percentage deviation calculation based on
# format string
def get_delta(new_value, old_value, delta_format):
    if old_value > 0:
        if '%' not in delta_format:
            return new_value - old_value
        else:
            return round(100.0 * (new_value - old_value) / old_value, 2)
    return 0


class Metric:
    def __init__(self, caption, path, value = 0, limit = 1, delta_format = ' %'):
        self.caption = caption            # display caption
        self.path = path                  # metrics.json path -- for now a list of json labels.
                                          # Can be an XPath (or the json equivalent).
        self.value = value                # metric value
        self.limit = limit                # limit
        self.delta_format = delta_format  # whether the delta is an absolute difference or percentage

    def setValue(self, value):
        self.value = value

    def addValue(self, value):
        self.value += value

    # Extract the metrics based on the path provided
    # Need to find a better way to specialize this (for not it works)
    def process(self, dump):
        if len(self.path) < 2:
            tmp = convert_to_number(dump[self.path[0]])
        else:
            tmp = dump[self.path[0]][self.path[1]]
            if not isinstance(tmp, int) and len(tmp) > 0:
                tmp = get_metric(tmp, self.path[2])
        self.value = tmp

    def print_data(self, dt):
        dt.add_row([self.caption, self.value])
        return dt

    def compare(self, metric):
        return get_delta(self.value, metric.value, self.delta_format)

    def analyze(self, metric):
        result = 0
        delta = self.compare(metric)
        if delta > self.limit:
            result = -1
            print(self.caption, delta, 'exceeded the limit of', self.limit, self.delta_format)
        elif delta < 0:
            print(self.caption, 'improved!')
        return result

    def display_comparison(self, metric, dt):
        dt.add_row([self.caption, metric.value, self.value, str(self.compare(metric)) + self.delta_format])


class CoreMetrics():
    def __init__(self):
        self.metrics = OrderedDict()
        self.metrics['normal_phv_bits_occupied'] = Metric('Normal PHV bits_occupied', ('phv', 'normal', 'bits_occupied'), limit = 40, delta_format='')
        self.metrics['normal_phv_containers_occupied'] = Metric('Normal PHV containers_occupied', ('phv', 'normal', 'containers_occupied'), limit = 2, delta_format='')
        self.metrics['mau_srams'] = Metric('MAU srams', ('mau', 'srams'), limit = 10.0)
        self.metrics['mau_tcams'] = Metric('MAU tcams', ('mau', 'tcams'), limit = 10.0)
        self.metrics['mau_logical_tables'] = Metric('MAU logical_tables', ('mau', 'logical_tables'), limit = 10.0)
        self.metrics['mau_power'] = Metric('MAU power estimate', ('mau', 'power', 'estimate'), limit = 10.0)
        self.metrics['parser_ingress_tcam_rows'] = Metric('Parser ingress tcam rows', ('parser', 'ingress', 'tcam_rows'), limit = 10.0)
        self.metrics['parser_egress_tcam_rows'] = Metric('Parser egress tcam rows', ('parser', 'egress', 'tcam_rows'), limit = 10.0)
        self.metrics['compilation_time'] = Metric('Compilation time', ('compilation_time', ), limit = 40.0)

    def display(self):
        dt = PrettyTable(['Metric', 'Value'])
        for m, m_info in self.metrics.items():
            dt = m_info.print_data(dt)
        print(dt)

    def process_metric(self, dump):
        for m, m_info in self.metrics.items():
            m_info.process(dump)

    def display_comparison(self, metric):
        dt = PrettyTable(['Metric', 'Master', 'Current', 'Delta'])
        for m, m_info in self.metrics.items():
            m_info.display_comparison(metric.metrics[m], dt)
        print(dt)

    def analyze(self, metric):
        result = 0
        for m, m_info in self.metrics.items():
            result += m_info.analyze(metric.metrics[m])
        return result

class TofinoMetrics(CoreMetrics):
    def __init__(self):
        CoreMetrics.__init__(self)
        self.metrics['tagalong_phv_bits_occupied'] = Metric('Tagalong PHV bits_occupied', ('phv', 'tagalong', 'bits_occupied'), limit = 20, delta_format='')
        self.metrics['tagalong_phv_containers_occupied'] = Metric('Tagalong PHV containers_occupied', ('phv', 'tagalong', 'containers_occupied'), limit = 1, delta_format='')

class Tofino2Metrics(CoreMetrics):
    def __init__(self):
        CoreMetrics.__init__(self)
        self.metrics['mocha_phv_bits_occupied'] = Metric('Mocha PHV bits_occupied', ('phv', 'mocha', 'bits_occupied'), limit = 20, delta_format='')
        self.metrics['mocha_phv_containers_occupied'] = Metric('Mocha PHV containers_occupied', ('phv', 'mocha', 'containers_occupied'), limit = 2, delta_format='')
        self.metrics['dark_phv_bits_occupied'] = Metric('Dark PHV bits_occupied', ('phv', 'dark', 'bits_occupied'), limit = 20, delta_format='')
        self.metrics['dark_phv_containers_occupied'] = Metric('Dark PHV containers_occupied', ('phv', 'dark', 'containers_occupied'), limit = 2, delta_format='')
        self.metrics['clots_ingress_unallocated_bits'] = Metric('Clots ingress unallocated_bits', ('clots', 'ingress', 'unallocated_bits'), limit = 10.0)
        self.metrics['clots_ingress_redundant_phv_bits'] = Metric('Clots ingress redundant_phv_bits', ('clots', 'ingress', 'redundant_phv_bits'), limit = 10.0)
        self.metrics['clots_egress_unallocated_bits'] = Metric('Clots egress unallocated_bits', ('clots', 'egress', 'unallocated_bits'), limit = 10.0)
        self.metrics['clots_egress_redundant_phv_bits'] = Metric('Clots egress redundant_phv_bits', ('clots', 'egress', 'redundant_phv_bits'), limit = 10.0)
