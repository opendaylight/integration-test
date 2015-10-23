"""Utility for playing generated BGP data to ODL.

It needs to be run with sudo-able user when you want to use ports below 1024
as --myip. This utility is used to avoid excessive waiting times which EXABGP
exhibits when used with huge router tables and also avoid the memory cost of
EXABGP in this type of scenario."""

# Copyright (c) 2015 Cisco Systems, Inc. and others.  All rights reserved.
#
# This program and the accompanying materials are made available under the
# terms of the Eclipse Public License v1.0 which accompanies this distribution,
# and is available at http://www.eclipse.org/legal/epl-v10.html

__author__ = "Vratko Polak"
__copyright__ = "Copyright(c) 2015, Cisco Systems, Inc."
__license__ = "Eclipse Public License v1.0"
__email__ = "vrpolak@cisco.com"

# TODO: Introduce support for different update scenarios (prefix withdrawn, preudo-random updates, ...)
# - introduced logging and new command-line parameters (regression testing)
# - new parameters initialisation & new functions of MessageGenerator class introduced (testing non-regression)
#   - OPEN & KEEPALIVE messages replaced
#   - UPDATE messages replaced
#   - code cleaning

import argparse
import binascii
import ipaddr
import select
import socket
import time
import logging
import struct


def parse_arguments():
    """Use argparse to get arguments, return args object."""
    parser = argparse.ArgumentParser()
    # TODO: Should we use --argument-names-with-spaces?
    str_help = 'Autonomous System number use in the stream (current default as in ODL: 64496).'
    parser.add_argument('--asnumber', default=64496, type=int, help=str_help)
    # FIXME: We are acting as iBGP peer, we should mirror AS number from peer's open message.
    str_help = 'Amount of IP prefixes to generate. Negative number means "practically infinite".'
    parser.add_argument('--amount', default='1', type=int, help=str_help)
    str_help = 'Maximal number of IP prefixes to be announced in one iteration (one update message)'
    parser.add_argument('--insert', default='1', type=int, help=str_help)
    str_help = 'Maximal number of IP prefixes to be withdrawn in one iteration (one update message)'
    parser.add_argument('--withdraw', default='0', type=int, help=str_help)
    str_help = 'The number of prefixes to process without withdrawals'
    parser.add_argument('--prefill', default='0', type=int, help=str_help)
    str_help = 'Prefix insertion and withdrawal in separate UPDATE messages'
    parser.add_argument('--separate', dest='combined', action='store_const', const=False,
                        default=False, help=str_help)
    str_help = 'Prefix insertion and withdrawal in common UPDATE message'
    parser.add_argument('--common', dest='combined', action='store_const', const=True,
                        default=False, help=str_help)
    str_help = 'Generates preudo-random UPDATES for remaining number of prefixes'
    parser.add_argument('--randomize', dest='randomize', action='store_const', const=True,
                        default=False, help=str_help)
    parser.add_argument('--firstprefix', default='8.0.1.0', type=ipaddr.IPv4Address, help=str_help)
    str_help = 'The prefix length.'
    parser.add_argument('--prefixlen', default=28, type=int, help=str_help)
    str_help = 'If present, this tool will be listening for connection, instead of initiating it.'
    parser.add_argument('--listen', action='store_true', help=str_help)
    str_help = 'Numeric IP Address to bind to and derive BGP ID from. Default value only suitable for listening.'
    parser.add_argument('--myip', default='0.0.0.0', type=ipaddr.IPv4Address, help=str_help)
    str_help = 'TCP port to bind to when listening or initiating connection. Default only suitable for initiating.'
    parser.add_argument('--myport', default='0', type=int, help=str_help)
    str_help = 'The IP of the next hop to be placed into the update messages.'
    parser.add_argument('--nexthop', default='192.0.2.1', type=ipaddr.IPv4Address, dest="nexthop", help=str_help)
    str_help = 'Numeric IP Address to try to connect to. Currently no effect in listening mode.'
    parser.add_argument('--peerip', default='127.0.0.2', type=ipaddr.IPv4Address, help=str_help)
    str_help = 'TCP port to try to connect to. No effect in listening mode.'
    parser.add_argument('--peerport', default='179', type=int, help=str_help)
    str_help = 'Local hold time.'
    parser.add_argument('--holdtime', default='180', type=int, help=str_help)
    str_help = 'Maximal idle time when waiting for an input'
    parser.add_argument('--idle', default='86400', type=int, help=str_help)
    str_help = 'Log level (--error, --info, --debug)'
    parser.add_argument('--error', dest='loglevel', action='store_const', const=logging.ERROR,
                        default=logging.ERROR, help=str_help)
    parser.add_argument('--info', dest='loglevel', action='store_const', const=logging.INFO,
                        default=logging.ERROR, help=str_help)
    parser.add_argument('--debug', dest='loglevel', action='store_const', const=logging.DEBUG,
                        default=logging.ERROR, help=str_help)
    arguments = parser.parse_args()
    # TODO: Are sanity checks (such as asnumber>=0) required?
    return arguments


