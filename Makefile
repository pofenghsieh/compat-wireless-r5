KLIB:= $(ROOT_DIR)/kernel
KLIB_BUILD ?= $(KLIB)

DESTDIR?=

ifneq ($(KERNELRELEASE),)

NOSTDINC_FLAGS := -I$(M)/include/ \
	-include $(M)/include/linux/compat-2.6.h \
	$(CFLAGS)

obj-y := compat/

ifeq ($(BT),)
obj-$(CONFIG_COMPAT_WIRELESS) += net/wireless/ net/mac80211/
obj-$(CONFIG_COMPAT_WIRELESS_MODULES) += drivers/net/wireless/
endif

else

export PWD :=	$(shell pwd)
CFLAGS += \
        -DCOMPAT_BASE_TREE="\"$(shell cat compat_base_tree)\"" \
        -DCOMPAT_BASE_TREE_VERSION="\"$(shell cat compat_base_tree_version)\"" \
        -DCOMPAT_PROJECT="\"Compat-wireless\"" \
        -DCOMPAT_VERSION="\"$(shell cat compat_version)\""

# These exported as they are used by the scripts
# to check config and compat autoconf
export COMPAT_CONFIG=config.mk
export CONFIG_CHECK=.$(COMPAT_CONFIG)_md5sum.txt
export COMPAT_AUTOCONF=include/linux/compat_autoconf.h
export CREL=$(shell cat $(PWD)/compat_version)
export CREL_PRE:=.compat_autoconf_
export CREL_CHECK:=$(CREL_PRE)$(CREL)

include $(PWD)/$(COMPAT_CONFIG)

all: modules

modules: $(CREL_CHECK)
	@./scripts/check_config.sh
	$(MAKE) -C $(KLIB_BUILD) M=$(PWD) modules
	@touch $@

install: modules
	@echo "Installing WG73/75xx(WL12xx) compat driver..."
	@mkdir -p $(DESTDIR)/system/lib/modules
	@install compat/compat.ko                           $(DESTDIR)/system/lib/modules
	@install drivers/net/wireless/wl12xx/wl12xx.ko      $(DESTDIR)/system/lib/modules
	@install net/mac80211/mac80211.ko                   $(DESTDIR)/system/lib/modules
	@install net/wireless/cfg80211.ko                   $(DESTDIR)/system/lib/modules
	@install drivers/net/wireless/wl12xx/wl12xx_sdio.ko $(DESTDIR)/system/lib/modules
	@install drivers/net/wireless/wl12xx/wl12xx_spi.ko  $(DESTDIR)/system/lib/modules

# With the above and this we make sure we generate a new compat autoconf per
# new relase of compat-wireless-2.6 OR when the user updates the 
# $(COMPAT_CONFIG) file
$(CREL_CHECK):
	@# Force to regenerate compat autoconf
	@rm -f $(CONFIG_CHECK)
	@./scripts/check_config.sh
	@touch $@
	@md5sum $(COMPAT_CONFIG) > $(CONFIG_CHECK)

clean:
	@if [ -d net -a -d $(KLIB_BUILD) ]; then \
		$(MAKE) -C $(KLIB_BUILD) M=$(PWD) clean ;\
	fi
	@rm -f $(CREL_PRE)*                                                                                                               

.PHONY: all clean install modules

endif

clean-files += Module.symvers Module.markers modules modules.order
clean-files += $(CREL_CHECK) $(CONFIG_CHECK)
