# 参考https://github.com/timescale/timescaledb-docker-ha/blob/master/Dockerfile
# 基于 postgres:16 镜像[Debian-bookworm 镜像]
# Dockerfile for PostgreSQL with Apache AGE, PGvector, PGAudit, and pgsodium extensions

# Define build arguments for versions
ARG POSTGRES_VERSION=16 #可修改

# Stage 1: Builder stage for compiling extensions
FROM postgres:${POSTGRES_VERSION} AS builder
ARG PG_VER=16 #可修改

ARG AGE_VERSION="PG16/v1.5.0-rc0"  #AGE 目前最新支持是 PG16
ARG PGAUDIT_VERSION="REL_16_STABLE"
ARG PGVECTOR_VERSION=0.8.0
ARG PGSODIUM_VERSION=3.1.9 #默认先不启用
ARG PGVECTO_RS=0.4.0
ARG PGVECTORSCALE_VERSION="0.5.1"

# Install necessary build tools and dependencies
USER root
RUN apt-get update && apt-get install -y --no-install-recommends \
    postgresql-server-dev-${PG_VER} \
    build-essential libreadline-dev zlib1g-dev flex bison\
    ca-certificates unzip\
    curl \
    git \
    pkg-config \
    libkrb5-dev \
    libsodium-dev \
    libssl-dev \
    python3-dev \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean && mkdir -p /usr/local/share/postgresql/extension; mkdir -p /usr/local/lib/postgresql 

# Compile Apache AGE
RUN git clone --depth 1 --branch ${AGE_VERSION} https://github.com/apache/age.git \
    && cd age \
    && pg_config \
    && make -j$(nproc) && make install \
    && cd .. && rm -rf age \
    && cp -r /usr/share/postgresql/${PG_VER}/extension/age* /usr/local/share/postgresql/extension/ \
    && cp -r /usr/lib/postgresql/${PG_VER}/lib/age.so /usr/local/lib/postgresql/ 

# Compile pgvector
RUN git clone --depth 1 --branch v${PGVECTOR_VERSION} https://github.com/pgvector/pgvector.git \
    && cd pgvector \
    && make OPTFLAGS="-O2"  && make install \
    && cd .. && rm -rf pgvector \
    && cp -r /usr/share/postgresql/${PG_VER}/extension/vector* /usr/local/share/postgresql/extension/ \
    && cp -r /usr/lib/postgresql/${PG_VER}/lib/vector.so /usr/local/lib/postgresql/ 

# INSTALL VECTO.RS
RUN curl --silent \
            --location \
            --output /tmp/vectors.deb \
            "https://github.com/tensorchord/pgvecto.rs/releases/download/v${PGVECTO_RS}/vectors-pg${PG_VER}_${PGVECTO_RS}_$(dpkg --print-architecture).deb" && \
        dpkg -i /tmp/vectors.deb && \
        rm -rfv /tmp/vectors.deb && \
        cp -r /usr/lib/postgresql/${PG_VER}/lib/vectors.so /usr/local/lib/postgresql/ ;\
        cp -r /usr/share/postgresql/${PG_VER}/extension/vectors* /usr/local/share/postgresql/extension/


# Compile pgsodium
RUN git clone --depth 1 --branch v${PGSODIUM_VERSION} https://github.com/michelp/pgsodium.git \
    && cd pgsodium \
    && make  -j$(nproc) && make install \
    && cd .. && rm -rf pgsodium \
    && cp -r /usr/share/postgresql/${PG_VER}/extension/pgsodium* /usr/local/share/postgresql/extension/ \
    && cp -r /usr/lib/postgresql/${PG_VER}/lib/pgsodium.so /usr/local/lib/postgresql/

# Compile PGAudit
RUN git clone --depth 1 --branch ${PGAUDIT_VERSION} https://github.com/pgaudit/pgaudit.git \
    && cd pgaudit \
    && make USE_PGXS=1 PG_CONFIG=$(which pg_config) && make USE_PGXS=1 install \
    && cd .. && rm -rf pgaudit \
    && cp -r /usr/share/postgresql/${PG_VER}/extension/pgaudit* /usr/local/share/postgresql/extension/ \
    && cp -r /usr/lib/postgresql/${PG_VER}/lib/pgaudit.so /usr/local/lib/postgresql/ 

