#!/bin/bash
# Author:  yeho <lj2007331 AT gmail.com>
# BLOG:  https://blog.linuxeye.com
#
# Notes: OneinStack for CentOS/RadHat 6+ Debian 7+ and Ubuntu 12+
#
# Project home page:
#       https://oneinstack.com
#       https://github.com/lj2007331/oneinstack

clear
printf "
#######################################################################
#                        vhost generate script                        #
#######################################################################
"

. ./script/color.sh
. ./script/get_char.sh

# Check if user is root
[ $(id -u) != '0' ] && { echo "${CFAILURE}Error: You must be root to run this script${CEND}"; exit 1; }

Usage() {
  printf "
Usage: $0 [ ${CMSG}add${CEND} | ${CMSG}del${CEND} ]
${CMSG}add${CEND}    --->Add Virtualhost
${CMSG}del${CEND}    --->Delete Virtualhost
"
}

Create_self_SSL() {
  printf "
You are about to be asked to enter information that will be incorporated
into your certificate request.
What you are about to enter is what is called a Distinguished Name or a DN.
There are quite a few fields but you can leave some blank
For some fields there will be a default value,
If you enter '.', the field will be left blank.
"

  echo
  read -p "Country Name (2 letter code) [CN]: " SELFSIGNEDSSL_C
  [ -z "${SELFSIGNEDSSL_C}" ] && SELFSIGNEDSSL_C="CN"

  echo
  read -p "State or Province Name (full name) [Shanghai]: " SELFSIGNEDSSL_ST
  [ -z "${SELFSIGNEDSSL_ST}" ] && SELFSIGNEDSSL_ST="Shanghai"

  echo
  read -p "Locality Name (eg, city) [Shanghai]: " SELFSIGNEDSSL_L
  [ -z "${SELFSIGNEDSSL_L}" ] && SELFSIGNEDSSL_L="Shanghai"

  echo
  read -p "Organization Name (eg, company) [Example Inc.]: " SELFSIGNEDSSL_O
  [ -z "${SELFSIGNEDSSL_O}" ] && SELFSIGNEDSSL_O="Example Inc."

  echo
  read -p "Organizational Unit Name (eg, section) [IT Dept.]: " SELFSIGNEDSSL_OU
  [ -z "${SELFSIGNEDSSL_O}U" ] && SELFSIGNEDSSL_OU="IT Dept."

  openssl req -new -newkey rsa:2048 -sha256 -nodes -out ${PATH_SSL}/${domain}.csr -keyout ${PATH_SSL}/${domain}.key -subj "/C=${SELFSIGNEDSSL_C}/ST=${SELFSIGNEDSSL_ST}/L=${SELFSIGNEDSSL_L}/O=${SELFSIGNEDSSL_O}/OU=${SELFSIGNEDSSL_OU}/CN=${domain}" > /dev/null 2>&1
  openssl x509 -req -days 36500 -sha256 -in ${PATH_SSL}/${domain}.csr -signkey ${PATH_SSL}/${domain}.key -out ${PATH_SSL}/${domain}.crt > /dev/null 2>&1
}

Create_SSL() {
  while :; do echo
  read -p "Do you want to use a Let's Encrypt certificate? [y/n]: " letsencrypt_yn
  if [[ ! ${letsencrypt_yn} =~ ^[y,n]$ ]]; then
      echo "${CWARNING}input error! Please only input 'y' or 'n'${CEND}"
  else
      break
  fi
  done
  if [ "${letsencrypt_yn}" == 'y' ]; then
  PUBLIC_IPADDR=$(./include/get_public_ipaddr.py)
  for D in ${domain} ${moredomainame}
  do
      Domain_IPADDR=$(ping ${D} -c1 | sed '1{s/[^(]*(//;s/).*//;q}')
      [ "${PUBLIC_IPADDR%.*}" != "${Domain_IPADDR%.*}" ] && { echo; echo "${CFAILURE}DNS problem: NXDOMAIN looking up A for ${D}${CEND}"; echo; exit 1; }
  done

  #add Email
  while :
  do
      echo
      read -p "Please enter Administrator Email(example: admin@example.com): " Admin_Email
      if [ -z "$(echo ${Admin_Email} | grep '.*@.*\..*')" ]; then
      echo "${CWARNING}input error! ${CEND}"
      else
      break
      fi
  done

  [ "${moredomainame_yn}" == 'y' ] && moredomainame_D="$(for D in ${moredomainame}; do echo -d ${D}; done)"
  if [ "${nginx_ssl_yn}" == 'y' ]; then
      [ ! -d ${nginx_conf_dir} ] && mkdir ${nginx_conf_dir}
      echo "server {  server_name ${domain}${moredomainame};  root ${vhostdir};  access_log off; }" > ${nginx_conf_dir}/${domain}.conf
  fi

  if [ -s "$acme_ssl_dir/${domain}/fullchain.cer" ]; then
      [ -e "${PATH_SSL}/${domain}.crt" ] && rm -rf ${PATH_SSL}/${domain}.{crt,key}
      ln -f $acme_ssl_dir/${domain}/fullchain.cer ${PATH_SSL}/${domain}.crt
      ln -f $acme_ssl_dir/${domain}/${domain}.pem ${PATH_SSL}/${domain}.key

  else
      echo "${CFAILURE}Error: Let's Encrypt SSL certificate installation failed! ${CEND}"
      exit 1
  fi
  else
  Create_self_SSL
  fi
}

