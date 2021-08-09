FROM debian:buster
ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8
LABEL maintainer="avery.rozar@trolleyesecurity.com"
COPY configs/sudoers /tmp/sudoers
RUN apt update && apt install sudo -y && \
    mkdir /home/gvm_user/ && \
    useradd -G sudo --home-dir /home/gvm_user gvm_user && \
    chown gvm_user:gvm_user -R /home/gvm_user && \
    sudo useradd -r -M -U -G sudo -s /usr/sbin/nologin gvm && \
    sudo usermod -aG gvm gvm_user && \
    mv /tmp/sudoers /etc/sudoers && \
    echo "export PATH=$PATH:/usr/local/sbin" > /etc/environment
COPY scripts/* /
RUN chmod +x /*.sh
USER gvm_user
RUN bash /install_gvm.sh
RUN bash /initial_setup.sh
CMD sudo /start.sh