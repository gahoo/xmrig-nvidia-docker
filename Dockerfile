FROM nvcr.io/nvidia/jetpack:4.4 AS build

ENV VERSION 'v2.14.5'
ENV CMAKE_OPTS='-DCMAKE_C_COMPILER=gcc-7 -DCMAKE_CXX_COMPILER=g++-7 -DWITH_AEON=OFF -DWITH_HTTPD=OFF'

RUN sed 's#ports.ubuntu.com#mirrors.aliyun.com#g' /etc/apt/sources.list -i && \
    sed 's#https://#http://10.147.20.16:9000/#g' /etc/apt/sources.list.d/* -i && \
    echo 'Acquire::HTTP::Proxy "http://172.17.0.1:3142";' >> /etc/apt/apt.conf.d/01proxy && \
    echo 'Acquire::HTTPS::Proxy "false";' >> /etc/apt/apt.conf.d/01proxy
RUN apt-get -y update && apt-get -y upgrade
RUN apt-get -y install git build-essential cmake libuv1-dev libmicrohttpd-dev libssl-dev

RUN git clone https://github.com/xmrig/xmrig-nvidia.git
RUN cd xmrig-nvidia && git checkout ${VERSION} && mkdir build

WORKDIR xmrig-nvidia/build
RUN export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/lib/aarch64-linux-gnu/tegra/ && \
    cmake .. -DCUDA_TOOLKIT_ROOT_DIR=/usr/local/cuda ${CMAKE_OPTS} && make


FROM nvcr.io/nvidia/l4t-base:r32.4.4

LABEL maintainer='docker@merxnet.io'

COPY --from=build /tmp/xmrig-nvidia/build/xmrig-nvidia /usr/local/bin/xmrig-nvidia

ENTRYPOINT ["xmrig-nvidia"]
