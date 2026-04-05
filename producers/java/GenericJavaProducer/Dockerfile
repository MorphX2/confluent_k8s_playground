FROM maven:3.9-amazoncorretto-21 AS builder
WORKDIR /build
COPY pom.xml .

RUN mvn dependency:go-offline

COPY src ./src
RUN mvn clean package

FROM eclipse-temurin:21-jre-jammy

# Create a non-root user for security (K8s best practice)
RUN groupadd -r appgroup && useradd -r -g appgroup appuser
USER appuser

WORKDIR /app
COPY --from=builder /build/target/producer.jar /app/producer.jar

ENTRYPOINT ["java", "-jar", "producer.jar"]