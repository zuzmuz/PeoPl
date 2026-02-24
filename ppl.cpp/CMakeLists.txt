cmake_minimum_required(VERSION 3.28)
project(peopl
    VERSION 0.0.0.0
    DESCRIPTION "PeoPl - Pipeline Expression Oriented Programming Language"
    LANGUAGES CXX
)

set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

enable_testing()   # must be in root, before add_subdirectory

add_subdirectory(src)
add_subdirectory(tests)
