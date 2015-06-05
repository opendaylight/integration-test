ps axf | grep karaf | grep -v grep | awk '{print "kill -9 " $1}' | sudo sh
