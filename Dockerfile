# Use UBI 8.10 as the base image
FROM registry.access.redhat.com/ubi8/ubi:8.10 AS builder

# Define build-time arguments for Sonar Scanner and GitHub Runner versions
ARG MAVEN_VERSION=3.5.4
ARG SONAR_SCANNER_VERSION=5.0.1.3006
ARG GITHUB_RUNNER_VERSION=2.325.0

# Create /u01 directory, create 'oracle' user with home at /u01/oracle
# Grant appropriate permissions to the oracle user
RUN mkdir /u01 && \
    useradd -b /u01 -d /u01/oracle -m -s /bin/bash oracle && \
    chown oracle:root -R /u01 && \
    chmod -R 775 /u01

# Copy JDK tarball to image and extract it to /u01/jdk
# Also create Maven local repository directory for oracle user
COPY jdk-8u291-linux-x64.tar.gz /tmp/jdk-8u291-linux-x64.tar.gz
RUN mkdir -p /u01/jdk && \
    tar -xvzf /tmp/jdk-8u291-linux-x64.tar.gz -C /u01/jdk && \
    rm -f /tmp/jdk-8u291-linux-x64.tar.gz && \
    mkdir -p /u01/oracle/.m2

# Copy pre-extracted Maven repository to oracle user's home
COPY --chown=oracle:oracle m2_extracted/.m2 /u01/oracle/.m2
RUN chmod -R u+rwX /u01/oracle/.m2

# Switch to root and set required environment variables
USER root
ENV FMW_JAR1=fmw_12.2.1.4.0_soa_quickstart.jar \
    FMW_JAR2=fmw_12.2.1.4.0_soa_quickstart2.jar \
    JAVA_HOME=/u01/jdk/jdk1.8.0_291 \
    ORACLE_HOME=/u01/oracle \
    MAVEN_HOME=/u01/maven \
    SONAR_SCANNER_HOME=/u01/sonar-scanner \
    RUNNER_HOME=/u01/runner/actions-runner \
    PATH=$PATH:/u01/jdk/jdk1.8.0_291/bin:/u01/oracle/oracle_common/common/bin:/u01/oracle/wlserver/common/bin:/u01/maven/bin:/u01/sonar-scanner/bin

# Install necessary utilities and libraries required for Maven, Sonar, and runner
RUN yum install -y \
        curl \
        jq \
        tar \
        unzip \
        git \
        libicu \
        krb5-libs \
        libcurl \
        openssl \
        zlib \
        gettext \
    && yum clean all

# Download and extract Maven manually (fixed to 3.5.4 due to compatibility needs)
RUN curl -fsSL https://archive.apache.org/dist/maven/maven-3/3.5.4/binaries/apache-maven-3.5.4-bin.tar.gz -o /tmp/maven.tar.gz && \
    tar -xzf /tmp/maven.tar.gz -C /u01 && \
    ln -s /u01/apache-maven-${MAVEN_VERSION} /u01/maven && \
    rm -f /tmp/maven.tar.gz

# Download and extract Sonar Scanner CLI to /u01 and create a symbolic link
RUN curl -fsSL https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-${SONAR_SCANNER_VERSION}-linux.zip -o /tmp/sonar.zip && \
    unzip /tmp/sonar.zip -d /u01 && \
    ln -s /u01/sonar-scanner-${SONAR_SCANNER_VERSION}-linux /u01/sonar-scanner && \
    rm -f /tmp/sonar.zip

# Copy WebLogic SOA installer files and installation config to image
COPY --chown=oracle:root $FMW_JAR1 $FMW_JAR2 soasuite.response oraInst.loc /u01/

# Switch to oracle user and run WebLogic SOA QuickStart installation in silent mode
USER oracle
RUN cd /u01/ && \
    java -jar $FMW_JAR1 -silent -responseFile /u01/soasuite.response -invPtrLoc /u01/oraInst.loc -jreLoc $JAVA_HOME -ignoreSysPrereqs -force -novalidation ORACLE_HOME=$ORACLE_HOME

# Setup GitHub Actions Runner
WORKDIR /u01/runner
RUN mkdir -p ${RUNNER_HOME} && \
    cd ${RUNNER_HOME} && \
    curl -fsSL -o actions-runner.tar.gz https://github.com/actions/runner/releases/download/v${GITHUB_RUNNER_VERSION}/actions-runner-linux-x64-${GITHUB_RUNNER_VERSION}.tar.gz && \
    tar -xzf actions-runner.tar.gz && \
    rm actions-runner.tar.gz

# Copy entrypoint script for container start-up and make it executable
USER root
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Switch back to oracle user and set entrypoint
USER oracle
ENTRYPOINT ["/entrypoint.sh"]