Print_ssl() {
  if [ "${letsencrypt_yn}" == 'y' ]; then
    echo "$(printf "%-30s" "Let's Encrypt SSL Certificate:")${CMSG}$acme_ssl_dir/${domain}/fullchain.pem${CEND}"
    echo "$(printf "%-30s" "SSL Private Key:")${CMSG}$acme_ssl_dir/${domain}/privkey.pem${CEND}"
  else
    echo "$(printf "%-30s" "Self-signed SSL Certificate:")${CMSG}${DOCKER_PATH_SSL}/${domain}.crt${CEND}"
    echo "$(printf "%-30s" "SSL Private Key:")${CMSG}${DOCKER_PATH_SSL}/${domain}.key${CEND}"
    echo "$(printf "%-30s" "SSL CSR File:")${CMSG}${DOCKER_PATH_SSL}/${domain}.csr${CEND}"
  fi
}


Input_Add_domain() {
  while :; do echo
    read -p "Do you want to setup SSL under Nginx? [y/n]: " nginx_ssl_yn
    if [[ ! ${nginx_ssl_yn} =~ ^[y,n]$ ]]; then
      echo "${CWARNING}input error! Please only input 'y' or 'n'${CEND}"
    else
      break
    fi
  done

  [ "${nginx_ssl_yn}" == 'y' ] && { [ ! -d "${PATH_SSL}" ] && mkdir ${PATH_SSL}; }

  while :; do echo
    read -p "Please input domain(example: www.example.com): " domain
    if [ -z "$(echo ${domain} | grep '.*\..*')" ]; then
      echo "${CWARNING}input error! ${CEND}"
    else
      break
    fi
  done

  while :; do echo
    echo "Please input the directory for the domain:${domain} :"
    read -p "(Default directory: ${wwwroot_dir}/${domain}): " vhostdir
    if [ -n "${vhostdir}" -a -z "$(echo ${vhostdir} | grep '^/')" ]; then
      echo "${CWARNING}input error! Press Enter to continue...${CEND}"
    else
      if [ -z "${vhostdir}" ]; then
        vhostdir="${wwwroot_dir}/${domain}"
        docker_vhostdir="${CWD}/${vhostdir}"
        echo "Virtual Host Directory=${CMSG}${vhostdir}${CEND}"
      fi
      echo
      echo "Create Virtul Host directory......"
      mkdir -p ${docker_vhostdir}
      echo "set permissions of Virtual Host directory......"
      # chown -R ${run_user}.${run_user} ${vhostdir}
      break
    fi
  done

  if [ -e "${nginx_conf_dir}/${domain}.conf" ]; then
    [ -e "${nginx_conf_dir}/${domain}.conf" ] && echo -e "${domain} in the Nginx/Tengine/OpenResty already exist! \nYou can delete ${CMSG}${nginx_conf_dir}/${domain}.conf${CEND} and re-create"
    exit
  else
    echo "domain=${domain}"
  fi

  while :; do echo
    read -p "Do you want to add more domain name? [y/n]: " moredomainame_yn
    if [[ ! ${moredomainame_yn} =~ ^[y,n]$ ]]; then
      echo "${CWARNING}input error! Please only input 'y' or 'n'${CEND}"
    else
      break
    fi
  done

  if [ "${moredomainame_yn}" == 'y' ]; then
    while :; do echo
      read -p "Type domainname or IP(example: example.com other.example.com): " moredomain
      if [ -z "$(echo ${moredomain} | grep '.*\..*')" ]; then
        echo "${CWARNING}input error! ${CEND}"
      else
        [ "${moredomain}" == "${domain}" ] && echo "${CWARNING}Domain name already exists! ${CND}" && continue
        echo domain list="$moredomain"
        moredomainame=" $moredomain"
        break
      fi
    done

    while :; do echo
      read -p "Do you want to redirect from ${moredomain} to ${domain}? [y/n]: " redirect_yn
      if [[ ! ${redirect_yn} =~ ^[y,n]$ ]]; then
        echo "${CWARNING}input error! Please only input 'y' or 'n'${CEND}"
      else
        break
      fi
    done
    [ "${redirect_yn}" == 'y' ] && Nginx_redirect="if (\$host != $domain) {  return 301 \$scheme://${domain}\$request_uri;  }"
  fi

  if [ "${nginx_ssl_yn}" == 'y' ]; then
    while :; do echo
      read -p "Do you want to redirect all HTTP requests to HTTPS? [y/n]: " https_yn
      if [[ ! ${https_yn} =~ ^[y,n]$ ]]; then
        echo "${CWARNING}input error! Please only input 'y' or 'n'${CEND}"
      else
        break
      fi
    done

    LISTENOPT="443 ssl http2"
    Create_SSL
    Nginx_conf=$(echo -e "listen 80;\n  listen ${LISTENOPT};\n  ssl_certificate ${DOCKER_PATH_SSL}/${domain}.crt;\n  ssl_certificate_key ${DOCKER_PATH_SSL}/${domain}.key;\n  ssl_protocols TLSv1 TLSv1.1 TLSv1.2;\n  ssl_ciphers EECDH+CHACHA20:EECDH+AES128:RSA+AES128:EECDH+AES256:RSA+AES256:EECDH+3DES:RSA+3DES:!MD5;\n  ssl_prefer_server_ciphers on;\n  ssl_session_timeout 10m;\n  ssl_session_cache builtin:1000 shared:SSL:10m;\n  ssl_buffer_size 1400;\n  add_header Strict-Transport-Security max-age=15768000;\n  ssl_stapling on;\n  ssl_stapling_verify on;\n")
  else
    Nginx_conf="listen 80;"
  fi
}

