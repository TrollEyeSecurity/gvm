FROM centos:latest
LABEL maintainer="avery.rozar@trolleyesecurity.com"
COPY install-pkgs.sh /install-pkgs.sh
RUN bash /install-pkgs.sh && mkdir /var/run/sshd && sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd
COPY scripts/* /
RUN bash /initial_setup.sh
CMD '/start.sh'