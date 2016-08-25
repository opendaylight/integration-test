#!/usr/bin/env bash


echo "Starting Hive MQTT Server"
cd ./ODL_Vagrant/Hive_MQTT/bin 
pwd
chmod 755 run.sh
./run.sh &
./run.sh > /dev/null 2>&1 &

#java -jar IoT_Sim.jar test.properties
#There should be .properties file

echo "Hive MQTT server started !"

echo "Starting AMQP server"
cd ../../Rabbit_AMQP/sbin
pwd
./rabbitmq-server &
./rabbitmq-server > /dev/null 2>&1 &
#echo "AMQP started !"
