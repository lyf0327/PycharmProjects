FROM
RUN echo 'Acquire::http::Proxy "http://user:password@109.105.1.254:3128/";' > /etc/apt/apt.conf&&apt-get update||exit 0
RUN apt-get -y install vim ssh wget
RUN sed -i '/^AcceptEnv/s/.*/AcceptEnv */g' /etc/ssh/sshd_config&&echo 'AddressFamily inet' >>/etc/ssh/sshd_config
RUN echo  '#!/usr/bin/env bash\ntest -d /root/.ssh_config && test -f /root/.ssh_config/authorized_keys && cp /root/.ssh_config/authorized_keys /root/.ssh/authorized_keys\n/usr/sbin/sshd -D' >/run.sh&&chmod +x /run.sh
RUN echo  '#!/bin/bash\n#Description: write your job script here to run a job.\n#for example:\n#       source ~/.bashrc\n#       /usr/bin/python -u /data/hello-world.py 2>&1|tee /data/hello-world.txt' >/job.sh&&chmod +x /job.sh
RUN sed -i '/\"\$PS1\"/s/^/#/' /root/.bashrc
RUN mkdir -p /root/.ssh&&mkdir -p /var/run/sshd&&mkdir -p /run/sshd
CMD /run.sh
