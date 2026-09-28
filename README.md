# STM32 Blink Firmware

This repository contains a CMake-based firmware project for the STM32F407VG (Cortex-M4). It builds the `blink` firmware executable and, after linking, converts it to raw binary (`.bin`) and Intel HEX (`.hex`) formats.

The project can be built with the bundled ARM GNU toolchain on a Linux host or in the published Docker development image.

## Project Structure

```text
.
|-- CMakeLists.txt                    # Top-level CMake project
|-- CMakePresets.json                 # Ninja configure/build preset
|-- config/
|   `-- arm-none-eabi.cmake           # ARM cross-compilation and linker settings
|-- docker/
|   `-- Dockerfile                    # Debian build environment and default build
|-- firmware/
|   |-- CMakeLists.txt                # Firmware target and post-link commands
|   |-- app/
|   |   `-- main.c                    # Application entry point
|   |-- bsp/                          # STM32DISC1 board support
|   |-- config/                       # Firmware configuration target
|   |-- drivers/                      # Device driver layer
|   |-- hal/                          # Hardware abstraction layer
|   `-- vendor/
|       `-- platform/
|           |-- cmsis/                # ARM CMSIS headers
|           `-- stm32f4xx/            # STM32F4 startup/device/linker files
|-- tools/
|   `-- arm_gcc/                      # Bundled arm-none-eabi toolchain (Git-ignored)
|-- build/                            # Generated CMake files and firmware outputs (Git-ignored)
|-- docs/                             # Project documentation
|-- sim/                              # Simulation-related files
`-- tests/                            # Test-related files
```

`firmware/CMakeLists.txt` links the `blink` executable with the firmware libraries. Its post-build commands print memory usage and use `arm-none-eabi-objcopy` to generate `blink.bin` and `blink.hex`.

## Build on Linux

Prerequisites are CMake 3.20 or newer, Ninja, and the ARM GNU toolchain. This repository has a bundled toolchain under `tools/arm_gcc/`; add its `bin` directory to `PATH` before configuring:

```bash
export PATH="$PWD/tools/arm_gcc/bin:$PATH"
```

From the repository root, configure and build using the `default` preset:

```bash
cmake --preset default
cmake --build --preset default
```

The preset uses Ninja, configures a Debug build, and places generated files in `build/default/`. To build only the firmware executable (including its post-build steps):

```bash
cmake --build --preset default --target blink
```

To print the compiler, linker, and `objcopy` commands as they execute:

```bash
cmake --build --preset default --verbose
```

### Firmware Artifacts

After a successful link, the expected outputs are:

```text
build/default/firmware/blink       # Linked executable (ELF)
build/default/firmware/blink.bin   # Raw binary image
build/default/firmware/blink.hex   # Intel HEX image
```

The `.bin` and `.hex` files are generated automatically when `blink` links. To explicitly regenerate them from the linked executable, run these from the repository root:

```bash
arm-none-eabi-objcopy -O binary \
  build/default/firmware/blink build/default/firmware/blink.bin

arm-none-eabi-objcopy -O ihex \
  build/default/firmware/blink build/default/firmware/blink.hex
```

These commands require `tools/arm_gcc/bin` to be on `PATH`. The generated files are firmware images; flashing them to hardware requires a separate programmer/debugger tool such as STM32CubeProgrammer or OpenOCD.

### Clean the Build

Remove compiled target outputs while keeping the CMake configuration:

```bash
cmake --build --preset default --target clean
```

Remove the complete generated build directory and configure from scratch:

```bash
rm -rf build
cmake --preset default
cmake --build --preset default
```

## Build with Docker

Build the image from the repository root:

```bash
docker build --progress=plain -f docker/Dockerfile -t blinker:v1 .
```

The image contains Debian, CMake, Ninja, and the ARM toolchain at `/opt/arm_gcc`. The default container command builds the project copy included in the image:

```bash
docker run --rm blinker:v1
```

For active development, first clone the source repository and enter its root directory. Pull the published image, then start a shell with the local source mounted into the container:

```bash
docker pull YOUR_DOCKERHUB_USERNAME/blinker:v1

docker run --rm -it \
  -v "$PWD:/blink" \
  -w /blink \
  --entrypoint /bin/bash \
  YOUR_DOCKERHUB_USERNAME/blinker:v1
```

Inside the container, configure and build as usual:

```bash
cmake --preset default
cmake --build --preset default --verbose
```

Because the host project is mounted at `/blink`, source edits and build outputs are shared with the host. The ARM toolchain is installed separately at `/opt/arm_gcc`, outside the mounted directory, so the mount does not hide it. The `--rm` option removes the container when it exits; it does not remove files in the mounted project directory.

To run the image's default build command against the mounted source without opening a shell:

```bash
docker run --rm \
  -v "$PWD:/blink" \
  -w /blink \
  YOUR_DOCKERHUB_USERNAME/blinker:v1
```

Replace `YOUR_DOCKERHUB_USERNAME` with the Docker Hub account that owns the image.

## Publish the Image to Docker Hub

Create a Docker Hub repository named `blinker`, then log in and tag the local image with the account namespace:

```bash
docker login
docker tag blinker:v1 YOUR_DOCKERHUB_USERNAME/blinker:v1
docker push YOUR_DOCKERHUB_USERNAME/blinker:v1
```

Other developers can then retrieve it with:

```bash
docker pull YOUR_DOCKERHUB_USERNAME/blinker:v1
```

The namespace is the Docker Hub username or organization; `blinker` is the repository name; `v1` is the tag. Publish new versions under a new tag (for example, `v2`) when changing the toolchain or image setup.

## Toolchain Note

`tools/` is listed in `.gitignore`, so the bundled ARM toolchain is not included in a normal Git commit. The Dockerfile currently copies `tools/arm_gcc/` when building the image, so the toolchain directory must be present in the Docker build context to rebuild the image. Developers who only clone the source repository can use the already-published Docker image; they do not need the compiler in their checkout because the image provides it at `/opt/arm_gcc`.

## Target Configuration

The toolchain file configures cross-compilation for ARM Cortex-M4, selects the STM32F407VGTX linker script, and enables linker memory-usage output. The current CMake options use a Debug build with `-O0 -g`.