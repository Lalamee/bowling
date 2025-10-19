# Build stage
FROM gradle:8.7-jdk17-alpine AS build
WORKDIR /build

COPY build.gradle settings.gradle gradlew ./
COPY gradle ./gradle

RUN ./gradlew dependencies --no-daemon || true

COPY src ./src

RUN ./gradlew clean bootJar --no-daemon -x test --refresh-dependencies

# Runtime stage
FROM amazoncorretto:17
WORKDIR /app
COPY --from=build /build/build/libs/*.jar app.jar

ENV SPRING_PROFILES_ACTIVE=prod

EXPOSE 8080

ENTRYPOINT ["java", "-jar", "app.jar"]