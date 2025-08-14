# Build

in order to build the project for development
``` bash
swift build
```

To exclude development features from build, like socket lsp server
``` bash
swift build -Xswiftc -DRELEASE build -c release
```


in order to use llvm

on mac

- make sure llvm is installed through brew
- llvm-config should be in path
- have llvm in pkgconfig
