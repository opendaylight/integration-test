#!/usr/bin/python
import re

text_file = open("out.log.txt", "r")
log = text_file.read()
text_file.close()

rate = []
time = []

add_rate = re.compile(r'Add Rate: (?P<rate1>[0-9,\.]+) flows/second')
collect_time = re.compile(r'monitoring finished in \+(?P<time1>[0-9,\.]+) seconds')

for line in log.splitlines():
    res = add_rate.search(line)
    if res is not None:
        rate.append(res.groups('rate1')[0])
print rate

for line in log.splitlines():
    res = collect_time.search(line)
    if res is not None:
        time.append(res.groups('time1')[0])
print time

text_file = open("rates.csv", "w")
text_file.write('Add Rate\n')
text_file.write('{0}\n'.format(rate[0]))
text_file.close()

text_file = open("times.csv", "w")
text_file.write('Add Confirm Time,Delete Confirm Time\n')
text_file.write('{0},{1}\n'.format(time[0], time[1]))
text_file.close()
