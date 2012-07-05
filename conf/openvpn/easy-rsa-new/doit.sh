#!/bin/sh
source ./vars
./clean-all
export KEY_NAME='CA'
./build-ca
export KEY_NAME='SERVER'
./build-key-server server
export KEY_NAME='CLIENT1'
./build-key client1
./build-dh
