include $(TOPDIR)/rules.mk

PKG_NAME:=gluon-neighbour

PKG_MAINTAINER:=David Bauer <mail@david-bauer.net>
PKG_LICENSE:=BSD-2-Clause
PKG_VERSION:=1.0

include $(INCLUDE_DIR)/package.mk
include $(INCLUDE_DIR)/cmake.mk

define Package/gluon-neighbour
  SECTION:=gluon
  CATEGORY:=Gluon
  DEPENDS:=+gluon-ucode
  TITLE:=Gluon neighbour daemon
endef

define Package/gluon-neighbour/install
	$(INSTALL_DIR) $(1)/usr/lib/ucode/gluon/native $(1)/usr/bin $(1)/etc/init.d

	$(CP) $(PKG_BUILD_DIR)/neighbour-info.so $(1)/usr/lib/ucode/gluon/native/neighbour.so

	$(INSTALL_BIN) ./files/gluon-neighbour.uc $(1)/usr/bin/gluon-neighbour
	$(INSTALL_BIN) ./files/gluon-neighbour.init $(1)/etc/init.d/gluon-neighbour
endef

$(eval $(call BuildPackage,gluon-neighbour))
