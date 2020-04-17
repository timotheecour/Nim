static: doAssert defined(js)

import unittest
import jscore

test "js DateTime":
  # compare behavior with times.DateTime
  let birthday = newDate("January 16, 2000 23:15:30".cstring)
  check birthday.getDay == 0
  check birthday.getMonth == 0
  check birthday.getMonthDay == 16
