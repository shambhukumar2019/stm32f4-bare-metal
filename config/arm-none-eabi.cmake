set(CMAKE_SYSTEM_NAME "Generic")
set(CMAKE_SYSTEM_PROCESSOR "ARM")

set(MCU "STM32F407VGTX" cache STRING "Target_MCU")

set(CMAKE_C_COMPILER arm-none-eabi-gcc)
set(CMAKE_ASM_COMPILER arm-none-eabi-gcc)
set(CMAKE_CXX_COMPILER arm-none-eabi-g++)

set(CMAKE_TRY_COMPILE_TARGET_TYPE STATIC_LIBRARY)

add_compile_options(-O0 -g -Wall -Wextra -mcpu=cortex-m4 -mthumb -mfpu=fpv4-sp-d16 -mfloat-abi=hard -ffunction-sections -fdata-sections)
add_link_options(-mcpu=cortex-m4 -mthumb -mfpu=fpv4-sp-d16 -mfloat-abi=hard --specs=nano.specs -Wl,--print-memory-usage -Wl,-Map=${CMAKE_PROJECT_NAME}.map -Wl,--gc-sections -T${CMAKE_SOURCE_DIR}/firmware/vendor/platform/stm32f4xx/STM32F407VGTX.ld)

