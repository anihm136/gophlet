%{
#include "common.h"
#include <stdio.h>

int TABLE_SIZE = 10009;
union NodeVal value;

typedef struct symbol_table {
    char name[31];
    char type[10];
    char value[10];
    int addr;
    int hcode;
  }ST;
  
 ST hashTable[10009];

struct Stack {
   char s[25][25];
   int top;
};
typedef struct Stack stack;
stack stack_i = {.top = -1};
stack stack_v = {.top = -1};

int* create(int size)
{
	return(malloc(sizeof(int)*size));
}

int stfull(stack st,int size) 
{
			if (st.top >= size - 1)
						return 1;
			else
						return 0;
}

void push(stack *p_st,char *item) 
{
			p_st->top++;
			strcpy(p_st->s[p_st->top], item);
}

int stempty(stack st) {
			if (st.top == -1)
						return 1;
			else
						return 0;
}

char * pop(stack *p_st) {
			char *item;
			item = p_st->s[p_st->top];
			p_st->top--;
			return (item);
}

int hash1(char *token) {
				
				int hash = 0;
				for (int i = 0; token[i] != '\0'; i++) 
				{ 
								hash = ( 256 * hash + token[i] ) % 1000000009; 
				}

				hash = hash % TABLE_SIZE;
				return hash;

}

int check(char *token) {
				
				int index1 = hash1(token); 
				int i = 0;
				while ( i < TABLE_SIZE && strcmp(hashTable[( index1 + i ) % TABLE_SIZE].name, token) != 0 )
								i++;

				if ( i == TABLE_SIZE )
								return 1;
				else
								return index1 + i;

}


void insert(char *token, char *type, char *value) {

  if (check(token) != 1) {
    printf("Error: %s is redeclared..!\n");
    exit(0);
    return;
  }
  int index = hash1(token);

  if (hashTable[index].hcode != -1) {

    int i = 1;
    while (1) {
      int newIndex = (index + i) % TABLE_SIZE;

      if (hashTable[newIndex].hcode == -1) {
        strcpy(hashTable[newIndex].name, token);
        strcpy(hashTable[newIndex].type, type);
        strcpy(hashTable[newIndex].value, value);
        hashTable[newIndex].hcode = 1;
        break;
      }
      i++;
    }
  }

  else {
    strcpy(hashTable[index].name, token);
    strcpy(hashTable[index].type, type);
    strcpy(hashTable[index].value, value);
    hashTable[index].hcode = 1;
  }
}

void search(char *token) {

				int index1 = hash1(token); 
				int i = 0;
				while ( i < TABLE_SIZE && strcmp(hashTable[( index1 + i ) % TABLE_SIZE].name, token)!=0 )
								i++;

				if ( i == TABLE_SIZE ) {
								printf("Error: %s is not defined\n", token);
								exit(0);
				}
				else
								return ;
}


void update(char *token, char *type, char *value) {
	int index = check(token);
	if ( index == 1 ) {
		printf("Error: %s is not defined\n", token);
		exit(0);
		return;
	}
	
	else {
		if (strcmp(hashTable[index].value, "NULL") != 0)
			strcpy(hashTable[index].value, value);
		if (strcmp(hashTable[index].type, "NULL") != 0)
			strcpy(hashTable[index].type, type);
	}
}

%}

%define api.value.type union
%define parse.error verbose
/* %define api.value.prefix {T_} */
%start SourceFile
/* %expect 11 */

%type <Node *> IdentifierList ExprList Expr Literal BasicLit Operand OperandName rel_op add_op mul_op UnaryExpr PrimaryExpr assign_op unary_op PackageName QualifiedID Assignment VarSpec VIdentifierListSuff VIdentifierListTypeSuff

%token <char const *> T_ID "identifier"
%token <int> L_INT "integer literal"
%token <double> L_FLOAT "float literal"
%token <char const *> L_RUNE "rune literal"
%token <char const *> L_STRING "string literal"

%token K_BREAK
%token K_DEFAULT
%token K_FUNC
%token K_INTERFACE
%token K_SELECT
%token K_CASE
%token K_DEFER
%token K_GO
%token K_MAP
%token K_STRUCT
%token K_CHAN
%token K_ELSE
%token K_GOTO
%token K_PACKAGE
%token K_SWITCH
%token K_CONST
%token K_FALLTHROUGH
%token K_IF
%token K_RANGE
%token K_TYPE
%token K_CONTINUE
%token K_FOR
%token K_IMPORT
%token K_RETURN
%token K_VAR

