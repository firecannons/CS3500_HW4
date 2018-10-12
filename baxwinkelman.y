/*
	baxz.y

        flex baxz.l
        bison baxz.y
        g++ baxz.tab.c -o parser
        parser < let_noErrors.txt > myoutput.out
        diff myoutput.out fileName.txt.out --ignore-space-change --side-by-side --ignore-case --ignore-blank-lines --color
        python3 Runner.py out HW4_sample_input HW4_expected_output
 */

%{
#include <stdio.h>
#include <string.h>
#include <string>
#include <stack>
#include <map>
#include <iostream>

#define UNDEFINED  -1   // Type codes
#define FUNCTION 0
#define INT 1
#define STR 2
#define INT_OR_STR 3
#define BOOL 4
#define INT_OR_BOOL 5
#define STR_OR_BOOL 6
#define INT_OR_STR_OR_BOOL 7
#define NOT_APPLICABLE -1

typedef struct
{
  int type;       // one of the above type codes
  int numParams;  // numParams and returnType only applicableif type == FUNCTION
  int returnType;
} TYPE_INFO;

#include "SymbolTable.h"

stack<SYMBOL_TABLE> scopeStack;

int numLines = 1; 

void printRule(const char *lhs, const char *rhs);
int yyerror(const char *s);
void printTokenInfo(const char* tokenType, const char* lexeme);
void beginScope( );
void endScope( );
bool findEntryInAnyScope(const string theName, SYMBOL_TABLE_ENTRY & temp);
bool isBitSet(int value, int shift) 
{
    bool output = false ;
    if (value & (1 << (shift - 1))) 
        output = true ;
    return output ;
}

extern "C" 
{
  int yyparse(void);
  int yylex(void);
  int yywrap() { return 1; }
}

%}

%union
{
  char* text;
  TYPE_INFO typeInfo;
};

/* Token declarations */
%token T_IDENT
%token T_LPAREN
%token T_RPAREN
%token T_INTCONST
%token T_STRCONST
%token T_T
%token T_NIL
%token T_IF
%token T_LETSTAR
%token T_LAMBDA
%token T_PRINT
%token T_INPUT
%token T_MULT
%token T_SUB
%token T_DIV
%token T_ADD
%token T_AND
%token T_OR
%token T_LT
%token T_GT
%token T_LE
%token T_GE
%token T_EQ
%token T_NE
%token T_NOT

%type <text> T_IDENT N_BIN_OP N_ARITH_OP N_LOG_OP N_REL_OP
%type <typeInfo> N_CONST N_EXPR N_PARENTHESIZED_EXPR N_IF_EXPR N_LAMBDA_EXPR N_ARITHLOGIC_EXPR N_LET_EXPR N_INPUT_EXPR N_PRINT_EXPR N_EXPR_LIST N_ID_LIST

/* Starting point */
%start		N_START

/* Translation rules */
%% 

N_START		: N_EXPR
			{
			printRule("START", "EXPR");
			printf("\n---- Completed parsing ----\n\n");
			return 0;
			}
			;
N_EXPR    : N_CONST
      {
      $$.type = $1.type;
      printRule("EXPR", "CONST");
      }
    | T_IDENT
      {
      printRule("EXPR", "IDENT");
      /*cout << "printing symbol table" << endl ;
      map<string, SYMBOL_TABLE_ENTRY>::iterator it;
      for ( it = scopeStack.top().hashTable.begin(); it != scopeStack.top().hashTable.end(); it++ )
      {
          std::cout << it->first  // string (key)
                    << ": ("
                    << it->second.getName() << " "   // string's value 
                    << it->second.getTypeCode() << " "
                    << it->second.getNumParams() << " "
                    << it->second.getReturnType() << " ) "
                    << std::endl ;
      }*/
      
      SYMBOL_TABLE_ENTRY temp;
      if (!findEntryInAnyScope(string $1, temp))
        yyerror("Undefined identifier");
      findEntryInAnyScope(string $1, temp);
      $$.type = temp.getTypeCode();
      $$.numParams = temp.getNumParams();
      $$.returnType = temp.getReturnType();
      //cout << "resolving " << $1 << " " << $$.type << " " << temp.getTypeCode() << " " << temp.getNumParams() << " " << temp.getReturnType() << endl ;
      }
    | T_LPAREN N_PARENTHESIZED_EXPR T_RPAREN
      {
      printRule("EXPR", "( PARENTHESIZED_EXPR )");
      //cout << $2.type << " = $2.type " << endl ;
      $$.type = $2.type;
      $$.numParams = $2.numParams;
      $$.returnType = $2.returnType;
      //cout << $$.numParams << endl ;
      }
      ;
