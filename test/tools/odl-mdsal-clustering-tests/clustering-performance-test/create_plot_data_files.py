#!/usr/bin/python

text_file = open("out.log.txt", "r")
log = text_file.read()
text_file.close()

data = []

for line in log.splitlines():
    if 'Total success rate: ' in line:
        ll = line.split(',')
        data.append(ll[0][24:])
print data

text_file = open("rates.csv", "w")
text_file.write('Add,Delete\n')
text_file.write('{0},{1}\n'.format(data[0], data[1]))
text_file.close()
