rm pps*;
rm rpcs*;
for i in {1..10}
	do
		pybot 010_Southbound_MapRequest.robot;
		mv pps.csv pps$i.csv;
		mv rpcs.csv rpcs$i.csv;
	done

./plot_pps.sh
./plot_rpc.sh

scp -r cisco@172.27.231.21:/home/cisco/odl/deploy/current/odl/data/log log21/
scp -r cisco@172.27.231.35:/home/cisco/odl/deploy/current/odl/data/log log35/
scp -r cisco@172.27.231.128:/home/cisco/odl/deploy/current/odl/data/log log128/

