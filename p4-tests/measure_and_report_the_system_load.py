#!/usr/bin/env python3

### the next 2 lines: half-hearted attempts at backwards compatibility with Python pre-3.0
from __future__ import division
from __future__ import print_function

### https://psutil.readthedocs.io/en/latest/
### https://www.thepythoncode.com/article/get-hardware-system-information-python
import psutil, sys, time


###### this block of code: didn`t work, not with the import line and the filter line just before the "x is 1", not in "main", not here...  BUT WORKS in the REPL of the same damned Python version!!! !@#$$%^$^&*
### the following 2 lines are needed due to some idiot deciding that e.g. "x is 1" should cause a warning by default !@#$%^&* in Python >= 3.8
# import warnings
# warnings.filterwarnings("ignore", ".*is.* with a literal.*")
# warnings.filterwarnings("ignore") ### sledge-hammer approach, since the preceding didn`t work in a _script_ [but was just fine interactively :-(]




empty_if_1_else_s                 = lambda x: "" if (str(x)=='1') else 's' ### I replaced the earlier "1==x" with the str-based expression b/c [unfortunately] the idiomatic English reading of "{x} seconds" for {x is 1.0} is "one-point-zero secondS" [final capital letter for emphasis]... that, and the fact that the Python "community" screwed up e.g. "x is 1" with a NONsuppressable-in-scripts warning starting with [C]Python 3.8
number_of_seconds___humanReadable = lambda x: str(x) + " second" + empty_if_1_else_s(x)

def create_or_append(stats, key, value):
  if not key in stats:
    stats[key] = []
  stats[key].append(value) ### safer than "+=" in case there`s something wrong somehow



if __name__ == "__main__":
  import argparse
  arg_parser = argparse.ArgumentParser()
  arg_parser.add_argument("--between-samples_delay_in_seconds", type=float, required=False, default=1.0, help="float, >0, default=1.0")
  arg_parser.add_argument("--number_of_samples_to_take", type=int, required=False, default=3, help="float, >0, default=3")
# arg_parser.add_argument("--verbose", action="store_true", required=False, help="optional")
# arg_parser.add_argument("--debug",   action="store_true", required=False, help="optional")
  parsed_args = arg_parser.parse_args()

  delay_in_seconds = float(parsed_args.between_samples_delay_in_seconds)
  delay_in_seconds___humanReadable = number_of_seconds___humanReadable(delay_in_seconds)

  number_of_samples_to_take = int(parsed_args.number_of_samples_to_take)

  assert delay_in_seconds          > 0
  assert number_of_samples_to_take > 0

#  if parsed_args.debug:
#    global_debug = True
#    print ()
#    log("INFO", "debug code enabled.")
#    print ()

  statistics_data = {} ### _damned_ lies. ;-)

  for sample_index in range(number_of_samples_to_take):

    header_line_1 = "Epoch time:" + str( time.time() ) + "; local time: ''" + time.ctime() + "'' in the "

    ### best-effort dealing with DST :-(
    if time.daylight and (len(time.tzname) > 1):
      header_line_1 += "DST timezone ''"     + time.tzname[1] + "''"
    else:
      header_line_1 += "non-DST timezone ''" + time.tzname[0] + "''"

    print (header_line_1)
    print (len(header_line_1)*'-')

    current_CPU_available_in_percent = 100.0 - psutil.cpu_percent()
    create_or_append(statistics_data, "current_CPU_available_in_percent", current_CPU_available_in_percent)
    print ("current_CPU_available_in_percent =", current_CPU_available_in_percent)

    swap_memory = psutil.swap_memory()

    current_RAM_available_in_bytes = psutil.virtual_memory().available - swap_memory.free
    create_or_append(statistics_data, "current_RAM_available_in_bytes", current_RAM_available_in_bytes)
    print ("current_RAM_available_in_bytes =", current_RAM_available_in_bytes)

    print ("swap total (in bytes)            :", swap_memory.total)
    print ("swap used  (in bytes)            :", swap_memory.used)
    print ("swap free  (in bytes)            :", swap_memory.free)
    print ("swap percent used                :", swap_memory.percent)
    print ("swapped in  since boot (in bytes):", swap_memory.sin)
    print ("swapped out since boot (in bytes):", swap_memory.sout)
    print ()

    create_or_append(statistics_data, "swap total (in bytes)", swap_memory.total)
    create_or_append(statistics_data, "swap percent used"    , swap_memory.percent)
### create_or_append(statistics_data, "", <...>)

    if (sample_index + 1) < number_of_samples_to_take: ### don`t bother with delaying after the last sample
      print ("[About to sleep for " + delay_in_seconds___humanReadable + '.]')
      time.sleep(delay_in_seconds)
      print ()

  print ("Done measuring.")

  print ()

  for key in statistics_data:
    data = statistics_data[key]
    if len(data) > 1: ### otherwise, why bother reporting stats?
      print (key)
      print (len(key)*'-')
      print ( "#/samples:", len(data) )
      print ( "Min.:", min(data) )
      print ( "Max.:", max(data) )
      print ( "Avg.:", sum(data)/len(data) )
      print ()

  ### That`s All, Folks! ###
