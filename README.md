##Dockerization & CI/CD Documentation for first-servlet-app##
1. Project Overview
first-servlet-app is a Java web application. The CI/CD pipeline automates:
Git clone
SonarQube code analysis
Maven build (WAR artifact)
Upload to Nexus
Dockerize WAR
Push Docker image to DockerHub
Deploy in Tomcat container
________________________________________
2. Prerequisites
2.1 Software / Tools
Git – Source code management
Jenkins – CI/CD automation
SonarQube – Code quality analysis
Nexus Repository – Artifact storage
Docker & DockerHub – Containerization
Maven – Build automation
2.2 Jenkins Plugins
GitHub Integration
Pipeline
SonarQube Scanner
Docker Pipeline
Nexus Artifact Uploader (optional)
2.3 Jenkins Credentials
Credential	ID
SonarQube Token	Sonar
Nexus Username/Password	Nexus
DockerHub Username/Password	dockerhub
________________________________________
3. Architecture
GitHub (first-servlet-app)
        │
        ▼
  Jenkins Pipeline
        │
  ┌─────┴─────┐
  │           │
SonarQube   Maven Build
  │           │
  └───> Nexus Repository
            │
        Dockerize WAR
            │
       DockerHub Push
            │
      Deploy to Tomcat
________________________________________
4. Jenkins Pipeline (Declarative)
pipeline {
    agent any
    environment {
        REPO = "munagotisai/first-servlet-app"
        NEXUS_URL = "http://51.20.35.90:8081"
        NEXUS_RELEASE_REPO = "maven-releases"
        NEXUS_SNAPSHOT_REPO = "maven-snapshots"
        SONAR_TOKEN = credentials('Sonar')
    }

 









 

    tools { maven 'Maven3' }

    stages {
        stage('Clone') { steps { git branch: 'main', url: 'https://github.com/Sai-Munagoti/first-servlet-app.git' } }

        stage('Code Quality') {
            steps { withSonarQubeEnv('sonar') { sh "mvn clean verify sonar:sonar -Dsonar.login=${SONAR_TOKEN}" } }
        }

        stage('Build') { steps { sh 'mvn clean package' } }

        stage('Upload to Nexus') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'Nexus', usernameVariable: 'NEXUS_USER', passwordVariable: 'NEXUS_PASS')]) {
                    sh 'mvn deploy -Dusername=${NEXUS_USER} -Dpassword=${NEXUS_PASS}'
                }
            }
        }

        stage('Dockerize') {
            steps {
                writeFile file: 'Dockerfile', text: 'FROM tomcat:9\nCOPY app.war /usr/local/tomcat/webapps/'
                sh "docker build -t ${REPO}:latest ."
            }
        }

        stage('Push to DockerHub') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'dockerhub', usernameVariable: 'USER', passwordVariable: 'PASS')]) {
                    sh "echo $PASS | docker login -u $USER --password-stdin && docker push ${REPO}:latest"
                }
            }
        }

        stage('Deploy to Tomcat') {
            steps {
                sh """
                    docker stop tomcat-app || true
                    docker rm tomcat-app || true
                    docker run -d --name tomcat-app -p 9090:8080 ${REPO}:latest
                """
            }
        }
    }

    post {	
        success { echo 'Pipeline executed successfully!' }
        failure { echo 'Pipeline failed!' }
    }
}




________________________________________
 


5. Dockerfile
# Nexus connection info (static)
ENV NEXUS_URL=http://51.20.35.90:8081
ENV GROUP_PATH=com/aja/first-servlet-app
ENV VERSION=1.0-SNAPSHOT
ENV NEXUS_REPO=maven-snapshots

# Accept username/password from --build-arg
ARG NEXUS_USER
ARG NEXUS_PASS

# Install curl
RUN apt-get update && apt-get install -y curl && apt-get clean

# Clean default webapps
RUN rm -rf /usr/local/tomcat/webapps/*

# Copy base webapps
RUN cp -r /usr/local/tomcat/webapps.dist/* /usr/local/tomcat/webapps/

# Download latest snapshot WAR
RUN SNAP_VERSION=$(curl -s -u "$NEXUS_USER:$NEXUS_PASS" \
      $NEXUS_URL/repository/$NEXUS_REPO/$GROUP_PATH/$VERSION/maven-metadata.xml \
      | awk '/<snapshotVersion>/{flag=1} /<\/snapshotVersion>/{flag=0} flag' \
      | grep -A1 '<extension>war</extension>' \
      | grep -oPm1 "(?<=<value>)[^<]+") && \
    WAR_FILE="first-servlet-app-$SNAP_VERSION.war" && \
    echo "Resolved WAR = $WAR_FILE" && \
    curl -u "$NEXUS_USER:$NEXUS_PASS" \
      -o /usr/local/tomcat/webapps/app.war \
      $NEXUS_URL/repository/$NEXUS_REPO/$GROUP_PATH/$VERSION/$WAR_FILE

# Expose Tomcat port
EXPOSE 8080

# Start Tomcat
CMD ["catalina.sh", "run"]________________________________________



 



6. Usage
Run Jenkins Pipeline:
Create a new pipeline job.
Add credentials (Sonar, Nexus, DockerHub).
Paste the Jenkinsfile and run.
Access Applications:
Tomcat App → http://<Jenkins_host>:9090/app
SonarQube → http://<Sonar_host>:9000
Jenkins → http://<Jenkins_host>:8080
Nexus → http://<Nexus_host>:8081
________________________________________
7. Benefits
Fully automated CI/CD
Enforced code quality via SonarQube
Artifact management with Nexus

 
