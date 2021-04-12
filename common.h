#include <stdio.h>
#include <ctype.h>
#include <string.h>
#include <stdlib.h>

#define INT 1
#define FLOAT 2
#define STRING 3
#define RUNE 4
#define ID 5
#define SEQ 6
#define OP 7
#define NIL 8
#define BOOL 9
#define FUNC 10
#define TYPE 11

struct node;

union NodeVal {
	int i;
	float f;
	char str[100];
	char name[100];
	char b;
	char op[5];
	struct node* n;
};

typedef struct node {
	int type;
	union NodeVal value;
	char loc[100];
	struct node* lop;
	struct node* rop;
} Node;

typedef struct ifnode {
	char next[10];
} IfNode;

Node *makeNode(int type, union NodeVal value, Node* lop, Node* rop);
int seqLen(Node *seq);
char* getLoc(Node *LiteralNode);

int yylex();

void yyerror(const char *error);

