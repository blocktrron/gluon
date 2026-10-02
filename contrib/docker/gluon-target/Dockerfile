ARG GLUON_BUILD_IMAGE=gluon-build
FROM ${GLUON_BUILD_IMAGE}

ARG GLUON_COMMIT
ARG GLUON_TARGET

RUN test -n "${GLUON_COMMIT}" \
	&& test -n "${GLUON_TARGET}" \
	&& git clone https://github.com/freifunk-gluon/gluon.git . \
	&& git checkout "${GLUON_COMMIT}" \
	&& make update \
	&& make -j4 V=s GLUON_TARGET="${GLUON_TARGET}" toolchain
