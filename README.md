# STM32F4 bare-metal blink firmware

This repository builds a small bare-metal firmware image for an STM32F407VGTX target, using CMake and the GNU ARM toolchain. The current application is intentionally minimal: it configures the clock tree, enables the GPIO clock, sets the green LED on GPIOD pin 12 as an output, and toggles it forever.

The board in use is an STM32F407VG-based Discovery-style board. The ST-LINK/V2.1 programmer appears as:

```text
Bus 001 Device 004: ID 0483:3752 STMicroelectronics ST-LINK/V2.1
```

## Project layout

```text
.
├── CMakeLists.txt                    # Top-level CMake project
├── CMakePresets.json                 # Debug/release configure and build presets
├── config/
│   ├── arm-none-eabi.cmake           # ARM cross-compilation toolchain
│   ├── stm32f407_target.cmake        # MCU compile/link options
│   └── stm32f4_post_build.cmake      # Size report and BIN/HEX generation
├── docker/
│   └── Dockerfile                    # Containerized build environment
├── firmware/
│   ├── CMakeLists.txt                # Firmware executable and library targets
│   ├── app/
│   │   ├── CMakeLists.txt
│   │   └── main.c                    # Clock setup and LED blink loop
│   ├── bsp/
│   │   ├── CMakeLists.txt
│   │   ├── stm32disc1.c
│   │   └── stm32disc1.h              # STM32DISC1 board support
│   ├── config/
│   │   └── CMakeLists.txt
│   ├── drivers/
│   │   └── CMakeLists.txt
│   ├── hal/
│   │   └── CMakeLists.txt
│   └── vendor/
│       ├── CMakeLists.txt
│       └── platform/
│           ├── cmsis/                # CMSIS core headers
│           ├── platform.h            # Platform include
│           └── stm32f4xx/
│               ├── STM32F407VGTX.ld  # Linker script
│               ├── inc/              # STM32F4 device headers
│               ├── src/              # System and runtime support
│               └── startup_stm32f407vgtx.s
├── docs/                             # Documentation
├── sim/                              # Simulation files
├── tests/                            # Test files
├── tools/
│   └── arm_gcc/                      # Local ARM GNU toolchain (ignored by Git)
│       ├── bin/                      # Compiler and utility executables
│       └── arm-none-eabi/            # Target headers and libraries
├── .gitignore
├── README.md
└── todo
```

The CMake build directory (for example, `build/debug/`) is generated when configuring a preset and is not part of the source tree.

## CMake structure

The top-level `CMakeLists.txt` is deliberately small:

```cmake
cmake_minimum_required(VERSION 3.20)
project(blink LANGUAGES C ASM)

set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

include(${CMAKE_SOURCE_DIR}/config/stm32f407_target.cmake)
include(${CMAKE_SOURCE_DIR}/config/stm32f4_post_build.cmake)

add_subdirectory(firmware)
```

`config/arm-none-eabi.cmake` configures the cross-toolchain by locating:

- `arm-none-eabi-gcc`
- `arm-none-eabi-g++`
- `arm-none-eabi-objcopy`
- `arm-none-eabi-objdump`
- `arm-none-eabi-size`

The target settings in `config/stm32f407_target.cmake` add the Cortex-M4 flags to the MCU interface target:

```cmake
target_compile_options(stm32f407_mcu INTERFACE
    -Wall -Wextra
    -mcpu=cortex-m4 -mthumb -mfpu=fpv4-sp-d16 -mfloat-abi=hard
    -ffunction-sections -fdata-sections
)

target_link_options(stm32f407_mcu INTERFACE
    -mcpu=cortex-m4 -mthumb -mfpu=fpv4-sp-d16 -mfloat-abi=hard
    --specs=nano.specs
    -Wl,--print-memory-usage
    -Wl,-Map=${CMAKE_PROJECT_NAME}.map
    -Wl,--gc-sections
    -T${CMAKE_SOURCE_DIR}/firmware/vendor/platform/stm32f4xx/STM32F407VGTX.ld
)
```

