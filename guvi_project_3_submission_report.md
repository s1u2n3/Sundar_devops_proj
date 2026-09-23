# DevOps Assignment -- Complete Implementation Guide

## 1. Introduction

This project implements a complete CI/CD workflow for deploying a React
application using Docker, Docker Compose, GitHub, Jenkins, Docker Hub,
AWS EC2 and Uptime Kuma.

The objective was to take the provided React production build,
containerize it, automate image creation and publishing through Jenkins,
deploy the production image to AWS EC2, and continuously monitor the
deployed application.

Supporting screenshots covering the implementation, configuration,
successful builds, AWS setup, Docker Hub repositories, deployment and
monitoring have been uploaded to the project repository.

------------------------------------------------------------------------

## 2. Project Repository Setup

The project was maintained in GitHub:

**Repository:**\
https://github.com/s1u2n3/Sundar_devops_proj

Git was used through the command line for version control.

The repository contains the application build along with the Docker,
Compose, Bash and Jenkins configuration required for the deployment.

The main branches used for the CI/CD process are:

-   `dev` -- development branch
-   `master` -- production branch

The same `Jenkinsfile` is maintained in both branches so that the
pipeline logic remains consistent.

------------------------------------------------------------------------

## 3. React Application

The provided React application already contained a compiled production
`build` directory.

The build contains the static React application files such as:

-   `index.html`
-   `static/`
-   `asset-manifest.json`
-   `favicon.ico`
-   React application assets

Since the compiled build was already available, a separate Node.js build
process was not required for deployment.

The application was first verified locally by serving the existing
`build` directory and confirming that the React application loaded
correctly.

------------------------------------------------------------------------

## 4. Creating the Dockerfile

The React production build was containerized using Nginx.

The Dockerfile was created as follows:

``` dockerfile
FROM nginx:alpine

COPY build/ /usr/share/nginx/html/

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
```

### Explanation

-   `nginx:alpine` provides a lightweight production web server.
-   The compiled React files are copied into Nginx's default web root.
-   Port 80 is exposed for HTTP access.
-   Nginx is kept running in the foreground so that Docker can manage
    the container correctly.

The Docker image was initially tested locally to verify that the React
application worked correctly through Nginx.

------------------------------------------------------------------------

## 5. Docker Compose

Docker Compose was introduced to simplify application deployment and
container management.

The Compose configuration was designed to use the Docker Hub production
image:

``` yaml
services:
  app:
    image: ${IMAGE_NAME:-sund123/prod}:${IMAGE_TAG:-latest}
    container_name: sundar-devops-app
    ports:
      - "80:80"
    restart: unless-stopped
```

### Explanation

The application container:

-   Uses the Docker Hub image.
-   Runs as `sundar-devops-app`.
-   Maps EC2 port 80 to container port 80.
-   Automatically restarts if the container stops.
-   Allows the image name and tag to be supplied through environment
    variables.

This makes the same Compose configuration reusable while allowing
Jenkins to deploy the production image.

------------------------------------------------------------------------

## 6. Git Ignore Configuration

A `.gitignore` file was created to prevent unnecessary files from being
committed.

``` gitignore
*.log
```

A `.dockerignore` file was also created:

``` dockerignore
.git
*.log
```

The Git repository itself is excluded from the Docker build context, and
log files are ignored.

The Dockerfile and Docker Compose file were intentionally kept in Git
because they are required components of the deployment.

------------------------------------------------------------------------

## 7. Bash Build Script

A `build.sh` script was created to standardize Docker image creation:

``` bash
#!/bin/bash
docker build -t sundar-devops-app .
```

This script provides a simple command-line way to build the application
image.

Although Jenkins performs the actual CI build, keeping the build script
in the repository satisfies the assignment requirement and provides a
reusable build command.

------------------------------------------------------------------------

## 8. Bash Deployment Script

A `deploy.sh` script was created for production deployment:

