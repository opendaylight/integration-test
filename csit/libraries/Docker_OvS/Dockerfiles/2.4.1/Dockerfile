FROM ubuntu:14.04

RUN apt-get update
RUN apt-get install linux-headers-$(uname -r) dkms openssl python python-argparse module-assistant debhelper racoon python-openvswitch uuid-runtime openssh-server grub linux-image-$(uname -r) -y --force-yes --assume-yes

## Add sshd service to the container
RUN mkdir /var/run/sshd
RUN echo 'root:root' | chpasswd
RUN sed -i 's/PermitRootLogin without-password/PermitRootLogin yes/' /etc/ssh/sshd_config
RUN sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd


## Lib SSL
RUN wget -O libssl1.0.2_1.0.2f-2_amd64.deb https://www.dropbox.com/s/tc38mteo3p04xut/libssl1.0.2_1.0.2f-2_amd64.deb?dl=0
## OvS common
RUN wget -O openvswitch-common_2.4.1-1_amd64.deb https://www.dropbox.com/s/xm5il4c3ihagdko/openvswitch-common_2.4.1-1_amd64.deb?dl=0
## OvS switch
RUN wget -O openvswitch-switch_2.4.1-1_amd64.deb https://www.dropbox.com/s/3jyn6fb84ui3wln/openvswitch-switch_2.4.1-1_amd64.deb?dl=0

ADD ../run.sh /root/run.sh

## Install Precompiled OpenVSwitch Version 2.4.1
RUN dpkg -i libssl1.0.2_1.0.2f-2_amd64.deb
RUN dpkg -i openvswitch-common_2.4.1-1_amd64.deb openvswitch-switch_2.4.1-1_amd64.deb

## Open Required Ports
EXPOSE 22
EXPOSE 6633

CMD /usr/sbin/sshd -D ; /root/run.sh