#!/usr/bin/env bash

password=admin123
echo ${PWD}
OLD_PWD=${PWD}

if [ ! -z $1 ]; then
    test -d $1 || mkdir -p $1
    cd $1
fi
echo ${PWD}

rm csit-keystore-* csit-truststore-* 2>>/dev/null
for ID in $(seq 1 5); do
    keytool -genkeypair \
            -alias odl-sxp-${ID} \
            -keyalg RSA \
            -storepass ${password} \
            -keypass ${password} \
            -dname "CN=www.opendaylight.org, OU=csit, O=ODL, L=N/A, S=N/A, C=N/A" \
            -keystore csit-keystore-${ID}
    keytool -exportcert \
            -keystore csit-keystore-${ID} \
            -alias odl-sxp-${ID} \
            -storepass ${password} \
            -file odl-sxp-${ID}.cer
done

# Node-1 TRUSTS Node-2, Node-5
keytool -importcert \
        -keystore csit-truststore-1 \
        -alias odl-sxp-2 \
        -storepass ${password} \
        -keypass ${password} \
        -file odl-sxp-2.cer \
        -noprompt
keytool -importcert \
        -keystore csit-truststore-1 \
        -alias odl-sxp-5 \
        -storepass ${password} \
        -keypass ${password} \
        -file odl-sxp-5.cer \
        -noprompt
# Node-2 TRUSTS Node-1
keytool -importcert \
        -keystore csit-truststore-2 \
        -alias odl-sxp-2 \
        -storepass ${password} \
        -keypass ${password} \
        -file odl-sxp-1.cer \
        -noprompt
# Node-3 TRUSTS Node-1
keytool -importcert \
        -keystore csit-truststore-3 \
        -alias odl-sxp-2 \
        -storepass ${password} \
        -keypass ${password} \
        -file odl-sxp-1.cer \
        -noprompt
# Node-5 TRUSTS Node-1
keytool -importcert \
        -keystore csit-truststore-5 \
        -alias odl-sxp-2 \
        -storepass ${password} \
        -keypass ${password} \
        -file odl-sxp-1.cer \
        -noprompt

cp csit-keystore-4 csit-truststore-4
rm odl-sxp-*.cer
chmod 755 csit-keystore-* csit-truststore-*

ssh ${ODL_SYSTEM_IP} "mkdir -p $1"
scp ./csit-keystore-* ${ODL_SYSTEM_IP}:$1
scp ./csit-truststore-* ${ODL_SYSTEM_IP}:$1

cd ${OLD_PWD}
