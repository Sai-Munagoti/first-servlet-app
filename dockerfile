# Use Tomcat 9 with JDK 17
FROM tomcat:9-jdk17

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
CMD ["catalina.sh", "run"]

