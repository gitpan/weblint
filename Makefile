#
# Makefile for weblint
#
VERSION	= 1.020

SHELL	= /bin/sh

BINDIR	= /usr/local/bin
MANDIR	= /usr/local/man/man1
PSROFF	= groff -Tps
PSVIEW	= ghostview
RM	= /bin/rm -f

PROGRAM	= weblint
PSFILE	= $(PROGRAM).ps
TARFILE	= $(PROGRAM)-$(VERSION).tar
TGZ	= $(TARFILE).gz

all: $(PROGRAM) $(PSFILE)

install: $(PROGRAM)
	-cp $(PROGRAM) $(BINDIR)
	-chmod 755 $(BINDIR)/$(PROGRAM)
	-cp $(PROGRAM).1 $(MANDIR)
	-chmod 644 $(MANDIR)/$(PROGRAM).1

test:
	@./test.pl

$(PSFILE): $(PROGRAM).1
	$(PSROFF) -man $(PROGRAM).1 > $(PSFILE)


preview: $(PSFILE)
	$(PSVIEW) $(PSFILE) &

tar: clean $(PROGRAM)
	(						\
	  cd .. ;					\
	  tar cvf $(TARFILE) $(PROGRAM)-$(VERSION) ;	\
	  gzip $(TARFILE) ;				\
	  mv $(TGZ) $(PROGRAM)-$(VERSION)		\
	)

zip: clean $(PROGRAM)
	(						\
	  cd .. ;					\
	  mv $(PROGRAM)-$(VERSION) $(PROGRAM) ;		\
	  zip -r $(PROGRAM) $(PROGRAM) ;		\
	  mv $(PROGRAM) $(PROGRAM)-$(VERSION) ;		\
	  mv $(PROGRAM).zip $(PROGRAM)-$(VERSION)	\
	)

clean:
	$(RM) *~ $(PSFILE) $(TARFILE) $(TGZ) test.log $(PROGRAM).zip

