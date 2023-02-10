# This is free software, licensed under the Apache 2.0 license.

include $(TOPDIR)/rules.mk

PKG_NAME:=gluon-remote-command

include ../gluon.mk

define Package/gluon-remote-command
  TITLE:=Remote command Framework
endef

define Package/gluon-remote-command/description
	Guon Framework to trigger commands in the boot-process
endef

define Package/gluon-remote-command/install
	$(Gluon/Build/Install)
	$(INSTALL_DIR) $(1)/lib/gluon/remote-command

	$(INSTALL_BIN) $(PKG_BUILD_DIR)/command-rx $(1)/lib/gluon/remote-command/gluon-remote-command-rx
endef

$(eval $(call BuildPackageGluon,gluon-remote-command))
