%{
#include "common.h"
#include <stdio.h>
#include <stdlib.h>
int TABLE_SIZE = 10009;
union NodeVal value;

int base = 1000;
int scope_depth = 0;
int scope_id = 0;

typedef struct symbol_table {
  char name[31];
  char dtype[10];
  char type;
  char value[20];
	int scope_depth;
	int scope_id;
  int hcode;
} ST;

ST hashTable[10009];

struct Stack {
  char s[25][25];
  int top;
};

typedef struct queue {
  char s[25][200];
  int front;
	int back;
} queue;

typedef struct Stack stack;

stack stack_i = {.top = -1};
stack stack_v = {.top = -1};
stack stack_t = {.top = -1};
stack stack_scope = {.top = -1};
stack if_cond = {.top = -1};
queue for_loc = {.front = -1, .back = -1};

void add(queue *p_st, char *item) {
	if (p_st->back==199) {
		printf("Cannot insert into full queue\n");
		exit(1);
	}
	strcpy(p_st->s[++p_st->back], item);
}

char *rem(queue *p_st) {
	if (p_st->front==p_st->back) {
		printf("Cannot remove from empty queue\n");
		exit(1);
	}
	char *item;
	item = strdup(p_st->s[++p_st->front]);
	return (item);
}

char result[20];
char Tflag[20] = "";

int tid = 0;
int lid = 0;
char temp[10];
char label[10];
FILE* icfile;

void newtemp() {
	sprintf(temp, "_t%d", tid++);
}

void newlabel() {
	sprintf(label, "L%d", lid++);
}

int stfull(stack st, int size) {
  if (st.top >= size - 1)
    return 1;
  else
    return 0;
}

void push(stack *p_st, char *item) {
  p_st->top++;
  strcpy(p_st->s[p_st->top], item);
}

int stempty(stack st) {
  if (st.top == -1)
    return 1;
  else
    return 0;
}

char *pop(stack *p_st) {
  char *item;
  item = p_st->s[p_st->top];
  p_st->top--;
  return (item);
}

int hash1(char *token) {
  int hash = 0;
  for (int i = 0; token[i] != '\0'; i++) {
    hash = (256 * hash + token[i]) % 1000000009;
  }
  hash = hash % TABLE_SIZE;
  return hash;
}

int check(char *token) {
  int index1 = hash1(token);
  int i = 0;
  while (i < TABLE_SIZE &&
         !(strcmp(hashTable[(index1 + i) % TABLE_SIZE].name, token) == 0 &&
				 hashTable[(index1 + i) % TABLE_SIZE].scope_depth == scope_depth &&
				 hashTable[(index1 + i) % TABLE_SIZE].scope_id == scope_id))
    i++;

  if (i == TABLE_SIZE)
    return -1;
  else
    return index1 + i;
}

int check_parent_scopes(char *token) {
  int index1 = hash1(token);
  int i = 0;
  while (i < TABLE_SIZE &&
         !(strcmp(hashTable[(index1 + i) % TABLE_SIZE].name, token) == 0 &&
				 (hashTable[(index1 + i) % TABLE_SIZE].scope_depth == scope_depth &&
				 hashTable[(index1 + i) % TABLE_SIZE].scope_id == scope_id) ||
				 hashTable[(index1 + i) % TABLE_SIZE].scope_depth < scope_depth))
    i++;

  if (i == TABLE_SIZE)
    return -1;
  else
    return index1 + i;
}

void insert(char type, char *token, char *dtype, char *value, int scope_depth, int scope_id) {
  if (check(token) != -1) {
    yyerror("variable is redeclared");
		exit(1);
  }
  int index = hash1(token);

  if (hashTable[index].hcode != -1) {

    int i = 1;
    while (1) {
      int newIndex = (index + i) % TABLE_SIZE;

      if (hashTable[newIndex].hcode == -1) {

        strcpy(hashTable[newIndex].name, token);
        strcpy(hashTable[newIndex].dtype, dtype);
        strcpy(hashTable[newIndex].value, value);
				hashTable[newIndex].scope_depth = scope_depth;
				hashTable[newIndex].scope_id = scope_id;
        hashTable[newIndex].type = type;
        hashTable[newIndex].hcode = 1;
        break;
      }
      i++;
    }
  }
  else {
    strcpy(hashTable[index].name, token);
    strcpy(hashTable[index].dtype, dtype);
    strcpy(hashTable[index].value, value);
		hashTable[index].scope_depth = scope_depth;
		hashTable[index].scope_id = scope_id;
    hashTable[index].type = type;
    hashTable[index].hcode = 1;
  }
}
char *search(char *token) {
  int index1 = hash1(token);
  int i = 0;
  while (i < TABLE_SIZE &&
         strcmp(hashTable[(index1 + i) % TABLE_SIZE].name, token) != 0)
    i++;
  if (i == TABLE_SIZE) {
		return NULL;
  } else
    return hashTable[index1 + i].dtype;
}

int max_id_at_depth[] = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0};

