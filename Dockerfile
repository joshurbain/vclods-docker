FROM oraclelinux:8

RUN dnf -y update && dnf clean all && \
    dnf install -y python3 python3-pip git findutils gettext ksh mysql which rsyslog sudo passwd \
                   logrotate postgresql psmisc sshpass epel-release

# Install SQL Server tools (SQLCMD)
RUN curl -o /etc/yum.repos.d/msprod.repo https://packages.microsoft.com/config/rhel/8/prod.repo && \
    ACCEPT_EULA=Y dnf install -y mssql-tools unixODBC-devel && \
    ln -s /opt/mssql-tools/bin/sqlcmd /usr/local/bin/sqlcmd

# Install jq (EPEL is required for this)
RUN dnf install -y jq

# Setup rsyslogd (to do nothing)
RUN touch /etc/rsyslog.conf && rsyslogd

WORKDIR /app/scripts
ADD ./vclods /app

# Install Oracle Instant Client and SQL*Plus
RUN dnf install -y oracle-instantclient-release-el8 && \
    dnf install -y oracle-instantclient-basic oracle-instantclient-sqlplus oracle-instantclient-tools && \
    ln -s /usr/lib/oracle/21/client64/lib/network/admin /app/oracle_config
ENV PATH="/usr/lib/oracle/21/client64/bin:$PATH"

RUN chmod +x /app/INSTALL.sh /app/run_tests.sh
RUN /app/INSTALL.sh

RUN touch /app/test/secure_config

COPY ./docker-entrypoint.sh /
RUN chmod 777 /docker-entrypoint.sh

# @USER_TODO: Setup your password here
RUN useradd -m -s /bin/bash -G wheel vclods && \
    echo -e "r3@llyl4m3p@55w0rd\nr3@llyl4m3p@55w0rd" | passwd vclods
RUN chown vclods:root -R /app

RUN printf """\
VCLOD_LOCK_DIR=/dev/shm/\n\
VCLOD_ERR_DIR=/dev/shm/\n\
LOG_BASE_DIR=/tmp/\n\
""" > /etc/vclods

# @USER_TODO: Setup your connection information here
RUN printf """\n\
VCLOD_ENGINE=mysql\n\
VCLOD_HOST=host.docker.internal\n\
VCLOD_USER=root\n\
VCLOD_PASSWORD=r3@llyl4m3p@55w0rd\n\
VCLOD_DB=information_schema\n\
OPERATIONS_EMAIL=[your-email-here]\n\
""" >> /etc/vclods

# Allow cleartext passwords for legacy connections
ENV LIBMYSQL_ENABLE_CLEARTEXT_PLUGIN=y

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["vclods"]
