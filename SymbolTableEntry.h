#ifndef SYMBOL_TABLE_ENTRY_H
#define SYMBOL_TABLE_ENTRY_H

#include <string>
using namespace std;

class SYMBOL_TABLE_ENTRY 
{
private:
  // Member variables
  string name;
  int typeCode;
  int numParams;
  int returnType;

public:
  // Constructors
  SYMBOL_TABLE_ENTRY( ) { name = ""; typeCode = UNDEFINED; int numParams = 0 ; int returnType = UNDEFINED ; }

  SYMBOL_TABLE_ENTRY(const string theName, const int theType , int theNumParams = 0 , int theReturnType = UNDEFINED) 
  {
    name = theName;
    typeCode = theType;
    numParams = theNumParams;
    returnType = theReturnType;
  }

  // Accessors
  string getName() const { return name; }
  int getTypeCode() const { return typeCode; }
  int getNumParams() const { return numParams; }
  int getReturnType() const { return returnType; }
};

#endif  // SYMBOL_TABLE_ENTRY_H
