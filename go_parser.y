%{
#include "common.h"
%}

%define api.value.type union
%define parse.error verbose
/* %define api.value.prefix {T_} */
%start SourceFile

%token <char const *> T_ID "identifier"
%token <int> L_INT "integer"
%token <double> L_FLOAT "float"
%token <char const *> L_RUNE "rune"
%token <char const *> L_STRING "string"
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
%token O_ADDEQ
%token O_ANDEQ
%token O_LAND
%token O_EQ
%token O_NEQ
%token O_SUBEQ
%token O_OREQ
%token O_LOR
%token O_LT
%token O_LEQ
%token O_MULEQ
%token O_XOREQ
%token O_CHAN_DIR
%token O_GT
%token O_GEQ
%token O_LSHIFT
%token O_DIVEQ
%token O_LSHIFTEQ
%token O_INC
%token O_ASSGN
%token O_RSHIFT
%token O_MODEQ
%token O_RSHIFTEQ
%token O_DEC
%token O_ELLIPSES
%token O_AMPXOR
%token O_AMPXOREQ

%%

/* Top Level */
SourceFile : PackageClause ImportDecls TopLevelDecls
					 {if (yychar != YYEOF) {printf("Invalid\n"); YYERROR;} printf("Valid\n"); YYACCEPT;}
		 ;

/* Package */
PackageClause : K_PACKAGE PackageName;

PackageName : T_ID;

/* Import */
ImportDecls : %empty
						| ImportDecl ImportDecls
						;

ImportDecl : K_IMPORT ImportSpec
					 | K_IMPORT '(' ImportSpecList ')'
					 ;

ImportSpecList : ImportSpec ImportSpecList2
							 ;

ImportSpecList2 : ImportSpec ImportSpecList2
								| %empty
								;

ImportSpec : L_STRING
					 | '.' L_STRING
					 | PackageName L_STRING
					 ;

/* Types */
Type : TypeName 
		 | TypeLiteral 
		 | '(' Type ')'
		 ;

TypeName : T_ID
				 | QualifiedID
				 ;

TypeLiteral : ArrayType 
						| StructType 
						| PointerType 
						| FunctionType 
						| InterfaceType 
						| SliceType 
						| MapType 
						| ChannelType
						;

QualifiedID : PackageName '.' T_ID;

ArrayType   : '[' ArrayLength ']' ElementType;
ArrayLength : Expr;
ElementType : Type;

SliceType : '[' ']' ElementType;

MapType     : K_MAP '[' KeyType ']' ElementType;
						KeyType     : Type;

ChannelType : ChanDirection ElementType;
ChanDirection : K_CHAN 
							| K_CHAN O_CHAN_DIR
							| O_CHAN_DIR K_CHAN
							;

StructType    : K_STRUCT '{' FieldDecls '}';
FieldDecls    : FieldDecl FieldDecls
							| %empty
							;
FieldDecl     : FieldType FieldSuff;
FieldSuff     : %empty
							| Tag
							;
FieldType     : IdentifierList Type
							| EmbeddedField
							;
EmbeddedField : TypeName
							| '*' TypeName
							;
Tag           : L_STRING;

PointerType : '*' Type;

FunctionType   : K_FUNC Signature;
Signature      : Parameters SignatureSuff;
SignatureSuff  : %empty
							 | Result
							 ;
Result         : Parameters | Type
Parameters     : '(' ParameterList ')';
ParameterList  : %empty
							 | ParameterDecl ParameterList2
							 ;
ParameterList2 : %empty
							 | ParameterDecl ',' ParameterList2
							 ;
ParameterDecl  : ParameterDeclPre Type;
ParameterDeclPre : %empty
								 | IdentifierList IdentifierListSuff
								 | O_ELLIPSES
								 ;
IdentifierListSuff : %empty
								 | O_ELLIPSES
								 ;

InterfaceType      : K_INTERFACE '{' InterfaceTypeList '}';
InterfaceTypeList  : InterfaceTypes InterfaceTypeList
									 | %empty
									 ;
InterfaceTypes     : MethodSpec
									 | InterfaceTypeName
									 ;
MethodSpec         : MethodName Signature;
MethodName         : T_ID;
InterfaceTypeName  : TypeName;


/* Declarations */
TopLevelDecls : %empty
							| TopLevelDecl TopLevelDecls
							;
TopLevelDecl  : Declaration 
							| FunctionDecl 
							| MethodDecl
							;
Declaration   : ConstDecl 
							| TypeDecl 
							| VarDecl
							;

FunctionDecl : K_FUNC FunctionName Signature FunctionBody;
FunctionName : T_ID;
FunctionBody : %empty
						 | Block
						 ;

MethodDecl : K_FUNC Receiver MethodName Signature FunctionBody;
Receiver   : Parameters;

ConstDecl : K_CONST ConstSpec
					| K_CONST '(' ConstSpec ')'
					;
