# rdev

Helper script for Rakudo Perl 6 core development

# INSTALLATION

```bash
git clone https://github.com/zoffixznet/rdev ~/rdev &&
cd ~/rdev &&
zef --depsonly install .

echo 'export PATH="$HOME/rdev/bin:$PATH"' >> ~/.bashrc
. ~/.bashrc

pico ~/rdev/config.json
# set your build directory and other config, save, and close
```

**This installs command `z` into your PATH.**

# COMMAND REFERENCE

```
z --init         # clone all repos and build everything
z                # make, make install rakudo
z --test         # make, make test, make install rakudo

z n              # re-make nqp and rakudo
z n --test       # re-make nqp and rakudo + run make test for both
z m              # re-make MoarVM

z s              # run spectest
z ss             # run stresstest
z bs             # run "best test" (have > 10 cores ?? stresstest !! spectest)

z bump           # bump MoarVM and nqp + best test + bump push on success
z bump --no-push # bump MoarVM and nqp + best test, but don't push
z bump m         # bump MoarVM version
z bump n         # bump nqp version
z bump push      # push already-done version bumps for MoarVM and nqp
z bump push m    # push already-done version bump for MoarVM
z bump push n    # push already-done version bump for nqp
```

# USAGE

## Building

### `--init`

```bash
$ z --init
```

Initialize build dir (set as `"dir"` key in `~/rdev/config.json`).

This clones rakudo/nqp/MoarVM repos and builds everything into `install` dir
inside the build dir.

### `f`

```bash
$ z f
```

Fetch any new commits to all repos. Uses `git pull --rebase`

### (no args) / (no args) `--test`

```bash
$ z
# or
$ z --test
```

**Use after making changes to Rakudo's codebase.**
Runs `make` and `make install` in rakudo's repo. Pass `--test` param to also
run `make test`

### `n` / `n --test`

```bash
$ z n
# or
$ z n --test
```

**Use after making changes to nqp's codebase.**
Runs `make clean`, `make`, and `make install` in nqp's and rakudo's repos.
Pass `--test` param to also run `make test`

### `m`

```bash
$ z m
```

**Use after making changes to MoarVM's codebase.**
Runs `make` and `make install` in MoarVM's repo.

## Testing

### `s`

```bash
$ z s
```

Runs `make spectest` in rakudo's repo.

### `ss`

```bash
$ z ss
```

Runs `make stresstest` in rakudo's repo.

### `bs`

```bash
$ z bs
```

Runs "best test" in rakudo's repo. If the box we're on has more than 10 cores,
run stresstest, otherwise run spectest.

## Version Bumps

Version bumping involves fetching new commits to repos
using `git pull --rebase`. In [some cases that might not be what
you want](https://rakudo.party/post/I-Botched-A-Perl-6-Release-And-Now-A-Robot-Is-Taking-My-Job)

### `bump` / `bump --no-push`

```bash
$ z bump
# or
$ z bump --no-push
```

Bumps MoarVM version in NQP, then bumps NQP version in Rakudo, runs "best test"
(see above) and automatically pushes the changes to the repos if the best test
passes. If it fails, will ask whether to push changes or not. Will not push
anything to the repo if `--no-push` was specified (commits will remain committed
locally).

Will prepare commit summaries for each of the commit messages.

### `bump m`

```bash
$ z bump m
```

Bump MoarVM version only. Does not test or push.

### `bump n`

```bash
$ z bump n
```

Bump nqp version only. Does not test or push.

### `bump push`

```bash
$ z bump push
```

Push already prepared version bumps for MoarVM and nqp. Does `git pull --rebase`
in nqp and rakudo's repos.

### `bump push m`

```bash
$ z bump push m
```

Push already prepared version bump for MoarVM. Does `git pull --rebase`
in nqp's repo.

### `bump push n`

```bash
$ z bump push n
```

Push already prepared version bump for MoarVM. Does `git pull --rebase`
in rakudo's repo.

----

#### REPOSITORY

Fork this module on GitHub:
https://github.com/zoffixznet/rdev

#### BUGS

To report bugs or request features, please use
https://github.com/zoffixznet/rdev/issues

#### AUTHOR

Zoffix Znet (http://perl6.party/)

#### LICENSE

You can use and distribute this module under the terms of the
The Artistic License 2.0. See the `LICENSE` file included in this
distribution for complete details.

The `META6.json` file of this distribution may be distributed and modified
without restrictions or attribution.
