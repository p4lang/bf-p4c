#! /usr/bin/env python

import os
import sys
import json
import sqlite3
import shutil
import config
sys.path.append("..")
from runner import RunCmd
from collections import OrderedDict
from prettytable import PrettyTable

class OrderedDictWithDict(OrderedDict):
    def __missing__ (self, dict_key):
        self[dict_key] = {}
        return self[dict_key]

def create_dictionary(db_info):
    db = OrderedDictWithDict()
    for line in db_info:
        test_info = OrderedDict()
        test_info['Commit_sha'] = line[0]
        test_info['Name'] = line[1]
        test_info['Compiler'] = line[2]
        test_info['Timestamp'] = line[3]
        metrics_data = json.loads(line[4])
        test_info['Metrics_json'] = []
        for metric in metrics_data:
            test_info['Metrics_json'].append(metric)
        db[line[1]] = test_info
    return db

def get_metrics(metrics_outdir, ts):
    metrics_find_cmd = "cd " + metrics_outdir + " && find . -name metrics.json"
    rc = RunCmd(metrics_find_cmd, config.TEST_DRIVER_TIMEOUT)
    metrics_files = []
    if rc.out is not None and len(rc.out) > 0:
        for line in rc.out.split('\n'):
            if ts in line and 'metrics.json' in line:
                metrics_files.append(metrics_outdir + line[2:])
    else:
        print ('No metrics files found!')
    return metrics_files

# TODO: Currently handles max two pipes, need to extend once driver support is added
# to better identify metrics.json files
def copy_metrics(tests, metrics_outdir, ts):
    metrics_files = get_metrics(metrics_outdir, ts)
    metrics = OrderedDictWithDict()
    for mTest in tests:
        metrics_out_path = os.path.join(mTest.out_path, 'P4C')
        metrics_dest = os.path.join(config.METRICS_DIR, mTest.p4, mTest.timestamp)
        test_info = OrderedDict()
        test_info['Name'] = mTest.p4
        test_info['Commit_sha'] = config.COMMIT_SHA
        test_info['Compiler'] = 'P4C'
        test_info['Timestamp'] = ts
        test_info['Metrics_json'] = []
        metrics[mTest.p4] = test_info
        metrics_dest = os.path.join(config.METRICS_DIR, mTest.p4, ts)
        if not os.path.exists(metrics_dest):
            os.makedirs(metrics_dest)
        metrics_data = {}
        for mfile in metrics_files:
            if mTest.out_path in mfile:
                with open(mfile, 'r') as f:
                    metrics_json  = f.read()
                if 'custom_pipe' in mfile:
                    shutil.copy2(mfile, os.path.join(metrics_dest, 'metrics_custom_pipe.json'))
                    metrics_data['custom'] = json.loads(metrics_json)
                else:
                    shutil.copy2(mfile, os.path.join(metrics_dest, 'metrics.json'))
                    metrics_data['regular'] = json.loads(metrics_json)
        if 'regular' in metrics_data:
             metrics[mTest.p4]['Metrics_json'].append(metrics_data['regular'])
        if 'custom' in metrics_data:
             metrics[mTest.p4]['Metrics_json'].append(metrics_data['custom'])
    return metrics

def get_cumulative_metric(metrics_info, metric):
    cum_metric = 0
    for sub_info in metrics_info:
        cum_metric += sub_info[metric]
    return cum_metric

def process_metrics(dump):
    j_info = config.Metric()
    normal_phv_info = dump['phv']['normal']
    tagalong_phv_info = dump['phv']['tagalong']
    mau_info = dump['mau']
    j_info.normal_phv_bits_occupied = get_cumulative_metric(normal_phv_info, 'bits_occupied')
    j_info.normal_phv_containers_occupied = get_cumulative_metric(normal_phv_info, 'containers_occupied')
    j_info.tagalong_phv_bits_occupied = get_cumulative_metric(tagalong_phv_info, 'bits_occupied')
    j_info.tagalong_phv_containers_occupied = get_cumulative_metric(tagalong_phv_info, 'containers_occupied')
    j_info.mau_srams = mau_info['srams']
    j_info.mau_tcams = mau_info['tcams']
    j_info.mau_logical_tables = mau_info['logical_tables']
    return j_info

