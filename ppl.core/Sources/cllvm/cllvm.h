#define _GNU_SOURCE
#define __STDC_CONSTANT_MACROS
#define __STDC_FORMAT_MACROS
#define __STDC_LIMIT_MACROS

#include <llvm-c/Analysis.h>
#include <llvm-c/BitReader.h>
#include <llvm-c/BitWriter.h>
#include <llvm-c/Core.h>
#include <llvm-c/Comdat.h>
#include <llvm-c/DataTypes.h>
#include <llvm-c/DebugInfo.h>
#include <llvm-c/Disassembler.h>
#include <llvm-c/DisassemblerTypes.h>
#include <llvm-c/Error.h>
#include <llvm-c/ErrorHandling.h>
#include <llvm-c/ExecutionEngine.h>
#include <llvm-c/ExternC.h>
// #include <llvm-c/Initialization.h>
#include <llvm-c/IRReader.h>
#include <llvm-c/Linker.h>
// #include <llvm-c/LinkTimeOptimizer.h>
// #include <llvm-c/lto.h>
#include <llvm-c/Object.h>
#include <llvm-c/Orc.h>
#include <llvm-c/Support.h>
#include <llvm-c/Target.h>
#include <llvm-c/TargetMachine.h>
// #include <llvm-c/Transforms/IPO.h>
#include <llvm-c/Transforms/PassBuilder.h>
// #include <llvm-c/Transforms/Scalar.h>
// #include <llvm-c/Transforms/Utils.h>
// #include <llvm-c/Transforms/Vectorize.h>
#include <llvm-c/Types.h>
