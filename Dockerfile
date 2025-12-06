# === STAGE 1: Build ===
FROM eclipse-temurin:17-jdk-alpine AS builder

# Diretório de trabalho
WORKDIR /app

# Copiar arquivos do Maven
COPY mvnw .
COPY .mvn .mvn
COPY pom.xml .

# Baixar dependências (cache layer)
RUN ./mvnw dependency:go-offline -B

# Copiar código fonte
COPY src src

# Permissão do mvnw
RUN chmod +x mvnw

# Compilar e gerar JAR (sem executar testes)
RUN ./mvnw clean package -DskipTests

# === STAGE 2: Runtime ===
FROM eclipse-temurin:17-jre-alpine

# Metadados
LABEL maintainer="equipe@example.com"
LABEL description="TDD Projeto - Aplicação de Gamificação"
LABEL version="1.0"

# Criar usuário não-root
RUN addgroup -S spring && adduser -S spring -G spring
USER spring:spring

# Diretório de trabalho
WORKDIR /app

# Copiar JAR do stage anterior
COPY --from=builder /app/target/*.jar app.jar

# Variáveis de ambiente
ENV JAVA_OPTS="-Xms256m -Xmx512m"
ENV SPRING_PROFILES_ACTIVE=prod

# Expor porta
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:8080/actuator/health || exit 1

# Comando de execução
ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]