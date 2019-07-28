#! /usr/bin/env python

import os
import sys
import json
import sqlite3
import shutil
import config
import metrics
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

def get_manifest_files(metrics_outdir, ts):
    manifest_find_cmd = "cd " + metrics_outdir + " && find . -name manifest.json"
    rc = RunCmd(manifest_find_cmd, config.TEST_DRIVER_TIMEOUT)
    manifest_files = []
    if rc.out is not None and len(rc.out) > 0:
        for line in rc.out.split('\n'):
            if ts in line and 'manifest.json' in line:
                manifest_files.append(metrics_outdir + line[2:])
    else:
        print ('No manifest files found!')
    return manifest_files

def get_metrics(metrics_outdir, ts):
    metrics_files = []
    manifest_files = get_manifest_files(metrics_outdir, ts)
    for manifest_file in manifest_files:
        output_directory = os.path.dirname(manifest_file)
        with open(manifest_file, "rb") as json_file:
            try:
                manifest_info = json.load(json_file)
            except:
                error_msg = "ERROR: Input file '" + manifest_file + \
                    "' could not be decoded as JSON.\n"
                return metrics_files
            if (type(manifest_info) is not dict or "programs" not in manifest_info):
                error_msg = "ERROR: Input file '" + manifest_file + \
                    "' does not appear to be valid manifest JSON.\n"
        programs = manifest_info['programs']
        for prog in programs:
            for pipe in prog["pipes"]:
                pipe_id = pipe['pipe_id']
                try:
                    metrics_info = pipe["files"]["metrics"]
                    metrics_files.append([pipe_id, os.path.join(output_directory, metrics_info["path"])])
                except:
                    print 'metrics.json not found. Compilation might not have succeeded for', str(prog["program_name"])
                    continue
    return metrics_files

def copy_metrics(tests, metrics_outdir, ts):
    metrics_files = get_metrics(metrics_outdir, ts)
    c_metrics = OrderedDictWithDict()
    for mTest in tests:
        metrics_out_path = os.path.join(mTest.out_path, 'P4C')
        metrics_dest = os.path.join(config.METRICS_DIR, mTest.p4, mTest.timestamp)
        test_info = OrderedDict()
        test_info['Name'] = mTest.p4
        test_info['Commit_sha'] = config.COMMIT_SHA
        test_info['Compiler'] = 'P4C'
        test_info['Timestamp'] = ts
        test_info['Metrics_json'] = []
        c_metrics[mTest.p4] = test_info
        metrics_dest = os.path.join(config.METRICS_DIR, mTest.p4, ts)
        if not os.path.exists(metrics_dest):
            os.makedirs(metrics_dest)
        metrics_data = {}
        for mfile in metrics_files:
            if mTest.out_path in mfile[1]:
                with open(mfile[1], 'r') as f:
                    metrics_json  = f.read()
                shutil.copy2(mfile[1], os.path.join(metrics_dest, 'metrics_' + str(mfile[0]) + '.json'))
                metrics_data[mfile[0]] = json.loads(metrics_json)
        for mdata in metrics_data:
             c_metrics[mTest.p4]['Metrics_json'].append(metrics_data[mdata])
    return c_metrics

def extract_info(m_info):
    json_info = []
    json_dumps = m_info['Metrics_json']
    for dump in json_dumps:
        if 'tofino2' in dump['target']:
            json_obj = metrics.Tofino2Metrics()
        else:
            json_obj = metrics.TofinoMetrics()
        json_obj.process_metric(dump)
        json_info.append(json_obj)
    return json_info

def compare_metrics(curr, master):
    curr.display_comparison(master)
    return curr.analyze(master)

def test_metrics(db_curr, db_master):
    results = {}
    for curr, curr_info in db_curr.iteritems():
        print 'Analyzing:', curr
        result = 0
        if not curr_info['Metrics_json']:
            print 'Possible test failure, metrics.json not found'
            result = -1
        else:
            curr_metrics = extract_info(curr_info)
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