%token <char const *> O_ADDEQ
%token <char const *> O_ANDEQ
%token <char const *> O_LAND
%token <char const *> O_EQ
%token <char const *> O_NEQ
%token <char const *> O_SUBEQ
%token <char const *> O_OREQ
%token <char const *> O_LOR
%token <char const *> O_LT
%token <char const *> O_LEQ
%token <char const *> O_MULEQ
%token <char const *> O_XOREQ
%token <char const *> O_CHAN_DIR
%token <char const *> O_GT
%token <char const *> O_GEQ
%token <char const *> O_LSHIFT
%token <char const *> O_DIVEQ
%token <char const *> O_LSHIFTEQ
%token <char const *> O_INC
%token <char const *> O_ASSGN
%token <char const *> O_RSHIFT
%token <char const *> O_MODEQ
%token <char const *> O_RSHIFTEQ
%token <char const *> O_DEC
%token <char const *> O_ELLIPSES
%token <char const *> O_AMPXOR
%token <char const *> O_AMPXOREQ

%token P_TYPE
%token <char const *> P_CONST
%token P_NIL
%token <char const *> P_FUNC

%precedence EMPTY
%precedence NORMAL
%left O_LOR
%left O_LAND
%left O_EQ O_NEQ O_LT O_LEQ O_GT O_GEQ
%left '+' '-' '|' '^'
%left '*' '/' '%' O_LSHIFT O_RSHIFT '&' O_AMPXOR
%nonassoc O_CHAN_DIR
%right P_UNARY

%left   NotPackage
%left   K_PACKAGE

%left   NotParen
%left   '('

%left   ')'
%left   PreferToRightParen

%%

/* Top Level */
SourceFile :
					 PackageClause ImportDecls TopLevelDecls
					 {if (yychar != YYEOF) {printf("Invalid - reached start symbol before EOF\n")
; YYERROR;} printf("Valid\n"); YYACCEPT;}

;

/* Package */
PackageClause :
							K_PACKAGE PackageName
;

PackageName :
						T_ID
						{strcpy(value.name, $1); $$ = makeNode(ID, value, NULL, NULL);}
;

/* Import */
ImportDecls :
						ImportDecl ImportDecls %prec NORMAL
						| %empty %prec EMPTY
;

ImportDecl :
					 K_IMPORT ImportSpec
					 | K_IMPORT '(' ImportSpecList ')'
;

ImportSpecList :
							 ImportSpec ImportSpecList2
;

ImportSpecList2 :
								ImportSpec ImportSpecList2 %prec NORMAL
								| %empty %prec EMPTY
;

ImportSpec :
					 L_STRING
					 | '.' L_STRING
					 | PackageName L_STRING
;

/* Types */
Type :
		 TypeName 
		 | TypeLiteral 
		 | '(' Type ')'
;

TypeName :
				 P_TYPE
				 | QualifiedID
;
/*  */
TypeLiteral :
						ArrayType 
						| StructType 
						| PointerType 
						| SliceType 
/* 						| FunctionType  */
/* 						| InterfaceType  */
/* 						| MapType  */
/* 						| ChannelType */
;

QualifiedID :
						PackageName '.' T_ID
						{value.name[0] = 0; strcat(value.name, $1->value.name); strcat(value.name, "."); strcat(value.name, $3); $$ = makeNode(ID, value, NULL, NULL);}
;

ArrayType   :
						'[' ArrayLength ']' ElementType
;
ArrayLength :
						Expr
;
ElementType :
						Type
;

SliceType :
					'[' ']' ElementType
;

/* MapType     : */
/* 						K_MAP '[' KeyType ']' ElementType */
/* ; */
/* KeyType     : */
/* 						Type */
/* ; */
/*  */
/* ChannelType : */
/* 						ChanDirection ElementType */
/* ; */
/* ChanDirection : */
/* 							K_CHAN  */
/* 							| K_CHAN O_CHAN_DIR */
/* 							| O_CHAN_DIR K_CHAN */
/*  */
/* ; */
/*  */
StructType    :
							K_STRUCT '{' FieldDecls '}'
