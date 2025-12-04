# Solution Steps

1. Create a multi-stage Dockerfile at the project root that uses a Maven + JDK image to build the Spring Boot Apache Camel application and a slim JRE image to run the resulting fat JAR, running the JAR as a non-root user and exposing port 8080.

2. In the Dockerfile build stage, copy only pom.xml first and run `mvn -DskipTests dependency:go-offline` to cache dependencies, then copy the src directory and run `mvn -DskipTests package` to produce the application JAR into `target/`.

3. In the Dockerfile runtime stage, start from `eclipse-temurin:17-jre`, create a dedicated `spring` user/group, install `curl` for healthchecks, copy the built `target/*.jar` as `/app/app.jar`, set `JAVA_OPTS` defaults, expose port 8080, and use an `ENTRYPOINT` that runs `java $JAVA_OPTS -jar app.jar`.

4. Under `src/main/resources`, add an `application-docker.yml` Spring Boot profile that configures the datasource using `${DB_HOST}`, `${DB_PORT}`, `${DB_NAME}`, `${DB_USER}`, and `${DB_PASSWORD}` environment variables, sets the Postgres driver and dialect, and defines a `crm.base-url` that points to `http://${CRM_HOST}:${CRM_PORT}` (defaulting to `db` and `crm-mock` service names).

5. In `application-docker.yml`, configure logging (console pattern, log levels for root, Camel, and your application package) and enable the actuator health endpoint and probes so Docker can check `/actuator/health` for container health.

6. Create a `crm-mock` directory and inside it add a `package.json` defining a small Node.js service with `express` and `morgan` dependencies and a `start` script that runs `node server.js`.

7. In `crm-mock/server.js`, implement an Express app that exposes `GET /health` (returns `{status:'UP'}`) and `POST /crm/customers` which validates the payload, logs the request with a `requestId`, and randomly returns either 201 (success) or 503 (simulated transient failure) based on a configurable `FAILURE_RATE` environment variable, defaulting to 0.3, plus global 404 and error handlers for clean logging.

8. Add `crm-mock/Dockerfile` that starts from `node:20-alpine`, sets `WORKDIR /usr/src/app`, copies `package*.json`, runs `npm install --only=production`, copies `server.js`, exposes port 8080, and defines `CMD ["npm", "start"]`.

9. Create a `db/init` directory with `01-schema.sql` that defines a `customers` table including `synced_to_crm BOOLEAN DEFAULT FALSE` and useful indexes, and `02-test-data.sql` that inserts a few unsynced sample customers using `ON CONFLICT DO NOTHING` so the script is idempotent.

10. Add a `docker-compose.yml` at the project root that defines three services: `db` (Postgres), `crm-mock` (built from `./crm-mock`), and `customer-sync-app` (built from the root Dockerfile), and a named `db-data` volume for persistent Postgres data.

11. Configure the `db` service in `docker-compose.yml` to use `postgres:16-alpine`, set `POSTGRES_DB`, `POSTGRES_USER`, and `POSTGRES_PASSWORD`, mount `./db/init` to `/docker-entrypoint-initdb.d`, expose `5432:5432` for local access, and add a `pg_isready`-based healthcheck with sensible intervals and retries.

12. Configure the `crm-mock` service in `docker-compose.yml` to build from `./crm-mock`, set `PORT` and `FAILURE_RATE` environment variables, expose `8081:8080` to the host, and add a healthcheck that uses `node -e` to perform an HTTP GET to `http://localhost:8080/health` and exits non-zero on failure.

13. Configure the `customer-sync-app` service in `docker-compose.yml` to build from the root Dockerfile, depend on `db` and `crm-mock` with `condition: service_healthy`, expose `8080:8080`, set `SPRING_PROFILES_ACTIVE=docker` and the DB/CRM environment variables (using Docker service names `db` and `crm-mock` as hosts), and define a healthcheck that runs `curl -fsS http://localhost:8080/actuator/health` inside the container.

14. Create `scripts/up.sh` that `cd`s to the project root and runs `docker compose -f docker-compose.yml up -d --build`, printing a short message about how to follow logs with `docker compose logs -f`.

15. Create `scripts/down.sh` that `cd`s to the project root and runs `docker compose -f docker-compose.yml down -v` to stop containers and remove related networks and volumes, giving you a clean teardown of all resources.

