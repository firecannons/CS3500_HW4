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

%type <text> T_IDENT
%type <typeInfo> N_CONST N_EXPR N_PARENTHESIZED_EXPR N_IF_EXPR N_LAMBDA_EXPR N_ARITHLOGIC_EXPR

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
      SYMBOL_TABLE_ENTRY temp;
      if (!findEntryInAnyScope(string $1, temp))
        yyerror("Undefined identifier");
      findEntryInAnyScope(string $1, temp);
      $$.type = temp.getTypeCode();
      }
    | T_LPAREN N_PARENTHESIZED_EXPR T_RPAREN
      {
      printRule("EXPR", "( PARENTHESIZED_EXPR )");
      $$.type = $2.type;
      $$.numParams = $2.numParams;
      $$.returnType = $2.returnType;
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
      printRule("CONST", "T");
      }          
          | T_NIL
      {
      printRule("CONST", "NIL");
      }
      ;
N_PARENTHESIZED_EXPR    : N_ARITHLOGIC_EXPR
      {
      printRule("PARENTHESIZED_EXPR", "ARITHLOGIC_EXPR");
      }
    | N_IF_EXPR
      {
      printRule("PARENTHESIZED_EXPR", "IF_EXPR");
      }
    | N_LET_EXPR
      {
      printRule("PARENTHESIZED_EXPR", "LET_EXPR");
      }
    | N_LAMBDA_EXPR
      {
      $$.type = $1.type;
      printRule("PARENTHESIZED_EXPR", "LAMBDA_EXPR");
      }
    | N_PRINT_EXPR
      {
      printRule("PARENTHESIZED_EXPR", "PRINT_EXPR");
      }
    | N_INPUT_EXPR
      {
      printRule("PARENTHESIZED_EXPR", "INPUT_EXPR");
      }
    | N_EXPR_LIST 
      {
      printRule("PARENTHESIZED_EXPR", "EXPR_LIST");
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
            if ( $2.type != INT && $2.type != STR)
            {
                  yyerror("Arg 1 must be integer");
                  exit(1);
            }
            if ( $3.type != INT && $3.type != STR)
            {
                  yyerror("Arg 2 must be integer");
                  exit(1);
            }
      }
    ;
N_IF_EXPR               : T_IF N_EXPR N_EXPR N_EXPR
      {
      printRule("IF_EXPR", "IF EXPR EXPR EXPR");
      };
N_LET_EXPR              : T_LETSTAR T_LPAREN N_ID_EXPR_LIST T_RPAREN N_EXPR
      {
      printRule("LET_EXPR", "let* ( ID_EXPR_LIST ) EXPR");
      endScope();
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
      if (!scopeStack.top().addEntry(SYMBOL_TABLE_ENTRY($3, UNDEFINED)))
      	yyerror("Multiply defined identifier");
      else
      	scopeStack.top().addEntry(SYMBOL_TABLE_ENTRY($3, UNDEFINED));
      }
      ;
N_LAMBDA_EXPR           : T_LAMBDA T_LPAREN N_ID_LIST T_RPAREN N_EXPR
      {
      $$.type = FUNCTION;
      printRule("LAMBDA_EXPR", "LAMBDA ( ID_LIST ) EXPR");
      endScope();
      }
      ;
N_ID_LIST               : /* epsilon */
      {
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
      }
      ;
N_PRINT_EXPR            : T_PRINT N_EXPR
      {
      printRule("PRINT_EXPR", "PRINT EXPR");
      }
      ;
N_INPUT_EXPR            : T_INPUT
      {
      printRule("INPUT_EXPR", "INPUT");
      }
      ;

N_EXPR_LIST             : N_EXPR N_EXPR_LIST
      {
      printRule("EXPR_LIST", "EXPR EXPR_LIST");
      }
    | N_EXPR
      {
      printRule("EXPR_LIST", "EXPR");
      }
      ;
N_BIN_OP                : N_ARITH_OP
      {
      printRule("BIN_OP", "ARITH_OP");
      }
    | N_LOG_OP
      {
      printRule("BIN_OP", "LOG_OP");
      }
    | N_REL_OP
      {
      printRule("BIN_OP", "REL_OP");
      }
      ;
N_ARITH_OP              : T_MULT
      {
      printRule("ARITH_OP", "*");
      }
    | T_SUB
      {
      printRule("ARITH_OP", "-");
      }
    | T_DIV
      {
      printRule("ARITH_OP", "/");
      }
    | T_ADD
      {
      printRule("ARITH_OP", "+");
      }
      ;
N_LOG_OP                : T_AND
      {
      printRule("LOG_OP", "and");
      }
    | T_OR
      {
      printRule("LOG_OP", "or");
      }
      ;
N_REL_OP                : T_LT
      {
      printRule("REL_OP", "<");
      }
    | T_GT
      {
      printRule("REL_OP", ">");
      }
    | T_LE
      {
      printRule("REL_OP", "<=");
      }
    | T_GE
      {
      printRule("REL_OP", ">=");
      }
    | T_EQ
      {
      printRule("REL_OP", "=");
      }
    | T_NE
      {
      printRule("REL_OP", "/=");
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
