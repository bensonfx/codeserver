#! /bin/bash -eu

run_aria2() {
    local param=
    if [ "$ARIA2_RPC_SSL" = "true" ]; then
        param="$param --rpc-secret="$ARIA2_RPC_SECRET" --rpc-secure"
    fi

    if [ -f "${ARIA2_RPC_KEY}" ] && [ -f "${ARIA2_RPC_CERT}" ];then
        param="$param --rpc-certificate=${ARIA2_RPC_CERT} --rpc-private-key=${ARIA2_RPC_KEY}"
    fi
    /usr/bin/aria2c --conf-path="/root/conf/aria2.conf" --enable-rpc --rpc-listen-all $param
}

prepare() {
    #local aria2_path=/usr/local/www/aria2
    local aria2_path=${CADDY_ROOT}
    if [ -z "$aria2_path" ] || [ ! -d "${aria2_path}" ];then
        echo "$aria2_path do not exist"
        return 1
    fi

    local aria_ng=$(find /root/ -name AriaNg-*.zip)
    [ -d "$aria2_path" ] || install -d $aria2_path $aria2_path/Download
    if [ $(ls -A $aria2_path| wc -w) -lt 1 ];then
        cd $aria2_path
        unzip $aria_ng
        #rm -rf $aria_ng
        #chown -R www-data:root ${aria2_path}
        chown -R 82:root ${aria2_path}
        chmod -R 775 ${aria2_path}
        cd -
    fi

    echo "check version"
    local curr_ver=$(cd $aria2_path;grep -oE "buildVersion:\"v[0-9.]+" js/aria-ng-*.min.js |grep -oE "[0-9.]+")
    local docker_ver=$(find /root -name AriaNg-*.zip | grep -oE "[0-9.]+[0-9]")

    if [ -z "$docker_ver" ];then
        echo "can not get ariaNg package"
        return 0
    fi

    if [ "$curr_ver" != "$docker_ver" ];then
        echo "update ariaNg version from $curr_ver to $docker_ver"
        cd ${aria2_path}
        rm -rf ${aria2_path}/*
        unzip -o $aria_ng
        cd -
    fi
    return 0
}

prepare
run_aria2