int next_id(int scope_depth) {
	int scope_id = -1;
	if (scope_depth == 1) {
		scope_id = 1;
	} else {
		scope_id = ++max_id_at_depth[scope_depth];
	}
	return scope_id;
}

int restore_id(int scope_depth) {
	int scope_id = -1;
	if (scope_depth == 1) {
		scope_id = 1;
	} else {
		scope_id = max_id_at_depth[scope_depth];
	}
	return scope_id;
}

void update(char *token, char *dtype, char *value) {
  int index = check_parent_scopes(token);
  if (index == -1) {
		char error[100];
		printf("In here\n");
		sprintf(error, "%s is not defined", token);
    yyerror(error);
    exit(1);
  }

  if (hashTable[index].type == 'c') {
		char error[100];
		sprintf(error, "cannot assign to %s (declared const)", token);
		yyerror(error);
    exit(1);
  } else {
    if (strcmp(hashTable[index].value, "NULL") != 0)
      strcpy(hashTable[index].value, value);
    if (strcmp(hashTable[index].dtype, "NULL") != 0)
      strcpy(hashTable[index].dtype, dtype);
  }
}

void disp_symtbl() {
  int base = 1000;
  printf("%s\t\t%s\t\t%s\t\t%s\t\t%s\n", "Name", "Data Type", "Value",
         "Scope Depth", "Scope ID");

  for (int i = 0; i < TABLE_SIZE; i++) {
    if (hashTable[i].hcode != -1)
      printf("%s\t\t%s\t\t\t%s\t\t%d\t\t%d\n", hashTable[i].name,
             hashTable[i].dtype, hashTable[i].value,
             hashTable[i].scope_depth, hashTable[i].scope_id);
  }
}

void doAssign(char decltype, Node *lhs, Node *rhs) {
	if (lhs==NULL && rhs==NULL) {
		Tflag[0] = 0;
		return;
	}
	if (seqLen(lhs) != seqLen(rhs) && seqLen(rhs) != 0) {
		yyerror("Imbalanced assignment");
		exit(1);
	} else {
		if (seqLen(rhs) == 0){
			insert(decltype, pop(&stack_i), Tflag, "NULL", scope_depth, scope_id);
			doAssign(decltype, lhs->rop, rhs);
		} else {
			if (Tflag[0] != 0) {
				if (strcmp(pop(&stack_t),Tflag) != 0) {
					yyerror("Mismatch between declared type and assigned value");
					exit(1);
				}
				insert(decltype, pop(&stack_i), Tflag, pop(&stack_v), scope_depth, scope_id);
			} else {
				insert(decltype, pop(&stack_i), pop(&stack_t), pop(&stack_v), scope_depth, scope_id);
			}
		}
		fprintf(icfile, "%s = %s\n", lhs->lop->value.name, rhs->lop->loc);
		doAssign(decltype, lhs->rop, rhs->rop);
	} 
}

