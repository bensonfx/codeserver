#!/bin/sh
export LC_ALL=C

Mem=`free -m | awk '/Mem:/{print $2}'`
PHP_INI_DIR="/usr/local/etc/php"
PHP_INI_FILE=${PHP_INI_DIR}/php.ini
PHP_CONF_DIR=$(php --ini | grep additional | grep -o "/.*/etc/php.*")
FPM_CONF_DIR="/usr/local/etc/php-fpm.d"

#if [ $Mem -le 640 ]; then
#  php_mem_setting=0
#elif [ $Mem -gt 640 -a $Mem -le 1280 ]; then
#  php_mem_setting=1
#elif [ $Mem -gt 1280 -a $Mem -le 2500 ]; then
#  php_mem_setting=2
#elif [ $Mem -gt 2500 -a $Mem -le 3500 ]; then
#  php_mem_setting=3
#elif [ $Mem -gt 3500 -a $Mem -le 4500 ]; then
#  php_mem_setting=4
#elif [ $Mem -gt 4500 -a $Mem -le 8000 ]; then
#  php_mem_setting=6
#elif [ $Mem -gt 8000 ]; then
#  php_mem_setting=8
#fi
#
#if [ $Mem -eq 3000 ]; then
#  php_fpm_setting=1
#elif [ $Mem -gt 3000 -a $Mem -le 4500 ]; then
#  php_fpm_setting=2
#elif [ $Mem -gt 4500 -a $Mem -le 6500 ]; then
#  php_fpm_setting=3
#elif [ $Mem -gt 6500 -a $Mem -le 8500 ]; then
#  php_fpm_setting=4
#elif [ $Mem -gt 8500 ]; then
#  php_fpm_setting=5
#fi

php_mem_setting=1
memory_limit() {
  case ${php_mem_setting} in
    0)
      Mem_level=512M
      Memory_limit=64
      THREAD=1
      ;;
    1)
      Mem_level=1G
      Memory_limit=128
      ;;
    2)
      Mem_level=2G
      Memory_limit=192
      ;;
    3)
      Mem_level=3G
      Memory_limit=256
      ;;
    4)
      Mem_level=4G
      Memory_limit=320
      ;;
    6)
      Mem_level=6G
      Memory_limit=384
      ;;
    8)
      Mem_level=8G
      Memory_limit=448
      ;;
  esac
}

php_fpm_setting=2
set_php_fpm_value() {
  case $php_fpm_setting in
    1)
      max_children=$(($Mem/3/20))
      start_servers=$(($Mem/3/30))
      min_spare_servers=$(($Mem/3/40))
      max_spare_servers=$((Mem/3/20))
      ;;
    2)
      max_children=50
      start_servers=30
      min_spare_servers=20
      max_spare_servers=50
      ;;
    3)
      max_children=60
      start_servers=40
      min_spare_servers=30
      max_spare_servers=60
      ;;
    4)
      max_children=70
      start_servers=50
      min_spare_servers=40
      max_spare_servers=70
      ;;
    5)
      max_children=80
      start_servers=60
      min_spare_servers=50
      max_spare_servers=80
      ;;
  esac
}

