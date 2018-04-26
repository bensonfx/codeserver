#!/bin/sh
new_favicon="/etc/gitlab/favicon.ico"
favicon_dir="/opt/gitlab/embedded/service/gitlab-rails/app/assets/images/"
favicon_pub_dir="/opt/gitlab/embedded/service/gitlab-rails/public"
favicon_cache_dir="/opt/gitlab/embedded/service/gitlab-rails/public/assets/"

[ -f ${new_favicon} ] || exit 0

get_icons() {
    test -n "$1" || return
    find $@ -maxdepth 1 -name favicon*.ico
}

# cp "/etc/gitlab/favicon.ico" "$favicon_file"
# gzip -kf "$favicon_file"
for ico in $(get_icons $favicon_cache_dir);do
    cp -fv ${new_favicon} $ico
    gzip -kf $ico
done

for ico in $(get_icons $favicon_dir $favicon_pub_dir);do
    cp -fv ${new_favicon} $ico
done
