#include "common.h"

Node *makeNode(int type, union NodeVal value, Node* lop, Node* rop) {
	Node* newNode = malloc(sizeof(Node));
	newNode->type = type;
	newNode->value = value;
	newNode->lop = lop;
	newNode->rop = rop;
	return newNode;
}

int seqLen(Node *seq) {
	if (seq==NULL) return 0;
	int len = 0;
	while (seq) {
		++len;
		seq = seq->rop;
	}
	return len;
}

char *getLoc(Node *OperandNode) {
	static char ret[100];
	switch (OperandNode->type) {
		case INT:
			snprintf(ret, 100, "%d", OperandNode->value.i);
			break;
		case FLOAT:
			snprintf(ret, 100, "%lf", OperandNode->value.f);
			break;
		case RUNE: case STRING:
			snprintf(ret, 100, "%s", OperandNode->value.str);
			break;
		case ID:
			snprintf(ret, 100, "%s", OperandNode->value.name);
			break;
		case NIL:
			snprintf(ret, 100, "%s", "nil");
			break;
		case BOOL:
			snprintf(ret, 100, "%dB", OperandNode->value.b);
			break;
		case OP:
			strcpy(ret, OperandNode->loc);
			break;
	}
	return ret;
}
