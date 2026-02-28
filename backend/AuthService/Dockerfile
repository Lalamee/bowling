# Build stage
FROM gradle:8.7-jdk17-alpine AS build
WORKDIR /build

COPY build.gradle settings.gradle ./
COPY gradle ./gradle
COPY src ./src

RUN gradle clean bootJar --no-daemon -x test --refresh-dependencies

# Runtime stage
FROM amazoncorretto:17
WORKDIR /app

COPY --from=build /build/build/libs/*.jar app.jar

ENV SPRING_PROFILES_ACTIVE=prod

EXPOSE 8081

ENTRYPOINT ["java", "-jar", "app.jar"]