def establish_connection(arguments):
    """Establish connection according to arguments, return socket."""
    if arguments.listen:
        logging.info('Connecting in the listening mode.')
        logging.debug('Local IP address: ' + str(arguments.myip))
        logging.debug('Local port: ' + str(arguments.myport))
        listening_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        listening_socket.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        listening_socket.bind((str(arguments.myip), arguments.myport))  # bind need single tuple as argument
        listening_socket.listen(1)
        bgp_socket, _ = listening_socket.accept()
        # TODO: Verify client IP is cotroller IP.
        listening_socket.close()
    else:
        logging.info('Connecting in the talking mode.')
        logging.debug('Local IP address: ' + str(arguments.myip))
        logging.debug('Local port: ' + str(arguments.myport))
        logging.debug('Remote IP address: ' + str(arguments.peerip))
        logging.debug('Remote port: ' + str(arguments.peerport))
        talking_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        talking_socket.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        talking_socket.bind((str(arguments.myip), arguments.myport))  # bind to force specified address and port
        talking_socket.connect((str(arguments.peerip), arguments.peerport))  # socket does not spead ipaddr, hence str()
        bgp_socket = talking_socket
    logging.info('Connected to ODL.')
    return bgp_socket


def get_short_int_from_message(message, offset=16):
    """Extract 2-bytes number from packed string, default offset is for BGP message size."""
    high_byte_int = ord(message[offset])
    low_byte_int = ord(message[offset + 1])
    short_int = high_byte_int * 256 + low_byte_int
    return short_int


class MessageError(ValueError):
    """Value error with logging optimized for hexlified messages."""

    def __init__(self, text, message, *args):
        """Store and call super init for textual comment, store raw message which caused it."""
        self.text = text
        self.msg = message
        super(MessageError, self).__init__(text, message, *args)

    def __str__(self):
        """
        Generate human readable error message

        Concatenate text comment, colon with space
        and hexlified message. Use a placeholder string
        if the message turns out to be empty.
        """
        message = binascii.hexlify(self.msg)
        if message == "":
            message = "(empty message)"
        return self.text + ': ' + message


def read_open_message(bgp_socket):
    """Receive message, perform some validation, return the raw message."""
    msg_in = bgp_socket.recv(65535)  # TODO: Is smaller buffer size safe?
    # TODO: Is it possible for incoming open message to be split in more than one packet?
    # Some validation.
    if len(msg_in) < 37:  # 37 is minimal length of open message with 4-byte AS number.
        raise MessageError("Got something else than open with 4-byte AS number", msg_in)
    # TODO: We could check BGP marker, but it is defined only later; decide what to do.
    reported_length = get_short_int_from_message(msg_in)
    if len(msg_in) != reported_length:
        raise MessageError("Message length is not " + reported_length + " in message", msg_in)
    logging.info('Open message received.')
    return msg_in


