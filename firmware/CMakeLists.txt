add_subdirectory(config)
add_subdirectory(vendor)
add_subdirectory(hal)
add_subdirectory(drivers)
add_subdirectory(bsp)
add_subdirectory(app)

add_executable(blink app/main.c)

target_link_libraries(blink PUBLIC
    config
    vendor
    hal
    drivers
    bsp
    app
)

add_custom_command(TARGET blink POST_BUILD
    COMMAND ${CMAKE_SIZE} $<TARGET_FILE:blink>
)


add_custom_command(TARGET blink POST_BUILD
    COMMAND ${CMAKE_OBJCOPY} -O binary $<TARGET_FILE:blink> ${CMAKE_PROJECT_NAME}.bin
    COMMAND ${CMAKE_OBJCOPY} -O ihex $<TARGET_FILE:blink> ${CMAKE_PROJECT_NAME}.hex
)

