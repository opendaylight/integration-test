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

text_file = open("plot_data_create.txt", "w")
text_file.write('Rate_create\n')
text_file.write('{0}\n'.format(data[0]))
text_file.close()

text_file = open("plot_data_delete.txt", "w")
text_file.write('Rate_delete\n')
text_file.write('{0}\n'.format(data[1]))
text_file.close()