class MessageGenerator(object):
    """Class with methods returning messages and state holding configuration data required to do it properly."""

    # TODO: Define bgp marker as class (constant) variable.
    def __init__(self, args):
        """Initialize data according to command-line args."""
        self.Total_Prefix_Amount = args.amount
        self.Remaining_Prefixes = self.Total_Prefix_Amount
        """Number of update messages left to be sent."""

        """New parameters initialisation"""
        self.Iteration = 0
        self.Prefix_Base_Default = args.firstprefix
        self.Prefix_Length_Default = args.prefixlen
        self.WR_Prefixes_Default = []
        self.NLRI_Prefixes_Default = []
        self.Version_Default = 4
        self.My_Autonomous_System_Default = args.asnumber
        self.Hold_Time_Default = args.holdtime  # Local hold time.
        self.BGP_Identifier_Default = int(args.myip)
        self.Next_Hop_Default = args.nexthop
        self.Prefix_Count_To_Add_Default = args.insert
        self.Prefix_Count_To_Del_Default = args.withdraw
        if self.Prefix_Count_To_Add_Default <= self.Prefix_Count_To_Del_Default:
            self.Prefix_Count_To_Add_Default = self.Prefix_Count_To_Del_Default + 1
            # total number of prefixes must grow
        self.Slot_Size_Default = self.Prefix_Count_To_Add_Default
        self.Remaining_Prefixes_Treshold = self.Total_Prefix_Amount - args.prefill
        self.Combined_Update_Default = args.combined
        self.Randomize_Prefixes_Default = args.randomize
        """Default values used for randomized part"""
        S1_Slots = ((self.Total_Prefix_Amount - self.Remaining_Prefixes_Treshold - 1) /
                    self.Prefix_Count_To_Add_Default + 1)
        S2_Slots = ((self.Remaining_Prefixes_Treshold - 1) /
                    (self.Prefix_Count_To_Add_Default - self.Prefix_Count_To_Del_Default) + 1)
        # S1_First_Index = 0
        # S1_Last_Index = S1_Slots * self.Prefix_Count_To_Add_Default - 1
        S2_First_Index = S1_Slots * self.Prefix_Count_To_Add_Default
        S2_Last_Index = (S2_First_Index +
                         S2_Slots * (self.Prefix_Count_To_Add_Default - self.Prefix_Count_To_Del_Default) - 1)
        self.Slot_Gap_Default = ((self.Total_Prefix_Amount - self.Remaining_Prefixes_Treshold - 1) /
                                 self.Prefix_Count_To_Add_Default + 1)
        self.Randomize_Lowest_Default = S2_First_Index
        self.Randomize_Highest_Default = S2_Last_Index

        logging.info('Initialisation')
        logging.info('  Target number of stored prefixes: ' + str(self.Total_Prefix_Amount))
        logging.info('  Prefix base: ' + str(self.Prefix_Base_Default) + '/' + str(self.Prefix_Length_Default))
        logging.info('  My Autonomous System number: ' + str(self.My_Autonomous_System_Default))
        logging.info('  My Hold Time: ' + str(self.Hold_Time_Default))
        logging.info('  My BGP Identifier: ' + str(self.BGP_Identifier_Default))
        logging.info('  Next Hop: ' + str(self.Next_Hop_Default))
        logging.info('  Prefix count to be inserted at once: ' + str(self.Prefix_Count_To_Add_Default))
        logging.info('  Prefix count to be withdrawn at once: ' + str(self.Prefix_Count_To_Del_Default))
        logging.info('  Remaining number of prefixes to process in parallel with withdrawals ' +
                     str(self.Remaining_Prefixes_Treshold) + ' prefixes')
        logging.debug('  Prefix index range used for remaining number of prefixes [' +
                      str(self.Randomize_Lowest_Default) + ', ' + str(self.Randomize_Highest_Default) + ']')
        logging.info('  Conbined UPDATE messages: ' + str(self.Combined_Update_Default))
        logging.info('  Randomize prefix generation: ' + str(self.Randomize_Prefixes_Default))
        logging.info('  Let\'s go ...\n')

        # TODO: Notification for hold timer expiration can be handy.

    # Return pseudo-randomized (reproducible) index for selected range
    def randomize_index(self, index, lowest=None, highest=None):
        # default values handling
        if lowest is None:
            lowest = self.Randomize_Lowest_Default
        if highest is None:
            highest = self.Randomize_Highest_Default
        # randomize
        if (index >= lowest) and (index <= highest):
            # we are in the randomized range -> shuffle it inside the range
            new_index = highest - (index - lowest)
        else:
            # we are out of the randomized range -> nothing to do
            new_index = index
        return new_index

    # Get list of prefixes
    def get_prefix_list(self, slot_index, slot_size=None, prefix_base=None, prefix_len=None, prefix_count=None,
                        randomize=None):
        # default values handling
        if slot_size is None:
            slot_size = self.Slot_Size_Default
        if prefix_base is None:
            prefix_base = self.Prefix_Base_Default
        if prefix_len is None:
            prefix_len = self.Prefix_Length_Default
        if prefix_count is None:
            prefix_count = slot_size
        if randomize is None:
            randomize = self.Randomize_Prefixes_Default
        # generating list of prefixes
        indexes = []
        prefixes = []
        prefix_gap = 2 ** (32 - prefix_len)
        for i in range(prefix_count):
            prefix_index = slot_index * slot_size + i
            if randomize:
                prefix_index = self.randomize_index(prefix_index)
            indexes.append(prefix_index)
            prefixes.append(prefix_base + prefix_index * prefix_gap)
        logging.debug('    Prefix slot index: ' + str(slot_index))
        logging.debug('    Prefix slot size: ' + str(slot_size))
        logging.debug('    Prefix count: ' + str(prefix_count))
        logging.debug('    Prefix indexes: ' + str(indexes))
        logging.debug('    Prefix list: ' + str(prefixes))
        return prefixes

    def compose_update_message(self, PrefixCountToAdd=None, PrefixCountToDel=None):
        """Return update message, prepare next prefix, decrease amount without checking it."""
        # default values handling
        if PrefixCountToAdd is None:
            PrefixCountToAdd = self.Prefix_Count_To_Add_Default
        if PrefixCountToDel is None:
            PrefixCountToDel = self.Prefix_Count_To_Del_Default
        # logging
        if not (self.Iteration % 1000):
            logging.info('Iteration: ' + str(self.Iteration) +
                         ' - total remaining routes: ' + str(self.Remaining_Prefixes))
        logging.debug('#' * 10 + ' Iteration: ' + str(self.Iteration) + ' ' + '#' * 10)
        logging.debug('  Remaining routes: ' + str(self.Remaining_Prefixes))
        # calculation reet of prefixes and possible corrections to numbers of prefixes
        if self.Remaining_Prefixes > self.Remaining_Prefixes_Treshold:
            PrefixCountToDel = 0
            logging.debug('  --- STARAIGHTFORWARD SCENARIO ---')
        else:
            logging.debug('  --- COMBINED SCENARIO ---')
        PrefixCountToAdd = (PrefixCountToDel + min(PrefixCountToAdd - PrefixCountToDel, self.Remaining_Prefixes))
        # prefix slots selection for insertion and withdrawal in this iteration
        SlotIndexToAdd = self.Iteration
        SlotIndexToDel = SlotIndexToAdd - self.Slot_Gap_Default
        # getting lists of prefixes for insertion in this iteration
        logging.debug('  Prefixes to be inserted in this iteration:')
        PrefixListToAdd = self.get_prefix_list(SlotIndexToAdd, prefix_count=PrefixCountToAdd)
        # getting lists of prefixes for withdrawal in this iteration
        logging.debug('  Prefixes to be withdrawn in this iteration:')
        PrefixListToDel = self.get_prefix_list(SlotIndexToDel, prefix_count=PrefixCountToDel)
        # generating the mesage
        if self.Combined_Update_Default:
            # Send routes to be introduced and withdrawn in one UPDATE message
            msg_out = self.UPDATE(WR_Prefixes=PrefixListToDel, NLRI_Prefixes=PrefixListToAdd)
        else:
            # Send routes to be introduced and withdrawn in separate UPDATE messages (if needed)
            msg_out = self.UPDATE(WR_Prefixes=[], NLRI_Prefixes=PrefixListToAdd)
            if PrefixCountToDel:
                msg_out += self.UPDATE(WR_Prefixes=PrefixListToDel, NLRI_Prefixes=[])
        # updating totals for the next iteration
        self.Iteration += 1
        self.Remaining_Prefixes -= (PrefixCountToAdd - PrefixCountToDel)
        # returning the encoded message
        return msg_out

    """New functions for BGP messages encoding introduced"""

    """ OPEN Message (rfc4271#section-4.2) """
    def OPEN(self, Version=None, My_Autonomous_System=None, Hold_Time=None, BGP_Identifier=None):

        # Default values handling
        if Version is None:
            Version = self.Version_Default
        if My_Autonomous_System is None:
            My_Autonomous_System = self.My_Autonomous_System_Default
        if Hold_Time is None:
            Hold_Time = self.Hold_Time_Default
        if BGP_Identifier is None:
            BGP_Identifier = self.BGP_Identifier_Default

        # Marker
        Marker_HEX = "\xFF" * 16

        # Type
        Type = 1
        Type_HEX = struct.pack('B', Type)

        # Version
        Version_HEX = struct.pack('B', Version)

        # My_Autonomous_System
        My_Autonomous_System_2B = 23456  # AS_TRANS value, 23456 decadic.
        if My_Autonomous_System < 65536:  # AS number is mappable to 2 bytes
            My_Autonomous_System_2B = My_Autonomous_System
        My_Autonomous_System_HEX_2B = struct.pack('>H', My_Autonomous_System)

        # Hold Time
        Hold_Time_HEX = struct.pack('>H', Hold_Time)

        # BGP Identifier
        BGP_Identifier_HEX = struct.pack('>I', BGP_Identifier)

        # Optional Parameters
        Optional_Parameters_HEX = (
            "\x02"  # Param type ("Capability Ad")
            "\x06"  # Length (6 bytes)
            "\x01"  # Capability type (NLRI Unicast), see RFC 4760, secton 8
            "\x04"  # Capability value length
            "\x00\x01"  # AFI (Ipv4)
            "\x00"  # (reserved)
            "\x01"  # SAFI (Unicast)

            "\x02"  # Param type ("Capability Ad")
            "\x06"  # Length (6 bytes)
            "\x41"  # "32 bit AS Numbers Support" (see RFC 6793, section 3)
            "\x04"  # Capability value length
            + struct.pack('>I', My_Autonomous_System)  # My AS in 32 bit format
        )

        # Optional Parameters Length
        Optional_Parameters_Length = len(Optional_Parameters_HEX)
        Optional_Parameters_Length_HEX = struct.pack('B', Optional_Parameters_Length)

        # Length (big-endian)
        Length = (
            len(Marker_HEX) + 2 + len(Type_HEX) + len(Version_HEX) + len(My_Autonomous_System_HEX_2B) +
            len(Hold_Time_HEX) + len(BGP_Identifier_HEX) + len(Optional_Parameters_Length_HEX) +
            len(Optional_Parameters_HEX)
        )
        Length_HEX = struct.pack('>H', Length)

        # OPEN Message
        Message_HEX = (
            Marker_HEX +
            Length_HEX +
            Type_HEX +
            Version_HEX +
            My_Autonomous_System_HEX_2B +
            Hold_Time_HEX +
            BGP_Identifier_HEX +
            Optional_Parameters_Length_HEX +
            Optional_Parameters_HEX
        )

        logging.debug('OPEN Message encoding')
        logging.debug('  Marker=0x' + binascii.hexlify(Marker_HEX))
        logging.debug('  Length=' + str(Length) + ' (0x' + binascii.hexlify(Length_HEX) + ')')
        logging.debug('  Type=' + str(Type) + ' (0x' + binascii.hexlify(Type_HEX) + ')')
        logging.debug('  Version=' + str(Version) + ' (0x' + binascii.hexlify(Version_HEX) + ')')
        logging.debug('  My Autonomous System=' + str(My_Autonomous_System_2B) +
                      ' (0x' + binascii.hexlify(My_Autonomous_System_HEX_2B) + ')')
        logging.debug('  Hold Time=' + str(Hold_Time) + ' (0x' + binascii.hexlify(Hold_Time_HEX) + ')')
        logging.debug('  BGP Identifier=' + str(BGP_Identifier) +
                      ' (0x' + binascii.hexlify(BGP_Identifier_HEX) + ')')
        logging.debug('  Optional Parameters Length=' + str(Optional_Parameters_Length) +
                      ' (0x' + binascii.hexlify(Optional_Parameters_Length_HEX) + ')')
        logging.debug('  Optional Parameters=0x' + binascii.hexlify(Optional_Parameters_HEX))
        logging.debug('  OPEN Message encoded: 0x' + binascii.b2a_hex(Message_HEX))

        return Message_HEX

    """ UPDATE Message (rfc4271#section-4.3) """
    def UPDATE(self, WR_Prefixes=None, NLRI_Prefixes=None, WR_Prefix_Length=None, NLRI_Prefix_Length=None,
               My_Autonomous_System=None, Next_Hop=None):

        # Default values handling
        if WR_Prefixes is None:
            WR_Prefixes = self.WR_Prefixes_Default  # no need to create a copy of the list
        if NLRI_Prefixes is None:
            NLRI_Prefixes = self.NLRI_Prefixes_Default  # no need to create a copy of the list
        if WR_Prefix_Length is None:
            WR_Prefix_Length = self.Prefix_Length_Default
        if NLRI_Prefix_Length is None:
            NLRI_Prefix_Length = self.Prefix_Length_Default
        if My_Autonomous_System is None:
            My_Autonomous_System = self.My_Autonomous_System_Default
        if Next_Hop is None:
            Next_Hop = self.Next_Hop_Default

        # Marker
        Marker_HEX = "\xFF" * 16

        # Type
        Type = 2
        Type_HEX = struct.pack('B', Type)

        # Withdrawn Routes
        Bytes = ((WR_Prefix_Length - 1) / 8) + 1
        Withdrawn_Routes_HEX = ''
        for prefix in WR_Prefixes:
            Withdrawn_Route_HEX = (struct.pack('B', WR_Prefix_Length) + struct.pack('>I', int(prefix))[:Bytes])
            Withdrawn_Routes_HEX += Withdrawn_Route_HEX

        # Withdrawn Routes Length
        Withdrawn_Routes_Length = len(Withdrawn_Routes_HEX)
        Withdrawn_Routes_Length_HEX = struct.pack('>H', Withdrawn_Routes_Length)

        # TODO: to replace hardcoded string by encoding?
        # Path Attributes
        if NLRI_Prefixes != []:
            Path_Attributes_HEX = (
                "\x40"  # Flags ("Well-Known")
                "\x01"  # Type (ORIGIN)
                "\x01"  # Length (1)
                "\x00"  # Origin: IGP
                "\x40"  # Flags ("Well-Known")
                "\x02"  # Type (AS_PATH)
                "\x06"  # Length (6)
                "\x02"  # AS segment type (AS_SEQUENCE)
                "\x01"  # AS segment length (1)
                + struct.pack('>I', My_Autonomous_System) +  # AS segment (4 bytes)
                "\x40"  # Flags ("Well-Known")
                "\x03"  # Type (NEXT_HOP)
                "\x04"  # Length (4)
                + struct.pack('>I', int(Next_Hop))  # IP address of the next hop (4 bytes)
            )
        else:
            Path_Attributes_HEX = ""

        # Total Path Attributes Length
        Total_Path_Attributes_Length = len(Path_Attributes_HEX)
        Total_Path_Attributes_Length_HEX = struct.pack('>H', Total_Path_Attributes_Length)

        # Network Layer Reachability Information
        Bytes = ((NLRI_Prefix_Length - 1) / 8) + 1
        NLRI_HEX = ''
        for Prefix in NLRI_Prefixes:
            NLRI_Prefix_HEX = (struct.pack('B', NLRI_Prefix_Length) + struct.pack('>I', int(Prefix))[:Bytes])
            NLRI_HEX += NLRI_Prefix_HEX

        # Length (big-endian)
        Length = (
            len(Marker_HEX) + 2 + len(Type_HEX) + len(Withdrawn_Routes_Length_HEX) + len(Withdrawn_Routes_HEX) +
            len(Total_Path_Attributes_Length_HEX) + len(Path_Attributes_HEX) + len(NLRI_HEX)
        )
        Length_HEX = struct.pack('>H', Length)

        # UPDATE Message
        Message_HEX = (
            Marker_HEX +
            Length_HEX +
            Type_HEX +
            Withdrawn_Routes_Length_HEX +
            Withdrawn_Routes_HEX +
            Total_Path_Attributes_Length_HEX +
            Path_Attributes_HEX +
            NLRI_HEX
        )

        logging.debug('UPDATE Message encoding')
        logging.debug('  Marker=0x' + binascii.hexlify(Marker_HEX))
        logging.debug('  Length=' + str(Length) + ' (0x' + binascii.hexlify(Length_HEX) + ')')
        logging.debug('  Type=' + str(Type) + ' (0x' + binascii.hexlify(Type_HEX) + ')')
        logging.debug('  Withdrawn_Routes_Length=' + str(Withdrawn_Routes_Length) +
                      ' (0x' + binascii.hexlify(Withdrawn_Routes_Length_HEX) + ')')
        logging.debug('  Withdrawn_Routes=' + str(WR_Prefixes) + '/' + str(WR_Prefix_Length) +
                      ' (0x' + binascii.hexlify(Withdrawn_Routes_HEX) + ')')
        logging.debug('  Total Path Attributes Length=' + str(Total_Path_Attributes_Length) +
                      ' (0x' + binascii.hexlify(Total_Path_Attributes_Length_HEX) + ')')
        logging.debug('  Path Attributes=' + '(0x' + binascii.hexlify(Path_Attributes_HEX) + ')')
        logging.debug('  Network Layer Reachability Information=' + str(NLRI_Prefixes) +
                      '/' + str(NLRI_Prefix_Length) + ' (0x' + binascii.hexlify(NLRI_HEX) + ')')
        logging.debug('  UPDATE Message encoded: 0x' + binascii.b2a_hex(Message_HEX))

        return Message_HEX

    """ NOTIFICATION Message (rfc4271#section-4.5) """
    def NOTIFICATION(self, Error_Code, Error_Subcode, Data_HEX=''):
        # Marker
        Marker_HEX = "\xFF" * 16

        # Type
        Type = 3
        Type_HEX = struct.pack('B', Type)

        # Error Code
        Error_Code_HEX = struct.pack('B', Error_Code)

        # Error Subode
        Error_Subcode_HEX = struct.pack('B', Error_Subcode)

        # Length (big-endian)
        Length = len(Marker_HEX) + 2 + len(Type_HEX) + len(Error_Code_HEX) + len(Error_Subcode_HEX) + len(Data_HEX)
        Length_HEX = struct.pack('>H', Length)

        # NOTIFICATION Message
        Message_HEX = (
            Marker_HEX +
            Length_HEX +
            Type_HEX +
            Error_Code_HEX +
            Error_Subcode_HEX +
            Data_HEX
        )

        logging.debug('NOTIFICATION Message encoding')
        logging.debug('  Marker=0x' + binascii.hexlify(Marker_HEX))
        logging.debug('  Length=' + str(Length) + ' (0x' + binascii.hexlify(Length_HEX) + ')')
        logging.debug('  Type=' + str(Type) + ' (0x' + binascii.hexlify(Type_HEX) + ')')
        logging.debug('  Error Code=' + str(Error_Code) + ' (0x' + binascii.hexlify(Error_Code_HEX) + ')')
        logging.debug('  Error Subode=' + str(Error_Subcode) + ' (0x' + binascii.hexlify(Error_Subcode_HEX) + ')')
        logging.debug('  Data=' + ' (0x' + binascii.hexlify(Data_HEX) + ')')
        logging.debug('  NOTIFICATION Message encoded: 0x' + binascii.b2a_hex(Message_HEX))

        return Message_HEX

    """ KEEP ALIVE Message (rfc4271#section-4.4) """
    def KEEPALIVE(self):

        # Marker
        Marker_HEX = "\xFF" * 16

        # Type
        Type = 4
        Type_HEX = struct.pack('B', Type)

        # Length (big-endian)
        Length = len(Marker_HEX) + 2 + len(Type_HEX)
        Length_HEX = struct.pack('>H', Length)

        # KEEP ALIVE Message
        Message_HEX = (
            Marker_HEX +
            Length_HEX +
            Type_HEX
        )

        logging.debug('KEEP ALIVE Message encoding')
        logging.debug('  Marker=0x' + binascii.hexlify(Marker_HEX))
        logging.debug('  Length=' + str(Length) + ' (0x' + binascii.hexlify(Length_HEX) + ')')
        logging.debug('  Type=' + str(Type) + ' (0x' + binascii.hexlify(Type_HEX) + ')')
        logging.debug('  KEEP ALIVE Message encoded: 0x' + binascii.b2a_hex(Message_HEX))

        return Message_HEX


