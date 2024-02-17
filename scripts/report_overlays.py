#!/usr/bin/python3

import re
import argparse
import sys

# Structure is:
#   <field>: [<stage_info>:] <container>[<bitrange>]
# Extract field, stage, container, and bitrange
# Do not do anything for: TPHV and B0, B16 (zero-deparser)
# For Mocha and Dark report also packed fields with overlapping liveranges and different liverange starts
# For other containers: map container bitranges to fields and stages
# class LiveField: contains field name and stage info
# class ContainerAlloc: contains Container name, mappings from each bit to set of LiveFields
#
# Populate ContainerAlloc instances by parsing all allocations
#    while populating ContainerAlloc's keep track of container bits that have more than one LiveFields

class IntRange:
    def __init__(self, lsb, msb):
        self.lsb = lsb
        self.msb = msb
    def __init__(self, lsb):
        self.lsb = lsb
        self.msb = lsb
    def __init__(self, match_string, full_range):
        int_range = re.findall(r"\d+", match_string)
        if len(int_range):
            self.lsb = int(int_range[0])
            self.msb = int(int_range[0])
            if len(int_range) == 2:
                self.msb = int(int_range[1])
        else:
            self.lsb = 0
            self.msb = (full_range-1)

    def get_bits_in_range(self):
        return range(self.lsb, self.msb + 1)

class LiveField:
    def __init__(self, fld, f_stage, l_stage):
        self.field = fld
        self.first_stage = f_stage
        self.last_stage = l_stage
    def __init__(self, fld, stage_string, num_stages):
        self.field = fld
        stg_range = re.findall(r"\d+", stage_string)
        if len(stg_range):
            self.first_stage = stg_range[0]
            self.last_stage = stg_range[0]
            if len(stg_range) == 2:
                self.last_stage = stg_range[1]
        else:
            self.first_stage = -1
            self.last_stage = num_stages

    # Comparison function
    def __eq__(self, other):
        if isinstance(other, LiveField):
            return (self.field == other.field and self.first_stage == other.first_stage and
                    self.last_stage == other.last_stage)
        return False

    def __ne__(self, other):
        return not self.__eq__(other)

    def __hash__(self):
        return hash('{}_{}_{}'.format(self.field, self.first_stage, self.last_stage))

    def __str__(self):
        return '{} stage(s): {}..{}'.format(self.field, self.first_stage, self.last_stage)
    
    # Check for liverange overlap
    def has_lrange_overlap(self, other):
        if isinstance(other, LiveField):
            return not (self.last_stage < other.first_stage or self.first_stage > other.last_stage)
        return False

def has_stage_overlap(lf_set):
    lf_list = list(lf_set)

    for i in range(len(lf_list)):
        for j in range(i+1, len(lf_list)):
            lf1 = lf_list[i]
            if not isinstance(lf1, LiveField):
                continue
            lf2 = of_list[j]
            if not isinstance(lf2, LiveField):
                continue
            if lf1.has_lrange_overlap(lf2):
                return True

    return False
    
class ContainerAlloc:
    def __init__(self, name):
        self.name = name
        self.bit_allocs = {}
        self.size = 8
        if re.search(r'[H]', name):
            self.size = 16
        elif re.search(r'[W]', name):
            self.size = 32

    # Check container name to determine overlay risk
    def overlay_risk(self):
        if re.match(r'T', self.name):
            return False
        if re.match(r'B0', self.name):
            return False
        if re.match(r'B16', self.name):
            return False
        return True
    
    def add_field_alloc(self, live_field, bit_range):
        # overlapping_fields = False
        cntr_range = IntRange(bit_range, self.size)
        for c_bit in cntr_range.get_bits_in_range():
            assert c_bit < self.size
            if c_bit not in self.bit_allocs:
                self.bit_allocs[c_bit] = set()
            self.bit_allocs[c_bit].add(live_field)
            # if len(self.bit_allocs[c_bit]) > 1:
            #     overlapping_fields = True

        # return overlapping_fields


    def get_overlay_bits(self, bit_range): #, stage_overlap):
        bits = set()
        for c_bit in bit_range.get_bits_in_range():
            if (c_bit in self.bit_allocs) and len(self.bit_allocs[c_bit]) > 1:
                # if stage_overlap and has_stage_overlap(self.bit_allocs[c_bit]):
                #     bits.append(c_bit)
                # elif not stage_overlap:
                    bits.append(c_bit)

        return bits

    def __str__(self):
        pretty_cntr = '{}\n  '.format(self.name)
        for key, value in self.bit_allocs.items():
            pretty_cntr += '{} : '.format(key)
            for item in value:
                pretty_cntr += '{} , '.format(str(item))
            pretty_cntr += '\n  '
        return pretty_cntr +'\n'

