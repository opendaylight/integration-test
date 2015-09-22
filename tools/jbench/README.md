HOW TO BUILD AND RUN
====================


Pre-requisites : JDK 1.7+, Maven 3+

- git clone ssh://<user-name>@git.opendaylight.org:29418/integration/test

- Change to jbench directory in the cloned respository. Issue the commad "cd test/tools/jbench"

- From jbench directory, issue the command "mvn clean install"

- This creates 'target' folder in jbench directory. Issue "cd target"

- From test/tools/jbench/target, issue "java -jar jbench-0.0.1-SNAPSHOT-jar-with-dependencies.jar <options for jbench program>"

  Example: java -jar jbench-0.0.1-SNAPSHOT-jar-with-dependencies.jar -n 3 -c 10.0.0.2:6633 10.0.0.3:6640 localhost:6640 -O latency


Options supported by jbench:
----------------------------
Options:
    -c, --controller       controller ip and port number
                           Default: []
    -C, --cooldown         loops to be disregarded at test end (cooldown)
                           Default: 0
    -d, --debug            enable debugging
                           Default: 0
    -D, --delay            delay starting testing after features_reply is
                           received (in ms)
                           Default: 0
    -h, --help             print this message
                           Default: false
    -l, --loops            loops per test
                           Default: 16
    -M, --mac-addresses    unique source mac addresses per switch
                           Default: 100000
    -m, --ms-per-test      test length in ms
                           Default: 1000
    -n, --number           number of controllers
                           Default: 1
  * -O, --operation-mode   latency or throughput mode
    -s, --switches         number of switches
                           Default: 16
    -w, --warmup           loops to be disregarded on test start (warmup)
                           Default: 1

- -O --operation-mode is a required option. The valid values are 'latency' or 'throughput'(irrespective of case while specifying the value i.e., laTENCy is also considered as valid.

- The user must  pass the same number of controller IP and port tuples to -c --controller option as specified as number of controllers to -n --number option. If they do not
  match, the following error message will be displayed to the user along with the command usage.

  Number of Controller Ip:port tuples supplied and number of controllers didn't match