class TimeTracker(object):
    """Class for tracking timers, both for my keepalives and peer's hold time."""

    def __init__(self, msg_in):
        """Initialize config, based on hardcoded defaults and open message from peer."""
        # Note: Relative time is always named timedelta, to stress that (non-delta) time is absolute.
        self.report_timedelta = 1.0  # In seconds. TODO: Configurable?
        """Upper bound for being stuck in the same state, we should at least report something before continuing."""
        # Negotiate the hold timer by taking the smaller of the 2 values (mine and the peer's).
        hold_timedelta = 240  # Not an attribute of self yet.
        # TODO: Make the default value configurable, default value could mirror what peer said.
        peer_hold_timedelta = get_short_int_from_message(msg_in, offset=22)
        if hold_timedelta > peer_hold_timedelta:
            hold_timedelta = peer_hold_timedelta
        if hold_timedelta != 0 and hold_timedelta < 3:
            raise ValueError("Invalid hold timedelta value: ", hold_timedelta)
        self.hold_timedelta = hold_timedelta  # only now the final value is visible from outside
        """If we do not hear from peer this long, we assume it has died."""
        self.keepalive_timedelta = int(hold_timedelta / 3.0)
        """Upper limit for duration between messages, to avoid being declared dead."""
        self.snapshot_time = time.time()  # The same as calling snapshot(), but also declares a field.
        """Sometimes we need to store time. This is where to get the value from afterwards."""
        self.peer_hold_time = self.snapshot_time + self.hold_timedelta  # time_keepalive may be too strict
        """At this time point, peer will be declared dead."""
        self.my_keepalive_time = None  # to be set later
        """At this point, we should be sending keepalive message."""

    def snapshot(self):
        """Store current time in instance data to use later."""
        self.snapshot_time = time.time()  # Read as time before something interesting was called.

    def reset_peer_hold_time(self):
        """Move hold time to future as peer has just proven it still lives."""
        self.peer_hold_time = time.time() + self.hold_timedelta

    # Some methods could rely on self.snapshot_time, but it is better to require user to provide it explicitly.
    def reset_my_keepalive_time(self, keepalive_time):
        """Move KA timer to future based on given time from before sending."""
        self.my_keepalive_time = keepalive_time + self.keepalive_timedelta

    def is_time_for_my_keepalive(self):
        if self.hold_timedelta == 0:
            return False
        return self.snapshot_time >= self.my_keepalive_time

    def get_next_event_time(self):
        if self.hold_timedelta == 0:
            return self.snapshot_time + 86400
        return min(self.my_keepalive_time, self.peer_hold_time)

    def check_peer_hold_time(self, snapshot_time):
        """Raise error if nothing was read from peer until specified time."""
        if self.hold_timedelta != 0:  # Hold time = 0 means keepalive checking off.
            if snapshot_time > self.peer_hold_time:  # time.time() may be too strict
                raise RuntimeError("Peer has overstepped the hold timer.")  # TODO: Include hold_timedelta?
                # TODO: Add notification sending (attempt). That means move to write tracker.


