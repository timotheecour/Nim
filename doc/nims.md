# NimScript

Strictly speaking, `NimScript` is the subset of Nim that can be evaluated by
Nim\'s builtin virtual machine (VM). This VM is used for Nim\'s compiletime
function evaluation features.

The `nim` executable processes the `.nims` configuration files in the following
directories (in this order; later files overwrite previous settings):

1)  If environment variable `XDG_CONFIG_HOME` is defined,
    `$XDG_CONFIG_HOME/nim/config.nims` or `~/.config/nim/config.nims` (POSIX) or
    `%APPDATA%/nim/config.nims` (Windows). This file can be skipped with the
    `--skipUserCfg` command line option.
2)  `$parentDir/config.nims` where `$parentDir` stands for any parent directory
    of the project file\'s path. These files can be skipped with the
    `--skipParentCfg` command line option.
3)  `$projectDir/config.nims` where `$projectDir` stands for the project\'s
    path. This file can be skipped with the `--skipProjCfg` command line option.
4)  A project can also have a project specific configuration file named
    `$project.nims` that resides in the same directory as `$project.nim`. This
    file can be skipped with the same `--skipProjCfg` command line option.

The VM cannot deal with `importc` because the FFI is not available. So the
stdlib modules using `importc` cannot be used with Nim\'s VM. However, at least
the following modules are available:

-   [macros](macros.html)
-   [ospaths](ospaths.html)
-   [strutils](strutils.html)
-   [math](math.html)
-   [distros](distros.html)

In addition to the standard Nim syntax ([system](system.html) module),
NimScripts support the procs and templates defined in the
[nimscript](nimscript.html) module too.

## NimScript as a configuration file

A command-line switch `--FOO` is written as `switch("FOO")` in NimScript.
Similarly, command-line `--FOO:VAL` translates to `switch("FOO", "VAL")`.

Here are few examples of using the `switch` proc:

``` {.sourceCode .nim
# command-line: --opt:size
switch("opt", "size")
# command-line: --define:foo or -d:foo
switch("define", "foo")
# command-line: --forceBuild
switch("forceBuild")}
```

NimScripts also support `--` templates for convenience, which look like
command-line switches written as-is in the NimScript file. So the above example
can be rewritten as:

``` {.sourceCode .nim
--opt:size
--define:foo
--forceBuild}
```

**Note**: In general, the *define* switches can also be set in NimScripts using
`switch` or `--`, as shown in above examples. Only the `release` define
(`-d:release`) cannot be set in NimScripts.

## NimScript as a build tool

The `task` template that the `system` module defines allows a NimScript file to
be used as a build tool. The following example defines a task `build` that is an
alias for the `c` command:

``` {.sourceCode .nim
task build, "builds an example":
setCommand "c"}
```

In fact, as a convention the following tasks should be available:

  Task      Description
  --------- ---------------------------------------------------------------------
  `help`    List all the available NimScript tasks along with their docstrings.
  `build`   Build the project with the required backend (`c`, `cpp` or `js`).
  `tests`   Runs the tests belonging to the project.
  `bench`   Runs benchmarks belonging to the project.

If the task runs an external command via `exec` it should afterwards call
`setCommand "nop"` to tell the Nim compiler that nothing else needs to be done:

```nim
task tests, "test regular expressions":
  exec "nim c -r tests"
  setCommand "nop"
```

Look at the module [distros](distros.html) for some support of the OS\'s native
package managers.

## Nimble integration

See the [Nimble readme](https://github.com/nim-lang/nimble#readme) for more
information.

## Standalone NimScript

NimScript can also be used directly as a portable replacement for Bash and Batch
files. Use `nim e myscript.nims` to run `myscript.nims`. For example,
installation of Nimble could be accomplished with this simple script:

```nim
mode = ScriptMode.Verbose

var id = 0
while dirExists("nimble" & $id):
  inc id

exec "git clone https://github.com/nim-lang/nimble.git nimble" & $id

withDir "nimble" & $id & "/src":
  exec "nim c nimble"

mvFile "nimble" & $id & "/src/nimble".toExe, "bin/nimble".toExe
```

You can also use the shebang `#!/usr/bin/env nim`, as long as your filename ends
with `.nims`:

```nim
#!/usr/bin/env nim
mode = ScriptMode.Silent

echo "hello world"
```
