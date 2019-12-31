include $(TOPDIR)/rules.mk

PKG_NAME:=gluon-wireless-encryption
PKG_VERSION:=1
PKG_RELEASE:=1

include ../gluon.mk

define Package/gluon-wireless-encryption-wpa2
  DEPENDS:=+hostapd-mini
  TITLE:=Package for supporting WPA2 encrypted wireless networks
endef

define Package/gluon-wireless-encryption-wpa3
  DEPENDS:=+hostapd-openssl
  TITLE:=Package for supporting WPA3 encrypted wireless networks
endef

define Package/gluon-wireless-encryption-wpa2/install
	$(INSTALL_DIR) $(1)/lib/gluon

	echo 'wpa2' >> $(1)/lib/gluon/supported_wireless_encryption
endef

define Package/gluon-wireless-encryption-wpa3/install
	$(INSTALL_DIR) $(1)/lib/gluon

	echo 'wpa2' >> $(1)/lib/gluon/supported_wireless_encryption
	echo 'wpa3' >> $(1)/lib/gluon/supported_wireless_encryption
endef

$(eval $(call BuildPackageGluon,gluon-wireless-encryption-wpa2))
$(eval $(call BuildPackageGluon,gluon-wireless-encryption-wpa3))
