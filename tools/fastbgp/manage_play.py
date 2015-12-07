
import argparse
import ipaddr
import logging
import thread

from itertools import izip

from play import *


def job(*args):
	
	# Create arguments object from tuple
	class Arguments:
		def __init__(self, **entries):
			self.__dict__.update(entries)

	iter_args = iter(args)
	arguments = Arguments(**dict(izip(iter_args, iter_args)))


	
	# vratko code continue here ...
	logging.basicConfig(format="%(asctime)s %(levelname)s: %(message)s")
	stdout_logger = logging.getLogger("stdout_logger")
	stdout_logger.setLevel(arguments.loglevel)
	bgp_socket = establish_connection(arguments)
	# Initial handshake phase. TODO: Can it be also moved to StateTracker?
	# Receive open message before sending anything.
	# FIXME: Add parameter to send default open message first,
	# to work with "you first" peers.
	msg_in = read_open_message(bgp_socket)
	timer = TimeTracker(msg_in)
	generator = MessageGenerator(arguments)
	msg_out = generator.open_message()
	stdout_logger.debug("Sending the OPEN message: " + binascii.hexlify(msg_out))
	# Send our open message to the peer.
	bgp_socket.send(msg_out)
	# Wait for confirming keepalive.
	# TODO: Surely in just one packet?
	# Using exact keepalive length to not to see possible updates.
	msg_in = bgp_socket.recv(19)
	if msg_in != generator.keepalive_message():
		stdout_logger.error("Open not confirmed by keepalive, instead got " + binascii.hexlify(msg_in))
		raise MessageError("Open not confirmed by keepalive, instead got", msg_in)
	timer.reset_peer_hold_time()
	# Send the keepalive to indicate the connection is accepted.
	timer.snapshot()  # Remember this time.
	msg_out = generator.keepalive_message()
	stdout_logger.debug("Sending a KEEP ALIVE message: " + binascii.hexlify(msg_out))
	bgp_socket.send(msg_out)
	# Use the remembered time.
	timer.reset_my_keepalive_time(timer.snapshot_time)
	# End of initial handshake phase.
	state = StateTracker(bgp_socket, generator, timer)
	while True:  # main reactor loop
		state.perform_one_loop_iteration()
	

def main():
	"""Use argparse to get arguments, return mgr_args object."""

	parser = argparse.ArgumentParser()
	# TODO: Should we use --argument-names-with-spaces?
	str_help = "Autonomous System number use in the stream (current default as in ODL: 64496)."
	parser.add_argument("--asnumber", default=64496, type=int, help=str_help)
	# FIXME: We are acting as iBGP peer, we should mirror AS number from peer's open message.
	str_help = "Amount of IP prefixes to generate. Negative number is taken as an overflown positive."
	parser.add_argument("--amount", default="1", type=int, help=str_help)
	str_help = "The first IPv4 prefix to announce, given as numeric IPv4 address."
	parser.add_argument("--firstprefix", default="8.0.1.0", type=ipaddr.IPv4Address, help=str_help)
	str_help = "If present, this tool will be listening for connection, instead of initiating it."
	parser.add_argument("--listen", action="store_true", help=str_help)
	str_help = "How many play.py utilities are to be started."
	parser.add_argument("--multiplicity", default="1", type=int, help=str_help)
	str_help = "Numeric IP Address to bind to and derive BGP ID from, for the first player."
	parser.add_argument("--myip", default="0.0.0.0", type=ipaddr.IPv4Address, help=str_help)
	str_help = "TCP port to bind to when listening or initiating connection."
	parser.add_argument("--myport", default="0", type=int, help=str_help)
	str_help = "The IP of the next hop to be placed into the update messages."
	parser.add_argument("--nexthop", default="192.0.2.1", type=ipaddr.IPv4Address, dest="nexthop", help=str_help)
	str_help = "Numeric IP Address to try to connect to. Currently no effect in listening mode."
	parser.add_argument("--peerip", default="127.0.0.2", type=ipaddr.IPv4Address, help=str_help)
	str_help = "TCP port to try to connect to. No effect in listening mode."
	parser.add_argument("--peerport", default="179", type=int, help=str_help)
	# TODO: The step between IP prefixes is currently hardcoded to 16. Should we make it configurable?
	# Yes, the argument list above is sorted alphabetically.
	mgr_args = parser.parse_args()
	# TODO: Are sanity checks (such as asnumber>=0) required?

	if mgr_args.multiplicity < 1:
		print "Multiplicity", mgr_args.multiplicity, "is not positive."
		raise SystemExit(1)
	amount_left = mgr_args.amount
	utils_left = mgr_args.multiplicity
	prefix_current = mgr_args.firstprefix
	myip_current = mgr_args.myip

	thread_args = []

	while 1:
		amount_per_util = (amount_left - 1) / utils_left + 1  # round up
		amount_left -= amount_per_util
		utils_left -= 1

		util_args = []
		util_args.extend(["asnumber", str(mgr_args.asnumber)])
		util_args.extend(["amount", str(amount_per_util)])
		util_args.extend(["firstprefix", str(prefix_current)])
		util_args.extend(["listen", bool(mgr_args.listen)])
		util_args.extend(["myip", str(myip_current)])
		util_args.extend(["myport", int(mgr_args.myport)])
		util_args.extend(["nexthop", str(mgr_args.nexthop)])
		util_args.extend(["peerip", str(mgr_args.peerip)])
		util_args.extend(["peerport", int(mgr_args.peerport)])

		util_args.extend(["loglevel", int(1)]) ### FIXME loglevel

		thread_args.append(util_args)

		if not utils_left:
			break
		prefix_current += amount_per_util * 16
		myip_current += 1

	try:
		# Create threads
		for t in thread_args:
			thread.start_new_thread(job, tuple(t))
	except Exception:
		print "Error: unable to start thread."
		raise SystemExit(2)

	# Work remains forever!
	while 1:
		pass
    
if __name__ == "__main__":
	main()