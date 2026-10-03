ARG GLUON_BUILD_IMAGE=gluon-build
FROM ${GLUON_BUILD_IMAGE}

ARG GLUON_COMMIT
ARG GLUON_TARGET
ARG GLUON_REPO

RUN test -n "${GLUON_COMMIT}" \
	&& test -n "${GLUON_TARGET}" \
	&& git clone "${GLUON_REPO}" \
	&& git -C gluon checkout "${GLUON_COMMIT}" \
	&& ln -s docs/site-example gluon/site
	&& make -C gluon update \
	&& make -C gluon -j4 V=s GLUON_TARGET="${GLUON_TARGET}" toolchain \
	&& rm gluon/site
