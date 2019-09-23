include $(TOPDIR)/rules.mk

PKG_NAME:=gluon-featureset
PKG_VERSION:=1

include ../gluon.mk

define Package/gluon-featureset-default
  PROVIDES:=gluon-featureset
  TITLE:=Indicates default available featureset
endef

define Package/gluon-featureset-tiny
  PROVIDES:=gluon-featureset
  TITLE:=Indicates tiny available featureset
endef

define Package/gluon-featureset-default/install
	$(INSTALL_DIR) $(1)/lib/gluon

	echo 'default' > $(1)/lib/gluon/featureset
endef

define Package/gluon-featureset-tiny/install
	$(INSTALL_DIR) $(1)/lib/gluon

	echo 'tiny' > $(1)/lib/gluon/featureset
endef

$(eval $(call BuildPackageGluon,gluon-featureset-default))
$(eval $(call BuildPackageGluon,gluon-featureset-tiny))