N_CONST   : T_INTCONST
      {
      printRule("CONST", "INTCONST");
      $$.type = INT;
      $$.numParams = NOT_APPLICABLE;
      $$.returnType = NOT_APPLICABLE;
      }
          | T_STRCONST
      {
      printRule("CONST", "STRCONST");   
      $$.type = STR;   
      $$.numParams = NOT_APPLICABLE;
      $$.returnType = NOT_APPLICABLE;   
      }
          | T_T
      {
      printRule("CONST", "t");
      $$.type = BOOL;
      }          
          | T_NIL
      {
      printRule("CONST", "nil");
      $$.type = BOOL;
      }
      ;
N_PARENTHESIZED_EXPR    : N_ARITHLOGIC_EXPR
      {
      printRule("PARENTHESIZED_EXPR", "ARITHLOGIC_EXPR");
      $$.type = $1.type;
      }
    | N_IF_EXPR
      {
      printRule("PARENTHESIZED_EXPR", "IF_EXPR");
      $$.type = $1.type;
      }
    | N_LET_EXPR
      {
      printRule("PARENTHESIZED_EXPR", "LET_EXPR");
      $$.type = $1.type;
      }
    | N_LAMBDA_EXPR
      {
      printRule("PARENTHESIZED_EXPR", "LAMBDA_EXPR");
      $$.type = $1.type;
      $$.returnType = $1.returnType;
      $$.numParams = $1.numParams;
      //cout << $$.numParams << endl ;
      }
    | N_PRINT_EXPR
      {
      printRule("PARENTHESIZED_EXPR", "PRINT_EXPR");
      $$.type = $1.type;
      }
    | N_INPUT_EXPR
      {
      printRule("PARENTHESIZED_EXPR", "INPUT_EXPR");
      $$.type = $1.type;
      }
    | N_EXPR_LIST 
      {
      printRule("PARENTHESIZED_EXPR", "EXPR_LIST");
      $$.type = $1.type;
      }
    ;
N_ARITHLOGIC_EXPR      : N_UN_OP N_EXPR
      {
      printRule("ARITHLOGIC_EXPR", "UN_OP EXPR");
      if ($2.type == FUNCTION)
      {
            yyerror("Arg 1 cannot be function");
            return(1);
      }
      $$.type = BOOL;
      $$.numParams = NOT_APPLICABLE;
      $$.returnType = NOT_APPLICABLE;
      }
    | N_BIN_OP N_EXPR N_EXPR
      {
            printRule("ARITHLOGIC_EXPR", "BIN_OP EXPR EXPR");
            //cout << $1 << " " << strcmp ( $1 , "<") << " " << ( strcmp ( $1 , "<") != 0 || strcmp ( $1 , ">") != 0 || strcmp ( $1 , "<=") != 0 || strcmp ( $1 , ">=") != 0 || strcmp ( $1 , "=") != 0 || strcmp ( $1 , "/=") != 0 ) << endl ;
            if ( strcmp ( $1 , "<") == 0 || strcmp ( $1 , ">") == 0 || strcmp ( $1 , "<=") == 0 || strcmp ( $1 , ">=") == 0 || strcmp ( $1 , "=") == 0 || strcmp ( $1 , "/=") == 0 )
            {
                  if ( isBitSet ( $2.type , 1 ) )
                  {
                        if ( ! isBitSet ( $3.type , 1 ) )
                        {
                              yyerror("Arg 2 must be integer or string");
                              exit(1);
                        }
                  }
                  else if ( isBitSet ( $2.type , 2 ) )
                  {
                        if ( !isBitSet ( $3.type , 2 ) )
                        {
                              yyerror("Arg 2 must be integer or string");
                              exit(1);
                        }
                  }
                  else
                  {
                       yyerror("Arg 1 must be integer or string");
                       exit(1); 
                  }
            }
            if ( strcmp ( $1 , "*") == 0 || strcmp ( $1 , "+") == 0 || strcmp ( $1 , "-") == 0 || strcmp ( $1 , "/") == 0 )
            {
                  if ( !isBitSet ( $2.type , 1 )  )
                  {
                       yyerror("Arg 1 must be integer");
                       exit(1); 
                  }
                  else if ( !isBitSet ( $3.type , 1 )  )
                  {
                       yyerror("Arg 2 must be integer");
                       exit(1); 
                  }
            }
            if ( strcmp ( $1 , "and") == 0 || strcmp ( $1 , "or") == 0 )
            {
                  if ( $2.type == FUNCTION )
                  {
                        yyerror("Arg 1 cannot be function");
                        exit(1); 
                  }
                  else if ( $3.type == FUNCTION  )
                  {
                        yyerror("Arg 2 cannot be function");
                        exit(1); 
                  }  
            }
      }
    ;
