FROM centos:7

RUN yum -y update && yum clean all && \
    yum install -y python3 git findutils gettext ksh mysql which rsyslog sudo passwd logrotate postgresql epel-release && \
    curl https://bootstrap.pypa.io/pip/3.6/get-pip.py | python3

# Install SQL Server tools (SQLCMD)
RUN curl -o /etc/yum.repos.d/msprod.repo https://packages.microsoft.com/config/rhel/8/prod.repo && \
    ACCEPT_EULA=Y yum install -y mssql-tools unixODBC-devel && \
    ln -s /opt/mssql-tools/bin/sqlcmd /usr/local/bin/sqlcmd

# Install jq (EPEL is required for this)
RUN yum install -y jq

# Setup rsyslogd (to do nothing)
RUN touch /etc/rsyslog.conf && rsyslogd

WORKDIR /app
ADD ./vclods /app

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

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["vclods"]
