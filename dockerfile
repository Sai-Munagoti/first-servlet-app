# ============================
# 1️⃣ BUILD STAGE (Maven + JDK17)
# ============================
FROM maven:3.9.6-eclipse-temurin-17-alpine AS build

WORKDIR /app

COPY pom.xml .
RUN mvn dependency:go-offline

COPY src ./src
RUN mvn clean package -DskipTests


# ============================
# 2️⃣ RUNTIME STAGE (Tomcat + JRE17)
# ============================
FROM tomcat:10.1-jdk17-temurin AS runtime

WORKDIR /usr/local/tomcat

# Remove default webapps
RUN rm -rf /usr/local/tomcat/webapps/*

# Copy base webapps
#RUN cp -r /usr/local/tomcat/webapps.dist/* /usr/local/tomcat/webapps/

# Copy WAR file from build stage
COPY --from=build /app/target/*.war /usr/local/tomcat/webapps/ROOT.war

EXPOSE 8080

CMD ["catalina.sh", "run"]