;
FieldDecls    :
							FieldDecl FieldDecls %prec NORMAL
							| %empty %prec EMPTY
;
FieldDecl     :
							FieldType FieldSuff
;
FieldSuff     :
							Tag %prec NORMAL
							| %empty %prec EMPTY
;
FieldType     :
							IdentifierList Type
							| EmbeddedField
;
EmbeddedField :
							TypeName
							| '*' TypeName
;
Tag           :
							L_STRING
;

PointerType :
						'*' Type
;

/* FunctionType   : */
/* 							 K_FUNC Signature */
/* ; */
Signature      :
							 Parameters SignatureSuff
;
SignatureSuff  :
							 Result %prec NORMAL
							 | %empty %prec EMPTY
;
Result         :
							 Parameters | Type
;
Parameters     :
							 '(' ParameterList ')'
;
ParameterList  :
							 ParameterDecl ParameterList2
							 | %empty
;
ParameterList2 :
							 ParameterList2 ',' ParameterDecl %prec NORMAL
							 | %empty %prec EMPTY
;
ParameterDecl  :
							 ParameterDeclPre Type
;
ParameterDeclPre :
								 IdentifierList PIdentifierListSuff %prec NORMAL
								 | O_ELLIPSES %prec NORMAL
								 | %empty %prec EMPTY
;
PIdentifierListSuff :
									 O_ELLIPSES %prec NORMAL
									 | %empty %prec EMPTY
;

/* InterfaceType      : */
/* 									 K_INTERFACE '{' InterfaceTypeList '}' */
/* ; */
/* InterfaceTypeList  : */
/* 									 InterfaceTypes InterfaceTypeList %prec NORMAL */
/* 									 | %empty %prec EMPTY */
/* ; */
/* InterfaceTypes     : */
/* 									 MethodSpec */
/* 									 | InterfaceTypeName */
/* ; */
/* MethodSpec         : */
/* 									 MethodName Signature */
/* ; */
MethodName         :
									 T_ID
;
/* InterfaceTypeName  : */
/* 									 TypeName */
/* ; */


/* Declarations */
TopLevelDecls :
							TopLevelDecl TopLevelDecls %prec NORMAL
							| %empty %prec EMPTY
;
TopLevelDecl  :
							Declaration 
							| FunctionDecl 
							| MethodDecl
;
Declaration   :
							ConstDecl 
							| TypeDecl 
							| VarDecl
;

FunctionDecl :
						 K_FUNC FunctionName Signature FunctionBody
;
FunctionName :
						 T_ID
;
FunctionBody :
						 Block
						 | %empty
;

MethodDecl :
					 K_FUNC Receiver MethodName Signature FunctionBody
;
Receiver   :
					 Parameters
;

ConstDecl :
					K_CONST ConstSpec
					| K_CONST '(' ConstSpecs ')'
;
ConstSpecs : ConstSpec
					 | ConstSpecs ConstSpec
;
ConstSpec :
					IdentifierList CIdentifierListSuff
;
CIdentifierListSuff :
										CIdentifierListSuffPre '=' ExprList
;
CIdentifierListSuffPre :
											 Type %prec NORMAL
											 | %empty %prec EMPTY
;

TypeDecl :
				 K_TYPE TypeSpecs
;
TypeSpecs :
					TypeSpec
					| '(' TypeSpecList ')'
;
TypeSpecList :
						 TypeSpec TypeSpecList %prec NORMAL
						 | %empty %prec EMPTY
;
TypeSpec :
				 AliasDecl 
				 | TypeDef
;
AliasDecl :
					T_ID '=' Type
;
TypeDef :
				T_ID Type
;

VarDecl :
				K_VAR VarSpec
				| K_VAR '(' VarSpecs ')'
;
VarSpecs : VarSpec
				 | VarSpecs VarSpec
;
VarSpec :
				IdentifierList VIdentifierListSuff
				{if($2) {printf("Assigning to variables\nIds: %d Exprs: %d\n", seqLen($1), seqLen($2->value.n)); value.op[0] = '='; value.op[1] = 0; $$ = makeNode(OP, value, $1, $2);} else {printf("Not assigning\n");$$ = NULL;}}
