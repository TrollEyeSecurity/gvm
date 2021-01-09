FROM ubuntu:20.04
LABEL maintainer="avery.rozar@trolleyesecurity.com"
ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8

COPY install-pkgs.sh /install-pkgs.sh
COPY vulners/ vulners/

RUN bash /install-pkgs.sh && mkdir /var/run/sshd && sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd

ENV gvm_libs_version="v20.8.0" \
    openvas_scanner_version="v20.8.0" \
    open_scanner_protocol_daemon="v20.8.1" \
    ospd_openvas="v20.8.0" \
    gvmd_version="v20.8.0" \
    python_gvm_version="v21.1.1" \
    gvm_tools_version="20.10.1" \
    openvas_smb="v1.0.5"

RUN echo "Starting Build..." && mkdir /build

    #
    # install libraries module for the Greenbone Vulnerability Management Solution
    #

RUN cd /build && \
    wget --no-verbose https://github.com/greenbone/gvm-libs/archive/$gvm_libs_version.tar.gz && \
    tar -zxf $gvm_libs_version.tar.gz && \
    cd /build/*/ && \
    mkdir build && \
    cd build && \
    cmake -DCMAKE_BUILD_TYPE=Release .. && \
    make && \
    make install && \
    cd /build && \
    rm -rf *

    #
    # Install Open Vulnerability Assessment System (OpenVAS) Scanner of the Greenbone Vulnerability Management (GVM) Solution
    #

RUN cd /build && \
    wget --no-verbose https://github.com/greenbone/openvas-scanner/archive/$openvas_scanner_version.tar.gz && \
    tar -zxf $openvas_scanner_version.tar.gz && \
    cd /build/*/ && \
    mkdir build && \
    cd build && \
    cmake -DCMAKE_BUILD_TYPE=Release .. && \
    make && \
    make install && \
    cd /build && \
    rm -rf *

    #
    # Install Open Scanner Protocol daemon (OSPd)
    #

RUN cd /build && \
    wget --no-verbose https://github.com/greenbone/ospd/archive/$open_scanner_protocol_daemon.tar.gz && \
    tar -zxf $open_scanner_protocol_daemon.tar.gz && \
    cd /build/*/ && \
    python3 setup.py install && \
    cd /build && \
    rm -rf *

    #
    # Install Open Scanner Protocol for OpenVAS
    #

RUN cd /build && \
    wget --no-verbose https://github.com/greenbone/ospd-openvas/archive/$ospd_openvas.tar.gz && \
    tar -zxf $ospd_openvas.tar.gz && \
    cd /build/*/ && \
    python3 setup.py install && \
    cd /build && \
    rm -rf *

    #
    # Install Greenbone Vulnerability Manager (GVMD)
    #

RUN cd /build && \
    wget --no-verbose https://github.com/greenbone/gvmd/archive/$gvmd_version.tar.gz && \
    tar -zxf $gvmd_version.tar.gz && \
    cd /build/*/ && \
    mkdir build && \
    cd build && \
    cmake -DOPENVAS_DEFAULT_SOCKET=/tmp/ospd.sock -DCMAKE_BUILD_TYPE=Release .. && \
    make && \
    make install && \
    cd /build && \
    rm -rf *

    #
    # Install Greenbone Vulnerability Management Python Library
    #

RUN cd /build && \
    wget --no-verbose https://github.com/greenbone/python-gvm/archive/$python_gvm_version.tar.gz # && \
    tar -zxf $python_gvm_version.tar.gz  && \
    cd python-gvm-${python_gvm_version:1} && \
    pip3 install . && \
    cd /build  && \
    rm -rf *

    #
    # Install GVM-Tools
    #

RUN pip3 install gvm-tools==$gvm_tools_version && \
    echo "/usr/local/lib" > /etc/ld.so.conf.d/openvas.conf && ldconfig

    #
    # install smb module for the OpenVAS Scanner
    #

RUN cd /build && \
    wget --no-verbose https://github.com/greenbone/openvas-smb/archive/$openvas_smb.tar.gz && \
    tar -zxf $openvas_smb.tar.gz && \
    cd /build/*/ && \
    mkdir build && \
    cd build && \
    cmake -DCMAKE_BUILD_TYPE=Release .. && \
    make && \
    make install && \
    cd /build && \
    rm -rf * && \
    cd / && \
    rm -rf /build

COPY scripts/* /
RUN bash /initial_setup.sh
CMD '/start.sh'