#include "common.h"

Node *makeNode(int type, union NodeVal value, Node* lop, Node* rop) {
	Node* newNode = malloc(sizeof(Node));
	newNode->type = type;
	newNode->value = value;
	newNode->lop = lop;
	newNode->rop = rop;
	return newNode;
}