class ReadTracker(object):
    """Class for tracking read of mesages chunk by chunk and for idle waiting."""

    def __init__(self, bgp_socket, timer):
        """Set initial state."""
        # References to outside objects.
        self.socket = bgp_socket
        self.timer = timer
        # Really new fields.
        self.header_length = 18
        """BGP marker length plus length field length."""  # TODO: make it class (constant) attribute
        self.reading_header = True
        """Computation of where next chunk ends depends on whether we are beyond length field."""
        self.bytes_to_read = self.header_length
        """Countdown towards next size computation."""
        self.msg_in = ""
        """Incremental buffer for message under read."""

    def read_message_chunk(self):
        """Read up to one message, do not return anything."""
        # TODO: We also could return the whole message, but currently nobody cares.
        # We assume the socket is readable.
        chunk_message = self.socket.recv(self.bytes_to_read)
        self.msg_in += chunk_message
        self.bytes_to_read -= len(chunk_message)
        if not self.bytes_to_read:  # TODO: bytes_to_read < 0 is not possible, right?
            # Finished reading a logical block.
            if self.reading_header:
                # The logical block was a BGP header. Now we know size of message.
                self.reading_header = False
                self.bytes_to_read = get_short_int_from_message(self.msg_in)
            else:  # We have finished reading the body of the message.
                # Peer has just proven it is still alive.
                self.timer.reset_peer_hold_time()
                # TODO: Do we want to count received messages?
                # This version ignores the received message.
                # TODO: Should we do validation and exit on anything besides update or keepalive?
                # Prepare state for reading another message.
                self.msg_in = ""
                self.reading_header = True
                self.bytes_to_read = self.header_length
        # We should not act upon peer_hold_time if we are reading something right now.
        return

    def wait_for_read(self):
        """When we know there are no more updates to send, we use this to avoid busy-wait."""
        # First, compute time to first predictable state change (or report event)
        event_time = self.timer.get_next_event_time()
        wait_timedelta = event_time - time.time()  # snapshot_time would be imprecise
        if wait_timedelta < 0:
            # The program got around to waiting to an event in "very near
            # future" so late that it became a "past" event, thus tell
            # "select" to not wait at all. Passing negative timedelta to
            # select() would lead to either waiting forever (for -1) or
            # select.error("Invalid parameter") (for everything else).
            wait_timedelta = 0
        # And wait for event or something to read.
        select.select([self.socket], [], [self.socket], wait_timedelta)
        # Not checking anything, that will be done in next iteration.
        return


