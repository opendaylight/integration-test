#!/usr/bin/python
import re

text_file = open("out.log.txt", "r")
log = text_file.read()
text_file.close()

data = []

pat = re.compile(r'Avg. requests/s: (?P<rate1>[0-9,\.]+) OK, (?P<rate2>[0-9,\.]+) Total')

for line in log.splitlines():
    res = pat.search(line)
    if res is not None:
        data.append(res.groups('rate1')[0])
print data

text_file = open("rates.csv", "w")
text_file.write('Add,Delete\n')
text_file.write('{0},{1}\n'.format(data[0], data[1]))
text_file.close()
