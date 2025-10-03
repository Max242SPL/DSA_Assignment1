FROM ballerina/ballerina:2201.8.0

WORKDIR /app

COPY main.bal .
COPY Ballerina.toml .

RUN bal build

EXPOSE 8083

CMD ["bal", "run", "target/bin/ticketing-service.jar"]

