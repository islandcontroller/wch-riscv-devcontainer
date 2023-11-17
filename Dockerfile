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
ARG CMAKE_URL="https://github.com/Kitware/CMake/releases/download/v3.27.7/cmake-3.27.7-linux-x86_64.tar.gz"
ARG CMAKE_HASH="https://github.com/Kitware/CMake/releases/download/v3.27.7/cmake-3.27.7-SHA-256.txt"

# Download and install package
RUN curl -sLO ${CMAKE_URL} && \
    curl -sL ${CMAKE_HASH} | grep $(basename "${CMAKE_URL}") | sha256sum -c - && \
    tar -xf $(basename "${CMAKE_URL}") -C /usr --strip-components=1 && \
    rm $(basename "${CMAKE_URL}")

# Prepare configuration storage
ENV CMAKE_CONFIGS_PATH=/usr/share/cmake/configs.d
RUN mkdir -p ${CMAKE_CONFIGS_PATH}

#- .NET 6 Runtime --------------------------------------------------------------
ARG DOTNET_URL="https://download.visualstudio.microsoft.com/download/pr/0e8de3f9-7fda-46b7-9337-a3709c8e385d/bc29c53eb79fda25abb0fb9be60c6a22/dotnet-runtime-6.0.25-linux-x64.tar.gz"
ARG DOTNET_SHA512="9d4cd137353b6340162ca2c381342957e22d6cb419af9198a09f2354ba647ce0ddd007c58e464a47b48ac778ffc2b77569d8ca7921d0819aa92a5ac69d99de27"
ARG DOTNET_INSTALL_DIR="/opt/dotnet"

# Download and install package
RUN curl -sLO ${DOTNET_URL} && \
    echo "${DOTNET_SHA512} $(basename ${DOTNET_URL})" | sha512sum -c - && \
    mkdir -p ${DOTNET_INSTALL_DIR} && \
    tar -xf $(basename "${DOTNET_URL}") -C ${DOTNET_INSTALL_DIR} --strip-components=1 && \
    rm $(basename "${DOTNET_URL}")
ENV PATH=$PATH:${DOTNET_INSTALL_DIR}

#- Mounriver Toolchain & Debugger ----------------------------------------------
# Package download URL
ARG MOUNRIVER_URL="http://file.mounriver.com/tools/MRS_Toolchain_Linux_x64_V1.80.tar.xz"
ARG MOUNRIVER_OPENOCD_INSTALL_DIR="/opt/openocd"
ARG MOUNRIVER_TOOLCHAIN_INSTALL_DIR="/opt/gcc-riscv-none-embed"
ARG MOUNRIVER_RULES_INSTALL_DIR="/opt/wch/rules"

# Download and install package
RUN curl -sLO ${MOUNRIVER_URL} && \
    MOUNRIVER_TMP=$(mktemp -d) && \
    tar -xf $(basename "${MOUNRIVER_URL}") -C $MOUNRIVER_TMP --strip-components=1 && \
    rm $(basename "${MOUNRIVER_URL}") && \
    mv $MOUNRIVER_TMP/beforeinstall/lib* /usr/lib/ && ldconfig && \
    mkdir -p ${MOUNRIVER_RULES_INSTALL_DIR} && \
    mv $MOUNRIVER_TMP/beforeinstall/*.rules ${MOUNRIVER_RULES_INSTALL_DIR} && \
    mv "$MOUNRIVER_TMP/RISC-V Embedded GCC" ${MOUNRIVER_TOOLCHAIN_INSTALL_DIR} && \
    rm $MOUNRIVER_TMP/OpenOCD/bin/wch-arm.cfg && \
    mv $MOUNRIVER_TMP/OpenOCD ${MOUNRIVER_OPENOCD_INSTALL_DIR} && \
    rm -rf $MOUNRIVER_TMP
COPY gcc-riscv-none-embed.cmake ${CMAKE_CONFIGS_PATH}
ENV PATH=$PATH:${MOUNRIVER_TOOLCHAIN_INSTALL_DIR}/bin:${MOUNRIVER_OPENOCD_INSTALL_DIR}/bin

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
ARG UPDATE_URL="http://file.mounriver.com/upgrade/MounRiver_Update_V184.zip"
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

# Add plugdev group for non-root debugger access
RUN usermod -aG plugdev vscode

#- User setup ------------------------------------------------------------------
USER vscode

VOLUME [ "/workspaces" ]
WORKDIR /workspaces