;
VIdentifierListSuff :
									 Type VIdentifierListTypeSuff
									 {$$ = $2;}
									 | '=' ExprList
									 {value.n = $2; $$ = makeNode(OP, value, NULL, NULL);}
;
VIdentifierListTypeSuff :
											 '=' ExprList %prec NORMAL 
											 {value.n = $2; $$ = makeNode(OP, value, NULL, NULL);}
											 | %empty %prec EMPTY 
											 {$$ = NULL;}
;

IdentifierList :
							 T_ID
							 {strcpy(value.name, $1); $$ = makeNode(ID, value, NULL, NULL); printf("Type: %d Value: %s\n", $$->type, $$->value.name);}
							 | IdentifierList ',' T_ID
							 {strcpy(value.name, $3); $$ = makeNode(SEQ, value, makeNode(ID, value, NULL, NULL), $1);}
;

/* Expressions */
ExprList :
				 Expr 
				 {$$ = $1;}
				 | ExprList ',' Expr
				 {$$ = makeNode(SEQ, value, $3, $1);}
;

/* binary_op  :
 O_LOR  */
/* 					 | O_LAND  */
/* 					 | rel_op  */
/* 					 | add_op  */
/* 					 | mul_op */
/* 					 
; */
rel_op     :
					 O_EQ 
					 {strcpy(value.op, $1); $$ = makeNode(OP, value, NULL, NULL); }
					 | O_NEQ
					 {strcpy(value.op, $1); $$ = makeNode(OP, value, NULL, NULL);}
					 | O_LT
					 {strcpy(value.op, $1); $$ = makeNode(OP, value, NULL, NULL);}
					 | O_LEQ
					 {strcpy(value.op, $1); $$ = makeNode(OP, value, NULL, NULL);}
					 | O_GT
					 {strcpy(value.op, $1); $$ = makeNode(OP, value, NULL, NULL);}
					 | O_GEQ
					 {strcpy(value.op, $1); $$ = makeNode(OP, value, NULL, NULL);}
;
add_op     :
					 '+' 
					 {value.op[0] = *((int*)&yylval); value.op[1] = 0; $$ = makeNode(OP, value, NULL, NULL);}
					 | '-' 
					 {value.op[0] = *((int*)&yylval); value.op[1] = 0; $$ = makeNode(OP, value, NULL, NULL);}
					 | '|' 
					 {value.op[0] = *((int*)&yylval); value.op[1] = 0; $$ = makeNode(OP, value, NULL, NULL);}
					 | '^'
					 {value.op[0] = *((int*)&yylval); value.op[1] = 0; $$ = makeNode(OP, value, NULL, NULL);}
;
mul_op     :
					 '*' 
					 {value.op[0] = *((int*)&yylval); value.op[1] = 0; $$ = makeNode(OP, value, NULL, NULL);}
					 | '/' 
					 {value.op[0] = *((int*)&yylval); value.op[1] = 0; $$ = makeNode(OP, value, NULL, NULL);}
					 | '%' 
					 {value.op[0] = *((int*)&yylval); value.op[1] = 0; $$ = makeNode(OP, value, NULL, NULL);}
					 | O_LSHIFT 
					 {strcpy(value.op, $1); $$ = makeNode(OP, value, NULL, NULL);}
					 | O_RSHIFT 
					 {strcpy(value.op, $1); $$ = makeNode(OP, value, NULL, NULL);}
					 | '&' 
					 {value.op[0] = *((int*)&yylval); value.op[1] = 0; $$ = makeNode(OP, value, NULL, NULL);}
					 | O_AMPXOR
					 {strcpy(value.op, $1); $$ = makeNode(OP, value, NULL, NULL);}
;
unary_op   :
					 '+' 
					 {value.op[0] = *((int*)&yylval); value.op[1] = 0; $$ = makeNode(OP, value, NULL, NULL);}
					 | '-' 
					 {value.op[0] = *((int*)&yylval); value.op[1] = 0; $$ = makeNode(OP, value, NULL, NULL);}
					 | '!' 
					 {value.op[0] = *((int*)&yylval); value.op[1] = 0; $$ = makeNode(OP, value, NULL, NULL);}
					 | '^' 
					 {value.op[0] = *((int*)&yylval); value.op[1] = 0; $$ = makeNode(OP, value, NULL, NULL);}
					 | '*' 
					 {value.op[0] = *((int*)&yylval); value.op[1] = 0; $$ = makeNode(OP, value, NULL, NULL);}
					 | '&' 
					 {value.op[0] = *((int*)&yylval); value.op[1] = 0; $$ = makeNode(OP, value, NULL, NULL);}