def extract_info(m_info):
    json_info = []
    json_dumps = m_info['Metrics_json']
    for dump in json_dumps:
        json_info.append(process_metrics(dump))
    return json_info

def display_comparison(metric1, metric2, delta):
    dt = PrettyTable(['Metric', 'Master', 'Current', 'Delta'])
    dt.add_row(['Normal PHV bits_occupied', metric1.normal_phv_bits_occupied, metric2.normal_phv_bits_occupied, delta.normal_phv_bits_occupied])
    dt.add_row(['Normal PHV containers_occupied', metric1.normal_phv_containers_occupied, metric2.normal_phv_containers_occupied, delta.normal_phv_containers_occupied])
    dt.add_row(['Tagalong PHV bits_occupied', metric1.tagalong_phv_bits_occupied, metric2.tagalong_phv_bits_occupied, delta.tagalong_phv_bits_occupied])
    dt.add_row(['Tagalong PHV containers_occupied', metric1.tagalong_phv_containers_occupied, metric2.tagalong_phv_containers_occupied, delta.tagalong_phv_containers_occupied])
    dt.add_row(['MAU srams', metric1.mau_srams, metric2.mau_srams, str(delta.mau_srams) + ' %'])
    dt.add_row(['MAU tcams', metric1.mau_tcams, metric2.mau_tcams, str(delta.mau_tcams) + ' %'])
    dt.add_row(['MAU logical_tables', metric1.mau_logical_tables, metric2.mau_logical_tables, str(delta.mau_logical_tables) + ' %'])
    print dt

# TODO: Need to refactor this
def compare_metrics(curr, master):
    result = 0
    m_diff = config.Metric()
    m_diff.normal_phv_bits_occupied = curr.normal_phv_bits_occupied - master.normal_phv_bits_occupied
    m_diff.normal_phv_containers_occupied = curr.normal_phv_containers_occupied - master.normal_phv_containers_occupied
    m_diff.tagalong_phv_bits_occupied = curr.tagalong_phv_bits_occupied - master.tagalong_phv_bits_occupied
    m_diff.tagalong_phv_containers_occupied = curr.tagalong_phv_containers_occupied - master.tagalong_phv_containers_occupied
    if curr.mau_srams > 0:
        m_diff.mau_srams = 100.0 * (curr.mau_srams - master.mau_srams)/curr.mau_srams
    else:
        m_diff.mau_srams = 0
    if curr.mau_tcams > 0:
        m_diff.mau_tcams = 100.0 * (curr.mau_tcams - master.mau_tcams)/curr.mau_tcams
    else:
        m_diff.mau_tcams= 0
    if curr.mau_logical_tables > 0:
        m_diff.mau_logical_tables = 100.0 * (curr.mau_logical_tables - master.mau_logical_tables)/curr.mau_logical_tables
    else:
        m_diff.mau_logical_tables = 0
    display_comparison(master, curr, m_diff)

    if m_diff.normal_phv_bits_occupied > config.limits.normal_phv_bits_occupied:
        result -= 1
        print 'Normal PHV bits_occupied:', m_diff.normal_phv_bits_occupied, 'exceeded the limit of', config.limits.normal_phv_bits_occupied
    elif m_diff.normal_phv_bits_occupied < 0:
        print 'Normal PHV bits_occupied improved!'

    if m_diff.normal_phv_containers_occupied > config.limits.normal_phv_containers_occupied:
        result -= 1
        print 'Normal PHV containers_occupied:', m_diff.normal_phv_containers_occupied, 'exceeded the limit of', config.limits.normal_phv_containers_occupied
    elif m_diff.normal_phv_containers_occupied < 0:
        print 'Normal PHV containers_occupied improved!'

    if m_diff.tagalong_phv_bits_occupied > config.limits.tagalong_phv_bits_occupied:
        result -= 1
        print 'Tagalong PHV bits_occupied:', m_diff.tagalong_phv_bits_occupied, 'exceeded the limit of', config.limits.tagalong_phv_bits_occupied
    elif m_diff.tagalong_phv_bits_occupied < 0:
        print 'Tagalong PHV bits_occupied improved!'

    if m_diff.tagalong_phv_containers_occupied > config.limits.tagalong_phv_containers_occupied:
        result -= 1
        print 'Tagalong PHV containers_occupied:', m_diff.tagalong_phv_containers_occupied, 'exceeded the limit of', config.limits.tagalong_phv_containers_occupied
    elif m_diff.tagalong_phv_containers_occupied < 0:
        print 'Tagalong PHV containers_occupied improved!'

    if m_diff.mau_srams > config.limits.mau_srams:
        result -= 1
        print 'MAU srams:', m_diff.mau_srams, 'exceeded the limit of', config.limits.mau_srams, '%'
    elif m_diff.mau_srams < 0:
        print 'MAU srams improved!'

    if m_diff.mau_tcams > config.limits.mau_tcams:
        result -= 1
        print 'MAU tcams:', m_diff.mau_tcams, 'exceeded the limit of', config.limits.mau_tcams, '%'
    elif m_diff.mau_tcams < 0:
        print 'MAU tcams improved!'

    if m_diff.mau_logical_tables > config.limits.mau_logical_tables:
        result -= 1
        print 'MAU srams:', m_diff.mau_logical_tables, 'exceeded the limit of', config.limits.mau_logical_tables, '%'
    elif m_diff.mau_logical_tables < 0:
        print 'MAU logical_tables improved!'

    return result

