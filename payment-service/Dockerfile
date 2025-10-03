FROM ballerina/ballerina:2201.8.0

WORKDIR /app

COPY main.bal .
COPY Ballerina.toml .

RUN bal build

EXPOSE 8084

CMD ["bal", "run", "target/bin/payment-service.jar"]

