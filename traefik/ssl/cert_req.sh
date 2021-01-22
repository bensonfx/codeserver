#!/bin/bash

key=bensonfx.cc.alpha.key
csr=${key%.key}.csr


openssl req -new -sha256 \
    -key $key  \
    -subj "/C=CN/ST=Beijing/L=Beijing/O=bensonfx.net/CN=*.bensonfx.net" \
    -reqexts SAN \
    -config <(cat /etc/ssl/openssl.cnf \
        <(printf "[SAN]\nsubjectAltName=DNS:*.bensonfx.net,DNS:bensonfx.net,DNS:*.bensonfx.app, DNS:bensonfx.app")) \
    -out $csr