# Download and install pgvectorscale
RUN curl --silent \
        --location \
        --output /tmp/pgvectorscale.zip \
    "https://github.com/timescale/pgvectorscale/releases/download/${PGVECTORSCALE_VERSION}/pgvectorscale-${PGVECTORSCALE_VERSION}-pg${PG_VER}-$(dpkg --print-architecture).zip" && \
    unzip /tmp/pgvectorscale.zip -d /tmp && \
    dpkg -i //tmp/pgvectorscale-postgresql-${PG_VER}_${PGVECTORSCALE_VERSION}*.deb && \
    strip --strip-unneeded "/usr/lib/postgresql/${PG_VER}/lib/pgvectorscale.so" && \
    rm -rf /tmp/pgvectorscale.zip /tmp/pgvectorscale-postgresql-${PG_VER}-*.deb ;\
    cp -r /usr/share/postgresql/${PG_VER}/extension/vectorscale* /usr/local/share/postgresql/extension/ \
    && cp -r /usr/lib/postgresql/${PG_VER}/lib/vectorscale*.so /usr/local/lib/postgresql/


    # Strip unnecessary symbols from shared libraries
RUN find /usr/local/lib/postgresql/  -name "*.so" -exec strip --strip-unneeded {} \;

# Copy extensions to postgres user directory

    #  && cp -r /usr/lib/postgresql/${PG_VER}/lib/* /usr/local/lib/postgresql/ \
    # && cp -r /usr/share/postgresql/${PG_VER}/extension/* /usr/local/share/postgresql/extension/

# Stage 2: Final image
FROM postgres:${POSTGRES_VERSION} AS final
ARG PG_VER=16 #可修改
# RUN apt-get update && apt-get install -y --no-install-recommends  \
#     postgresql-${PG_VER}-pgaudit \
#     postgresql-${PG_VER}-cron \
#     && rm -rf /var/lib/apt/lists/* \
#     && apt-get clean 
RUN apt-get update && apt-get install -y libsodium-dev \
libssl-dev  locales\
&& rm -rf /var/lib/apt/lists/* \
&& apt-get clean && localedef -i zh_CN -c -f UTF-8 -A /usr/share/locale/locale.alias zh_CN.UTF-8
# Copy compiled extensions from builder stage
COPY --from=builder --chown=postgres:postgres /usr/local/lib/postgresql/* /usr/lib/postgresql/${PG_VER}/lib/
COPY --from=builder --chown=postgres:postgres /usr/local/share/postgresql/extension/* /usr/share/postgresql/${PG_VER}/extension/

# 使用环境变量来管理密钥
# ENV PGSODIUM_KEY_FILE=/run/secrets/pgsodium_key
# 创建更安全的 pgsodium_getkey 脚本
# RUN echo '#!/bin/bash\nif [ -f "$PGSODIUM_KEY_FILE" ]; then\n  cat "$PGSODIUM_KEY_FILE"\nelse\n  echo "Key file not found" >&2\n  exit 1\nfi' > /usr/local/bin/pgsodium_getkey \
#     && chmod 500 /usr/local/bin/pgsodium_getkey \
#     && chown postgres:postgres /usr/local/bin/pgsodium_getkey

# Copy custom PostgreSQL configuration
COPY --chown=postgres:postgres  custom.conf /etc/postgresql/${PG_VER}/main/conf.d/

USER postgres
# Copy initialization script
COPY init.sql /docker-entrypoint-initdb.d/

# Health check to ensure PostgreSQL is ready
HEALTHCHECK --interval=30s --timeout=10s CMD pg_isready -U postgres

# Expose PostgreSQL default port
EXPOSE 5432

# Start PostgreSQL
# CMD ["postgres"]
CMD ["postgres", "-c", "shared_preload_libraries=age,vector,vectors,pgaudit"]