``` bash
#!/bin/bash

set -e

IMAGE_NAME="sund123/prod"
IMAGE_TAG="latest"

echo "Pulling production image..."
docker pull ${IMAGE_NAME}:${IMAGE_TAG}

echo "Stopping existing application..."
docker compose down || true

echo "Starting production application..."
IMAGE_NAME=${IMAGE_NAME} IMAGE_TAG=${IMAGE_TAG} docker compose up -d

echo "Application deployed successfully."
docker ps
```

### Deployment process

The script:

1.  Pulls the latest production image from Docker Hub.
2.  Stops the existing application container.
3.  Starts the new production container using Docker Compose.
4.  Displays the running containers after deployment.

This script is executed by Jenkins during the production pipeline.

------------------------------------------------------------------------

## 9. Docker Hub Setup

Two Docker Hub repositories were created to separate development and
production images.

### Development repository

``` text
sund123/dev
```

This repository receives images generated from the `dev` branch.

### Production repository

``` text
sund123/prod
```

This repository receives images generated from the `master` branch.

The production repository was configured as **private**, as required by
the assignment.

The development repository can be used for development and testing
images, while the production repository is used by the AWS deployment.

No Docker images were manually pushed as part of the final CI/CD
workflow. Jenkins performs the Docker Hub push.

------------------------------------------------------------------------

## 10. AWS EC2 Setup

An AWS EC2 instance was created to host Jenkins and the deployed
application.

The same EC2 instance was used for both purposes to keep the
infrastructure simple and suitable for the assignment.

The server hosts:

-   Jenkins
-   Docker
-   Docker Compose
-   The production React application
-   Uptime Kuma monitoring

The deployed application is available on HTTP port 80.

The EC2 public IP used during the implementation was:

``` text
16.4.35.99
```

------------------------------------------------------------------------

## 11. AWS Security Group

The EC2 Security Group was configured to provide access to the required
services.

The important rules were:

  Port   Purpose                      Source
  ------ ---------------------------- -----------
  22     EC2 administration           My IP
  80     Deployed application         0.0.0.0/0
  8080   Jenkins and GitHub webhook   0.0.0.0/0
  3001   Uptime Kuma                  My IP

Port 80 was made publicly accessible so the deployed application could
be accessed through a browser.

SSH access remained restricted to the administrator's IP.

------------------------------------------------------------------------

## 12. Installing Jenkins

Jenkins was installed directly on the Amazon Linux EC2 instance.

Java 21 was installed first because Jenkins requires Java.

The following components were installed and configured:

-   Amazon Corretto Java 21
-   Jenkins
-   Git
-   Docker
-   Docker Compose

Jenkins was configured as a system service and verified to be running
successfully.

The Jenkins server was accessed through:

``` text
http://16.4.35.99:8080
```

------------------------------------------------------------------------

## 13. Jenkins and Docker Integration

Jenkins needs access to Docker because Jenkins performs the Docker image
build and push operations.

The Jenkins user was added to the Docker group:

``` bash
sudo usermod -aG docker jenkins
```

Jenkins and Docker were then restarted.

Docker access was verified using the Jenkins user:

``` bash
sudo -u jenkins docker version
```

Docker Compose was also installed as a Docker CLI plugin and verified
for the Jenkins user:

``` bash
sudo -u jenkins docker compose version
```

This allowed Jenkins to build, push and deploy Docker containers
directly on the EC2 server.

------------------------------------------------------------------------

## 14. Jenkins Multibranch Pipeline

A Jenkins **Multibranch Pipeline** job was created.

The job automatically discovers branches containing a valid
`Jenkinsfile`.

The configured repository is:

``` text
https://github.com/s1u2n3/Sundar_devops_proj.git
```

The discovered branches used by the CI/CD workflow are:

``` text
dev
master
```

The Jenkins pipeline definition is stored inside the Git repository
rather than being maintained only inside Jenkins.

