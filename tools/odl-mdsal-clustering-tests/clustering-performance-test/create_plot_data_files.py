#!/usr/bin/python
import re

text_file = open("out.log.txt", "r")
log = text_file.read()
text_file.close()

rate = []
time = []

pat_rate = re.compile(r'Avg. requests/s: (?P<rate1>[0-9,\.]+) OK, (?P<rate2>[0-9,\.]+) Total')
pat_time = re.compile(r'Stats collected in (?P<time1>[0-9,\.]+) seconds')

for line in log.splitlines():
    res = pat_rate.search(line)
    if res is not None:
        rate.append(res.groups('rate1')[0])
print rate

for line in log.splitlines():
    res = pat_time.search(line)
    if res is not None:
        time.append(res.groups('time1')[0])
print time

text_file = open("rates.csv", "w")
text_file.write('Add,Delete\n')
text_file.write('{0},{1}\n'.format(rate[0], rate[1]))
text_file.close()

text_file = open("times.csv", "w")
text_file.write('Add,Delete\n')
text_file.write('{0},{1}\n'.format(time[0], time[1]))
text_file.close()