class WriteTracker(object):
    """Class tracking enqueueing messages and sending chunks of them."""

    def __init__(self, bgp_socket, generator, timer):
        """Set initial state."""
        # References to outside objects,
        self.socket = bgp_socket
        self.generator = generator
        self.timer = timer
        # Really new fields.
        # TODO: Would attribute docstrings add anything substantial?
        self.sending_message = False
        self.bytes_to_send = 0
        self.msg_out = ""

    def enqueue_message_for_sending(self, message):
        """Change write state to include the message."""
        self.msg_out += message
        self.bytes_to_send += len(message)
        self.sending_message = True

    def send_message_chunk_is_whole(self):
        """Perform actions related to sending (chunk of) message, return whether message was completed."""
        # We assume there is a msg_out to send and socket is writable.
        # print 'going to send', repr(self.msg_out)
        self.timer.snapshot()
        bytes_sent = self.socket.send(self.msg_out)
        self.msg_out = self.msg_out[bytes_sent:]  # Forget the part of message that was sent.
        self.bytes_to_send -= bytes_sent
        if not self.bytes_to_send:
            # TODO: Is it possible to hit negative bytes_to_send?
            self.sending_message = False
            # We should have reset hold timer on peer side.
            self.timer.reset_my_keepalive_time(self.timer.snapshot_time)
            # Which means the possible reason for not prioritizing reads is gone.
            return True
        return False


