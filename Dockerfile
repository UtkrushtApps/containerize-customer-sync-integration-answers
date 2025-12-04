# syntax=docker/dockerfile:1

# ---------------------------------------------------------------------------
# Build stage: compile the Spring Boot + Apache Camel application
# ---------------------------------------------------------------------------
FROM maven:3.9.9-eclipse-temurin-17 AS builder

WORKDIR /workspace

# First copy only the pom to leverage Docker layer caching for dependencies
COPY pom.xml ./

# Pre-download dependencies (offline build support)
RUN mvn -q -B -DskipTests dependency:go-offline

# Now copy the full source tree and build the application
COPY src ./src

RUN mvn -q -B -DskipTests package

# ---------------------------------------------------------------------------
# Runtime stage: lightweight JRE image to run the fat JAR
# ---------------------------------------------------------------------------
FROM eclipse-temurin:17-jre-jammy AS runtime

# Create non-root user for security
RUN groupadd --system spring \
    && useradd --system --gid spring spring

# Install curl for health checks and simple diagnostics
RUN apt-get update \
    && apt-get install -y --no-install-recommends curl \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy the built application JAR from the builder stage
COPY --from=builder /workspace/target/*.jar /app/app.jar

RUN chown -R spring:spring /app
USER spring

# Default JVM options (can be overridden at runtime)
ENV JAVA_OPTS="-Xms256m -Xmx512m"

EXPOSE 8080

# Use sh -c so that JAVA_OPTS from env is honored
ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -Djava.security.egd=file:/dev/./urandom -jar app.jar"]
