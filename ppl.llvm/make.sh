#!/usr/bin/env zsh
 clang++ `llvm-config --cxxflags --ldflags --system-libs --libs core`  main.cpp -o main; ./main
