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
    cu \
    make \
    software-properties-common \
    tar \
    udev \
    usbutils \
    wget

# Setup dir for packages installation
WORKDIR /tmp

#- CMake -----------------------------------------------------------------------
ARG CMAKE_URL="https://github.com/Kitware/CMake/releases/download/v3.27.7/cmake-3.27.7-linux-x86_64.tar.gz"
ARG CMAKE_HASH="https://github.com/Kitware/CMake/releases/download/v3.27.7/cmake-3.27.7-SHA-256.txt"

# Download and install package
RUN wget -nv ${CMAKE_URL} && \
    wget -nv ${CMAKE_HASH} && \
    grep $(basename "${CMAKE_URL}") $(basename "${CMAKE_HASH}") > $(basename "${CMAKE_HASH}.sng") && \
    sha256sum -c $(basename "${CMAKE_HASH}.sng")
RUN tar -xf $(basename "${CMAKE_URL}") -C /usr --strip-components=1 && \
    rm $(basename "${CMAKE_URL}") $(basename "${CMAKE_HASH}") $(basename "${CMAKE_HASH}.sng")

# Prepare configuration storage
ENV CMAKE_CONFIGS_PATH=/usr/share/cmake/configs.d
RUN mkdir -p ${CMAKE_CONFIGS_PATH}

#- .NET 6 Runtime --------------------------------------------------------------
ARG DOTNET_URL="https://download.visualstudio.microsoft.com/download/pr/872b4f32-dd0d-49e5-bca3-2b27314286a7/e72d2be582895b7053912deb45a4677d/dotnet-runtime-6.0.24-linux-x64.tar.gz"
ARG DOTNET_SHA512="3a72ddae17ecc9e5354131f03078f3fbfa1c21d26ada9f254b01cddcb73869cb33bac5fc0aed2200fbb57be939d65829d8f1514cd0889a2f5858d1f1eec136eb"

# Download and install package
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