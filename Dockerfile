FROM debian/jessie

MAINTAINER John Foster <johntfosterjr@gmail.com>

ENV HOME /root

RUN apt-get update
RUN apt-get -yq install gcc \
                        gfortran \
                        build-essential \
                        libopenmpi-dev \
                        openmpi-bin \
                        libblas-dev \
                        liblapack-dev \
                        libboost-dev \
                        cmake  \
                        git \
                        libyaml-cpp0.5 \
                        libyaml-cpp-dev \
                        openssh-server


#Build Trilinos
RUN git clone https://github.com/trilinos/Trilinos.git trilinos; \
    mkdir trilinos/build

WORKDIR trilinos/build
RUN cmake -DCMAKE_INSTALL_PREFIX:PATH=/usr/local/trilinos/ \
          -DCMAKE_BUILD_TYPE:STRING=Release \
          -DBUILD_SHARED_LIBS:BOOL=OFF \
          -DCMAKE_CXX_FLAGS:STRING="-Wno-unused -std=c++14" \
          -DCMAKE_Fortran_COMPILER:STRING="mpif90" \
          -DTrilinos_ENABLE_ALL_PACKAGES:BOOL=OFF \
          -DTrilinos_ENABLE_ALL_OPTIONAL_PACKAGES:BOOL=OFF \
          -DTrilinos_ENABLE_ALL_FORWARD_DEP_PACKAGES:BOOL=ON \
          -DTrilinos_ENABLE_Teuchos:BOOL=ON \
          -DTrilinos_ENABLE_Tpetra:BOOL=ON \
          -DTrilinos_ENABLE_SEACAS:BOOL=OFF \
          -DTrilinos_ENABLE_SEACASAprepro=ON \
          -DTPL_ENABLE_MPI:BOOL=ON \
          -DMPI_BASE_DIR:PATH=/usr \
          -DTPL_ENABLE_BLAS:BOOL=ON \
          -DTPL_ENABLE_LAPACK:BOOL=ON \
          -DTPL_ENABLE_Boost:BOOL=ON \
          -DTPL_Boost_INCLUDE_DIRS:PATH=/usr/include/boost \
          -DTPL_ENABLE_QT:BOOL=OFF \
          -DTPL_ENABLE_X11:BOOL=OFF \
          -DCMAKE_VERBOSE_MAKEFILE:BOOL=OFF \
          -DTrilinos_VERBOSE_CONFIGURE:BOOL=OFF \
          -DTeuchosCore_ENABLE_yaml-cpp:BOOL=ON \
          -DTPL_ENABLE_yaml-cpp:BOOL=ON \
          -Dyaml-cpp_INCLUDE_DIRS:PATH=/usr/include/yaml-cpp \
          -DTPL_yaml-cpp_LIBRARIES:FILEPATH=/usr/lib/x86_64-linux-gnu/libyaml-cpp.so.0.5 \
          ..

RUN make -j8 && make install

#Build Tadiga
RUN git clone https://github.com/johntfoster/tadiga.git tadiga 
RUN mkdir /tadiga/build

WORKDIR /tadiga/build/
RUN cmake \
    -D CMAKE_BUILD_TYPE:STRING=Release \
    -D CMAKE_INSTALL_PREFIX:PATH=/usr/local/tadiga \
    -D CMAKE_CXX_FLAGS:STRING="-std=c++14" \
    -D TRILINOS_DIR:PATH=/usr/local/trilinos/lib/cmake/Trilinos \
    -D CMAKE_CXX_COMPILER:STRING="mpicxx" \
    ..; \
    make && make install && make test
    cd ..; \
    rm -rf tadiga

VOLUME /output
WORKDIR /output
ENV PATH /usr/local/tadiga/bin:$PATH

RUN mkdir /var/run/sshd
EXPOSE 22
CMD    ["/usr/sbin/sshd", "-D"]
