add_library(synpeopl
    main.cpp
)

target_include_directories(synpeopl PUBLIC ${CMAKE_CURRENT_SOURCE_DIR})
add_executable(peopl)
target_sources(peopl
  PRIVATE
    main.cpp
)
