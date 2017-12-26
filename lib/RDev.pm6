unit class RDev;
use Temp::Path;

has %.conf is required;
has IO::Path $!dir;
has Str $!rak;
has Str $!nqp;
has Str $!moar;
has Str $!spec;
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
        $!spec = .add('rakudo/t/spec/').absolute;
    }
}

method init {
    .mkdir for $!dir, $!rak.IO, $!nqp.IO, $!moar.IO, $!inst.IO;
    run «git clone https://github.com/rakudo/rakudo "$!rak"»;
    run «git clone https://github.com/perl6/roast   "$!spec"»;
    run «git clone https://github.com/perl6/nqp     "$!nqp"»;
    run «git clone https://github.com/MoarVM/MoarVM "$!moar"»;
}

method make-links {
    $!inst.IO.add('bbin/perl6-m').symlink: 'perl6';
}

method best-test {
    $!cores > 10 ?? self.stresstest !! self.spectest;
}

method bump-moar {
    self!pull-moar;
    self!pull-nqp;

    my $ver-file = $!nqp.IO.add: 'tools/build/MOAR_REVISION';

    my $before = $ver-file.slurp.trim;
    my $after  = self!run-moar-out: «git describe»;
    if $before eq $after {
        note "\n\n### No fresh commits in MoarVM; no bumping is needed\n\n";
        exit;
    }
    $ver-file.spurt: "$after\n";

    my $log = self!run-moar-out: «git log --oneline "$before...$after"»;
    my $n-commits = +$log.lines;
    my $title = "[MoarVM Bump] Brings $n-commits commit"
        ~ ("s" if $n-commits > 1);

    if $log.lines == 1 {
        $title = "[MoarVM Bump] " ~ self!trim: $log, 36;
        $log = '';
    }
    $log = "MoarVM bump brought: "
        ~ "https://github.com/MoarVM/MoarVM/compare/$before...$after"
        ~ ("\n$log\n" if $log);
    say "$title\n\n$log".indent: 8;
    self!run-nqp: «git commit VERSION -m "$title" -m "$log"»;
    $log
}

method bump-nqp (Str:D $moar-log = '') {
    self!pull-nqp;
    self!pull-rak;

    my $ver-file = $!rak.IO.add: 'tools/build/NQP_REVISION';

    my $before = $ver-file.slurp.trim;
    my $after  = self!run-nqp-out: «git describe»;
    if $before eq $after {
        note "\n\n### No fresh commits in NQP; no bumping is needed\n\n";
        exit;
    }
    $ver-file.spurt: "$after\n";

    my $log = self!run-nqp-out: «git log --oneline "$before...$after"»;
    my $n-commits = +$log.lines;
    my $title = "[NQP Bump] Brings $n-commits commit"
        ~ ("s" if $n-commits > 1);
    if $log.lines == 1 {
        $title = "[NQP Bump] " ~ self!trim: $log, 39;
        $log = '';
    }
    $log = "NQP bump brought: "
        ~ "https://github.com/perl6/nqp/compare/$before...$after"
        ~ ("\n$log\n"        if $log)
        ~ ("\n\n$moar-log\n" if $moar-log);

    say "$title\n\n$log".indent: 8;
    self!run-rak: «git commit "$ver-file.absolute()" -m "$title" -m "$log"»;
    $log
}

method bump-push-moar {
    self!run-nqp: «git pull --rebase»;
    self!run-nqp: «git push»;
}

method bump-push-nqp {
    self!run-rak: «git pull --rebase»;
    self!run-rak: «git push»;
}

method pull-all {
    self!pull-moar;
    self!pull-nqp;
    self!pull-rak;
    self!pull-spec;
}
method !pull-moar { self!run-moar: «git pull --rebase» }
method !pull-nqp  { self!run-nqp:  «git pull --rebase» }
method !pull-rak  { self!run-rak:  «git pull --rebase» }
method !pull-spec { self!run-spec: «git pull --rebase» }

method !init-zef {
    temp %*ENV<PATH> = my $path = join ($*DISTRO.is-win ?? ";" !! ":"),
        $!inst.IO.add('bin').absolute,
        $!inst.IO.add('share/perl6/site/bin').absolute,
        $*SPEC.path;

    unless run :!out, :!err, «zef --help» {
        indir make-temp-dir, {
            run «git clone https://github.com/ugexe/zef .»;
            run «perl6 -Ilib bin/zef install .»;
        }
    }

    $path;
}
method install-modules(@mods, Bool :$tests) {
    temp %*ENV<PATH> = self!init-zef;
    run «zef --debug --/serial», |('--/test' unless $tests), 'install', |@mods;
}
method uninstall-modules(@mods) {
    temp %*ENV<PATH> = self!init-zef;
    run «zef --debug uninstall», |@mods;
}

method spectest {
    self!run-rak: «make spectest»;
}
method stresstest {
    self!run-rak: «make stresstest»;
}

method re-make-moar {
    self!run-moar: «make "-j$!cores"»;
    self!run-moar: «make install»;
}
method re-make-nqp(Bool :$test) {
    self!run-nqp: «make clean»;
    self!run-nqp: «make "-j$!cores"»;
    self!run-nqp: «make test» if $test;
    self!run-nqp: «make install»;
}
method re-make-rakudo(Bool :$test, Bool :$clean) {
    self!run-rak: «make clean» if $clean;
    self!run-rak: «make "-j$!cores"»;
    self!run-rak: «make test» if $test;
    self!run-rak: «make install»;
}

method build-moar {
    self!run-moar: «perl Configure.pl "--prefix=$!inst"»;
    self!run-moar: «make "-j$!cores"»;
    self!run-moar: «make install»;
}

method build-nqp(Bool :$test) {
    self!run-nqp: «perl Configure.pl "--prefix=$!inst" --backends=moar»;
    self!run-nqp: «make "-j$!cores"»;
    self!run-nqp: «make test» if $test;
    self!run-nqp: «make install»;
}

method build-rakudo (Bool :$test) {
    self!run-rak: «perl Configure.pl "--prefix=$!inst" --backends=moar»;
    self!run-rak: «make "-j$!cores"»;
    self!run-rak: «make test» if $test;
    self!run-rak: «make install»;
}

method !run-moar (|c) { run :cwd($!moar), |c }
method !run-nqp  (|c) { run :cwd($!nqp),  |c }
method !run-rak  (|c) { run :cwd($!rak),  |c }
method !run-spec (|c) { run :cwd($!spec), |c }

method !run-moar-out (|c) { self!run-moar(|c, :out).out.slurp(:close).trim }
method !run-nqp-out  (|c) { self!run-nqp( |c, :out).out.slurp(:close).trim }
method !run-rak-out  (|c) { self!run-rak( |c, :out).out.slurp(:close).trim }
method !run-spec-out (|c) { self!run-spec(|c, :out).out.slurp(:close).trim }

method !trim (Str:D $str, UInt:D $max) {
    $str.chars > $max
        ?? $str.substr(0, $max-4) ~ ' […]'
        !! $str
}