;

assign_op  :
					 O_ADDEQ
					 {strcpy(value.op, $1); $$ = makeNode(OP, value, NULL, NULL);}
					 | O_SUBEQ
					 {strcpy(value.op, $1); $$ = makeNode(OP, value, NULL, NULL);}
					 | O_OREQ
					 {strcpy(value.op, $1); $$ = makeNode(OP, value, NULL, NULL);}
					 | O_XOREQ
					 {strcpy(value.op, $1); $$ = makeNode(OP, value, NULL, NULL);}
					 | O_MULEQ
					 {strcpy(value.op, $1); $$ = makeNode(OP, value, NULL, NULL);}
					 | O_DIVEQ
					 {strcpy(value.op, $1); $$ = makeNode(OP, value, NULL, NULL);}
					 | O_MODEQ
					 {strcpy(value.op, $1); $$ = makeNode(OP, value, NULL, NULL);}
					 | O_ANDEQ
					 {strcpy(value.op, $1); $$ = makeNode(OP, value, NULL, NULL);}
					 | O_LSHIFTEQ
					 {strcpy(value.op, $1); $$ = makeNode(OP, value, NULL, NULL);}
					 | O_RSHIFTEQ
					 {strcpy(value.op, $1); $$ = makeNode(OP, value, NULL, NULL);}
					 | O_AMPXOREQ
					 {strcpy(value.op, $1); $$ = makeNode(OP, value, NULL, NULL);}
;

Expr :
		 Expr O_LOR Expr
		 {strcpy(value.op, $2); $$ = makeNode(OP, value, $1, $3);}
		 | Expr O_LAND Expr
		 {strcpy(value.op, $2); $$ = makeNode(OP, value, $1, $3);}
		 | Expr rel_op Expr %prec O_EQ
		 {strcpy(value.op, $2->value.op); $$ = makeNode(OP, value, $1, $3);}
		 | Expr add_op Expr %prec '+'
		 {strcpy(value.op, $2->value.op); $$ = makeNode(OP, value, $1, $3);}
		 | Expr mul_op Expr %prec '-'
		 {strcpy(value.op, $2->value.op); $$ = makeNode(OP, value, $1, $3);}
		 | UnaryExpr %prec P_UNARY
		 {$$ = $1;}
;
UnaryExpr :
					O_CHAN_DIR UnaryExpr
					{strcpy(value.op, $1); $$ = makeNode(OP, value, $2, NULL);}
					| unary_op UnaryExpr %prec P_UNARY
					{strcpy(value.op, $1->value.op); $$ = makeNode(OP, value, $2, NULL);}
					| PrimaryExpr
					{$$ = $1;}
;
PrimaryExpr :
						Operand
						{$$ = $1;}
						/* | PrimaryExpr Selector */
						| PrimaryExpr Index 
/* | PrimaryExpr Slice  */
						/* | PrimaryExpr TypeAssertion  */
						| PrimaryExpr Arguments 
;
/* Selector       : */
/*  '.' T_ID */
/* ; */
Index          :
							 '[' Expr ']'
;
/* Slice          :
 "[" [ Expression ] ":" [ Expression ] "]" | */
/* 							 :
	"[" [ Expression ] ":" Expression ":" Expression "]" . */
/* TypeAssertion  :
 "." "(" Type ")" . */
Arguments      :
							 '(' Args2 ArgsOp1 ArgsOp2 ')' 
;
Args2 :
			ExprList
			| Type
			| Type ',' ExprList
			| %empty
;
ArgsOp1 : 
				O_ELLIPSES
				| %empty
;
ArgsOp2 : 
				','
				| %empty
;

Operand     :
						Literal 
						{$$ = $1;}
						| OperandName 
						{$$ = $1;}
						| '(' Expr ')'
						{$$ = $2;}
						| P_NIL
						{value.n = NULL; $$ = makeNode(INT, value, NULL, NULL);}
						| P_CONST
						{value.b = strcmp($1, "true")==0 ? 1 : 0; $$ = makeNode(BOOL, value, NULL, NULL);}
