ps axf | grep "karaf[.]main" | grep -v grep | awk '{print "kill -9 " $1}' | sudo sh