class StateTracker(object):
    """Main loop has state so complex it warrants this separate class."""

    def __init__(self, bgp_socket, generator, timer):
        """Set the initial state according to existing socket and generator."""
        # References to outside objects.
        self.socket = bgp_socket
        self.generator = generator
        self.timer = timer
        # Sub-trackers.
        self.reader = ReadTracker(bgp_socket, timer)
        self.writer = WriteTracker(bgp_socket, generator, timer)
        # Prioritization state.
        self.prioritize_writing = False
        """
        In general, we prioritize reading over writing. But in order to not get blocked by neverending reads,
        we should check whether we are not risking running out of holdtime.
        So in some situations, this field is set to True to attempt finishing sending a message,
        after which this field resets back to False.
        """
        # TODO: Alternative is to switch fairly between reading and writing (called round robin from now on).
        # Message counting is done in generator.

    def perform_one_loop_iteration(self):
        """Calculate priority, resolve all ifs, call appropriate method, return to caller to repeat."""
        self.timer.snapshot()
        if not self.prioritize_writing:
            if self.timer.is_time_for_my_keepalive():
                if not self.writer.sending_message:
                    # We need to schedule a keepalive ASAP.
                    self.writer.enqueue_message_for_sending(self.generator.KEEPALIVE())
                # We are sending a message now, so prioritize finishing it.
                self.prioritize_writing = True
        # Now we know what our priorities are, we have to check which actions are available.
        # socket.socket() returns three lists, we store them to list of lists.
        list_list = select.select([self.socket], [self.socket], [self.socket], self.timer.report_timedelta)
        read_list, write_list, except_list = list_list
        # Lists are unpacked, each is either [] or [self.socket], so we will test them as boolean.
        if except_list:
            raise RuntimeError("Exceptional state on socket", self.socket)
        # We will do either read or write.
        if not (self.prioritize_writing and write_list):
            # Either we have no reason to rush writes, or the socket is not writable.
            # We are focusing on reading here.
            if read_list:  # there is something to read indeed
                # In this case we want to read chunk of message and repeat the select,
                self.reader.read_message_chunk()
                return
            # We were focusing on reading, but nothing to read was there.
            # Good time to check peer for hold timer.
            self.timer.check_peer_hold_time(self.timer.snapshot_time)
            # Things are quiet on the read front, we can go on and attempt to write.
        if write_list:
            # Either we really want to reset peer's view of our hold timer, or there was nothing to read.
            if self.writer.sending_message:  # We were in the middle of sending a message.
                whole = self.writer.send_message_chunk_is_whole()  # Was it the end of a message?
                if self.prioritize_writing and whole:  # We were pressed to send something and we did it.
                    self.prioritize_writing = False  # We prioritize reading again.
                return
            # Finally, we can look if there is some update message for us to generate.
            if self.generator.Remaining_Prefixes:
                msg_out = self.generator.compose_update_message()
                if not self.generator.Remaining_Prefixes:  # We have just finished update generation, end-of-rib is due.
                    logging.info('All update messages generated. Finally an END-OF-RIB is going to be sent.')
                    msg_out += self.generator.UPDATE(WR_Prefixes=[], NLRI_Prefixes=[])
                self.writer.enqueue_message_for_sending(msg_out)
                return  # Attempt for the actual sending will be done in next iteration.
            # Nothing to write anymore, except occasional keepalives.
            # To avoid busy loop, we do idle waiting here.
            self.reader.wait_for_read()
            return
        # We can neither read nor write.
        logging.warning('Input and output both blocked for ' + str(self.timer.report_timedelta) + ' seconds.')
        # FIXME: Are we sure select has been really waiting the whole period?
        return


