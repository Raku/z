unit class RDev;

has %.conf is required;
has IO::Path $!dir;
has Str $!rak;
has Str $!nqp;
has Str $!moar;
has Str $!inst;
has Int $!cores = Kernel.cpu-cores * 2;

submethod TWEAK {
    %!conf<dir> andthen $!dir = .IO orelse
        die "Missing `dir` param in configuration";

    with $!dir {
        $!rak  = .add('rakudo' ).absolute;
        $!nqp  = .add('nqp'    ).absolute;
        $!moar = .add('MoarVM' ).absolute;
        $!inst = .add('install').absolute;
    }
}

method init {
    .mkdir for $!dir, $!rak.IO, $!nqp.IO, $!moar.IO, $!inst.IO;
    run «git clone https://github.com/rakudo/rakudo "$!rak"»;
    run «git clone https://github.com/perl6/nqp     "$!nqp"»;
    run «git clone https://github.com/MoarVM/MoarVM "$!moar"»;
}

method make-links {
    $!inst.IO.add('bin/perl6-m').symlink: 'perl6';
}

method re-make-moar {
    run :cwd($!moar), «make "-j$!cores"»;
    run :cwd($!moar), «make install»;
}
method re-make-nqp(Bool :$test) {
    my $cwd := $!nqp;
    run :$cwd, «make "-j$!cores"»;
    run :$cwd, «make test» if $test;
    run :$cwd, «make install»;
}
method re-make-rakudo(Bool :$test) {
    my $cwd := $!rak;
    run :$cwd, «make "-j$!cores"»;
    run :$cwd, «make test» if $test;
    run :$cwd, «make install»;
}

method build-moar {
    my $cwd := $!moar;
    run :$cwd, «perl Configure.pl "--prefix=$!inst"»;
    run :$cwd, «make "-j$!cores"»;
    run :$cwd, «make install»;
}

method build-nqp(Bool :$test) {
    my $cwd := $!nqp;
    run :$cwd, «perl Configure.pl "--prefix=$!inst" --backends=moar»;
    run :$cwd, «make "-j$!cores"»;
    run :$cwd, «make test» if $test;
    run :$cwd, «make install»;
}

method build-rakudo (Bool :$test) {
    my $cwd := $!rak;
    run :$cwd, «perl Configure.pl "--prefix=$!inst" --backends=moar»;
    run :$cwd, «make "-j$!cores"»;
    run :$cwd, «make test» if $test;
    run :$cwd, «make install»;
}