This provides version-controlled CI/CD configuration.

------------------------------------------------------------------------

## 15. Docker Hub Credentials in Jenkins

Jenkins was configured with Docker Hub credentials.

A Jenkins credential was created using:

``` text
Kind: Username with password
Username: sund123
Credential ID: dockerhub-credentials
```

The password field contains a Docker Hub access token rather than the
normal Docker Hub account password.

The access token is stored securely in Jenkins and is not written
directly into the Jenkinsfile.

This allows Jenkins to authenticate to Docker Hub while avoiding
hard-coded credentials in source code.

------------------------------------------------------------------------

## 16. Jenkinsfile

The same Jenkinsfile is maintained in both the `dev` and `master`
branches.

The pipeline performs:

1.  Source checkout
2.  Docker image build
3.  Docker Hub authentication
4.  Branch-based image publishing
5.  Production deployment for `master`

The pipeline uses the branch name to determine whether the image belongs
to the development or production repository.

### Development branch behavior

When `BRANCH_NAME` is `dev`:

``` text
GitHub dev
   ↓
Jenkins checkout
   ↓
Docker build
   ↓
Docker Hub login
   ↓
Push sund123/dev:<BUILD_NUMBER>
   ↓
Push sund123/dev:latest
```

### Master branch behavior

When `BRANCH_NAME` is `master`:

``` text
GitHub master
   ↓
Jenkins checkout
   ↓
Docker build
   ↓
Docker Hub login
   ↓
Tag image for sund123/prod
   ↓
Push sund123/prod:<BUILD_NUMBER>
   ↓
Push sund123/prod:latest
   ↓
Run deploy.sh
```

The production deployment stage is restricted to the `master` branch.

------------------------------------------------------------------------

## 17. Development CI Pipeline

A change pushed to the `dev` branch triggers the development pipeline.

Jenkins checks out the source and builds the Docker image.

The image is pushed to:

``` text
sund123/dev
```

Two tags are maintained:

``` text
BUILD_NUMBER
latest
```

This provides a development image that can be tested before the changes
are promoted to production.

The development build was successfully tested and the resulting image
was verified in Docker Hub.

------------------------------------------------------------------------

## 18. Production CI/CD Pipeline

When the changes are merged from `dev` into `master`, Jenkins runs the
production pipeline.

The Docker image is built again and tagged for:

``` text
sund123/prod
```

The image is pushed to the private production repository.

After the image is pushed, Jenkins executes:

``` text
deploy.sh
```

The deployment script pulls:

``` text
sund123/prod:latest
```

and starts the application using Docker Compose.

The production build and deployment were successfully completed.

------------------------------------------------------------------------

## 19. GitHub Webhook

A GitHub webhook was configured so that Jenkins does not need to be
manually triggered for every source code change.

The webhook points to:

``` text
http://16.4.35.99:8080/github-webhook/
```

The webhook was tested through GitHub's webhook delivery interface.

A successful delivery was verified, and Jenkins was able to receive the
GitHub event and trigger the appropriate pipeline.

This provides the automatic CI/CD flow:

``` text
Git push
   ↓
GitHub webhook
   ↓
Jenkins
   ↓
Pipeline
```

------------------------------------------------------------------------

## 20. Production Deployment on EC2

The same EC2 instance used for Jenkins was configured to host the
production application.

After Jenkins pushes the production image, the deployment stage executes
the deployment script.

The deployment flow is:

``` text
Docker Hub
    ↓
sund123/prod:latest
    ↓
docker pull
    ↓
docker compose down
    ↓
docker compose up -d
    ↓
sundar-devops-app
    ↓
Port 80
```

The deployed React application was successfully accessed through:

``` text
http://16.4.35.99
```

The application runs inside the Docker container:

``` text
sundar-devops-app
```

with:

``` text
EC2 Port 80 → Container Port 80
```

------------------------------------------------------------------------

