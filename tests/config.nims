when defined(nimNimsNoimport):
  # In case we test locally without `--skipusercfg` (intentionally), and when
  # user has -d:nimNimsNoimport in his config.nims
  import system/nimscript

switch("path", "$nim/testament/lib") # so we can `import stdtest/foo` in this dir

## prevent common user config settings to interfere with testament expectations
## Indifidual tests can override this if needed to test for these options.
switch("colors", "off")
switch("listFullPaths", "off")
switch("excessiveStackTrace", "off")
