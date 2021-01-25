FROM nvcr.io/nvidia/jetpack:4.4 AS build

RUN apt-get -y update && \
    apt-get -y upgrade && \
    apt-get -y install git build-essential cmake libuv1-dev libmicrohttpd-dev libssl-dev

RUN cd /tmp && \
    git clone https://github.com/xmrig/xmrig-cuda.git && \
    cd xmrig-cuda && \
    mkdir build && \
    cd build && \
    cmake .. -DCUDA_LIB=/usr/local/cuda/lib64/stubs/libcuda.so -DCUDA_TOOLKIT_ROOT_DIR=/usr/local/cuda && \
    make -j$(nproc)

RUN cd /tmp && \
    git clone https://github.com/xmrig/xmrig.git && \
    cd xmrig && \
    mkdir build && \
    cd scripts &&\
    sed 's#https://#http://172.17.0.1:9000/#g' build.*.sh -i && \
    ./build_deps.sh && \
    cd ../build && \
    export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/lib/aarch64-linux-gnu/tegra/ && \
    cmake .. -DXMRIG_DEPS=scripts/deps && \
    make -j$(nproc)


FROM nvcr.io/nvidia/l4t-base:r32.4.4

LABEL maintainer='docker@merxnet.io'

COPY --from=build /tmp/xmrig/build/xmrig /usr/local/bin/xmrig
COPY --from=build /tmp/xmrig-cuda/build/libxmrig-cuda.so /usr/lib/libxmrig-cuda.so

ENTRYPOINT ["xmrig"]
