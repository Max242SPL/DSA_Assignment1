FROM ballerina/ballerina:2201.8.0

WORKDIR /app

COPY main.bal .
COPY Ballerina.toml .

RUN bal build

EXPOSE 8081

CMD ["bal", "run", "target/bin/passenger-service.jar"]

