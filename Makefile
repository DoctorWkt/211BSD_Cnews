wktcnews.tap: wktcnews.tar mktape
	./mktape wktcnews.tar > wktcnews.tap

mktape: mktape.c
	cc -o mktape mktape.c

clean:
	rm -f wktcnews.tap mktape
