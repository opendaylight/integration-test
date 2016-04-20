import re
import string

print "Keep writing yang identifiers (or bits/enums/whatever),"
print "The scrips will reply with translated Java class name."
print "The translation is stateful and dynamic,"
print "so results depend on previous identifiers and order matters."

mapping = dict()
pattern = re.compile("([A-Z]?[a-z0-9]*)")
while 1:
    print
    print "Yang:",
    identifier = raw_input()
    print "Java:",
    if identifier in mapping:
        print mapping[identifier]
        continue
    base = "".join(map(string.capitalize, pattern.findall(identifier)))
    if not base:
        base = "Foo"
    suffix_size = 0
    clazzes = mapping.values()
    while 1:
        suffix_number = 10 ** suffix_size
        for suffix_number in range(10 ** suffix_size, 2 * (10 ** suffix_size)):
            clazz = base + str(suffix_number)[1:]
            if clazz in clazzes:
                continue
            mapping[identifier] = clazz
            print clazz
            break
        if identifier in mapping:
            break
        suffix_size += 1