void doAssignExisting(Node *lhs, Node *rhs) {	
	if (lhs==NULL && rhs==NULL) {
		return;
	}
	if (seqLen(lhs) != seqLen(rhs)) {
		yyerror("Imbalanced assignment");
		exit(1);
	} else {
		char* res = search(lhs->lop->value.name);
		if (res==NULL) {
			char error[100];
			sprintf(error, "%s is not defined", lhs->lop->value.name);
			yyerror(error);
			exit(1);
		}
		strcpy(result, res);

		Node *cur = rhs->lop;
		while(cur->type == OP) {
			cur = cur->lop;
		}
		int type = cur->type;
		union NodeVal value = cur->value;
		if(cur->type == ID) {
			char *decltype = search(cur->value.name);
			if(decltype==NULL) {
				char error[100];
				sprintf(error, "%s is not defined", lhs->lop->value.name);
				yyerror(error);
				exit(1);
			}
		}
		printf("%s %d\n", result, type);
		if(strcmp(result, "int") == 0 && type == INT) {
			sprintf(result, "%d", value.i);
			update(lhs->lop->value.name, "int", result);
		} else if(strcmp(result, "float") == 0 && type == FLOAT) {
			sprintf(result, "%f", value.f);
			update(lhs->lop->value.name, "float", result);
		} else if(strcmp(result, "string") == 0 && type == STRING) {
			update(lhs->lop->value.name, "string", value.str);
		} else if(strcmp(result, "rune") == 0 && type == RUNE) {
			update(lhs->lop->value.name, "rune", value.str);
		} else if(strcmp(result, "bool") == 0 && type == BOOL) {
			sprintf(result, "%dB", value.b);
			update(lhs->lop->value.name, "bool", result);
		} else {
			yyerror("Error: type mismatched assignment");
			exit(1);
		}
		fprintf(icfile, "%s = %s\n", lhs->lop->value.name, rhs->lop->loc);
	}
	doAssignExisting(lhs->rop, rhs->rop);
}

%}

%define api.value.type union
%define parse.error verbose

%start SourceFile
/* %expect 11 */

%type <Node *> IdentifierList ExprList Expr Literal BasicLit Operand OperandName rel_op add_op mul_op UnaryExpr PrimaryExpr assign_op unary_op PackageName QualifiedID Assignment VarSpec VIdentifierListSuff VIdentifierListTypeSuff Type TypeName CIdentifierListSuff ConstSpec

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

%token <char const *> P_TYPE
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
						{	
							strcpy(value.name, $1); 
							$$ = makeNode(ID, value, NULL, NULL);
						}
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
		 TypeName { $$ = $1; }
		 | '(' Type ')' { $$ = $2; }
;

TypeName :
				P_TYPE
				{ 
				 	strcpy(value.name, $1);
				 	$$ = makeNode(ID, value, NULL, NULL);
				}
				 | QualifiedID
				 {$$ = $1;}
/*  */
/*
TypeLiteral :
						ArrayType 
						| StructType 
						| PointerType 
						| SliceType */
/* 						| FunctionType  */
/* 						| InterfaceType  */
/* 						| MapType  */
/* 						| ChannelType */


QualifiedID :
						PackageName '.' T_ID
						{	
							value.name[0] = 0; 
							strcat(value.name, $1->value.name); 
							strcat(value.name, "."); 
							strcat(value.name, $3); 
							$$ = makeNode(ID, value, NULL, NULL);
						}
;

