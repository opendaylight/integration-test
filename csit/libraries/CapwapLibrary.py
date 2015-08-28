"""
Library for the robot based system test tool of the OpenDaylight project.
Authors: Vaibhav Bhatnagar@Brocade
Updated: 2015-06-01
"""
import socket

from robot.libraries.BuiltIn import BuiltIn


class CapwapLibrary(object):
    """Provide many methods to simulate WTPs and their functions."""

    def __init__(self):
        self.builtin = BuiltIn()

    def send_discover(self, ac_ip, wtp_ip='', ip='ip', port=5246):
        """Send Discover CAPWAP Packet from a WTP."""
        data = ''.join(chr(x) for x in [0x00, 0x20, 0x01, 0x02, 0x03, 0x04, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16])
        self.builtin.log('Sending Discover Packet to: %s' % ac_ip, 'DEBUG')
        session = socket.socket(socket.AF_INET, socket.SOCK_DGRAM, socket.IPPROTO_UDP)
        session.sendto(data, (ac_ip, port))
        self.builtin.log('Packet Sent', 'DEBUG')

    def get_hostip(self):
        """Get Host IP Address."""
        ip_addr = socket.gethostbyname(socket.gethostname())
        return ip_addr

    def get_simulated_wtpip(self, controller):
        """Get the Simulated WTP ip based on the controller."""
        if controller == '127.0.0.1':
            exp_ip = controller
        else:
            exp_ip = self.get_hostip()
        return exp_ip
