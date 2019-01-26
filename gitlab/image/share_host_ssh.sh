#!/bin/bash

if [ $# -lt 1 ];then
    printf "./`base $0` gitlab_.ssh_path
            e.g: ./`base $0` /home/docker-env/gitlab/data/.ssh
"
    exit 1
fi

SSH_CONFIG_PATH=$(realpath $1)
if [ -z "${SSH_CONFIG_PATH}" ];then
    echo "ssh config path is not exist"
    exit 1
fi

groupadd -g 998 git
useradd -m -u 998 -g git -s /bin/sh -d /home/git git

su - git
ln -s $SSH_CONFIG_PATH /home/git/.ssh

ssh-keygen
cd .ssh && mv id_rsa.pub authorized_keys_proxy


GITLAB_SHELL_PATH=/opt/gitlab/embedded/service/gitlab-shell/bin
[ -d ${GITLAB_SHELL_PATH} ] || install -d ${GITLAB_SHELL_PATH}
cat > /opt/gitlab/embedded/service/gitlab-shell/bin/gitlab-shell << EOF
#!/bin/sh
ssh -i /home/git/.ssh/id_rsa -p 2222 -o StrictHostKeyChecking=no git@localhost "SSH_ORIGINAL_COMMAND=\"$SSH_ORIGINAL_COMMAND\" $0 $@"
EOF



