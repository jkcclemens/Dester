Dester
======

This is a fork of hawkfalcon's Chester! It's written entirely in D, which means that you can compile it straight to
machine code, instead of running it on a JVM.

It's also rewritten for easy-to-use expansion without ugly extended if statements.

Compilation
-----------

I prefer using GDC to compile.
```
find . -name "*.d" | tr '\n' ' ' | xargs gdc -frelease -ffunction-sections -fdata-sections -Wl,-s,--gc-sections -Os -o Dester
strip -s bin/Dester
```
If you use DMD, see below.
```
find . -name "*.d" | tr '\n' ' ' | xargs dmd -release -O -of Dester
strip -s bin/Dester
```
If you use LDC, see below.
```
find . -name "*.d" | tr '\n' ' ' | xargs ldc2 -release -Oz -of Dester
strip -s bin/Dester
```
In a bash shell, that will compile Dester.

*Note*: GDC will not compile unless you compile GDC and GCC together from their latest (git) sources.
