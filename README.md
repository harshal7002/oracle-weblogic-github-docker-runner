# oracle-weblogic-github-docker-runner

This Docker image provides a self-hosted GitHub Actions runner with the following pre-installed:

- Oracle SOA Suite 12.2.1.4 QuickStart
- Oracle JDK 8u291
- Apache Maven 3.5.4
- Sonar Scanner CLI 5.0.1.3006
- Preloaded `.m2` Maven repository
- GitHub Actions Runner 2.325.0

## 📁 Directory Structure
├── Dockerfile
├── jdk-8u291-linux-x64.tar.gz
├── fmw_12.2.1.4.0_soa_quickstart.jar
├── fmw_12.2.1.4.0_soa_quickstart2.jar
├── soasuite.response
├── oraInst.loc
├── m2_extracted/
└── entrypoint.sh

## 🏗️ Build the Docker Image

Make sure all required files are in the current directory, then run:

```
docker build -t github-oracle-runner .
```

## 🚀 Run the Container
```
docker run -d \
  -e GITHUB_URL=https://github.com/your-org-or-user/your-repo \
  -e GITHUB_TOKEN=your_github_self_hosted_runner_token \
  -e RUNNER_NAME=github-oracle-runner \
  --name github-oracle-runner \
  --restart unless-stopped \
  github-oracle-runner
```


## 🔧 Required Environment Variables

| Variable       | Description                                                            |
| -------------- | ---------------------------------------------------------------------- |
| `GITHUB_URL`   | GitHub repository or org URL (e.g., `https://github.com/org`)          |
| `GITHUB_TOKEN` | GitHub registration token for the runner (generate from GitHub UI/API) |
| `RUNNER_NAME`  | Name assigned to this self-hosted runner instance                      |


## 📝 Notes
The m2_extracted/ directory should contain a .m2 Maven cache to reduce dependency downloads.
entrypoint.sh is responsible for registering the GitHub runner and handling lifecycle tasks.



# 🔄 How to Update Tools
To update any tool in the image:

✅ Maven
Change ARG MAVEN_VERSION=3.5.4 to the new version (e.g. 3.9.6).

Update the download URL inside the Dockerfile:
https://archive.apache.org/dist/maven/maven-3/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.tar.gz
Rebuild the image.

✅ Sonar Scanner
Change ARG SONAR_SCANNER_VERSION=5.0.1.3006 to the desired version.

Update the download URL in the Dockerfile:
https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-${SONAR_SCANNER_VERSION}-linux.zip
Rebuild the image.

✅ GitHub Runner
Change ARG GITHUB_RUNNER_VERSION=2.325.0 to the new version.

Update the download link:
https://github.com/actions/runner/releases/download/v${GITHUB_RUNNER_VERSION}/actions-runner-linux-x64-${GITHUB_RUNNER_VERSION}.tar.gz
Rebuild the image.

✅ JDK
Download the desired JDK version tarball from Oracle or OpenJDK.

Replace jdk-8u291-linux-x64.tar.gz file.
Update the JAVA_HOME path accordingly in the Dockerfile:

ENV JAVA_HOME=/u01/jdk/jdk<new_version>
Rebuild the image after making these changes using the docker build command.
