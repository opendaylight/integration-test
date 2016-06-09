rm pps*;
rm rpcs*;
for i in {1..10}
	do
		pybot /home/joe/work/integration-test/csit/suites/lispflowmapping/performance/010_Southbound_MapRequest.robot;
		mv pps.csv pps$i.csv;
		mv rpcs.csv rpcs$i.csv;
	done

