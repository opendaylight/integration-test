#!/usr/bin/env bash

echo "Starting Blaster 1:"
./flow_config_blaster.py  --flows=1000 --threads=5 --auth --no-delete &

echo "Starting Blaster 2:"
./flow_config_blaster.py  --flows=1000 --threads=5 --auth --no-delete --startflow=5000 &

echo "Starting Blaster 3:"
./flow_config_blaster.py  --flows=1000 --threads=5 --auth --no-delete --startflow=10000 &

echo "Starting Blaster 4:"
./flow_config_blaster.py  --flows=1000 --threads=5 --auth --no-delete --startflow=15000 &

echo "Starting Blaster 5:"
./flow_config_blaster.py  --flows=1000 --threads=5 --auth --no-delete --startflow=20000 &

echo "Done."
