OCMock
======

OCMock is an Objective-C implementation of mock objects. 

Github is used to store and manage the source code. 

For documentation and support please visit [ocmock.org][].  

  [ocmock.org]: http://ocmock.org/

# Buiding OCMock

If you need to build your own build of OCMock, here are the following steps, from OSX Terminal:

* Make sure you use LLVM:

```
    export CC=
```
* Use the provided build script from Tools directory.
-r option is used to generate disk image.

```
    cd Tools
    ruby build.rb -r
```
