import re
import os
import subprocess
from collections import Counter

idp = "\s+([0-9a-zA-Z_\.\-]+)[\s;\{]"  # () is the identifier

stmtps = {
    "module": "[^\s]module",  # not to catch submodule
    "submodule": "submodule",
    "typedef": "typedef",
    "container": "container",
    "leaf": "leaf",
    "leaf-list": "leaf\-list",
    "list": "[^\s]list",
    "choice": "choice",
    "case": "case",
    "anyxml": "anyxml",
    "grouping": "grouping",
    "rpc": "rpc",
    "notification": "notification",
    "identyity": "identity",
    "extension": "extension",
    "feature": "feature",
}

cpts = {key: re.compile(stmt + idp) for key, stmt in stmtps.iteritems()}

counter = Counter()

for root, subFolders, files in os.walk("."):
    for filename in files:
        if not filename.lower().endswith(".yang"):
            continue
        with open(os.path.join(root, filename), "r") as fin:
            for line in fin:
                real_line = line.split("//")[0]
                for stmt, pattern in cpts.iteritems():
                    matches = pattern.findall(real_line)
                    for match in matches:
                        counter[(stmt, match)] += 1

with open("output.txt","w") as fout:
    for (stmt, match), count in counter.iteritems():
        fout.write(match + '\t' + stmt + '\t' + str(count) + '\n')

subprocess.call("sort output.txt | sort -k 2 -t '\t' -o sorted.txt -s", shell=True)
