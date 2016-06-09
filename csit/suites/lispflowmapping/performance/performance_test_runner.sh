./clean.sh

#/home/joe/work/integration-test/tools/clustering/cluster-deployer/deploy.py --distribution /home/joe/work/lispflowmapping/distribution-karaf/target/distribution-karaf-1.4.0-SNAPSHOT.zip  --rootdir /home/joe/odl  --hosts 192.168.100.1,192.168.100.3,192.168.100.4 --clean --template lispflowmapping --rf 3 --user joe --password joe

for i in {1..10}
	do
		echo "Run $i"
		pybot 010_Southbound_MapRequest.robot;
		mv pps.csv pps$i.csv;
		mv rpcs.csv rpcs$i.csv;
	done

./plot_pps.sh
./plot_rpc.sh

#scp -r joe@192.168.100.1:/home/joe/odl/deploy/current/odl/data/log log/
NOW=$(date +"%Y-%m-%d_%H-%M-%S")
ARCHIVE=""
if [ $1 != "" ]
  then
	ARCHIVE=$1-$NOW.zip
  else
        ARCHIVE=result-$NOW.zip
fi
scp -r cisco@172.23.188.24:/home/cisco/odl/deploy/current/odl/data/log log24/
zip $ARCHIVE rpcs* pps* result* log/*
#scp -r cisco@172.27.231.128:/home/cisco/odl/deploy/current/odl/data/log log128/
#scp -r cisco@172.27.231.21:/home/cisco/odl/deploy/current/odl/data/log log21/
#scp -r cisco@172.27.231.35:/home/cisco/odl/deploy/current/odl/data/log log35/
#scp -r cisco@172.27.231.128:/home/cisco/odl/deploy/current/odl/data/log log128/

