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