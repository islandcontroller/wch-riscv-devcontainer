# wch-riscv-devcontainer
[![License](https://img.shields.io/github/license/islandcontroller/wch-riscv-devcontainer)](LICENSE) [![GitHub](https://shields.io/badge/github-islandcontroller%2Fwch--riscv--devcontainer-black?logo=github)](https://github.com/islandcontroller/wch-riscv-devcontainer) [![Docker Hub](https://shields.io/badge/docker-islandc%2Fwch--riscv--devcontainer-blue?logo=docker)](https://hub.docker.com/r/islandc/wch-riscv-devcontainer) ![Docker Image Version (latest semver)](https://img.shields.io/docker/v/islandc/wch-riscv-devcontainer?sort=semver)

*WCH-IC RISC-V development and debugging environment inside a VSCode devcontainer.*

![Screenshot](scr.PNG)

### Packages
* [Microsoft .NET 6.0 Runtime](https://dotnet.microsoft.com/en-us/download/dotnet/6.0) Version 6.0.36
* [MounRiver Studio II (MRS2)](http://www.mounriver.com/download) Version 2.1.0
  * WCH-custom GNU toolchain for RISC-V Version 12.2.0
  * WCH-custom OpenOCD Version 0.11.0
  * ISP Firmware Version `v36`
  * SVD files
* [CH32X035 PIOC Assembler](https://github.com/openwch/ch32x035/tree/main/EVT/EXAM/PIOC/Tool_Manual/Tool) Version 3.1

* [CMake](https://cmake.org/download) Version 3.31.2
* [ch32-rs/wchisp](https://github.com/ch32-rs/wchisp/) Version 0.3.0
* [ch32-rs/wlink](https://github.com/ch32-rs/wlink/) Version 0.1.1

## System Requirements
* VSCode [Dev Containers](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers) extension
* (WSL only) [usbipd-win](https://learn.microsoft.com/en-us/windows/wsl/connect-usb)

## Usage
* Include this repo as `.devcontainer` in the root of your project
* Connect debug probe 
  * (WSL only) attach to WSL using `usbipd attach --wsl --busid <...>`. **This needs to be completed before starting the Dev Container.**
* Select `Dev Containers: Reopen in Container`

For CMake projects:
* Upon prompt, select the `GCC 12.x riscv-none-elf` CMake Kit. 
  * Alternatively, a toolchain definition file is provided in: `$CMAKE_CONFIGS_PATH/gcc-riscv-none-elf.cmake`.
* Run `CMake: Configure`
* Build using `CMake: Build [F7]`

### CMake+IntelliSense Notes
Upon first run, an error message may appear in Line 1, Column 1. Try re-running CMake configuration, or run a build. If the file is a `.h` header file, it needs to be `#include`'d into a C module.

### UDEV Rules installation
In order to use USB debug probes within the container, some udev rules need to be installed on the **host** machine. A setup script has been provided to aid with installation.
* Run `setup-devcontainer` inside the **container**
* Close the container, and re-open the work directory on your **host**
* Run the `install-rules` script inside `.vscode/setup/` on your host machine

      cd .vscode/setup
      sudo ./install-rules

### WCH-Link Firmware Update
**Firmware update files** are provided in `/opt/wch/firmware/` and can be programmed using the `wchisp` utility. See the [`wchisp` GitHub repository](https://github.com/ch32-rs/wchisp/) for more information.


See the [WCH-Link User Manual](https://www.wch-ic.com/downloads/WCH-LinkUserManual_PDF.html) about updating your programmer and to determine which firmware file to use.

    wchisp flash /opt/wch/firmware/<isp-specific firmware file>

### OpenOCD Config File
Configuration files for the OpenOCD debugger are included in `/opt/openocd/bin/`. To start the debugger, run the following command inside the devcontainer terminal:

    openocd -f /opt/openocd/bin/wch-riscv.cfg

### Peripheral Description Files Notes
Peripheral description files (SVD) for RISC-V MCUs are provided in `/opt/wch/`.

### Serial Monitor
To access the WCH-Link serial monitor inside the devcontainer, use the `cu` command as shown below:

    cu -l <serial port device> -s <baudrate>

e.g. "`cu -l /dev/ttyACM0 -s 115200`".

To close the connection, press RETURN/ESC/Ctrl-C, type "`~.`" (tilde, dot) and wait for 3 seconds.

### Flashing a target with pre-built image

To flash a target with a pre-built firmware image, use the included `wlink` utility. See the [`wlink`GitHub repository](https://github.com/ch32-rs/wlink/) for more information.

    wlink flash <hexfile>

### Running PIOC (CH53x) assembler
The CH32X035 *PIOC* uses a custom CPU architecture, hence at the moment only the WCH-provided assembler can be used to build PIOC binaries.
In order to run the assembler, a 32-bit WINE installation inside the container is required (~1 GiB installation).
* Run `setup-devcontainer --install-wine` inside the container.
* Run the compiler with 

      wasm53b <asm file name>

* Convert output binary to C-array

      xxd -i <binary file name> <C source file name>

## Licensing

If not stated otherwise, the contents of this project are licensed under The MIT License. The full license text is provided in the [`LICENSE`](LICENSE) file.

    SPDX-License-Identifier: MIT