Nginx_anti_hotlinking() {
  while :; do echo
    read -p "Do you want to add hotlink protection? [y/n]: " anti_hotlinking_yn
    if [[ ! $anti_hotlinking_yn =~ ^[y,n]$ ]]; then
      echo "${CWARNING}input error! Please only input 'y' or 'n'${CEND}"
    else
      break
    fi
  done

  if [ -n "$(echo ${domain} | grep '.*\..*\..*')" ]; then
    domain_allow="*.${domain#*.} ${domain}"
  else
    domain_allow="*.${domain} ${domain}"
  fi

  if [ "${anti_hotlinking_yn}" == 'y' ]; then
    if [ "${moredomainame_yn}" == 'y' ]; then
      domain_allow_all=${domain_allow}${moredomainame}
    else
      domain_allow_all=${domain_allow}
    fi
    anti_hotlinking=$(echo -e "location ~ .*\.(wma|wmv|asf|mp3|mmf|zip|rar|jpg|gif|png|swf|flv|mp4)$ {\n    valid_referers none blocked ${domain_allow_all};\n    if (\$invalid_referer) {\n        rewrite ^/ http://www.linuxeye.com/403.html;\n        return 403;\n    }\n  }")
  else
    anti_hotlinking=
  fi
}

Nginx_log() {
  while :; do echo
    read -p "Allow Nginx/Tengine/OpenResty access_log? [y/n]: " access_yn
    if [[ ! "${access_yn}" =~ ^[y,n]$ ]]; then
      echo "${CWARNING}input error! Please only input 'y' or 'n'${CEND}"
    else
      break
    fi
  done
  if [ "${access_yn}" == 'n' ]; then
    N_log="access_log off;"
  else
    N_log="access_log ${wwwlogs_dir}/${domain}_nginx.log combined;"
    echo "You access log file=${CMSG}${wwwlogs_dir}/${domain}_nginx.log${CEND}"
  fi
}

