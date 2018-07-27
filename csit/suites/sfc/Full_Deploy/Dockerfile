FROM socketplane/busybox:latest
MAINTAINER The SocketPlane Team <support@socketplane.io>
ARG OVS_VERSION

ENV OVS openvswitch_${OVS_VERSION}

# Configure supervisord
RUN mkdir -p /var/log/supervisor/
ADD supervisord.conf /etc/
RUN mkdir -p /var/log/supervisor/
RUN mkdir -p /etc/openvswitch

# Install supervisor_stdout
COPY supervisor-stdout-0.1.1.tar.gz /opt/
WORKDIR /opt
RUN tar -xzvf supervisor-stdout-0.1.1.tar.gz && \
    mv supervisor-stdout-0.1.1 supervisor-stdout && \
    rm supervisor-stdout-0.1.1.tar.gz && \
    cd supervisor-stdout && \
    python setup.py install -q

# Get Open vSwitch
WORKDIR /
COPY ovs_package/${OVS}.tgz /
RUN ls -la /
RUN ls -la /var
RUN tar -xzvf ${OVS}.tgz &&\
    mv $OVS openvswitch &&\
    cp -r openvswitch/* / &&\
    rm -r openvswitch &&\
    rm ${OVS}.tgz
ADD configure-ovs.sh /usr/local/share/openvswitch/
RUN mkdir -p /usr/local/var/run/openvswitch

COPY libcrypto.so.10 /usr/lib
COPY libssl.so.10 /usr/lib
COPY libgssapi_krb5.so.2 /usr/lib
COPY libkrb5.so.3 /usr/lib
COPY libcom_err.so.2 /usr/lib
COPY libk5crypto.so.3 /usr/lib
COPY libkrb5support.so.0 /usr/lib
COPY libkeyutils.so.1 /usr/lib
COPY libselinux.so.1 /usr/lib
COPY libpcre.so.1 /usr/lib
COPY liblzma.so.5 /usr/lib


# Create the database
RUN ovsdb-tool create /etc/openvswitch/conf.db /usr/local/share/openvswitch/vswitch.ovsschema
# Put the OVS Python modules on the Python Path
RUN cp -r /usr/local/share/openvswitch/python/ovs /usr/lib/python2.7/site-packages/ovs
CMD ["/usr/bin/supervisord"]