config_php() {
  cp ${PHP_INI_DIR}/php.ini-production ${PHP_INI_FILE}
  sed -i "s@^memory_limit.*@memory_limit = ${Memory_limit}M@" ${PHP_INI_FILE}
  sed -i 's@^output_buffering =@output_buffering = On\noutput_buffering =@' ${PHP_INI_FILE}
  sed -i 's@^;cgi.fix_pathinfo.*@cgi.fix_pathinfo=0@' ${PHP_INI_FILE}
  sed -i 's@^short_open_tag = Off@short_open_tag = On@' ${PHP_INI_FILE}
  sed -i 's@^expose_php = On@expose_php = Off@' ${PHP_INI_FILE}
  sed -i 's@^request_order.*@request_order = "CGP"@' ${PHP_INI_FILE}
  sed -i 's@^;date.timezone.*@date.timezone = Asia/Shanghai@' ${PHP_INI_FILE}
  sed -i 's@^post_max_size.*@post_max_size = 100M@' ${PHP_INI_FILE}
  sed -i 's@^upload_max_filesize.*@upload_max_filesize = 50M@' ${PHP_INI_FILE}
  sed -i 's@^max_execution_time.*@max_execution_time = 600@' ${PHP_INI_FILE}
  sed -i 's@^;realpath_cache_size.*@realpath_cache_size = 2M@' ${PHP_INI_FILE}
  sed -i 's@^disable_functions.*@disable_functions = passthru,exec,system,chroot,chgrp,chown,shell_exec,proc_open,proc_get_status,ini_alter,ini_restore,dl,openlog,syslog,readlink,symlink,popepassthru,stream_socket_server,fsocket,popen@' ${PHP_INI_FILE}
  [ -e /usr/sbin/sendmail ] && sed -i 's@^;sendmail_path.*@sendmail_path = /usr/sbin/sendmail -t -i@' ${PHP_INI_FILE}
  #sed -i "s@^;curl.cainfo.*@curl.cainfo = ${openssl_install_dir}/cert.pem@" ${PHP_INI_FILE}
  #sed -i "s@^;openssl.cafile.*@openssl.cafile = ${openssl_install_dir}/cert.pem@" ${PHP_INI_FILE}

  cat > ${PHP_CONF_DIR}/zz-opcache.ini << EOF
[opcache]
opcache.enable=1
opcache.enable_cli=1
opcache.memory_consumption=${Memory_limit}
opcache.interned_strings_buffer=8
opcache.max_accelerated_files=100000
opcache.max_wasted_percentage=5
opcache.use_cwd=1
opcache.validate_timestamps=1
opcache.revalidate_freq=60
;opcache.save_comments=0
opcache.consistency_checks=0
;opcache.optimization_level=0
EOF

  #run php-fpm as deamon
  #local php_fpm_docker_cfg=${FPM_CONF_DIR}/zz-docker.conf
  #sed -i "s#^daemonize = .*#daemonize = yes#g" $php_fpm_docker_cfg
  #sed -i "s#listen = .*#listen = /dev/shm/php-cgi.sock#g" $php_fpm_docker_cfg

  local php_fpm_www_cfg=${FPM_CONF_DIR}/www.conf
  sed -i "s#^pm.max_children =.*#pm.max_children = ${max_children}#g" $php_fpm_www_cfg
  sed -i "s#^pm.start_servers =.*# pm.start_servers = ${start_servers}#g" $php_fpm_www_cfg
  sed -i "s#^pm.min_spare_servers = .*#pm.min_spare_servers = ${min_spare_servers}#g" $php_fpm_www_cfg
  sed -i "s#^pm.max_spare_servers = .*#pm.max_spare_servers = ${max_spare_servers}#g" $php_fpm_www_cfg
  sed -i "s#^;pm.max_requests = .*#pm.max_requests = 2048#g" $php_fpm_www_cfg
  #[ "$web_yn" == 'n' ] && sed -i "s@^listen =.*@listen = $IPADDR:9000@" ${PHP_INI_DIR}/etc/php-fpm.conf
}

init_deps() {
  config_php
  sed -i 's@dl-cdn.alpinelinux.org@mirrors.aliyun.com@g' /etc/apk/repositories
  apk add --no-cache --virtual .fetch-deps \
          openldap-dev zlib-dev \
          gettext-dev perl libcap
  apk add --no-cache --virtual .build-deps \
          coreutils make zip autoconf gcc libc-dev
  export PHP_EXT="gettext zip pdo_mysql opcache"
  docker-php-ext-install -j$(nproc) ${PHP_EXT}
  pecl install -o -f redis
}

####### main start #######
init_deps