ConstSpec : IdentifierList CIdentifierListSuff;
CIdentifierListSuff : CIdentifierListSuffPre '=' ExprList;
CIdentifierListSuffPre : %empty
											 | Type
											 ;

TypeDecl : K_TYPE TypeSpecs;
TypeSpecs : TypeSpec
					| '(' TypeSpecList ')'
					;
TypeSpecList : TypeSpec TypeSpecList
						 | %empty
						 ;
TypeSpec : AliasDecl 
				 | TypeDef
				 ;
AliasDecl : T_ID '=' Type;
TypeDef : T_ID Type;

VarDecl : K_VAR VarSpec
				| K_VAR '(' VarSpec ')'
				;
VarSpec : IdentifierList IdentifierListSuff;
IdentifierListSuff : %empty
									 | Type IdentifierListTypeSuff
									 | '=' ExprList
									 ;
IdentifierListTypeSuff : %empty
											 | "=" ExprList
											 ;

IdentifierList : T_ID IdentifierList2;
IdentifierList2 : IdentifierList2 ',' T_ID 
								| %empty
								;

/* Expressions */
ExprList : Expr ExprList2;
ExprList2 : ExprList2 ',' Expr
					| %empty
					;

/* binary_op  : O_LOR  */
/* 					 | O_LAND  */
/* 					 | rel_op  */
/* 					 | add_op  */
/* 					 | mul_op */
/* 					 ; */
rel_op     : O_EQ 
					 | O_NEQ
					 | O_LT
					 | O_LEQ
					 | O_GT
					 | O_GEQ
					 ;
add_op     : '+' 
					 | '-' 
					 | '|' 
					 | '^'
					 ;
mul_op     : '*' 
					 | '/' 
					 | '%' 
					 | O_LSHIFT 
					 | O_RSHIFT 
					 | '&' 
					 | "&^"
					 ;
unary_op   : '+' 
					 | '-' 
					 | '!' 
					 | '^' 
					 | '*' 
					 | '&' 
					 | O_CHAN_DIR
					 ;
assign_op  : O_ADDEQ
					 | O_SUBEQ
					 | O_OREQ
					 | O_XOREQ
					 | O_MULEQ
					 | O_DIVEQ
					 | O_MODEQ
					 | O_ANDEQ
					 | O_LSHIFTEQ
					 | O_RSHIFTEQ
					 | O_AMPXOREQ
					 ;

Expr : Expr O_LOR Land
		 | Sum
		 ;
Land : Land O_LAND Lcomp
		 | Lcomp
		 ;
Lcomp : Lcomp rel_op Sum
			| Sum
			;
Sum  : Sum add_op Prod
		 | Prod
		 ;
Prod : Prod mul_op UnaryExpr
		 | UnaryExpr
		 ;
UnaryExpr : unary_op UnaryExpr
					| PrimaryExpr
					;
PrimaryExpr : Operand
						| PrimaryExpr Selector
						| PrimaryExpr Index 
						;
						/* | PrimaryExpr Slice  */
						/* | PrimaryExpr TypeAssertion  */
						/* | PrimaryExpr Arguments ; */
Selector       : '.' T_ID;
Index          : '[' Expr ']';
/* Slice          : "[" [ Expression ] ":" [ Expression ] "]" | */
/* 							 :	"[" [ Expression ] ":" Expression ":" Expression "]" . */
/* TypeAssertion  : "." "(" Type ")" . */
/* Arguments      : "(" [ ( ExpressionList | Type [ "," ExpressionList ] ) [ O_ELLIPSES ] [ "," ] ] ")" . */

Operand     : Literal 
						| OperandName 
						| '(' Expr ')'
						;
Literal     : BasicLit 
						/* | CompositeLit  */
						/* | FunctionLit */
						;
BasicLit    : L_INT
						| L_FLOAT
						/* | imaginary_lit  */
						| L_RUNE
						| L_STRING
						;
OperandName : T_ID
						| QualifiedID
						;

/* Blocks and Statements */
Block : '{' StatementList '}';
StatementList : Statement StatementList 
							/* | %empty */
							;

/* To be modified */
Statement : SimpleStmt;
SimpleStmt : EmptyStmt 
					| ExprStmt 
					| SendStmt 
					| IncDecStmt 
					| Assignment 
					| ShortVarDecl
					;

EmptyStmt : %empty;

ExprStmt : Expr;

SendStmt : Channel O_CHAN_DIR Expr;
Channel : Expr;

IncDecStmt : Expr O_INC
					 | Expr O_DEC
					 ;

Assignment : ExprList assign_op ExprList;

ShortVarDecl : IdentifierList O_ASSGN ExprList;
%%
void yyerror(char const* error) {
	fprintf(stderr, "%s\n", error);
}

int main()
{
yydebug = 1;
yyparse();
return 0;
}
