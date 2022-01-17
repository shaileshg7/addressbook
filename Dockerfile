FROM maven:3.8.3-jdk-11 as build
WORKDIR /app
COPY . /app
RUN mvn clean install -DskipTests

FROM openjdk:11
WORKDIR /app
COPY --from=build /app/  /app/
EXPOSE 8080
ENTRYPOINT ["java","-jar","/app/target/addressbook.jar"]