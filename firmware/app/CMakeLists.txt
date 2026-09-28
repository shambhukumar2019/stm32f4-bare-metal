file(GLOB SRC_FILES "*.c")


add_library(app STATIC 
    ${SRC_FILES}
)

target_link_libraries(app PUBLIC vendor)