class ContainerOverlays:
    def __init__(self, container_allocs):
        self.bit_overlays = {}  # map container bit (e.g. B2[0]) to set of overlaid fields

        for alloc in container_allocs:
            # Collect overlay bits regardless of liverange (stage) overlap
            ov_bits = alloc.get_overlay_bits(IntRange('', alloc.size)) 

            for ov_bit in ov_bits:
                bit_id = '{}[{}]'.format(alloc.name, ov_bit)
                bit_overlays[bit_id] = set(alloc.bit_allocs[ov_bit])
                # if has_stage_overlap(alloc.bit_allocs[ov_bit]):
                #     stage_overlays[bit_id] = set(alloc.bit_allocs[ov_bit])

    def filter_liverange_overlaps(self):
        # Collect non liverange overlapping bits
        rem_bits = set()
        for key, value in bit_overlays.items():
            if not has_stage_overlap(value):
                rem_bits.add(key)

        # Remove them from set of overlaid bits
        for b in rem_bits:
            del bit_overlays[b]

    def __str__(self):
        pretty_overlay_bits = '\n'
        for key, value in self.bit_overlays.items():
            pretty_overlay_bits += '{} : '.format(key)
            for item in value:
                pretty_overlay_bits += '{} , '.format(str(item))
            pretty_overlay_bits += '\n  '
        return pretty_overlay_bits +'\n'

    def no_overlays(self):
        if (len(self.bit_overlays) == 0):
            return True
        return False
    

def parse_file(filename, start_token, stop_token):
    num_stages = 12  # Set it for Tofino and update later for Tofino2
    mappings = {}
    container_allocs = []

    with open(filename, 'r') as file:
        is_parsing = False
        line_num = 0

        for line in file:
            alloc = line.strip()
            line_num += 1
            
            if re.match(r'^target: Tofino2', alloc):
                num_stages = 20

            if alloc == start_token:
                is_parsing = True
                print("is_parsing=True ({}  line:{})".format(start_token, str(line_num)))
                continue
            elif is_parsing and (alloc == stop_token):
                print("is_parsing=False ({}  line:{})".format(start_token, str(line_num)))
                break

            if is_parsing:
                # *TODO* Add support for multiple stage definitions: e.g.:
                # Virgilina.Funston.Dugger: {  stage 0..4: B22(0), stage 5..14: DB4(0), stage 15..16: B22(0) }
                # Match Container slice WITH stage info
                match = re.match(r'^([a-zA-Z0-9.$_-]+): \{  stage ([0-9.]+): ([a-zA-Z]{1,2}\d+)([()0-9.]*)',
                                 alloc)
                if match:
                    fld, stg, cntr, cntr_range = match.groups()
                    mappings[cntr] = fld
                    lf = LiveField(fld, stg, num_stages)
                    c_alloc = ContainerAlloc(cntr)
                    c_alloc.add_field_alloc(lf, cntr_range)
                    if c_alloc.overlay_risk():
                        container_allocs.append(c_alloc)
                    print(cntr, '[', cntr_range, ']', " --> ", fld, " @stage " , stg)
                    continue

                # Match container slice WITHOUT stage info
                match = re.match(r'^([a-zA-Z0-9.$_-]+): ([a-zA-Z]{1,2}\d+)([()0-9.]*)', alloc)
                if match:
                    fld, cntr, cntr_range = match.groups()
                    mappings[cntr] = fld
                    lf = LiveField(fld, '', num_stages)
                    c_alloc = ContainerAlloc(cntr)
                    cntr_bits = ''
                    if cntr_range is not None:
                        cntr_bits = cntr_range
                    c_alloc.add_field_alloc(lf, cntr_bits)
                    if c_alloc.overlay_risk():
                        container_allocs.append(c_alloc)
                    print("2. ", cntr, ' [', cntr_range, "] --> ", fld)
                    continue

                
    return mappings, container_allocs


def main(input_file, output_file):
    print('Parsing bfa file: {}'.format(input_file))
        
    i_result, i_allocs = parse_file(input_file, 'phv ingress:', 'context_json:')
    ingr_overlays = ContainerOverlays(i_allocs)
    e_result, e_allocs = parse_file(input_file, 'phv egress:', 'context_json:')
    egr_overlays = ContainerOverlays(e_allocs)

    # *TODO* report overlay for non liverange overlaps using ContainerOverlays.filter_liverange_overlaps()
    with open(output_file, 'w') as file:
        # Report Ingress Overlays
        file.write('********   INGRESS OVERLAYS  *********\n')
        if (ingr_overlays.no_overlays()):
            file.write('NO OVERLAYS FOUND!!!')
        else:
            file.write(str(ingr_overlays))
        file.write('\n')

        # Report Egress Overlays
        file.write('********   EGRESS OVERLAYS  *********\n')
        if (egr_overlays.no_overlays()):
            file.write('NO OVERLAYS FOUND!!!')
        else:
            file.write(str(egr_overlays))
        file.write('\n')

            
    print('\nOutput stored in file {}'.format(output_file))



if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='''\nUsage info: \n\nn  report_overlays.py 
                                                  -i <input.bfa> [-o <output.log>]''')

    parser.add_argument("-i", "--input", required=True, help = "Input BF assembly file")
    parser.add_argument("-0", "--output", help = "Output text report file")
    args = parser.parse_args()
    in_file = args.input
    if (not re.match(r'\S+\.bfa$', in_file)):
        sys.exit("Input file is not a *.bfa")
    out_file = args.output if args.output else in_file.replace('.bfa', '.log')

    main(in_file, out_file)
