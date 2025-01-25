# Z-Script

Helper script for Rakudo core development

# INSTALLATION

```bash
git clone https://github.com/zoffixznet/z ~/zscript &&
cd ~/zscript &&
zef --depsonly install .

echo 'export PATH="$HOME/zscript/bin:$PATH"' >> ~/.bashrc
. ~/.bashrc

z init ~/R # or some other dir you wanna use for all the repos
```

**This installs command `z` into your PATH.**

If you want to call `z` by a different name (for instance, if you use the popular [`z` script](https://github.com/rupa/z) included in several Linux distributions), you should be aware that (this) `z` uses libraries relative to its own directory. So some typical workarounds for this, like creating a _~/bin/p6z_ → _~/zscript/bin/z_ symbolic link, will make `z` run incorrectly.

The easiest way to deal with this is by using a shell alias (_instead_ of the above):

```bash
echo 'alias p6z="$HOME/zscript/bin/z"' >> ~/.bashrc
. ~/.bashrc

p6z init ~/R
```


# ENV VARS

You can set `ZSCRIPT_DIR` env var to change which build dir Z-Script uses.
Otherwise, `dir` config value is used (this is the dir you provided to
`z init`). This var allows you to have multiple build dirs.

# COMMAND REFERENCE

**BELOW LIST IS NO LONGER KEPT UP-TO-DATE. RUN `z --help` TO SEE ALL THE
OPTIONS*

```
z init Some-Dir  # clone all repos and build everything inside Some-Dir
                 # Some-Dir defaults to `.`; must be empty

z z              # pulls all repos and rebuilds MoarVM, nqp, and Rakudo from scratch
z f              # pulls updates into all repos
z                # re-make rakudo
z --test         # re-make rakudo + run make test
z n              # re-make nqp and rakudo
z n --test       # re-make nqp and rakudo + run make test for both
z m              # re-make MoarVM
z md             # re-make MoarVM after reconf with DEBUG (with --no-optimize)
z mnd            # re-make MoarVM after reconf with no DEBUG

z s              # run rakudo's make test + spectest
z ss             # run rakudo's make test + stresstest
z bs             # run "best test" (have > 10 cores ?? stresstest !! spectest)
z t some files   # run t/fudgeandrun some files

z bump           # bump MoarVM and nqp + best test + bump push on success
z bump --no-push # bump MoarVM and nqp + best test, but don't push
z bump m         # bump MoarVM version
z bump n         # bump nqp version
z bump push      # push already-done version bumps for MoarVM and nqp
z bump push m    # push already-done version bump for MoarVM
z bump push n    # push already-done version bump for nqp

z mod Some Module         # install modules 'Some' and 'Module', without tests
z mod Some Module --tests # install modules 'Some' and 'Module', with tests
z umod Some Module        # uninstall modules 'Some' and 'Module'
z modi5                   # install Inline::Perl5 module

z conf                     # print all configuration
z conf dir                 # print value for configuration key "dir"
z conf dir /home/zoffix/R  # set config key "dir" to value "/home/zoffix/R"

vm 111.222.333.444  # set VM IP to given IP (trims surrounding whitespace)
vm                  # rsyncs all local changes to VM
vm s                # sync spec changes
vm d                # sync doc changes
vm m                # sync moar changes
vm n                # sync nqp changes
vm r                # sync rakudo changes
vm SCRUB            # run `git reset --hard` in all local repos and pull
                    # new commits. This *** DELETES ALL LOCAL YOUR CHANGES ***
                    # Yup. LOCAL, not VM. It's under `vm` because you'd use
                    # this command to sync local when editing locally and
                    # committing remotely


z q  # opens Grammar/Actions/World/Optimizer in atom editor; assumes we're
     # in the root of a rakudo checkout

z r Some Command    # run Some Command in all the repos (may have issues with
                    # named args)


                    # full-cycle builds are only needed when you need to
                    # re-run Configure.pl if, say, core files were added/deleted
z build moar        # full-cycle build moarvm
z build nqp         # full-cycle build nqp
z build rakudo      # full-cycle build rakduo
```

----

#### REPOSITORY

Fork this module on GitHub:
https://github.com/zoffixznet/z

#### BUGS

To report bugs or request features, please use
https://github.com/zoffixznet/z/issues

#### AUTHOR

Zoffix Znet (http://perl6.party/)

#### LICENSE

You can use and distribute this module under the terms of the
The Artistic License 2.0. See the `LICENSE` file included in this
distribution for complete details.

The `META6.json` file of this distribution may be distributed and modified
without restrictions or attribution.
