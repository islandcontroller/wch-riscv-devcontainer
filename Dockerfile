#-------------------------------------------------------------------------------
# WCH-IC RISC-V Toolchain Devcontainer
# Copyright © 2023 islandcontroller and contributors
#-------------------------------------------------------------------------------

# Base image: Ubuntu Dev Container
FROM mcr.microsoft.com/devcontainers/base:ubuntu

# Root user for setup
USER root

# Dependencies setup
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    cmake \
    cu \
    make \
    software-properties-common \
    tar \
    udev \
    usbutils \
    wget

# Setup dir for packages installation
WORKDIR /tmp

#- CMake Configurations Storage ------------------------------------------------
ENV CMAKE_CONFIGS_PATH=/usr/share/cmake/configs.d
RUN mkdir -p ${CMAKE_CONFIGS_PATH}

#- .NET 6 Runtime --------------------------------------------------------------
ARG DOTNET_URL="https://download.visualstudio.microsoft.com/download/pr/f812da49-53de-4f59-93d2-742a61229149/35ff2eb90bf2583d21ad25146c291fe4/dotnet-runtime-6.0.22-linux-x64.tar.gz"
ARG DOTNET_SHA512="c24ed83cd8299963203b3c964169666ed55acaa55e547672714e1f67e6459d8d6998802906a194fc59abcfd1504556267a839c116858ad34c56a2a105dc18d3d"

# Downlaod and install package
RUN wget -nv ${DOTNET_URL} && \
    echo "${DOTNET_SHA512} $(basename ${DOTNET_URL})" > $(basename "${DOTNET_URL}.asc") && \
    sha512sum -c $(basename "${DOTNET_URL}.asc")
RUN mkdir -p /opt/dotnet && \
    tar -xf $(basename "${DOTNET_URL}") -C /opt/dotnet --strip-components=1 && \
    rm $(basename "${DOTNET_URL}") $(basename "${DOTNET_URL}.asc")
ENV PATH=$PATH:/opt/dotnet

#- Mounriver Toolchain & Debugger ----------------------------------------------
# Package download URL
ARG MOUNRIVER_URL="http://file.mounriver.com/tools/MRS_Toolchain_Linux_x64_V1.80.tar.xz"

# Download and install package
RUN wget -nv ${MOUNRIVER_URL}
RUN mkdir -p /tmp/MRS && \
    tar -xf $(basename "${MOUNRIVER_URL}") -C /tmp/MRS --strip-components=1 && \
    rm $(basename "${MOUNRIVER_URL}")
RUN mv MRS/beforeinstall/lib* /usr/lib/ && \
    ldconfig
RUN mv 'MRS/RISC-V Embedded GCC' /opt/gcc-riscv-none-embed && \
    mv MRS/OpenOCD /opt/openocd
COPY gcc-riscv-none-embed.cmake ${CMAKE_CONFIGS_PATH}
COPY svd/*.svd /opt/wch/
ENV PATH=$PATH:/opt/gcc-riscv-none-embed/bin:/opt/openocd/bin

# Add plugdev group for non-root debugger access
RUN sudo usermod -aG plugdev vscode

#- User setup ------------------------------------------------------------------
USER vscode

VOLUME [ "/src" ]
WORKDIR /src