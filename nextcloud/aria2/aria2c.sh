#! /bin/bash -eu
run() {
    echo "Run aria2c and ariaNG"
    if [ "$ARIA2_ENABLE_AUTH" = "true" ]; then
        echo "Using Basic Auth config file "
        CADDY_FILE=/usr/local/caddy/SecureCaddyfile
    else
        echo "Using caddy without Basic Auth"
        CADDY_FILE=/usr/local/caddy/Caddyfile
    fi

    if [ "$ARIA2_RPC_SSL" = "true" ]; then
        echo "Start aria2 with secure config"

        /usr/bin/aria2c --conf-path="/root/conf/aria2.conf" -D  \
        --enable-rpc --rpc-listen-all  \
        --rpc-certificate=/root/conf/key/aria2.crt \
        --rpc-private-key=/root/conf/key/aria2.key \
        --rpc-secret="$ARIA2_RPC_SECRET" --rpc-secure \
        && caddy -quic --conf ${CADDY_FILE}
    else
        echo "Start aria2 with standard mode"
        /usr/bin/aria2c --conf-path="/root/conf/aria2.conf" -D \
        --enable-rpc --rpc-listen-all \
        && caddy -quic --conf ${CADDY_FILE}
    fi
}

run_aria2() {
    local param=
    if [ "$ARIA2_RPC_SSL" = "true" ]; then
        param="--rpc-certificate=/root/conf/key/aria2.crt --rpc-private-key=/root/conf/key/aria2.key --rpc-secret="$ARIA2_RPC_SECRET" --rpc-secure"
    fi
    /usr/bin/aria2c --conf-path="/root/conf/aria2.conf" --enable-rpc --rpc-listen-all $param
}


prepare() {
    local aria2_path=/usr/local/www/aria2
    local aria_ng=/root/AriaNg.zip
    [ -d "$aria2_path" ] || install -d $aria2_path $aria2_path/Download
    if [ $(ls -A $aria2_path| wc -w) -lt 1 ];then
        cd $aria2_path
        unzip $aria_ng
        rm -rf $aria_ng
        chown -R www-data:root ${aria2_path}
        chmod -R 775 ${aria2_path}
        cd -
    fi
}

prepare
#run
run_aria2