;
Literal     :
						BasicLit 
						{$$ = $1;}
						/* | CompositeLit  */
						| FunctionLit
;
BasicLit    :
						L_INT
						{value.i = $1; $$ = makeNode(INT, value, NULL, NULL);}
						| L_FLOAT
						{value.f = $1; $$ = makeNode(FLOAT, value, NULL, NULL);}
						/* | imaginary_lit  */
						| L_RUNE
						{strcpy(value.str, $1); $$ = makeNode(RUNE, value, NULL, NULL);}
						| L_STRING
						{strcpy(value.str, $1); $$ = makeNode(STRING, value, NULL, NULL);}
;
FunctionLit : 
						K_FUNC Signature FunctionBody
;
OperandName :
						T_ID 
						{strcpy(value.name, $1); $$ = makeNode(ID, value, NULL, NULL);}
						| P_FUNC
						{strcpy(value.name, $1); $$ = makeNode(FUNC, value, NULL, NULL);}
						| QualifiedID
						{$$ = $1;}
;

/* Blocks and Statements */
Block :
			'{' StatementList '}'
;
StatementList :
							StatementList Statement %prec NORMAL
							| %empty %prec EMPTY
;

/* To be modified */
Statement :
					SimpleStmt
					| Declaration
					| ForStmt
					| IfStmt
					| ReturnStmt
;
SimpleStmt :
					ExprStmt 
					/* | SendStmt  */
					| IncDecStmt 
					| Assignment 
					| ShortVarDecl
					/* | EmptyStmt  */
;

/* EmptyStmt : */
/* 					%empty %prec EMPTY */
/* ; */

ExprStmt :
				 Expr
;

/* SendStmt : */
/* 				 Channel O_CHAN_DIR Expr */
/* ; */
Channel :
				Expr
;

IncDecStmt :
					 Expr O_INC
					 | Expr O_DEC
;

Assignment :
					 ExprList '=' ExprList
					 {printf("started\n"); value.op[0] = '='; value.op[1] = 0; printf("Operator: %s\n", value.op); $$ = makeNode(OP, value, $1, $3);}
					 | Expr assign_op Expr
					 {strcpy(value.op, $2->value.op); $$ = makeNode(OP, value, $1, $3);}
;

ShortVarDecl :
						 IdentifierList O_ASSGN ExprList
;

ForStmt : K_FOR
				OptionalForClause
				Block
;
OptionalForClause : 
									Condition %prec NORMAL
									| ForClause %prec NORMAL
									| RangeClause %prec NORMAL
									| %empty %prec EMPTY
Condition : 
					Expr
;
ForClause :
					OptionalForClauseInit ';' OptionalForClauseCondition ';' OptionalForClausePost
;
OptionalForClauseInit :
											InitStmt %prec NORMAL
											| %empty %prec EMPTY
;
OptionalForClauseCondition :
													 Condition
;
OptionalForClausePost :
											PostStmt %prec NORMAL
											| %empty %prec EMPTY
;
InitStmt :
				 SimpleStmt
;
PostStmt :
				 SimpleStmt
;
RangeClause :
						OptionalForRangePre K_RANGE Expr
;
OptionalForRangePre : 
										ExprList '=' %prec NORMAL
										| IdentifierList O_ASSGN %prec NORMAL
										| %empty %prec EMPTY
;

IfStmt : 
			 K_IF /* OptionalStmt */ Expr Block OptionalElse
;
/* OptionalStmt :  */
/* 						 SimpleStmt ';' */
/* 						 | %empty */
/* ; */
OptionalElse :
						 K_ELSE IfStmt
						 | K_ELSE Block
						 | %empty
;

ReturnStmt :
					 K_RETURN 
					 | K_RETURN ExprList
;

%%
extern int yylineno;

void yyerror(char const* error) {
	fprintf(stderr, "%d: %s\n", yylineno, error)
;
}

int main()
{
	for(int i=0; i<TABLE_SIZE; i++)
		hashTable[i].hcode = -1;
	/* yydebug = 1; */
	yyparse();
	return 0;
}
