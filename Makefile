all: lex.yy.c go_parser.tab.c common.h
	gcc go_parser.tab.c lex.yy.c -lfl -o parser

go_parser.tab.c: go_parser.y
	bison -d --debug go_parser.y

lex.yy.c: go_tokenizer.l
	flex -d go_tokenizer.l