N_IF_EXPR               : T_IF N_EXPR N_EXPR N_EXPR
      {
      printRule("IF_EXPR", "if EXPR EXPR EXPR");
      if ( $2.type == FUNCTION )
      {
            yyerror("Arg 1 cannot be function");
            exit(1);
      }
      else if ( $3.type == FUNCTION )
      {
            yyerror("Arg 2 cannot be function");
            exit(1);
      }
      else if ( $4.type == FUNCTION )
      {
            yyerror("Arg 3 cannot be function");
            exit(1);
      }
      };
N_LET_EXPR              : T_LETSTAR T_LPAREN N_ID_EXPR_LIST T_RPAREN N_EXPR
      {
      printRule("LET_EXPR", "let* ( ID_EXPR_LIST ) EXPR");
      endScope();
      //cout << $5.type << " = $5.type" << endl ;
      if ( $5.type == FUNCTION )
      {
            yyerror("Arg 2 cannot be function");
            exit(1);
      }
      $$.type = $5.type;
      }
    ;
N_ID_EXPR_LIST          : /* epsilon */
      {
      printRule("ID_EXPR_LIST", "epsilon");
      }
    | N_ID_EXPR_LIST T_LPAREN T_IDENT N_EXPR T_RPAREN
      {
      printRule("ID_EXPR_LIST", "ID_EXPR_LIST ( IDENT EXPR )");
      printf("___Adding %s to symbol table\n", $3);
      if (!scopeStack.top().addEntry(SYMBOL_TABLE_ENTRY($3, $4.type, $4.numParams, $4.returnType)))
      	yyerror("Multiply defined identifier");
      else
      	scopeStack.top().addEntry(SYMBOL_TABLE_ENTRY($3, $4.type));
      //cout << $4.type << endl ;
      }
      ;
N_LAMBDA_EXPR           : T_LAMBDA T_LPAREN N_ID_LIST T_RPAREN N_EXPR
      {
      printRule("LAMBDA_EXPR", "lambda ( ID_LIST ) EXPR");
      endScope();
      if ( $5.type == FUNCTION )
      {
            yyerror("Arg 2 cannot be function");
            exit(1);
      }
      else
      {
            $$.type = FUNCTION;
            $$.numParams = $3.numParams;
            $$.returnType = $5.type;
            //cout << "number params = " << $$.numParams << endl ;
      }
      }
      ;
N_ID_LIST               : /* epsilon */
      {
      $$.numParams = 0;
      printRule("ID_LIST", "epsilon");
      }
    | N_ID_LIST T_IDENT
      {
      printRule("ID_LIST", "ID_LIST IDENT");
      printf("___Adding %s to symbol table\n", $2);
      if (!scopeStack.top().addEntry(SYMBOL_TABLE_ENTRY($2, INT)))
      	yyerror("Multiply defined identifier");
      else
      	scopeStack.top().addEntry(SYMBOL_TABLE_ENTRY($2, INT));
      $$.numParams = $1.numParams + 1 ;
      //cout << $1.numParams << " plus 1 makes " << $$.numParams << endl ;
      }
      ;
N_PRINT_EXPR            : T_PRINT N_EXPR
      {
            printRule("PRINT_EXPR", "print EXPR");
            /*SYMBOL_TABLE_ENTRY temp;
            if (!findEntryInAnyScope(string ( $2.name ), temp))
              yyerror("Undefined identifier");
            findEntryInAnyScope(string($2.name), temp);*/
            //cout << $2.type << endl;
            if ( $2.type == FUNCTION )
            {
                  yyerror("Arg 1 cannot be function");
                  exit(1); 
            }
            $$.type = $2.type;
      }
      ;
N_INPUT_EXPR            : T_INPUT
      {
      $$.type = INT_OR_STR;
      printRule("INPUT_EXPR", "input");
      }
      ;

