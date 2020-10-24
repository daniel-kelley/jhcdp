#
#  Makefile
#
#  Copyright (c) 2020 by Daniel Kelley
#

all: z.svg

z.svg: z.dot
	dot -Tsvg $< > $@

z.dot: jhcdp.rb
	ruby $< $@

clean:
	-rm -f z.svg z.dot