def test_metrics(db_curr, db_master):
    results = {}
    for curr, curr_info in db_curr.iteritems():
        curr_metrics = extract_info(curr_info)
        print 'Analyzing:', curr
        result = 0
        if not curr_info['Metrics_json']:
            result = -1
        else:
            if curr in db_master:
                master_info = db_master[curr]
                master_metrics = extract_info(master_info)
                for i, cmetric in enumerate(curr_metrics):
                    result += compare_metrics(cmetric, master_metrics[i])
            else:
            	print 'Nothing to compare, possibly new test added'
            	for i, cmetric in enumerate(curr_metrics):
            		cmetric.display() 
        if result < 0:
            results[curr] = 'FAIL'
        else:
            results[curr] = 'PASS'
        print '='*120 + '\n'
    return results

def test_and_report_metrics(db_curr, db_master):
    return test_metrics(db_curr, db_master)

def update_metrics(metrics_db, db_curr, db_master):
    for curr, curr_info in db_curr.iteritems():
        metrics_db.update_metrics(curr, curr_info)

def test_and_update_metrics(metrics_db, db_curr, db_master):
    results = test_metrics(db_curr, db_master)
    update_metrics(metrics_db, db_curr, db_master)
    return results

class metricstable(object):
    def __init__(self):
        self.db_conn = sqlite3.connect(config.METRICS_DB)
        self.db_cursor = self.db_conn.cursor()

    def insert_metric(self, metric, test_info):
        try:
            self.db_cursor.execute("INSERT INTO metrics \
                       VALUES (?, ?, ?, ?, ?);", \
                       (test_info['Commit_sha'], metric, \
                        test_info['Compiler'], test_info['Timestamp'], \
                        json.dumps(test_info['Metrics_json'])))
            self.db_conn.commit()
        except Exception as err:
            print('Error inserting metric into database:', err)

    def insert_metrics(self, metrics_info):
        for metric, test_info in metrics_info.iteritems():
            self.insert_metric(metric, test_info)

    def update_metrics(self, test, test_info):
        print ('Updating database entry for', test)
        self.insert_metric(test, test_info)

    def get_all(self):
        self.db_cursor.execute("SELECT Commit_sha, Name, Compiler, Max(Timestamp), Metrics_json FROM metrics GROUP BY Name")
        db_content = self.db_cursor.fetchall()
        db_info = create_dictionary(db_content)
        return db_info

    def extract_metrics(self):
        return self.get_all()

    def display_metrics(self):
        db_info = self.get_all()
        print(json.dumps(db_info, indent=4))

    def close(self):
        self.__del__()

    def __del__(self):
        if self.db_conn:
            self.db_conn.close()
