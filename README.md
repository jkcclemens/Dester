Dester
======

This is a fork of hawkfalcon's Chester! It's written entirely in D, which means that you can compile it straight to
machine code, instead of running it on a JVM.

It's also rewritten for easy-to-use expansion without ugly extended if statements.

Compilation
-----------

I prefer using GDC to compile.
```
cat build.rf | sed ':a;N;$!ba;s/\n/ /g' | xargs gdc -frelease -ffunction-sections -fdata-sections -Wl,-s,--gc-sections -Os
strip -s bin/Dester
```
If you use DMD, see below.
```
cat build.rf | sed ':a;N;$!ba;s/\n/ /g' | xargs dmd -release -O
strip -s bin/Dester
```
In a bash shell, that will compile Dester.

*Note*: GDC will not compile unless you compile GDC and GCC together from their latest (git) sources.
