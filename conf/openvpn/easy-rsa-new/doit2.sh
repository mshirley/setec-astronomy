#!/bin/sh
export EASY_RSA="`pwd`"
export OPENSSL="openssl"
export PKCS11TOOL="pkcs11-tool"
export GREP="grep"
export KEY_CONFIG=`$EASY_RSA/whichopensslcnf $EASY_RSA`
export KEY_DIR="$EASY_RSA/keys"
echo NOTE: If you run ./clean-all, I will be doing a rm -rf on $KEY_DIR
export PKCS11_MODULE_PATH="dummy"
export PKCS11_PIN="dummy"
export KEY_SIZE=1024
export CA_EXPIRE=3650
export KEY_EXPIRE=3650
export KEY_COUNTRY="US"
export KEY_PROVINCE="CA"
export KEY_CITY="SanFrancisco"
export KEY_ORG="Fort-Funston"
export KEY_EMAIL="me@myhost.mydomain"
export KEY_EMAIL=mail@host.domain
export KEY_CN=changeme
export KEY_NAME=changeme
export KEY_OU=changeme
export PKCS11_MODULE_PATH=changeme
export PKCS11_PIN=1234

# clean-all
if [ "$KEY_DIR" ]; then
    rm -rf "$KEY_DIR"
    mkdir "$KEY_DIR" && \
  chmod go-rwx "$KEY_DIR" && \
  touch "$KEY_DIR/index.txt" && \
  echo 01 >"$KEY_DIR/serial"
else
    echo 'Please source the vars script first (i.e. "source ./vars")'
    echo 'Make sure you have edited it to reflect your configuration.'
fi

# create ca
export KEY_NAME='CA'
#export EASY_RSA="${EASY_RSA:-.}"
"$EASY_RSA/pkitool" --initca 

# create server cert
export KEY_NAME='SERVER'
#export EASY_RSA="${EASY_RSA:-.}"
"$EASY_RSA/pkitool" --server server

# create client cert
export KEY_NAME='CLIENT1'
#export EASY_RSA="${EASY_RSA:-.}"
"$EASY_RSA/pkitool" client1

# create dh
if [ -d $KEY_DIR ] && [ $KEY_SIZE ]; then
    $OPENSSL dhparam -out ${KEY_DIR}/dh${KEY_SIZE}.pem ${KEY_SIZE}
else
    echo 'Please source the vars script first (i.e. "source ./vars")'
    echo 'Make sure you have edited it to reflect your configuration.'
fi
