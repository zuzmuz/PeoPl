#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/LLVMContext.h"
#include "llvm/IR/Module.h"

int main() {
    llvm::LLVMContext context;
    llvm::IRBuilder<> builder(context);
    llvm::Module module("id", context);
    return 0;
}