The firmware target is created in `firmware/CMakeLists.txt` and linked against the MCU target and the project libraries:

```cmake
add_executable(${CMAKE_PROJECT_NAME}.elf
    ${CMAKE_CURRENT_SOURCE_DIR}/app/main.c
)

target_link_libraries(${CMAKE_PROJECT_NAME}.elf PUBLIC
    stm32f407_mcu
    config
    vendor
    hal
    drivers
    bsp
    app
)

add_fw_artifacts(${CMAKE_PROJECT_NAME})
```

`config/stm32f4_post_build.cmake` adds the post-link size output and creates the firmware image files:

```cmake
add_custom_command(TARGET ${TARGET_NAME}.elf POST_BUILD
    COMMAND ${CMAKE_SIZE} $<TARGET_FILE:${TARGET_NAME}.elf>
)

add_custom_command(TARGET ${TARGET_NAME}.elf POST_BUILD
    COMMAND ${CMAKE_OBJCOPY} -O binary $<TARGET_FILE:${TARGET_NAME}.elf> ${TARGET_NAME}.bin
    COMMAND ${CMAKE_OBJCOPY} -O ihex $<TARGET_FILE:${TARGET_NAME}.elf> ${TARGET_NAME}.hex
)
```

## Building the project

### Prerequisites

- CMake 3.20 or newer
- Ninja
- GNU ARM embedded toolchain (`arm-none-eabi-*`)

If the toolchain is installed locally outside the default PATH, add it before configuring:

```bash
export PATH="$PWD/tools/arm_gcc/bin:$PATH"
```

If the toolchain is installed system-wide, this may not be needed.

### Configure and build

The project defines `debug` and `release` presets in `CMakePresets.json`:

```bash
cmake --preset debug
cmake --build --preset debug
```

For a release build:

```bash
cmake --preset release
cmake --build --preset release
```

The actual generated files are placed under the appropriate build directory, for example:

```text
build/debug/firmware/blink.elf
build/debug/firmware/blink.bin
build/debug/firmware/blink.hex
build/debug/firmware/blink.map
```

To view the detailed compile and link commands while building:

```bash
cmake --build --preset debug --verbose
```

To build only the ELF target:

```bash
cmake --build --preset debug --target blink.elf
```

## Cleaning the build

Remove the generated object files while keeping the configuration:

```bash
cmake --build --preset debug --target clean
```

Remove the build tree entirely and reconfigure from scratch:

```bash
rm -rf build
cmake --preset debug
cmake --build --preset debug
```

## Docker build environment

The repository includes a Docker build image under `docker/` for a Debian-based toolchain environment. The image is meant to provide the ARM GNU toolchain and CMake/Ninja so the firmware can be built in a repeatable environment.

Typical usage from the repo root:

```bash
docker build --progress=plain -f docker/Dockerfile -t blinker:v1 .
docker run --rm blinker:v1
```

For local source work, the project can also be mounted into the container and built in the same way as the host environment:

```bash
docker run --rm -it \
  -v "$PWD:/blink" \
  -w /blink \
  --entrypoint /bin/bash \
  blinker:v1
```

Inside the container, run the same CMake commands listed above.

## Programming the board

After the build succeeds, program the generated `.bin` or `.hex` image to the target using an ST-LINK-compatible tool such as:

- STM32CubeProgrammer
- OpenOCD
- `st-flash` (if installed)

The project currently produces `blink.bin` and `blink.hex`, which are intended to be flashed to the STM32F407VGTX flash memory via the ST-LINK programmer connected to the board.

## Notes

- The project is a bare-metal embedded firmware example; there is no RTOS or HAL driver framework layered above the direct register access.
- The linker script is `firmware/vendor/platform/stm32f4xx/STM32F407VGTX.ld`.
- The build intentionally uses the GNU ARM cross-compiler and generates raw binary and Intel HEX artifacts automatically after each link.
