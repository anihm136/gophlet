%{
#include "common.h"
%}

%define api.value.type union
%define parse.error verbose
/* %define api.value.prefix {T_} */
%start SourceFile

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

%precedence EMPTY
%precedence NORMAL
%left O_LOR
%left O_LAND
%left O_EQ O_NEQ O_LT O_LEQ O_GT O_GEQ
%left '+' '-' '|' '^'
%left '*' '/' '%' O_LSHIFT O_RSHIFT '&' O_AMPXOR
%right P_UNARY

%%

/* Top Level */
SourceFile :
					 PackageClause ImportDecls TopLevelDecls
					 {if (yychar != YYEOF) {printf("Invalid\n")
; YYERROR;} printf("Valid\n"); YYACCEPT;}

;

/* Package */
PackageClause :
							K_PACKAGE PackageName
;

PackageName :
						T_ID
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
				 T_ID
				 | QualifiedID
;

TypeLiteral :
						ArrayType 
						| StructType 
						| PointerType 
						| FunctionType 
						| InterfaceType 
						| SliceType 
						| MapType 
						| ChannelType
;

QualifiedID :
						PackageName '.' T_ID
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

MapType     :
						K_MAP '[' KeyType ']' ElementType
;
KeyType     :
						Type
;

ChannelType :
						ChanDirection ElementType
;
ChanDirection :
							K_CHAN 
							| K_CHAN O_CHAN_DIR
							| O_CHAN_DIR K_CHAN

;

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

FunctionType   :
							 K_FUNC Signature
;
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
							 ParameterDecl ',' ParameterList2 %prec NORMAL
							 | %empty %prec EMPTY
;
ParameterDecl  :
							 ParameterDeclPre Type
;
ParameterDeclPre :
								 IdentifierList IdentifierListSuff %prec NORMAL
								 | O_ELLIPSES %prec NORMAL
								 | %empty %prec EMPTY
;
IdentifierListSuff :
									 O_ELLIPSES %prec NORMAL
									 | %empty %prec EMPTY
;

InterfaceType      :
									 K_INTERFACE '{' InterfaceTypeList '}'
;
InterfaceTypeList  :
									 InterfaceTypes InterfaceTypeList %prec NORMAL
									 | %empty %prec EMPTY
;
InterfaceTypes     :
									 MethodSpec
									 | InterfaceTypeName
;
MethodSpec         :
									 MethodName Signature
;
MethodName         :
									 T_ID
;
InterfaceTypeName  :
									 TypeName
;


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
						 /* | %empty */
;

MethodDecl :
					 K_FUNC Receiver MethodName Signature FunctionBody
;
Receiver   :
					 Parameters
;

ConstDecl :
					K_CONST ConstSpec
					| K_CONST '(' ConstSpec ')'

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
				| K_VAR '(' VarSpec ')'
;
VarSpec :
				IdentifierList IdentifierListSuff
;
IdentifierListSuff :
									 Type IdentifierListTypeSuff %prec NORMAL
									 | '=' ExprList %prec NORMAL
									 | %empty %prec EMPTY
;
IdentifierListTypeSuff :
											 '=' ExprList %prec NORMAL
											 | %empty %prec EMPTY
;

IdentifierList :
							 T_ID IdentifierList2
;
IdentifierList2 :
								IdentifierList2 ',' T_ID %prec NORMAL
								| %empty %prec EMPTY
;

/* Expressions */
ExprList :
				 Expr ExprList2
;
ExprList2 :
					ExprList2 ',' Expr %prec NORMAL
					| %empty %prec EMPTY
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
					 | O_NEQ
					 | O_LT
					 | O_LEQ
					 | O_GT
					 | O_GEQ
;
add_op     :
					 '+' 
					 | '-' 
					 | '|' 
					 | '^'
;
mul_op     :
					 '*' 
					 | '/' 
					 | '%' 
					 | O_LSHIFT 
					 | O_RSHIFT 
					 | '&' 
					 | O_AMPXOR
;
unary_op   :
					 '+' 
					 | '-' 
					 | '!' 
					 | '^' 
					 | '*' 
					 | '&' 
					 | O_CHAN_DIR
;
assign_op  :
					 '='
					 | O_ADDEQ
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

/* Expr : */
/* 		 Expr O_LOR Land %prec P_LOR */
/* 		 | Land */
/* ; */
/* Land : */
/* 		 Land O_LAND Lcomp %prec P_LAND */
/* 		 | Lcomp */
/* ; */
/* Lcomp : */
/* 			Lcomp rel_op Sum %prec P_REL */
/* 			| Sum */
/* ; */
/* Sum  : */
/* 		 Sum add_op Prod %prec P_SUM */
/* 		 | Prod */
/* ; */
/* Prod : */
/* 		 Prod mul_op UnaryExpr %prec P_PROD */
/* 		 | UnaryExpr */
/* ; */
Expr :
		 Expr O_LOR Expr
		 | Expr O_LAND Expr
		 | Expr rel_op Expr
		 | Expr add_op Expr
		 | Expr mul_op Expr
		 | UnaryExpr %prec P_UNARY
;
UnaryExpr :
					unary_op UnaryExpr %prec P_UNARY
					| PrimaryExpr
;
PrimaryExpr :
						Operand
						/* | PrimaryExpr Selector */
						| PrimaryExpr Index 
;
/* | PrimaryExpr Slice  */
						/* | PrimaryExpr TypeAssertion  */
						/* | PrimaryExpr Arguments 
; */
/* Selector       :
 '.' T_ID
; */
Index          :
							 '[' Expr ']'
;
/* Slice          :
 "[" [ Expression ] ":" [ Expression ] "]" | */
/* 							 :
	"[" [ Expression ] ":" Expression ":" Expression "]" . */
/* TypeAssertion  :
 "." "(" Type ")" . */
/* Arguments      :
 "(" [ ( ExpressionList | Type [ "," ExpressionList ] ) [ O_ELLIPSES ] [ "," ] ] ")" . */

Operand     :
						Literal 
						| OperandName 
						| '(' Expr ')'
;
Literal     :
						BasicLit 
						/* | CompositeLit  */
						| FunctionLit
;
BasicLit    :
						L_INT
						| L_FLOAT
						/* | imaginary_lit  */
						| L_RUNE
						| L_STRING
;
FunctionLit : 
						K_FUNC Signature FunctionBody
;
OperandName :
						T_ID
						| QualifiedID
;

/* Blocks and Statements */
Block :
			'{' StatementList '}'
;
StatementList :
							Statement StatementList %prec NORMAL
							| %empty %prec EMPTY
;

/* To be modified */
Statement :
					SimpleStmt
					| ForStmt
					| FunctionCall
;
SimpleStmt :
					ExprStmt 
					| SendStmt 
					| IncDecStmt 
					| Assignment 
					| ShortVarDecl
					/* | EmptyStmt  */
;

EmptyStmt :
					%empty %prec EMPTY
;

ExprStmt :
				 Expr
;

SendStmt :
				 Channel O_CHAN_DIR Expr
;
Channel :
				Expr
;

IncDecStmt :
					 Expr O_INC
					 | Expr O_DEC
;

Assignment :
					 ExprList assign_op ExprList
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

FunctionCall : 
						 FunctionCallName Parameters
;
FunctionCallName :
								 FunctionName
								 | QualifiedID
;

%%
void yyerror(char const* error) {
	fprintf(stderr, "%s\n", error)
;
}

int main()
{
yydebug = 1
;
yyparse()
;
return 0
;
}
