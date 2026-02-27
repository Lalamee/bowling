FROM gradle:8.7-jdk17-alpine AS build
WORKDIR /build

COPY build.gradle settings.gradle gradlew ./
COPY gradle ./gradle
COPY src ./src
COPY auth-service ./auth-service
COPY core-service ./core-service

RUN ./gradlew :auth-service:bootJar --no-daemon -x test

FROM amazoncorretto:17
WORKDIR /app
COPY --from=build /build/auth-service/build/libs/auth-service.jar app.jar

EXPOSE 8082
ENTRYPOINT ["java", "-jar", "app.jar"]
