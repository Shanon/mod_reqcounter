mod_reqcounter.la: mod_reqcounter.slo
	$(SH_LINK) -rpath $(libexecdir) -module -avoid-version  mod_reqcounter.lo
DISTCLEAN_TARGETS = modules.mk
shared =  mod_reqcounter.la
