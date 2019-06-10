when true:
  #[
  PRTEMP D20190605T143639:here
  here so that it's effective for $nimc_D/compiler/nim.nim (eg $nimc_D/compiler/ast.nim)
  and for system/gc.nim

  $nimc_D/config/config.nims didn't work for both
  Note: patch in $nimc_D/config/nim.cfg still needed though (and we couldn't make it as a new file in $nimc_D/nim.cfg)
  ]#

  --listFullPaths:on
  # switch("import", "timn/echo_simple")

  # switch("warning", "[CaseTransition]:on")
