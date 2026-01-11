Default debug build and run
>make run  
make run ARGS="input.txt --verbose"

Build tests only
>make test  
make test MODE=release

Compile + run tests
>make test-run  
make test-run ARGS="--verbose"

Shortcut for release build
>make release  
make run MODE=release  
make test-run MODE=release

Custom main is foo.qk
>make run MAIN=foo 

