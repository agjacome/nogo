CC = /usr/bin/gcc
FLEX = /usr/bin/flex
BISON = /usr/bin/bison
CFLAGS = -O2 -g
LDFLAGS = -lfl

nogo: nogo.tab.o nogo.lex.o
	$(CC) $(CFLAGS) -o nogo nogo.tab.o nogo.lex.o $(LDFLAGS)

nogo.lex.o: nogo.lex.c nogo.tab.h
	$(CC) $(CFLAGS) -c nogo.lex.c

nogo.tab.o: nogo.tab.c nogo.tab.h
	$(CC) $(CFLAGS) -c nogo.tab.c

nogo.tab.c: nogo.y
	$(BISON) -d nogo.y

nogo.lex.c: nogo.l
	$(FLEX) nogo.l
	mv  lex.yy.c nogo.lex.c

clean:
	rm nogo.tab.o nogo.lex.o nogo.tab.c nogo.lex.c nogo.tab.h nogo

