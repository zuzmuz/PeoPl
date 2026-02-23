cmake_minimum_required(VERSION 3.28)
project(peopl
    VERSION 0.0.0.0
    DESCRIPTION "PeoPl - Pipeline Expression Oriented Programming Language"
    LANGUAGES CXX
)

set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_STANDARD_REQUIRED true)

add_executable(peopl)
target_compile_options(peopl PRIVATE -Wswitch -Werror=switch)
target_compile_options(peopl PRIVATE -Wreturn-type -Werror=return-type)
target_sources(peopl
  PRIVATE
    src/main.cpp
)
