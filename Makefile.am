SUBDIRS = bf-asm p4c

### Helpful aliases for things in subdirectories

check-asm:
	$(MAKE) -C bf-asm all-am tests

check-%:
	$(MAKE) -C p4c $@

recheck-%:
	$(MAKE) -C p4c $@
