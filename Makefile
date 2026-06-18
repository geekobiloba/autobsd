# SPDX-License-Identifier: BSD 2-Clause

DIST_SITE ?= https://download.freebsd.org/releases
DIST_ARCH != uname -m
DIST_VER  != uname -r | sed -E 's,-p[0-9]+$$,,'
DIST_URL  ?= ${DIST_SITE}/${DIST_ARCH}/${DIST_VER}
DIST_DIR  ?= ${.CURDIR}/dist

MFSBSD_REPO            ?= https://github.com/mmatuska/mfsbsd.git
MFSBSD_DIR             ?= ${.CURDIR}/mfsbsd
MFSBSD_MFSROOT_MAXSIZE ?= 500m

OUT_NAME  != echo ${DIST_URL} | awk 'BEGIN {FS = "/"; OFS = "-"} {print "AutoBSD", $$(NF-1), $$(NF)}'
IMG_NAME  ?= ${OUT_NAME}.img
IMG_PATH  ?= ${.CURDIR}/${IMG_NAME}
ISO_NAME  ?= ${OUT_NAME}.iso
ISO_PATH  ?= ${.CURDIR}/${ISO_NAME}
ISO_LABEL != echo ${OUT_NAME} | tr '[[:punct:]]' _ | cut -c 1-32

MAIN_TARGETS += ${DIST_DIR}/MANIFEST
MAIN_TARGETS += ${DIST_DIR}/kernel.txz
MAIN_TARGETS += ${DIST_DIR}/base.txz
MAIN_TARGETS += ${MFSBSD_DIR}
MAIN_TARGETS += ${MFSBSD_DIR}/conf/ttys
MAIN_TARGETS += ${MFSBSD_DIR}/conf/loader.conf
MAIN_TARGETS += ${MFSBSD_DIR}/tools/packages
MAIN_TARGETS += ${MFSBSD_DIR}/customfiles/etc/installerconfig
MAIN_TARGETS += ${MFSBSD_DIR}/customfiles/etc/installerconfig.d
MAIN_TARGETS += ${MFSBSD_DIR}/customfiles/etc/profile.d/autorun.sh
MAIN_TARGETS += ${MFSBSD_DIR}/customfiles/usr/freebsd-dist/MANIFEST

.ifdef EMBED_DIST
MAIN_TARGETS += ${MFSBSD_DIR}/customfiles/usr/freebsd-dist/kernel.txz
MAIN_TARGETS += ${MFSBSD_DIR}/customfiles/usr/freebsd-dist/base.txz
.endif

.MAIN: ${MAIN_TARGETS}

all: iso img

iso: ${ISO_PATH}

img: ${IMG_PATH}

${ISO_PATH}: ${MAIN_TARGETS} ${MFSBSD_DIR}/Makefile.autobsd
	make -C ${.ALLSRC:[-1]:H} -f ${.ALLSRC:[-1]} \
		BASE="${DIST_DIR}" \
		ISOIMAGE="${.TARGET}" \
		ISOLABEL="${ISO_LABEL}" \
		MFSROOT_MAXSIZE="${MFSBSD_MFSROOT_MAXSIZE}" \
		iso
	sha256 "${ISO_PATH}" > "${ISO_PATH}.sha256"

${IMG_PATH}: ${MAIN_TARGETS} ${MFSBSD_DIR}/Makefile.autobsd
	make -C ${.ALLSRC:[-1]:H} -f ${.ALLSRC:[-1]} \
		BASE="${DIST_DIR}" \
		IMAGE="${.TARGET}" \
		MFSROOT_MAXSIZE="${MFSBSD_MFSROOT_MAXSIZE}" \
		image
	sha256 "${IMG_PATH}" > "${IMG_PATH}.sha256"

${DIST_DIR}/MANIFEST:
	mkdir -pv ${.TARGET:H}
	fetch --no-mtime -o ${.TARGET} ${DIST_URL}/${.TARGET:T}

${DIST_DIR}/kernel.txz:
	mkdir -pv ${.TARGET:H}
	fetch --no-mtime -o ${.TARGET} ${DIST_URL}/${.TARGET:T}

${DIST_DIR}/base.txz:
	mkdir -pv ${.TARGET:H}
	fetch --no-mtime -o ${.TARGET} ${DIST_URL}/${.TARGET:T}

${MFSBSD_DIR}:
	git clone --depth=1 ${MFSBSD_REPO}

${MFSBSD_DIR}/customfiles/etc/installerconfig: installerconfig
	mkdir -pv ${.TARGET:H}
	cp -v ${.ALLSRC:[1]} ${.TARGET}

${MFSBSD_DIR}/customfiles/etc/installerconfig.d: installerconfig.d
	mkdir -pv ${.TARGET:H}
	cp -RLv ${.ALLSRC:[1]} ${.TARGET}

${MFSBSD_DIR}/customfiles/etc/profile.d/autorun.sh: autorun.sh
	mkdir -pv ${.TARGET:H}
	cp -v ${.ALLSRC:[1]} ${.TARGET}

${MFSBSD_DIR}/customfiles/usr/freebsd-dist/MANIFEST: ${DIST_DIR}/MANIFEST
	mkdir -pv ${.TARGET:H}
	cp -v ${.ALLSRC:[1]} ${.TARGET}

${MFSBSD_DIR}/customfiles/usr/freebsd-dist/kernel.txz: ${DIST_DIR}/kernel.txz
	mkdir -pv ${.TARGET:H}
	cp -v ${.ALLSRC:[1]} ${.TARGET}

${MFSBSD_DIR}/customfiles/usr/freebsd-dist/base.txz: ${DIST_DIR}/base.txz
	mkdir -pv ${.TARGET:H}
	cp -v ${.ALLSRC:[1]} ${.TARGET}

${MFSBSD_DIR}/conf/ttys: ${.TARGET}.sample
	sed -E \
		-e 's,^(ttyv[[:digit:]].+)(Pc),\1al.\2,' \
		-e 's,^(ttyu[[:digit:]].+)3wire,\1al.115200,' \
		${.ALLSRC:[1]} > ${.TARGET}

${MFSBSD_DIR}/conf/loader.conf: ${.TARGET}.sample
	sed -E \
		-e 's,^(mfsbsd.autodhcp)="YES",\1="NO",' \
		${.ALLSRC:[1]} > ${.TARGET}

${MFSBSD_DIR}/tools/packages:
	> ${.TARGET}

${MFSBSD_DIR}/tools/do_gpt.autobsd.sh: ${MFSBSD_DIR}/tools/do_gpt.sh
	sed -E \
		-e 's,^(TMPIMG=).+,\1"$$(mktemp -p . -t $$(basename $${FSIMG}))",' \
		${.ALLSRC:[1]} > ${.TARGET}
	chmod +x ${.TARGET}

${MFSBSD_DIR}/Makefile.autobsd: ${MFSBSD_DIR}/Makefile ${MFSBSD_DIR}/tools/do_gpt.autobsd.sh
	sed -E \
		-e 's,^iso[[:space:]]*.*:,ISOLABEL ?= AutoBSD\n\n&,' \
		-e 's,(label=)mfsbsd,\1${ISO_LABEL},i' \
		-e 's,(do_gpt)(\.sh),\1.autobsd\2,' \
		${.ALLSRC:[1]} > ${.TARGET}

clean:
	rm -rf ${MFSBSD_DIR}

cleaner: clean
	rm -rf ${DIST_DIR}

cleanest: cleaner
	rm -f *.iso *.iso.sha256 *.img *.img.sha256

pristine: cleanest

# vim:ft=make:
