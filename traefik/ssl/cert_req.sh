#!/bin/bash

key=bensonfx.cc.alpha.key
csr=${key%.key}.csr


openssl req -new -sha256 \
    -key $key  \
    -subj "/C=CN/ST=Beijing/L=Beijing/O=bensonfx.cc/CN=*.bensonfx.cc" \
    -reqexts SAN \
    -config <(cat /etc/ssl/openssl.cnf \
        <(printf "[SAN]\nsubjectAltName=DNS:*.bensonfx.cc,DNS:bensonfx.cc")) \
    -out $csr
