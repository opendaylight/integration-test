# This script is designed to be run in a directory where the karaf.log file is present
# It greps the log file and produced 3 text files which can then be used to find more 
# information about transactions
#
# To properly use this script you must ensure that the karaf.log is produced with the 
# following log settings (this goes in etc/org.ops4j.pax.logging.cfg)
#
# log4j.logger.org.opendaylight.controller.cluster.datastore.Shard=DEBUG
# log4j.logger.org.opendaylight.controller.cluster.datastore.AbstractTransactionContext=DEBUG
#
 
grep "Total modifications" karaf.log | awk '{print $1","$2"," $20 "," $23}' > txnbegin.txt
grep "Applying local modifications for Tx" karaf.log | awk '{print $1","$2","$22}' > txnreached.txt
grep "currentTransactionComplete" karaf.log | awk '{print $1","$2"," $18}' > txnend.txt