/*
ArrayType   :
						'[' ArrayLength ']' ElementType
;
ArrayLength :
						Expr
;*/
/*
ElementType :
						Type
;

SliceType :
					'[' ']' ElementType
;
*/
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
										{
											if(stack_v.top != stack_i.top && stack_v.top != -1) {
												yyerror("Imbalanced assignment");
												YYERROR;
											}
											else {
												if (stack_v.top == -1){
													while(!stempty(stack_i)) {

														insert('c', pop(&stack_i), pop(&stack_t), "NULL", scope_depth, scope_id);

													}
												}
												else {
													while(!stempty(stack_i)) {

														insert('c', pop(&stack_i), pop(&stack_t), pop(&stack_v), scope_depth, scope_id);

													}
												}
											}  
										}
;
ConstSpecs : ConstSpec
					 | ConstSpecs ConstSpec
;
ConstSpec :
					IdentifierList CIdentifierListSuff
				{ 
					value.op[0] = '='; value.op[1] = 0; 
					$$ = makeNode(OP, value, $1, $2);
					doAssign('c', $1, $2->value.n);
				}
;
CIdentifierListSuff :
										CIdentifierListSuffPre '=' ExprList
									 {	
									 	value.n = $3; 
									 	$$ = makeNode(OP, value, NULL, NULL);
									 }
;
CIdentifierListSuffPre :
											 Type %prec NORMAL
											 {	
												strcpy(Tflag, $1->value.name);
											 }
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
				| K_VAR '(' VarSpecs ')' { 
											if(stack_v.top != stack_i.top && stack_v.top != -1) {
												yyerror("Imbalanced assignment");
												YYERROR;
											}
											else {
												if (stack_v.top == -1){
													while(!stempty(stack_i)) {

														insert('v', pop(&stack_i), Tflag, "NULL", scope_depth, scope_id);

													}
												}
												else {
													while(!stempty(stack_i)) {

														insert('v', pop(&stack_i), pop(&stack_t), pop(&stack_v), scope_depth, scope_id);

													}
												}
											} 
										}  
;
VarSpecs : VarSpec
				 | VarSpecs VarSpec
;
VarSpec :
				IdentifierList VIdentifierListSuff 
				{ 
					if($2) {
						value.op[0] = '='; value.op[1] = 0; 
						printf("Outside function: %d %d\n", seqLen($1), seqLen($2->value.n));
						$$ = makeNode(OP, value, $1, $2);
						doAssign('v', $1, $2->value.n);
					} 
					else {
						$$ = NULL;
						printf("Beginning with assign\n");
						doAssign('v', $1, $2);
						printf("Done with assign\n");
					}
				}
;
VIdentifierListSuff :
									 Type VIdentifierListTypeSuff
									 {	
									 	$$ = $2;
									 	strcpy(Tflag, $1->value.name);
									 }
									 | '=' ExprList
									 {	
									 	value.n = $2; 
									 	$$ = makeNode(OP, value, NULL, NULL);
									 }
;
VIdentifierListTypeSuff :
											 '=' ExprList %prec NORMAL 
											 {	
											 	value.n = $2; 
											 	$$ = makeNode(OP, value, NULL, NULL);
											 }
											 | %empty %prec EMPTY 
											 	{
											  		$$ = NULL; 

												}
;

IdentifierList :
							T_ID
							{	
							 	strcpy(value.name, $1); 
							 	$$ = makeNode(SEQ, value, makeNode(ID, value, NULL, NULL), NULL); 
							 	/*printf("Type: %d Value: %s\n", $$->type, $$->value.name);*/
								
								push(&stack_i, value.name);
								
							}
							| IdentifierList ',' T_ID
							{	
							 	strcpy(value.name, $3); 
								$$ = makeNode(SEQ, value, makeNode(ID, value, NULL, NULL), $1);

							 	push(&stack_i, value.name);
							}
;

