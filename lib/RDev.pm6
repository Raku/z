unit class RDev;
use Temp::Path;
use Config::JSON '';

has IO::Path:D $.conf is required;
has &!c  = &jconf      .assuming: $!conf;
has &!cw = &jconf-write.assuming: $!conf;
has IO::Path $!dir;
has Str $!rak;
has Str $!nqp;
has Str $!doc;
has Str $!moar;
has Str $!spec;
has Str $!inst;
has Int $!cores = Kernel.cpu-cores * 2;

submethod TWEAK { self!init-dirs }
method !init-dirs {
    with (%*ENV<ZSCRIPT_DIR> || &!c('dir')) -> IO() $_ {
        $!dir  = $_;
        $!rak  = .add('rakudo' ).absolute;
        $!nqp  = .add('nqp'    ).absolute;
        $!doc  = .add('doc'    ).absolute;
        $!moar = .add('MoarVM' ).absolute;
        $!inst = .add('install').absolute;
        $!spec = .add('rakudo/t/spec/').absolute;
    }
    else {
        warn '"dir" key not found in config. Please run `init` command.'
        ~ ' If you are running it right now, then ignore this warning'.
    }
}

method init (IO() $!dir = '.'.IO) {
    $!dir.dir.so and die "Init dir `$!dir.absolute()` must be empty.";
    &!cw('dir', $!dir.absolute);
    self!init-dirs;
    .mkdir for $!dir, $!rak.IO, $!nqp.IO, $!moar.IO, $!inst.IO;
    run «git clone https://github.com/rakudo/rakudo "$!rak"»;
    run «git clone https://github.com/perl6/roast   "$!spec"»;
    run «git clone https://github.com/perl6/nqp     "$!nqp"»;
    run «git clone https://github.com/perl6/doc     "$!doc"»;
    run «git clone https://github.com/MoarVM/MoarVM "$!moar"»;
}

method make-links {
    $!inst.IO.add('bin/perl6-m').symlink: $!dir.add: 'perl6';
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
    self!run-nqp: «git commit "$ver-file.absolute()" -m "$title" -m "$log"»;
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

method bump-push {
    self.bump-push-moar;
    self.bump-push-nqp;
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
    say "Pulling MoarVM";
    self!pull-moar;
    say "Pulling NQP";
    self!pull-nqp;
    say "Pulling Rakudo";
    self!pull-rak;
    say "Pulling Roast";
    self!pull-spec;
    say "Pulling Docs";
    self!pull-doc;
}
method !pull-moar { self!run-moar: «git pull --rebase» }
method !pull-nqp  { self!run-nqp:  «git pull --rebase» }
method !pull-rak  { self!run-rak:  «git pull --rebase» }
method !pull-spec { self!run-spec: «git pull --rebase» }
method !pull-doc  { self!run-doc:  «git pull --rebase» }

method run-in-all (@args --> Nil) {
    say "Running in MoarVM";
    my $ = self!run-moar: @args;
    say "Running in NQP";
    my $ = self!run-nqp: @args;
    say "Running in Rakudo";
    my $ = self!run-rak: @args;
    say "Running in Roast";
    my $ = self!run-spec: @args;
    say "Running in Docs";
    my $ = self!run-doc: @args;
}

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
    self!run-rak: «make install»;
    self!run-rak: «make test»;
    self!run-rak: «make spectest»;
}
method stresstest {
    self!run-rak: «make install»;
    self!run-rak: «make test»;
    self!run-rak: «make stresstest»;
}
method fudge-test (*@tests) {
    self!run-rak: 't/fudgeandrun', @tests;
}

method re-make-moar-debug {
    self!run-moar: «perl Configure.pl "--prefix=$!inst" --no-optimize --debug»;
    self.re-make-moar
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
    (self!run-rak: «make realclean»).so;
    self!run-moar: «perl Configure.pl "--prefix=$!inst"»;
    self!run-moar: «make "-j$!cores"»;
    self!run-moar: «make install»;
}

method build-nqp(Bool :$test, Bool :$jvm, Bool :$moar = True) {
    my $b = join ',', ('moar' if $moar), ('jvm' if $jvm);
    (self!run-rak: «make realclean»).so;
    self!run-nqp: «perl Configure.pl "--prefix=$!inst" "--backends=$b"»;
    self!run-nqp: «make "-j$!cores"»;
    self!run-nqp: «make test» if $test;
    self!run-nqp: «make install»;
}

method build-rakudo (Bool :$test, Bool :$jvm, Bool :$moar = True) {
    my $b = join ',', ('moar' if $moar), ('jvm' if $jvm);
    (self!run-rak: «make realclean»).so;
    self!run-rak: «perl Configure.pl "--prefix=$!inst" "--backends=$b"»;
    self!run-rak: «make "-j$!cores"»;
    self!run-rak: «make test» if $test;
    self!run-rak: «make install»;
}

method !run-inst (|c) { run :cwd($!inst), |c }
method !run-moar (|c) { run :cwd($!moar), |c }
method !run-nqp  (|c) { run :cwd($!nqp),  |c }
method !run-rak  (|c) { run :cwd($!rak),  |c }
method !run-spec (|c) { run :cwd($!spec), |c }
method !run-doc  (|c) { run :cwd($!doc),  |c }

