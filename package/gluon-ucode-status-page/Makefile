include $(TOPDIR)/rules.mk

PKG_NAME:=gluon-ucode-status-page

PKG_MAINTAINER:=David Bauer <mail@david-bauer.net>
PKG_LICENSE:=BSD-2-Clause
PKG_VERSION:=1.0

include $(INCLUDE_DIR)/package.mk
# include $(INCLUDE_DIR)/cmake.mk

define Package/gluon-ucode-status-page
  SECTION:=gluon
  CATEGORY:=Gluon
  DEPENDS:=+gluon-ucode
  TITLE:=Gluon ucode status page
endef

define Build/Compile
endef

define Package/gluon-ucode-status-page/install
	$(INSTALL_DIR) $(1)/usr/share/ucode/gluon $(1)/lib/gluon/status-page/www/cgi-bin/dyn/ucode
	$(CP) ./files/status-page.uc $(1)/usr/share/ucode/gluon/status-page.uc

	$(INSTALL_BIN) ./files/cgi/neighbour.uc $(1)/lib/gluon/status-page/www/cgi-bin/dyn/ucode/neighbour
	$(INSTALL_BIN) ./files/cgi/network.uc $(1)/lib/gluon/status-page/www/cgi-bin/dyn/ucode/network
	$(INSTALL_BIN) ./files/cgi/system.uc $(1)/lib/gluon/status-page/www/cgi-bin/dyn/ucode/system
endef

$(eval $(call BuildPackage,gluon-ucode-status-page))