/* Expressions */
ExprList :
				Expr 	
				{	
					$$ = makeNode(SEQ, value, $1, NULL); 
				 			
					switch ($1->type) {
						case INT:
							sprintf(result, "%d", $1->value.i);
							push(&stack_t, "int");
							break;
						case FLOAT:
							sprintf(result, "%f", $1->value.f);
							push(&stack_t, "float");
							break;
						case RUNE:
							sprintf(result, "%s", $1->value.str);
							push(&stack_t, "rune");
							break;
						case STRING:
							sprintf(result, "%s", $1->value.str);
							push(&stack_t, "string");
							break;
						case BOOL:
							sprintf(result, "%dB", $1->value.b);
							push(&stack_t, "bool");
							break;
						}
    							
    				push(&stack_v, result);
    				
				 }
				 | ExprList ',' Expr
				 { 
					$$ = makeNode(SEQ, value, $3, $1);

					switch ($3->type) {
						case INT:
							sprintf(result, "%d", $1->value.i);
							push(&stack_t, "int");
							break;
						case FLOAT:
							sprintf(result, "%f", $1->value.f);
							push(&stack_t, "float");
							break;
						case RUNE:
							sprintf(result, "%s", $1->value.str);
							push(&stack_t, "rune");
							break;
						case STRING:
							sprintf(result, "%s", $1->value.str);
							push(&stack_t, "string");
							break;
						case BOOL:
							sprintf(result, "%dB", $1->value.b);
							push(&stack_t, "bool");
							break;
						}
    						
    				push(&stack_v, result);
    			
				 }
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
		 {
		 strcpy(value.op, $2);
		 $$ = makeNode(OP, value, $1, $3);
		 newtemp();
		 fprintf(icfile, "%s = %s %s %s\n", temp, $1->loc, value.op, $3->loc);
		 strcpy($$->loc, temp);
		 }
		 | Expr O_LAND Expr
		 {
		 strcpy(value.op, $2);
		 $$ = makeNode(OP, value, $1, $3);
		 newtemp();
		 fprintf(icfile, "%s = %s %s %s\n", temp, $1->loc, value.op, $3->loc);
		 strcpy($$->loc, temp);
		 }
		 | Expr rel_op Expr %prec O_EQ
		 {
		 strcpy(value.op, $2->value.op);
		 $$ = makeNode(OP, value, $1, $3);
		 newtemp();
		 fprintf(icfile, "%s = %s %s %s\n", temp, $1->loc, value.op, $3->loc);
		 strcpy($$->loc, temp);
		 printf("While setting: %s\n", $$->loc);
		 }
		 | Expr add_op Expr %prec '+'
		 {
		 strcpy(value.op, $2->value.op);
		 $$ = makeNode(OP, value, $1, $3);
		 newtemp();
		 fprintf(icfile, "%s = %s %s %s\n", temp, $1->loc, value.op, $3->loc);
		 strcpy($$->loc, temp);
		 }
		 | Expr mul_op Expr %prec '-'
		 {
		 strcpy(value.op, $2->value.op);
		 $$ = makeNode(OP, value, $1, $3);
		 newtemp();
		 fprintf(icfile, "%s = %s %s %s\n", temp, $1->loc, value.op, $3->loc);
		 strcpy($$->loc, temp);
		 }
		 | UnaryExpr %prec P_UNARY
		 {$$ = $1;}
;
UnaryExpr :
					O_CHAN_DIR UnaryExpr
					{strcpy(value.op, $1); $$ = makeNode(OP, value, $2, NULL);}
					| unary_op UnaryExpr %prec P_UNARY
					{
					strcpy(value.op, $1->value.op);
					$$ = makeNode(OP, value, $2, NULL);
					strcpy($$->loc,getLoc($2));
					newtemp();
					fprintf(icfile, "%s = -%s\n", temp, $$->loc);
					strcpy($$->loc, temp);
					}
					| PrimaryExpr
					{$$ = $1; strcpy($$->loc,getLoc($1));}
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
						{value.n = NULL; $$ = makeNode(NIL, value, NULL, NULL);}
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
			'{' {++scope_depth; scope_id = next_id(scope_depth);} StatementList {--scope_depth; scope_id = restore_id(scope_depth);} '}'
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


