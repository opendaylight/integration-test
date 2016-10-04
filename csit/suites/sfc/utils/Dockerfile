FROM socketplane/busybox:latest
MAINTAINER The SocketPlane Team <support@socketplane.io>
ENV OVS openvswitch_2.5.90-1
ENV SUPERVISOR_STDOUT_VERSION 0.1.1
# Configure supervisord
RUN mkdir -p /var/log/supervisor/
ADD supervisord.conf /etc/
# Install supervisor_stdout
WORKDIR /opt
RUN mkdir -p /var/log/supervisor/
RUN mkdir -p /etc/openvswitch
RUN wget https://pypi.python.org/packages/source/s/supervisor-stdout/supervisor-stdout-$SUPERVISOR_STDOUT_VERSION.tar.gz --no-check-certificate && \
    tar -xzvf supervisor-stdout-0.1.1.tar.gz && \
    mv supervisor-stdout-$SUPERVISOR_STDOUT_VERSION supervisor-stdout && \
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


