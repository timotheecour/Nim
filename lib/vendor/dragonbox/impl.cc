#include "dragonbox/dragonbox_to_chars.h"

extern "C" char* nimtoStringDragonbox0ImplDouble(char* buffer, double value){
  return jkj::dragonbox::to_chars_n(value, buffer);
  // could also pass options, eg: `jkj::dragonbox::policy::cache::compressed`
}

extern "C" char* nimtoStringDragonbox0ImplFloat(char* buffer, float value){
  return jkj::dragonbox::to_chars_n(value, buffer);
}