IncDecStmt :
					 Expr O_INC
					 {
						newtemp(); fprintf(icfile, "%s = %s + 1\n", temp, $1->loc), fprintf(icfile, "%s = %s\n", $1->loc, temp);
					 }
					 | Expr O_DEC
					 {
						newtemp(); fprintf(icfile, "%s = %s - 1\n", temp, $1->loc), fprintf(icfile, "%s = %s\n", $1->loc, temp);
					 }
;

Assignment :
					 IdentifierList '=' ExprList
					 {
						value.op[0] = '='; 
						value.op[1] = 0; 
						$$ = makeNode(OP, value, $1, $3);
						doAssignExisting($1, $3);
					 }
					 | Expr assign_op Expr
					 {	
					 	strcpy(value.op, $2->value.op); 
					 	$$ = makeNode(OP, value, $1, $3);
					 }
;

ShortVarDecl :
					IdentifierList O_ASSGN ExprList
					{
						doAssign('v', $1, $3);
					}
;

ForStmt :
				K_FOR {newlabel(); add(&for_loc, label); newlabel(); add(&for_loc, label); strcpy($<IfNode>$.next, label);} OptionalForClause {strcpy($<IfNode>$.next, label);} Block
				{
					fprintf(icfile, "GOTO %s\n", label);
					fprintf(icfile, "%s:\n", $<IfNode>2.next);
				}
;
OptionalForClause : 
									Condition %prec NORMAL
									| ForClause %prec NORMAL
									| RangeClause %prec NORMAL
									| %empty %prec EMPTY
;
Condition : 
					Expr
					{
						fprintf(icfile, "IFFALSE %s GOTO %s\n", $1->loc, rem(&for_loc));
					}
;
ForClause :
					OptionalForClauseInit {strcpy($<IfNode>$.next, rem(&for_loc)); fprintf(icfile, "%s:\n", $<IfNode>$.next); } ';' OptionalForClauseCondition {newlabel();fprintf(icfile, "GOTO %s\n", label); add(&for_loc, label);} ';' {newlabel(); fprintf(icfile, "%s:\n", label);} OptionalForClausePost {fprintf(icfile, "GOTO %s\n", $<IfNode>2.next); fprintf(icfile, "%s:\n", rem(&for_loc));}
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
			 K_IF/* OptionalStmt */ Expr {newlabel(); fprintf(icfile, "IFFALSE %s GOTO %s\n", $2->loc, label); strcpy($<IfNode>$.next, label);} Block { push(&if_cond, $2->loc); fprintf(icfile, "%s:\n", $<IfNode>3.next); } OptionalElse
;
/* OptionalStmt :  */
/* 						 SimpleStmt ';' */
/* 						 | %empty */
/* ; */
OptionalElse :
						 K_ELSE IfStmt
						 | K_ELSE {newlabel(); fprintf(icfile, "IF %s GOTO %s\n", pop(&if_cond), label); strcpy($<IfNode>$.next, label);} Block
							{
								fprintf(icfile, "%s:\n", $<IfNode>2.next);
							}
						 | %empty
;

ReturnStmt :
					 K_RETURN 
					 | K_RETURN ExprList
;

%%
extern int yylineno;
char codeline[100];
void yyerror(char const* error) {
	fprintf(stderr, "Syntax error in line %d: %s\n", yylineno, error);
}

int main()
{
	icfile = fopen("intermediate.txt", "w");
	for(int i=0; i<TABLE_SIZE; i++)
		hashTable[i].hcode = -1;

	sprintf(result, "%d", base);
	base++;
	push(&stack_scope, result);

	yydebug = 1;
	if ( yyparse() != 0){
		printf("BUILD FAILED...!!\n\n");
		exit(1);
	}

	printf("\n\n\n");
	printf("---------------------------------Symbol Table---------------------------------\n\n");
	disp_symtbl();

	return 0;
}
