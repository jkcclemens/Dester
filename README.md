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

Experimental Compilation
------------------------

This will attempt to compile Dester using libphobos as a dynamic (shared) library; this will not statically link Phobos
into the executable, resulting is smaller file sizes.

This can only be done using DMD (as far as I know; to do this, it requires a shared library of Phobos).

Steps
- Execute ```find . -name "*.d" | tr '\n' ' ' | xargs dmd -release -O -c```
- You should end up with ```.o``` files (one or many; depends on compiler)
- Execute ```gcc *.o -o Dester -m64 -L/opt/dmd/linux/lib64 -Xlinker --no-warn-search-mismatch -Xlinker -l:libphobos2.so -s```
  - Change ```64``` to ```32``` if you're on a 32-bit OS.
  - Note that your path for ```/opt/dmd/linux/lib64``` may be different. Do ```which dmd``` to hopefully find the path. Otherwise, you can compile the program normally with the ```-v``` flag to find it.
- Find libphobos2.so (or whatever the shared Phobos library is called if using another compiler)
- Do ```ldd Dester```. You should see something like ```libphobos2.so.0.2 => not found``` in the resulting text. Make note of the missing library (```libphobos2.so.0.2``` in this case)
  - You should also see something similar to ```libc.so.6 => /lib/x86_64-linux-gnu/libc.so.6 (0x000002b05dfb1000)```. Make note of the file path (```/lib/x86_64-linux-gnu``` in this case)
- Symlink libphobos2.so into your standard libs folder (the folder you made note of in the last step) as the missing library from above
- Perform ```ldd Dester``` again. It should be a much larger output, but find a line like ```libphobos2.so.0.2 => /lib/x86_64-linux-gnu/libphobos2.so.0.2 (0x0000032cdaa5e000)```. If you can find that, you have successfully linked Phobos dynamically. You can now run Dester (it is already stripped). You can pack it with UPX to make it even smaller.
