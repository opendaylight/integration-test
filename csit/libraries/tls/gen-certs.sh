#!/usr/bin/env bash

CA_KEY="ca.key"
CA_CERT="ca.crt"

SWITCH_KEY="switch.key"
SWITCH_CERT="switch.crt"
SWITCH_CACHAIN="cachain.crt"

CONTROLLER_KEY="controller.key"
CONTROLLER_CERT="controller.crt"
CONTROLLER_KEYSTORE="keystore.p12"
CONTROLLER_TRUSTSTORE="truststore.p12"

OPENSSL_CONFIG="openssl.conf"
CA_INDEX="index.txt"
CERT_SERIAL="serial"

VALID_DAYS="1825" # 5 years
PASSWORD="opendaylight"
CA_KEY_LEN="4096"
CLIENT_KEY_LEN="2048"

WORKDIR="./cert-tmp"
CERT_FILES_SAVED=(
    "$SWITCH_KEY"
    "$SWITCH_CERT"
    "$SWITCH_CACHAIN"
    "$CONTROLLER_KEYSTORE"
    "$CONTROLLER_TRUSTSTORE"
)

function prep_cert_gen() {
    rm -rf "$WORKDIR"
    rm -f "${CERT_FILES_SAVED[@]}"
    mkdir -p "$WORKDIR"
}

function post_cleanup() {
    for i in "${CERT_FILES_SAVED[@]}"; do
        cp -p "$WORKDIR/$i" .
    done
    rm -rf "$WORKDIR"
}

function create_openssl_config() {
    touch "$CA_INDEX"
    echo 1000 >"$CERT_SERIAL"
    cat <<EOF >"$OPENSSL_CONFIG"
[ ca ]
default_ca = CA_default

[ CA_default ]
new_certs_dir     = .
database          = $CA_INDEX
serial            = $CERT_SERIAL
private_key       = $CA_KEY
certificate       = $CA_CERT
policy            = policy_loose
default_md        = sha256

[ policy_loose ]
countryName             = optional
stateOrProvinceName     = optional
localityName            = optional
organizationName        = optional
organizationalUnitName  = optional
commonName              = supplied
emailAddress            = optional

[ req ]
default_bits        = 2048
distinguished_name  = req_distinguished_name
string_mask         = utf8only
default_md          = sha256

[ req_distinguished_name ]
countryName                     = Country Name (2 letter code)
stateOrProvinceName             = State or Province Name
localityName                    = Locality Name
0.organizationName              = Organization Name
organizationalUnitName          = Organizational Unit Name
commonName                      = Common Name
emailAddress                    = Email Address

[ ca_cert ]
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always,issuer
basicConstraints = critical, CA:true
keyUsage = critical, digitalSignature, cRLSign, keyCertSign

[ client_cert ]
basicConstraints = CA:FALSE
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid,issuer:always
keyUsage = critical, digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth, clientAuth
EOF
}

function gen_ca() {
    echo -e "\\nGenerate CA Key & Certificate"
    echo -e "-----------------------------"

    echo -e "\\n> Root: Key & Self-Signed Certificate"
    openssl req \
        -config "$OPENSSL_CONFIG" \
        -new \
        -newkey rsa:"$CA_KEY_LEN" \
        -x509 \
        -nodes \
        -extensions ca_cert \
        -subj "/C=US/ST=California/L=San Jose/O=Verizon/CN=Root CA" \
        -days "$VALID_DAYS" \
        -keyout "$CA_KEY" \
        -out "$CA_CERT"

    chmod 0600 "$CA_KEY"
    chmod 0644 "$CA_CERT"
}

function gen_signed_cert() {
    local client="$1"
    local client_key="$2"
    local client_cert="$3"
    local client_csr

    client_csr="$(tr '[:upper:]' '[:lower:]' <<<"$client").csr"

    echo -e "\\n> $client: CSR\\n"
    openssl req \
        -config "$OPENSSL_CONFIG" \
        -new \
        -newkey rsa:"$CLIENT_KEY_LEN" \
        -nodes \
        -subj "/C=US/ST=California/L=San Jose/O=Verizon/CN=$client" \
        -keyout "$client_key" \
        -out "$client_csr"

    echo -e "\\n> $client: Certificate\\n"
    openssl ca \
        -batch \
        -config "$OPENSSL_CONFIG" \
        -extensions client_cert \
        -notext \
        -days "$VALID_DAYS" \
        -in "$client_csr" \
        -out "$client_cert"

    chmod 0600 "$client_key"
    chmod 0644 "$client_cert"
}

function gen_keystore() {
    local client="$1"
    local client_key="$2"
    local client_cert="$3"
    local client_keystore="$4"

    echo -e "\\n> $client: Keystore"
    openssl pkcs12 \
        -export \
        -in "$client_cert" \
        -inkey "$client_key" \
        -certfile "$CA_CERT" \
        -passout "pass:$PASSWORD" \
        -out "$client_keystore" \
        -name "$client"

    chmod 0600 "$client_keystore"
}

function gen_truststore() {
    local client="$1"
    local client_truststore="$2"

    echo -e "\\n> $client: Truststore"
    keytool -importcert \
        -noprompt \
        -file "$CA_CERT" \
        -storetype PKCS12 \
        -trustcacerts \
        -alias "rootca" \
        -keystore "$client_truststore" \
        -storepass "$PASSWORD"

    chmod 0644 "$client_truststore"
}

function gen_switch() {
    echo -e "\\nGenerate Switch Key & Certificate"
    echo -e "---------------------------------"
    gen_signed_cert "Switch" "$SWITCH_KEY" "$SWITCH_CERT"
    cp -p "$CA_CERT" "$SWITCH_CACHAIN"
}

function gen_controller() {
    echo -e "\\nGenerate Controller Keystore & Truststore"
    echo -e "-----------------------------------------"
    gen_signed_cert "Controller" "$CONTROLLER_KEY" "$CONTROLLER_CERT"
    gen_keystore "Controller" "$CONTROLLER_KEY" "$CONTROLLER_CERT" "$CONTROLLER_KEYSTORE"
    gen_truststore "Controller" "$CONTROLLER_TRUSTSTORE"
}

function run() {
    prep_cert_gen
    (
        cd "$WORKDIR" || exit 1
        create_openssl_config
        gen_ca
        gen_switch
        gen_controller
    )
    post_cleanup
}

run
