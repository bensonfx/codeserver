#!/bin/sh
namespase="bensonfx"
list="nginx php"
cwd=$(cd `dirname $0`;pwd)

nginx_name="nginx-vts_mod"
php_name="php-fpm"
#CTRL="\033[${STYLE};${FG};${BG}m"
RESET="\033[0m"
COLOR="\033[42;37m"

get_version() {
    local file=$1/Dockerfile
    cat $file |grep -oE "ENV.*VERSION( |=)[-0-9.a-z]+"|grep -oE "[-0-9.a-z]+"
}

log() {
 echo -e "$COLOR$1$RESET"
}

build_image() {
    if [ $# -gt 0 ]; then
        list="$1"
    fi
    cd $cwd
    for docker in $list;do
        local version=$(get_version $docker)
        eval local image="$namespase/\${${docker}_name}:$version"
        local msg="==> $image"
        docker build -t $image $docker
        if [ $? -ne 0 ];then
            log "$msg build failed"
            continue
        fi
        log "$msg build success"
    done
}

################ main start #############
build_image $@
