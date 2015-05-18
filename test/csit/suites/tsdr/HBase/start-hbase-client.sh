#Downloading and Installation of HBase will be performed during on Controller VM deployment refer controller.sh
echo "Starting Hbase Server daemon..."
export JAVA_HOME=/usr
/tmp/Hbase/hbase-0.94.15/bin/start-hbase.sh