method !run-inst-out (|c) { self!run-inst(|c, :out).out.slurp(:close).trim }
method !run-moar-out (|c) { self!run-moar(|c, :out).out.slurp(:close).trim }
method !run-nqp-out  (|c) { self!run-nqp( |c, :out).out.slurp(:close).trim }
method !run-rak-out  (|c) { self!run-rak( |c, :out).out.slurp(:close).trim }
method !run-spec-out (|c) { self!run-spec(|c, :out).out.slurp(:close).trim }
method !run-doc-out  (|c) { self!run-doc( |c, :out).out.slurp(:close).trim }

method !trim (Str:D $str, UInt:D $max) {
    $str.chars > $max
        ?? $str.substr(0, $max-4) ~ ' […]'
        !! $str
}


multi method print-conf (Str:D $prop) { say &!c($prop) // 'no such property' }
multi method print-conf (Whatever) {
    say .fmt: '%-20s => %-20s' for &!c(*)
}
method set-conf (Str:D $prop, Str:D $value) {
    &!cw($prop, $value);
    $value
}

method !sync-vm-creds {
    my ($ip, $user, $dir-to, $dir-from)
    = &!c('vm-ip'), &!c('vm-user'), &!c('vm-dir'), &!c('dir');
    if $ip ~~ Failure {
        $ip = trim prompt 'No VM IP. Gimme: ';
        &!cw('vm-ip', $ip)
    }
    if $user ~~ Failure {
        $user = trim prompt 'No VM user. Gimme: ';
        &!cw('vm-user', $user)
    }
    if $dir-to ~~ Failure {
        my $dir = prompt "No VM dir specified. What to use? [$dir-from]: ";
        $dir-to = $dir || $dir-from;
        $dir-to.IO.is-absolute or die "Must be absolute path";
        &!cw('vm-dir', $dir-to);
    }
    .subst: / '/'+ $ /, '' for $dir-to, $dir-from;
    ($ip, $user, $dir-to, $dir-from)
}
method sync-vm {
    self.sync-vm-spec;
    self.sync-vm-doc;
    self.sync-vm-moar;
    self.sync-vm-nqp;
    self.sync-vm-rak;
}
method sync-vm-spec {
    my ($ip, $user, $dir-to, $dir-from) = self!sync-vm-creds;
    self!run-spec-out(«git status --porcelain»).lines.map: {
        my $file := .trim.split(/\s+/, 2).tail;
        my $from := "$dir-from/rakudo/t/spec/$file";
        my $to   := "$dir-to/rakudo/t/spec/$file";
        self!run-inst:
            «rsync -avz --del -h --exclude .precomp --delete-missing-args»,
            $from, "$user\@$ip:$to";
    }
}

method sync-vm-doc {
    my ($ip, $user, $dir-to, $dir-from) = self!sync-vm-creds;
    self!run-doc-out(«git status --porcelain»).lines.map: {
        my $file := .trim.split(/\s+/, 2).tail;
        my $from := "$dir-from/doc/$file";
        my $to   := "$dir-to/doc/$file";
        self!run-inst:
            «rsync -avz --del -h --exclude .precomp --delete-missing-args»,
            $from, "$user\@$ip:$to";
    }
}

method sync-vm-moar {
    my ($ip, $user, $dir-to, $dir-from) = self!sync-vm-creds;
    self!run-moar-out(«git status --porcelain»).lines.map: {
        my $file := .trim.split(/\s+/, 2).tail;
        my $from := "$dir-from/MoarVM/$file";
        my $to   := "$dir-to/MoarVM/$file";
        self!run-inst:
            «rsync -avz --del -h --exclude .precomp --delete-missing-args»,
            $from, "$user\@$ip:$to";
    }
}

method sync-vm-nqp {
    my ($ip, $user, $dir-to, $dir-from) = self!sync-vm-creds;
    self!run-nqp-out(«git status --porcelain»).lines.map: {
        my $file := .trim.split(/\s+/, 2).tail;
        my $from := "$dir-from/nqp/$file";
        my $to   := "$dir-to/nqp/$file";
        self!run-inst:
            «rsync -avz --del -h --exclude .precomp --delete-missing-args»,
            $from, "$user\@$ip:$to";
    }
}

method sync-vm-rak {
    my ($ip, $user, $dir-to, $dir-from) = self!sync-vm-creds;
    self!run-rak-out(«git status --porcelain»).lines.map: {
        my $file := .trim.split(/\s+/, 2).tail;
        my $from := "$dir-from/rakudo/$file";
        my $to   := "$dir-to/rakudo/$file";
        self!run-inst:
            «rsync -rlpgoD -vz --del -h --delete-missing-args»,
            $from, "$user\@$ip:$to";
    }
}

method vm-SCRUB {
    if prompt('SCRUB stuff? Are you sure? [y/N]: ').lc eq 'y' {
        self!run-moar: «git reset --hard»;
        self!run-nqp:  «git reset --hard»;
        self!run-rak:  «git reset --hard»;
        self!run-spec: «git reset --hard»;
        self!run-doc:  «git reset --hard»;
        self.pull-all;
    }
    else {
        say "OK. Aborting";
    }
}