## 21. Monitoring with Uptime Kuma

For application monitoring, Uptime Kuma was selected because it is
open-source and provides a simple web-based health monitoring interface.

It was deployed as another Docker container on the same EC2 instance.

The monitoring dashboard is available on:

``` text
http://16.4.35.99:3001
```

The application monitor was configured as an HTTP monitor:

``` text
Monitor Type: HTTP(s)
Name: Sundar React Application
URL: http://16.4.35.99
Heartbeat: 60 seconds
```

The monitor continuously checks whether the application is responding.

The application was verified as:

``` text
UP
```

------------------------------------------------------------------------

## 22. Email Notification for Application Downtime

Uptime Kuma was also configured with an email notification using Gmail
SMTP.

The SMTP configuration uses:

``` text
SMTP Host: smtp.gmail.com
Port: 587
Security: STARTTLS
```

A Google App Password was used instead of the normal Gmail account
password.

The email notification was tested successfully.

The notification is associated with the application monitor so that a
notification can be generated when the application becomes unavailable.

Sensitive credentials and app passwords are not stored in the project
documentation.

------------------------------------------------------------------------

## 23. Final End-to-End Workflow

The complete implemented workflow is:

``` text
                  Developer
                      |
                      v
               GitHub Repository
                      |
             +--------+--------+
             |                 |
            dev              master
             |                 |
             v                 v
          Jenkins           Jenkins
             |                 |
             v                 v
       Docker Build       Docker Build
             |                 |
             v                 v
     Docker Hub dev      Docker Hub prod
                               |
                               v
                          deploy.sh
                               |
                               v
                           AWS EC2
                               |
                               v
                        Docker Compose
                               |
                               v
                         React App :80
                               |
                               v
                         Uptime Kuma
                               |
                       +-------+-------+
                       |               |
                      UP              DOWN
                       |               |
                    Healthy        Email Alert
```

------------------------------------------------------------------------

## 24. Technologies Used

The following technologies and services were used:

### Application

-   React
-   Nginx

### Containerization

-   Docker
-   Docker Compose

### Source Control

-   Git
-   GitHub

### CI/CD

-   Jenkins
-   Jenkins Multibranch Pipeline
-   GitHub Webhook

### Container Registry

-   Docker Hub

Repositories:

``` text
sund123/dev
sund123/prod
```

### Cloud

-   AWS EC2
-   AWS Security Groups

### Monitoring

-   Uptime Kuma
-   Gmail SMTP notifications

### Operating System / Server Tools

-   Amazon Linux
-   Java 21 / Amazon Corretto
-   Git
-   Bash

------------------------------------------------------------------------

## 25. Final URLs

### GitHub Repository

https://github.com/s1u2n3/Sundar_devops_proj

### Deployed Application

http://16.4.35.99

### Jenkins

http://16.4.35.99:8080

### Uptime Kuma

http://16.4.35.99:3001

### Docker Hub Development Image

https://hub.docker.com/r/sund123/dev

### Docker Hub Production Image

https://hub.docker.com/r/sund123/prod

------------------------------------------------------------------------

## 26. Final Result

The project successfully implements the requested DevOps workflow.

The React application is containerized and served through Nginx on port
80. GitHub is used for source control, Jenkins provides automated CI/CD,
Docker Hub stores separate development and production images, and AWS
EC2 hosts the Jenkins server and production application.

The `dev` branch automatically builds and publishes the development
Docker image. Once changes are merged into `master`, Jenkins builds and
publishes the private production image and deploys it to the AWS EC2
server.

GitHub webhooks provide automatic pipeline triggering, while Uptime Kuma
continuously monitors the deployed application and provides email
notification capability when the application becomes unavailable.

Supporting screenshots for the configuration, successful CI/CD builds,
AWS environment, Docker Hub repositories, deployed application, webhook
and monitoring setup have been uploaded separately to the project
repository.
