# Folosește un JDK slim (Java 17)
FROM openjdk:17-jdk-slim

# Setează un director de lucru
WORKDIR /myapp

# Copiază jar-ul construit
COPY target/myapp-0.0.1-SNAPSHOT.jar app.jar

# Expune portul pe care rulează Spring Boot
EXPOSE 8080

# Rulează aplicația
ENTRYPOINT ["java", "-jar", "/myapp/app.jar"]
