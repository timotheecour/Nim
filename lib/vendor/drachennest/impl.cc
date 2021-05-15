#include "schubfach_32.h"
#include "schubfach_64.h"
#include "dragonbox.h"

extern "C" char* nimtoStringDragonboxImplDouble(char* buffer, double value){
  return dragonbox::Dtoa(buffer, value);
}

extern "C" char* nimSchubfachFtoa(char* buffer, float value){
  return schubfach::Ftoa(buffer, value);
}

extern "C" char* nimSchubfachDtoa(char* buffer, double value){
  return schubfach::Dtoa(buffer, value);
}