def main():
    """Establish BGP connection and enter main loop for sending updates."""
    arguments = parse_arguments()
    logging.basicConfig(format='%(asctime)s %(levelname)s: %(message)s', level=arguments.loglevel)
    logging.basicConfig(level=arguments.loglevel)
    bgp_socket = establish_connection(arguments)
    # Initial handshake phase. TODO: Can it be also moved to StateTracker?
    # Receive open message before sending anything.
    # FIXME: Add parameter to send default open message first, to work with "you first" peers.
    msg_in = read_open_message(bgp_socket)
    timer = TimeTracker(msg_in)
    generator = MessageGenerator(arguments)
    msg_out = generator.OPEN()
    logging.debug('Sending the OPEN message: ' + binascii.hexlify(msg_out))
    # Send our open message to the peer.
    bgp_socket.send(msg_out)
    # Wait for confirming keepalive.
    # TODO: Surely in just one packet?
    msg_in = bgp_socket.recv(19)  # Using exact keepalive length to not see possible updates.
    if msg_in != generator.KEEPALIVE():
        logging.error('Open not confirmed by keepalive, instead got ' + binascii.hexlify(msg_in))
        raise MessageError("Open not confirmed by keepalive, instead got", msg_in)
    timer.reset_peer_hold_time()
    # Send the keepalive to indicate the connection is accepted.
    timer.snapshot()  # Remember this time.
    msg_out = generator.KEEPALIVE()
    logging.debug('Sending the KEEP ALIVE message: ' + binascii.hexlify(msg_out))
    bgp_socket.send(msg_out)
    timer.reset_my_keepalive_time(timer.snapshot_time)  # Use the remembered time.
    # End of initial handshake phase.
    state = StateTracker(bgp_socket, generator, timer)
    while True:  # main reactor loop
        state.perform_one_loop_iteration()

if __name__ == "__main__":
    main()
