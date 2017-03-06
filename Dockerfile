#################################################################
# ZNN image
# base requirements to install and run the ZNN network
#
# Building this image requires the git repo to be stored locally
# clone via:
#     git clone https://github.com/3Scan/znn-release.git
# build via:
#     docker build -t znn .
#################################################################

FROM ubuntu:16.04

WORKDIR /root

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        software-properties-common \
        curl \
        nano \
        vim \
        wget \
        less \
        bzip2 \
        build-essential \
        g++-4.8 \
        git \
        libfftw3-dev \
        cmake \
    && apt-get clean \
    && apt-get autoremove \
    && rm -rf /tmp/* /var/lib/apt/lists/* /var/tmp*
RUN apt-get install -y libfftw3-dev cmake

# install g++
RUN apt-get install -qq g++-4.8 &&\
    update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-4.8 50

# install boost
RUN add-apt-repository -y ppa:ubuntu-toolchain-r/test &&\
    apt-get -qq update
RUN wget http://sourceforge.net/projects/boost/files/boost/1.55.0/boost_1_55_0.tar.bz2 &&\
    tar --bzip2 -xf boost_1_55_0.tar.bz2
RUN cd boost_1_55_0 &&\
    ./bootstrap.sh --help &&\
    ./bootstrap.sh --with-libraries="atomic" &&\
    ./b2 install &&\
    cd ..

# python installs
RUN apt-get install -y \
    python3-dev=3.5.1-3 \
    python3-pip=8.1.1-2ubuntu0.4 \
    python3-tk=3.5.1-1 \
    python-qt4=4.11.4+dfsg-1build4 \
    qt4-dev-tools=4:4.8.7+dfsg-5ubuntu2 \
    python3-setuptools=20.7.0-1 \
    libhdf5-serial-dev \
    python3-h5py \
    libboost-python-dev

# redirect libboost to point to the python3 library, not the 2.7 version
RUN ln -s /usr/lib/x86_64-linux-gnu/libboost_python-py35.so /usr/lib/x86_64-linux-gnu/libboost_python3.so
RUN ln -s /usr/lib/x86_64-linux-gnu/libboost_python-py35.a /usr/lib/x86_64-linux-gnu/libboost_python3.a

# # install pip for other python packages
RUN pip3 install --upgrade pip
RUN pip3 install numpy==1.12.0 ipython==5.1.0 scipy==0.18.1 matplotlib==1.5.3

# get the ZNN repo
COPY . /root/znn-release

# install Boost.Numpy for python interface
ENV LD_LIBRARY_PATH $LD_LIBRARY:/usr/local/lib
ENV BOOST_DIR /root/boost_1_55_0
WORKDIR /root/
RUN git clone https://github.com/ndarray/Boost.NumPy.git
RUN mkdir -p Boost.NumPy/build
WORKDIR /root/Boost.NumPy/build
# RUN cmake -DBoost_NO_BOOST_CMAKE=ON -DPYTHON_EXECUTABLE=/usr/bin/python3.5 -DPYTHON_LIBRARY=/usr/lib/x86_64-linux-gnu/libpython3.5m.so ..
RUN cmake -DPYTHON_EXECUTABLE=/usr/bin/python3.5 -DPYTHON_LIBRARY=/usr/lib/x86_64-linux-gnu/libpython3.5m.so -DBOOST_LIBRARYDIR=/usr/lib/x86_64-linux-gnu/libboost_python-py34.so ..
RUN make
RUN make install
WORKDIR /root/znn-release

# make the znn binary
RUN make --jobs=3 --keep-going &&  make clean
# make the python core
RUN cd python/core/; make --jobs=3 --keep-going

# add tests here?

CMD /bin/bash