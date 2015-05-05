#echo "Downloading the distribution..."
#rm -rf /tmp/Hbase
#mkdir /tmp/Hbase
#cd /tmp/Hbase

#wget --no-verbose https://archive.apache.org/dist/hbase/hbase-0.94.15/hbase-0.94.15.tar.gz

#echo "Installing the Hbase Server..."
#tar -xvf hbase*.tar.gz
#Above installation has been moved to controller.sh on Controller VM deployment
echo "Starting Hbase Server daemon..."
export JAVA_HOME=/usr
/tmp/Hbase/hbase-0.94.15/bin/start-hbase.sh