Create_nginx_php-fpm_hhvm_conf() {
  [ ! -d ${nginx_conf_dir} ] && mkdir ${nginx_conf_dir}
  cat > ${nginx_conf_dir}/${domain}.conf << EOF
server {
  ${Nginx_conf}
  server_name ${domain}${moredomainame};
  ${N_log}
  index index.html index.htm index.php;
  root ${vhostdir};
  ${Nginx_redirect}
  include ${web_install_dir}/conf/rewrite/${rewrite}.conf;
  #error_page 404 /404.html;
  #error_page 502 /502.html;
  ${anti_hotlinking}
  ${NGX_CONF}

  location ~ .*\.(gif|jpg|jpeg|png|bmp|swf|flv|mp4|ico)$ {
    expires 30d;
    access_log off;
  }
  location ~ .*\.(js|css)?$ {
    expires 7d;
    access_log off;
  }
  location ~ /\.ht {
    deny all;
  }
}
EOF

  [ "${https_yn}" == 'y' ] && sed -i "s@^  root.*;@&\n  if (\$ssl_protocol = \"\") { return 301 https://\$host\$request_uri; }@" ${nginx_conf_dir}/${domain}.conf
  echo
  printf "
#######################################################################
#                        vhost generate script                        #
#######################################################################
"
  echo "$(printf "%-30s" "Your domain:")${CMSG}${domain}${CEND}"
  echo "$(printf "%-30s" "Virtualhost conf:")${CMSG}${nginx_conf_dir}/${domain}.conf${CEND}"
  echo "$(printf "%-30s" "Directory of:")${CMSG}${vhostdir}${CEND}"
  [ "${nginx_ssl_yn}" == 'y' ] && Print_ssl
}

Add_Vhost() {
    Input_Add_domain
    Nginx_anti_hotlinking
    Nginx_log
    Create_nginx_php-fpm_hhvm_conf
}

Del_NGX_Vhost() {
  [ -d "${nginx_conf_dir}" ] && Domain_List=$(ls ${nginx_conf_dir} | sed "s@.conf@@g")
  if [ -n "${Domain_List}" ]; then
    echo
    echo "Virtualhost list:"
    echo ${CMSG}${Domain_List}${CEND}
    while :; do echo
      read -p "Please input a domain you want to delete: " domain
      if [ -z "$(echo ${domain} | grep '.*\..*')" ]; then
        echo "${CWARNING}input error! ${CEND}"
      else
        if [ -e "${nginx_conf_dir}/${domain}.conf" ]; then
          Directory=$(grep '^  root' ${nginx_conf_dir}/${domain}.conf | head -1 | awk -F'[ ;]' '{print $(NF-1)}')
          rm -rf ${nginx_conf_dir}/${domain}.conf

          while :; do echo
            read -p "Do you want to delete Virtul Host directory? [y/n]: " Del_Vhost_wwwroot_yn
            if [[ ! ${Del_Vhost_wwwroot_yn} =~ ^[y,n]$ ]]; then
              echo "${CWARNING}input error! Please only input 'y' or 'n'${CEND}"
            else
              break
            fi
          done
          if [ "${Del_Vhost_wwwroot_yn}" == 'y' ]; then
            echo "Press Ctrl+c to cancel or Press any key to continue..."
            char=$(get_char)
            rm -rf ${Directory}
          fi
          echo
          echo "${CMSG}Domain: ${domain} has been deleted.${CEND}"
          echo
        else
            echo "${CWARNING}Virtualhost: ${domain} was not exist! ${CEND}"
        fi
        break
      fi
    done
  else
    echo "${CWARNING}Virtualhost was not exist! ${CEND}"
  fi
}

CWD=$(pwd)
acme_ssl_dir=/benson/.acme.sh
nginx_conf_dir=${CWD}/conf.d
DOCKER_PATH_SSL=/etc/nginx/ssl
PATH_SSL=$(pwd)/ssl
wwwroot_dir=/wwwroot

if [ $# == 0 ]; then
  Add_Vhost
elif [ $# == 1 ]; then
  case $1 in
  add)
    Add_Vhost
    ;;
  del)
    Del_NGX_Vhost
    ;;
  *)
    Usage
    ;;
  esac
else
  Usage
fi
