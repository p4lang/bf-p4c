SUBDIRS = bf-asm p4c

### Helpful aliases for things in subdirectories

check-asm:
	$(MAKE) -C bf-asm all-am tests

check-%:
	$(MAKE) -C p4c $@

recheck-%:
	$(MAKE) -C p4c $@

ctags:
	@: FIXME -- these are inconsistent
	$(MAKE) -C bf-asm tags
	$(MAKE) -C p4c ctags
	cd $(srcdir)/bf-p4c; ctags -R --langmap=C++:+.def,Flex:+.l,YACC:+.ypp \
	    ../p4c/frontends ../p4c/ir ../p4c/midend/ ../p4c/lib .
