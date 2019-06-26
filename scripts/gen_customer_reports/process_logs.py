#! /usr/bin/env python

import os
import sys
import xlsxwriter
from collections import OrderedDict

class OrderedDictWithDict(OrderedDict):
    def __missing__ (self, dict_key):
        self[dict_key] = {}
        return self[dict_key]

log_keywords = ['error:', 'unallocated', 'failed', 'Compiler Bug',
                'CRASH', 'Unimplemented', 'Cannot allocate',
                'unsatisfiable', 'TIMEOUT']

def gen_report(tb, db, tabname):
    ts = tb.add_worksheet(tabname)
    bold = tb.add_format({'bold': True})
    red = tb.add_format({'color': 'red', 'bold': True})
    green = tb.add_format({'color': 'green', 'bold': True})
    text_format = tb.add_format({'text_wrap': True, 'valign': 'top'})
    ts.set_column('A:A', 8)
    ts.set_column('B:B', 80)
    ts.set_column('C:C', 8)
    ts.set_column('D:D', 60)
    ts.set_column('E:E', 20)
    ts.write_string(0, 0, 'Test No.', bold)
    ts.write_string(0, 1, 'Test Name', bold)
    ts.write_string(0, 2, 'Result', bold)
    ts.write_string(0, 3, 'Log', bold)
    ts.write_string(0, 4, 'Comments', bold)
    count = 1
    for test in db:
        ts.write_number(count, 0, count)
        ts.write_string(count, 1, db[test]['Name'])
        if db[test]['Result'] == "PASS":
            ts.write_string(count, 2, db[test]['Result'], green)
        else:
            ts.write_string(count, 2, db[test]['Result'], red)
        ts.write_string(count, 3, '\n'.join(db[test]['Log']), text_format)
        if db[test]['Comments']:
            ts.write_string(count, 4, db[test]['Comments'], text_format)
        count += 1

def get_test_results(filename):
    db = OrderedDictWithDict()
    with open(filename,'r') as f:
        loglines = f.read()
    line_count = 0
    lines = loglines.split('\n')
    tot_lines = len(lines)
    for line_no, line in enumerate(lines):
        if 'Start ' in line:
            test_info = OrderedDict()
            tc = line.split(':')[1].strip()
            test_info['Name'] = tc
            test_info['Result'] = None
            test_res_found = 0
            test_info['Log'] = []
            test_info['Comments'] = None
            for curr_line in range((line_no + 2), tot_lines - 1):
                if test_res_found == 1:
                    break
                else:
                    if 'Test #' in lines[curr_line]:
                        if 'Passed' in lines[curr_line]:
                            test_info['Result'] = 'PASS'
                        elif 'Failed' in lines[curr_line]:
                            test_info['Result'] = 'FAIL'
                        test_res_found = 1
                    else:
                        for msg in log_keywords:
                            if msg in lines[curr_line] and lines[curr_line] not in test_info['Log']:
                                test_info['Log'].append(lines[curr_line][6:])
            if len(test_info['Log']) > 0 and test_info['Result'] == 'PASS':
                test_info['Result'] = 'FAIL'
                test_info['Comments'] = 'XFAIL in ctest'
            db[tc] = test_info
    return db

def ProcessLog(out_file, report, report_tab):
    tb = xlsxwriter.Workbook(report)
    data = get_test_results(out_file)
    gen_report(tb, data, report_tab)
    tb.close()
