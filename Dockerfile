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
    curl \
    make \
    software-properties-common \
    tar \
    udev \
    unzip \
    usbutils \
    && rm -rf /var/lib/apt/lists/*

# Setup dir for packages installation
WORKDIR /tmp

#- CMake -----------------------------------------------------------------------
ARG CMAKE_VERSION=3.29.0
ARG CMAKE_URL="https://github.com/Kitware/CMake/releases/download/v$CMAKE_VERSION/cmake-$CMAKE_VERSION-linux-x86_64.tar.gz"
ARG CMAKE_HASH="https://github.com/Kitware/CMake/releases/download/v$CMAKE_VERSION/cmake-$CMAKE_VERSION-SHA-256.txt"

# Download and install package
RUN curl -sLO ${CMAKE_URL} && \
    curl -sL ${CMAKE_HASH} | grep $(basename "${CMAKE_URL}") | sha256sum -c - && \
    tar -xf $(basename "${CMAKE_URL}") -C /usr --strip-components=1 && \
    rm $(basename "${CMAKE_URL}")

# Prepare configuration storage
ENV CMAKE_CONFIGS_PATH=/usr/share/cmake/configs.d
RUN mkdir -p ${CMAKE_CONFIGS_PATH}

#- .NET 6 Runtime --------------------------------------------------------------
ARG DOTNET_VERSION=6.0.28
ARG DOTNET_URL="https://dotnetcli.azureedge.net/dotnet/Runtime/$DOTNET_VERSION/dotnet-runtime-$DOTNET_VERSION-linux-x64.tar.gz"
ARG DOTNET_SHA512="5e9039c6c83bed02280e6455ee9ec59c9509055ed15d20fb628eca1147c6c3b227579fbffe5d890879b8e62312facf25089b81f4c461797a1a701a220b51d698"
ARG DOTNET_INSTALL_DIR="/opt/dotnet"

# Download and install package
RUN curl -sLO ${DOTNET_URL} && \
    echo "${DOTNET_SHA512} $(basename ${DOTNET_URL})" | sha512sum -c - && \
    mkdir -p ${DOTNET_INSTALL_DIR} && \
    tar -xf $(basename "${DOTNET_URL}") -C ${DOTNET_INSTALL_DIR} --strip-components=1 && \
    rm $(basename "${DOTNET_URL}")
ENV PATH=$PATH:${DOTNET_INSTALL_DIR}

#- Mounriver Toolchain & Debugger ----------------------------------------------
ARG MOUNRIVER_VERSION=1.91
ARG MOUNRIVER_URL="http://file.mounriver.com/tools/MRS_Toolchain_Linux_x64_V$MOUNRIVER_VERSION.tar.xz"
ARG MOUNRIVER_OPENOCD_INSTALL_DIR="/opt/openocd"
ARG MOUNRIVER_TOOLCHAIN_INSTALL_DIR="/opt/gcc-riscv-none-elf"
ARG MOUNRIVER_RULES_INSTALL_DIR="/opt/wch/rules"

# Download and install package
RUN curl -sLO ${MOUNRIVER_URL} && \
    MOUNRIVER_TMP=$(mktemp -d) && \
    tar -xf $(basename "${MOUNRIVER_URL}") -C $MOUNRIVER_TMP --strip-components=1 && \
    rm $(basename "${MOUNRIVER_URL}") && \
    mv $MOUNRIVER_TMP/beforeinstall/lib* /usr/lib/ && ldconfig && \
    mkdir -p ${MOUNRIVER_RULES_INSTALL_DIR} && \
    mv $MOUNRIVER_TMP/beforeinstall/*.rules ${MOUNRIVER_RULES_INSTALL_DIR} && \
    mv $MOUNRIVER_TMP/RISC-V_Embedded_GCC12 ${MOUNRIVER_TOOLCHAIN_INSTALL_DIR} && \
    rm $MOUNRIVER_TMP/OpenOCD/bin/wch-arm.cfg && \
    mv $MOUNRIVER_TMP/OpenOCD ${MOUNRIVER_OPENOCD_INSTALL_DIR} && \
    rm -rf $MOUNRIVER_TMP
COPY gcc-riscv-none-elf.cmake ${CMAKE_CONFIGS_PATH}
ENV PATH=$PATH:${MOUNRIVER_TOOLCHAIN_INSTALL_DIR}/bin:${MOUNRIVER_OPENOCD_INSTALL_DIR}/bin

# Display warning for mis-configured toolchains
ARG MOUNRIVER_LEGACY_TOOLCHAIN_INSTALL_DIR="/opt/gcc-riscv-none-embed"
COPY path-info.sh ${MOUNRIVER_LEGACY_TOOLCHAIN_INSTALL_DIR}/bin/path-info.sh
ENV MOUNRIVER_TOOLCHAIN_INSTALL_DIR=${MOUNRIVER_TOOLCHAIN_INSTALL_DIR}
RUN for i in $(ls ${MOUNRIVER_TOOLCHAIN_INSTALL_DIR}/bin/riscv-none-elf-*); do k=$(echo "$i" | sed s/-elf/-embed/g); ln -s ${MOUNRIVER_LEGACY_TOOLCHAIN_INSTALL_DIR}/bin/path-info.sh $k; done

#- ISP flashing tool -----------------------------------------------------------
ARG ISPTOOL_URL="https://github.com/ch32-rs/wchisp/releases/download/nightly/wchisp-linux-x64.tar.gz"
ARG ISPTOOL_INSTALL_DIR="/opt/wchisp"

# Download and install package; Copy firmware files
RUN curl -sLO ${ISPTOOL_URL} && \
    mkdir -p ${ISPTOOL_INSTALL_DIR} && \
    tar -xf $(basename ${ISPTOOL_URL}) -C ${ISPTOOL_INSTALL_DIR} && \
    rm -rf $(basename ${ISPTOOL_URL})
ENV PATH=$PATH:${ISPTOOL_INSTALL_DIR}

#- Debugger SVD and ISP Firmware files -----------------------------------------
ARG UPDATE_VERSION=191
ARG UPDATE_URL="http://file.mounriver.com/upgrade/MounRiver_Update_V$UPDATE_VERSION.zip"
ARG UPDATE_FIRMWARE_INSTALL_DIR="/opt/wch/firmware"
ARG UPDATE_SVD_INSTALL_DIR="/opt/wch/svd"

# Download update package, extract firmware/SVD files and install
RUN curl -sLO ${UPDATE_URL} && \
    UPDATE_TMP=$(mktemp -d) && \
    unzip $(basename ${UPDATE_URL}) -d $UPDATE_TMP && \
    rm $(basename ${UPDATE_URL}) && \
    mv $UPDATE_TMP/update/Firmware_Link ${UPDATE_FIRMWARE_INSTALL_DIR} && \
    mkdir -p ${UPDATE_SVD_INSTALL_DIR} && \
    for i in $(find $UPDATE_TMP/template/wizard/WCH/RISC-V/ -name *.svd | uniq); do mv $i ${UPDATE_SVD_INSTALL_DIR}; done && \
    rm -rf $UPDATE_TMP && \
    ln -s -t ${UPDATE_SVD_INSTALL_DIR}/../ $(ls ${UPDATE_SVD_INSTALL_DIR}/*.svd)

#- Target flasing tool ---------------------------------------------------------
ARG FLASHTOOL_URL="https://github.com/ch32-rs/wlink/releases/download/nightly/wlink-linux-x64.tar.gz"
ARG FLASHTOOL_INSTALL_DIR="/opt/wlink"

# Download and install package
RUN curl -sLO ${FLASHTOOL_URL} && \
    mkdir -p ${FLASHTOOL_INSTALL_DIR} && \
    tar -xf $(basename ${FLASHTOOL_URL}) -C ${FLASHTOOL_INSTALL_DIR} && \
    rm -rf $(basename ${FLASHTOOL_URL})
ENV PATH=$PATH:${FLASHTOOL_INSTALL_DIR}

#- Devcontainer utilities ------------------------------------------------------
ARG UTILS_INSTALL_DIR="/opt/devcontainer/"

# Add setup files and register in path
COPY setup-devcontainer ${UTILS_INSTALL_DIR}/bin/
COPY install-rules ${UTILS_INSTALL_DIR}
ENV PATH=$PATH:${UTILS_INSTALL_DIR}/bin

#- User setup ------------------------------------------------------------------
# Add plugdev group for non-root debugger access
RUN usermod -aG plugdev vscode

USER vscode

VOLUME [ "/workspaces" ]
WORKDIR /workspaces