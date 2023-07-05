cmake_minimum_required(VERSION 3.16)

# Pull in SDK (must be before project)
#if(NOT DEFINED PICO_SDK_PATH)
#    set(PICO_SDK_PATH ${CMAKE_SOURCE_DIR}/pico-sdk)
#    message(STATUS "PICO_SDK_PATH = ${PICO_SDK_PATH}")
#endif()

include(cmake/pico_sdk_import.cmake)

project(appletini)
set(CMAKE_C_STANDARD 11)
set(CMAKE_CXX_STANDARD 17)
set(PICO_BOARD pico_w)

pico_sdk_init()

# Set compile options
add_compile_options(
        -Wall
        -Wno-format          # int != int32_t as far as the compiler is concerned because gcc has int32_t as long int
        -Wno-unused-function # we have some for the docs that aren't called
        -Wno-maybe-uninitialized
        )

add_executable(appletini)

pico_generate_pio_header(appletini
    ${CMAKE_CURRENT_SOURCE_DIR}/bus_controller.pio)

target_sources(appletini PUBLIC
    main.c
)
target_include_directories(appletini PUBLIC ${CMAKE_CURRENT_SOURCE_DIR})
target_link_libraries(appletini PUBLIC
    pico_stdlib
    pico_cyw43_arch_none
    hardware_pio
)

pico_enable_stdio_usb(appletini 1)
pico_enable_stdio_uart(appletini 0)

pico_add_extra_outputs(appletini)
