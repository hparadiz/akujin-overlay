# Copyright 1999-2020 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

DESCRIPTION="A glossy Matrix collaboration client for desktop"
HOMEPAGE="https://element.io"

inherit unpacker xdg-utils

SRC_URI="https://github.com/vector-im/riot-desktop/archive/v${PV}.tar.gz -> element-desktop-${PV}.tar.gz
	https://github.com/vector-im/riot-web/archive/v${PV}.tar.gz -> riot-web-${PV}.tar.gz"
KEYWORDS="~amd64"
S="${WORKDIR}"
LICENSE="Apache-2.0"
SLOT="0"
IUSE="+emoji"
REQUIRED_USE=""

RESTRICT="network-sandbox"

RDEPEND="app-accessibility/at-spi2-atk:2
	dev-db/sqlcipher
	dev-libs/atk
	dev-libs/expat
	dev-libs/nspr
	dev-libs/nss
	>=net-libs/nodejs-12.14.0
	net-print/cups
	x11-libs/cairo
	x11-libs/gdk-pixbuf:2
	x11-libs/gtk+:3
	x11-libs/libxcb
	x11-libs/libX11
	x11-libs/libXcomposite
	x11-libs/libXcursor
	x11-libs/libXdamage
	x11-libs/libXext
	x11-libs/libXfixes
	x11-libs/libXi
	x11-libs/libXrandr
	x11-libs/libXrender
	x11-libs/libXtst
	x11-libs/libXScrnSaver
	x11-libs/pango
	emoji? ( media-fonts/noto-emoji )"
DEPEND="${RDEPEND}"
BDEPEND="
	sys-apps/yarn
	virtual/rust"
	
WEB_S="${WORKDIR}/riot-web-${PV}"
DESKTOP_S="${WORKDIR}/riot-desktop-${PV}"

QA_PREBUILT="
	chrome-sandbox
	element-desktop
	libEGL.so
	libGLESv2.so
	libffmpeg.so
	libvk_swiftshader.so
	swiftshader/libEGL.so
	swiftshader/libGLESv2.so"



src_prepare() {
	default
	pushd "${WEB_S}" >/dev/null || die
	yarn install || die
	cp config.sample.json config.json || die
	popd || die

	pushd "${DESKTOP_S}" >/dev/null || die
	yarn install || die
	popd || die
}

src_compile() {
	# build webapp first
	pushd "${WEB_S}" >/dev/null || die
	yarn build || die
	popd || die

	# go into desktop folder
	pushd "${DESKTOP_S}" >/dev/null || die

	# make link to webapp in web source folder
	ln -s "${WEB_S}"/webapp ./ || die
	yarn build:native || die
	yarn build || die
	popd || die
}

src_install() {
	pushd "${DESKTOP_S}" >/dev/null || die
	unpack ./dist/${PN}_${PV}_amd64.deb
	tar -xvf data.tar.xz || die

	./node_modules/asar/bin/asar.js p webapp opt/Riot/resources/webapp.asar || die
	mv usr/share/doc/${PN} usr/share/doc/${PF} || die
	gunzip ${DESKTOP_S}/usr/share/doc/${PF}/changelog.gz || die

	insinto /
	doins -r usr
	doins -r opt
	popd || die

	local f
	for f in ${QA_PREBUILT}; do
		chmod +x ${ED}"/opt/Element (Riot)/"${f}
	done

	dosym ${ED}"/opt/Element (Riot)/"${PN} /usr/bin/${PN}
}

pkg_postinst() {
	xdg_desktop_database_update
	xdg_icon_cache_update

	elog "Since upgrading Element to Electron 8 it uses StatusNotifierItem"
	elog "for displaying the tray icon."
	elog "Some popular status bars do not support the new API."
	elog
	elog "If you have problems with showing the tray icon, consider installing"
	elog "x11-misc/snixembed."
}

pkg_postrm() {
	xdg_desktop_database_update
	xdg_icon_cache_update
}
