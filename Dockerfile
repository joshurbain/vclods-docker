FROM oraclelinux:8

# Automatically set by Docker when --platform is passed to docker build
ARG TARGETARCH

RUN dnf -y update && dnf clean all && \
    dnf install -y python3 python3-pip git findutils gettext ksh mysql which rsyslog sudo passwd \
                   logrotate postgresql psmisc sshpass epel-release jq

# Install SQL Server tools (SQLCMD) — amd64 only
RUN if [ "$TARGETARCH" = "amd64" ]; then \
      curl -o /etc/yum.repos.d/msprod.repo https://packages.microsoft.com/config/rhel/8/prod.repo && \
      ACCEPT_EULA=Y dnf install -y mssql-tools unixODBC-devel && \
      ln -s /opt/mssql-tools/bin/sqlcmd /usr/local/bin/sqlcmd; \
    fi

WORKDIR /app/scripts
COPY ./vclods /app

# Install Oracle Instant Client and SQL*Plus — amd64 only
RUN if [ "$TARGETARCH" = "amd64" ]; then \
      dnf install -y oracle-instantclient-release-el8 && \
      dnf install -y oracle-instantclient-basic oracle-instantclient-sqlplus oracle-instantclient-tools && \
      ln -s /usr/lib/oracle/21/client64/lib/network/admin /app/oracle_config; \
    fi
ENV PATH="/usr/lib/oracle/21/client64/bin:$PATH"

RUN chmod +x /app/INSTALL.sh /app/run_tests.sh && \
    /app/INSTALL.sh

RUN touch /app/test/secure_config

COPY ./docker-entrypoint.sh /
RUN chmod 755 /docker-entrypoint.sh

# Override at build time with: docker build --build-arg VCLODS_USER_PASSWORD=yourpassword
ARG VCLODS_USER_PASSWORD=r3@llyl4m3p@55w0rd
RUN useradd -m -s /bin/bash -G wheel vclods && \
    echo "vclods:${VCLODS_USER_PASSWORD}" | chpasswd && \
    chown vclods:root -R /app

# Connection config — override at runtime with: docker run -e VCLOD_HOST=... -e VCLOD_PASSWORD=...
ENV VCLOD_ENGINE=mysql
ENV VCLOD_HOST=host.docker.internal
ENV VCLOD_USER=root
ENV VCLOD_PASSWORD=r3@llyl4m3p@55w0rd
ENV VCLOD_DB=information_schema
ENV OPERATIONS_EMAIL="username@example.com"

# Allow cleartext passwords for legacy connections
ENV LIBMYSQL_ENABLE_CLEARTEXT_PLUGIN=y

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["vclods"]
