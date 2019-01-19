#[
Utilities for CI
]#

import os

let isTravis* = existsEnv("TRAVIS")
let isAppVeyor* = existsEnv("APPVEYOR")
let isAzure* = existsEnv("AZURE_HTTP_USER_AGENT") # CHECKME; for azure-pipelines.yml CI
let isRunningUnderCI* = isTravis or isAppVeyor or isAzure