N_EXPR_LIST             : N_EXPR N_EXPR_LIST
      {
      printRule("EXPR_LIST", "EXPR EXPR_LIST");
      //cout << $1.type << " " << $2.type << " " << $1.returnType << " " << $2.returnType << endl ;
      if ( $2.type == FUNCTION )
      {
            yyerror("Arg 2 cannot be function");
            exit(1); 
      }
      else if ( $1.type == FUNCTION )
      {
            //cout << " checking param numbers " << $1.numParams << " " << $2.numParams << endl ;
            if ( $1.numParams < $2.numParams )
            {
                  yyerror("Too many parameters in function call");
                  exit(1); 
            }
            else if ( $2.numParams < $1.numParams )
            {
                  yyerror("Too few parameters in function call");
                  exit(1); 
            }
            $$.type = $1.returnType ;
      }
      else
      {
            $$.numParams = $2.numParams + 1 ;
            $$.type = $1.type ;
      }
      }
    | N_EXPR
      {
      printRule("EXPR_LIST", "EXPR");
      if ( $1.type == FUNCTION )
      {
            $$.type = $1.returnType ;
      }
      else
      {
            $$.numParams = 1;
            $$.type = $1.type;
      }
      //cout << $$.type << " = $$.type " << endl ;
      }
      ;
N_BIN_OP                : N_ARITH_OP
      {
      printRule("BIN_OP", "ARITH_OP");
      $$ = $1;
      }
    | N_LOG_OP
      {
      printRule("BIN_OP", "LOG_OP");
      $$ = $1;
      }
    | N_REL_OP
      {
      printRule("BIN_OP", "REL_OP");
      $$ = $1;
      }
      ;
N_ARITH_OP              : T_MULT
      {
      printRule("ARITH_OP", "*");
      $$ = "*";
      }
    | T_SUB
      {
      printRule("ARITH_OP", "-");
      $$ = "-";
      }
    | T_DIV
      {
      printRule("ARITH_OP", "/");
      $$ = "/";
      }
    | T_ADD
      {
      printRule("ARITH_OP", "+");
      $$ = "+";
      }
      ;
N_LOG_OP                : T_AND
      {
      printRule("LOG_OP", "and");
      $$ = "and";
      }
    | T_OR
      {
      printRule("LOG_OP", "or");
      $$ = "or";
      }
      ;
N_REL_OP                : T_LT
      {
      printRule("REL_OP", "<");
      $$ = "<";
      }
    | T_GT
      {
      printRule("REL_OP", ">");
      $$ = ">";
      }
    | T_LE
      {
      printRule("REL_OP", "<=");
      $$ = "<=";
      }
    | T_GE
      {
      printRule("REL_OP", ">=");
      $$ = ">=";
      }
    | T_EQ
      {
      printRule("REL_OP", "=");
      $$ = "=";
      }
    | T_NE
      {
      printRule("REL_OP", "/=");
      $$ = "/=";
      }
      ;
N_UN_OP                 : T_NOT
      {
      printRule("UN_OP", "not");
      }
    ;

%%

#include "lex.yy.c"
extern FILE *yyin;

void printRule(const char *lhs, const char *rhs) 
{
  printf("%s -> %s\n", lhs, rhs);
  return;
}

int yyerror(const char *s) 
{
  printf("Line %d: %s\n", numLines, s);
  exit(1);
  // return(1);
}

void printTokenInfo(const char* tokenType, const char* lexeme) 
{
  printf("TOKEN: %s  LEXEME: %s\n", tokenType, lexeme);
}

int main() 
{
  do 
  {
	yyparse();
  } while (!feof(yyin));

  return(0);
}

void beginScope( )
{
  scopeStack.push(SYMBOL_TABLE( ));
  printf("\n___Entering new scope...\n\n");
} 

void endScope( )
{
  scopeStack.pop( );
  printf("\n___Exiting scope...\n\n");
}

bool findEntryInAnyScope(const string theName, SYMBOL_TABLE_ENTRY & temp) 
{
  if (scopeStack.empty( )) 
    return(false);
  bool found = scopeStack.top( ).findEntry(theName, temp);
  if (found)
    return(true);
  else
  {    
    // check in "next higher" scope
    SYMBOL_TABLE symbolTable = scopeStack.top( );
    scopeStack.pop( );
    found = findEntryInAnyScope(theName, temp);
    scopeStack.push(symbolTable); // restore the stack
    return(found);
  } 
}
