import ballerina/http;
import ballerina/log;
import ballerina/time;
import ballerina/uuid;
import ballerinax/kafka;

// Database configuration
configurable string MONGODB_URI = "mongodb://localhost:27017/transport_db";
configurable string KAFKA_BROKERS = "localhost:9092";

// Types
type TicketType "SINGLE_RIDE"|"MULTIPLE_RIDES"|"WEEKLY_PASS"|"MONTHLY_PASS";
type TicketStatus "CREATED"|"PAID"|"VALIDATED"|"EXPIRED";

type Ticket record {
    string id?;
    string passengerId;
    string tripId;
    TicketType ticketType;
    decimal price;
    TicketStatus status;
    int validationCount?;
    int maxValidations?;
    time:Utc createdAt?;
    time:Utc updatedAt?;
};

type TicketRequest record {
    string passengerId;
    string tripId;
    TicketType ticketType;
    string paymentMethod;
};

type TicketValidation record {
    string ticketId;
    string tripId;
    string vehicleId;
    string validatorId;
    time:Utc validationTime;
    boolean isValid;
    string? reason;
};

type PaymentConfirmation record {
    string ticketId;
    string paymentId;
    boolean success;
    string? errorMessage;
    time:Utc timestamp;
};

// Database client
client class MongoClient {
    private final string connectionString;
    
    public function init(string connectionString) {
        self.connectionString = connectionString;
    }
    
    public function insertTicket(Ticket ticket) returns string|error {
        string id = uuid:createType1AsString();
        log:printInfo("Inserting ticket with ID: " + id);
        return id;
    }
    
    public function findTicketById(string id) returns Ticket?|error {
        // Simulate MongoDB find
        if (id == "ticket-1") {
            return {
                id: id,
                passengerId: "passenger-123",
                tripId: "trip-1",
                ticketType: "SINGLE_RIDE",
                price: 15.50,
                status: "PAID",
                validationCount: 0,
                maxValidations: 1,
                createdAt: time:utcNow(),
                updatedAt: time:utcNow()
            };
        }
        return ();
    }
    
    public function updateTicketStatus(string ticketId, TicketStatus status) returns boolean|error {
        log:printInfo("Updating ticket " + ticketId + " status to " + status);
        return true;
    }
    
    public function incrementValidationCount(string ticketId) returns boolean|error {
        log:printInfo("Incrementing validation count for ticket: " + ticketId);
        return true;
    }
    
    public function getTicketsByPassenger(string passengerId) returns Ticket[]|error {
        return [
            {
                id: "ticket-1",
                passengerId: passengerId,
                tripId: "trip-1",
                ticketType: "SINGLE_RIDE",
                price: 15.50,
                status: "PAID",
                validationCount: 0,
                maxValidations: 1,
                createdAt: time:utcNow(),
                updatedAt: time:utcNow()
            },
            {
                id: "ticket-2",
                passengerId: passengerId,
                tripId: "trip-2",
                ticketType: "WEEKLY_PASS",
                price: 100.00,
                status: "VALIDATED",
                validationCount: 3,
                maxValidations: 20,
                createdAt: time:utcNow(),
                updatedAt: time:utcNow()
            }
        ];
    }
    
    public function getTicketsByTrip(string tripId) returns Ticket[]|error {
        return [
            {
                id: "ticket-1",
                passengerId: "passenger-123",
                tripId: tripId,
                ticketType: "SINGLE_RIDE",
                price: 15.50,
                status: "PAID",
                validationCount: 0,
                maxValidations: 1,
                createdAt: time:utcNow(),
                updatedAt: time:utcNow()
            }
        ];
    }
}

// Kafka producer for ticket requests
kafka:Producer ticketRequestProducer = check new (kafka:DEFAULT_URL, {
    topics: ["ticket.requests"]
});

// Kafka producer for ticket validations
kafka:Producer ticketValidationProducer = check new (kafka:DEFAULT_URL, {
    topics: ["ticket.validations"]
});

// Kafka consumer for payment confirmations
kafka:Consumer paymentConfirmationConsumer = check new (kafka:DEFAULT_URL, {
    topics: ["payments.processed"],
    groupId: "ticketing-service"
});

// Initialize database client
final MongoClient mongoClient = new(MONGODB_URI);

// Ticket pricing logic
function calculateTicketPrice(TicketType ticketType) returns decimal {
    match ticketType {
        "SINGLE_RIDE" => return 15.50;
        "MULTIPLE_RIDES" => return 50.00;
        "WEEKLY_PASS" => return 100.00;
        "MONTHLY_PASS" => return 350.00;
    }
}

function getMaxValidations(TicketType ticketType) returns int {
    match ticketType {
        "SINGLE_RIDE" => return 1;
        "MULTIPLE_RIDES" => return 10;
        "WEEKLY_PASS" => return 20;
        "MONTHLY_PASS" => return 100;
    }
}

// Kafka consumer service for payment confirmations
service kafka:Service on paymentConfirmationConsumer {
    
    remote function onConsumerRecord(kafka:ConsumerRecord[] records) returns error? {
        foreach kafka:ConsumerRecord record in records {
            PaymentConfirmation|error confirmation = record.value.toString().fromJsonString();
            if (confirmation is PaymentConfirmation) {
                log:printInfo("Received payment confirmation for ticket: " + confirmation.ticketId);
                
                if (confirmation.success) {
                    // Update ticket status to PAID
                    boolean|error updateResult = mongoClient->updateTicketStatus(confirmation.ticketId, "PAID");
                    if (updateResult is error) {
                        log:printError("Failed to update ticket status", updateResult);
                    } else {
                        log:printInfo("Ticket status updated to PAID: " + confirmation.ticketId);
                    }
                } else {
                    // Update ticket status to EXPIRED if payment failed
                    boolean|error updateResult = mongoClient->updateTicketStatus(confirmation.ticketId, "EXPIRED");
                    if (updateResult is error) {
                        log:printError("Failed to update ticket status", updateResult);
                    } else {
                        log:printInfo("Ticket status updated to EXPIRED: " + confirmation.ticketId);
                    }
                }
            }
        }
    }
}

// HTTP service
service /ticketing on new http:Listener(8083) {
    
    resource function post tickets(http:Request req) returns http:Created|http:BadRequest|http:InternalServerError {
        TicketRequest|error ticketReq = req.getJsonPayload();
        if (ticketReq is error) {
            log:printError("Invalid request payload", ticketReq);
            return <http:BadRequest>{
                body: {error: "Invalid request payload"}
            };
        }
        
        // Validate required fields
        if (ticketReq.passengerId == "" || ticketReq.tripId == "" || 
            ticketReq.paymentMethod == "") {
            return <http:BadRequest>{
                body: {error: "All required fields must be provided"}
            };
        }
        
        // Calculate ticket price and max validations
        decimal price = calculateTicketPrice(ticketReq.ticketType);
        int maxValidations = getMaxValidations(ticketReq.ticketType);
        
        // Create ticket
        Ticket newTicket = {
            passengerId: ticketReq.passengerId,
            tripId: ticketReq.tripId,
            ticketType: ticketReq.ticketType,
            price: price,
            status: "CREATED",
            validationCount: 0,
            maxValidations: maxValidations,
            createdAt: time:utcNow(),
            updatedAt: time:utcNow()
        };
        
        string|error ticketId = mongoClient->insertTicket(newTicket);
        if (ticketId is error) {
            log:printError("Failed to create ticket", ticketId);
            return <http:InternalServerError>{
                body: {error: "Failed to create ticket"}
            };
        }
        
        // Publish ticket request to Kafka for payment processing
        map<json> ticketRequest = {
            ticketId: ticketId,
            passengerId: ticketReq.passengerId,
            tripId: ticketReq.tripId,
            ticketType: ticketReq.ticketType,
            price: price,
            paymentMethod: ticketReq.paymentMethod
        };
        
        kafka:ProducerResult|error result = ticketRequestProducer->send({
            topic: "ticket.requests",
            key: ticketId,
            value: ticketRequest.toString()
        });
        
        if (result is error) {
            log:printError("Failed to publish ticket request", result);
            return <http:InternalServerError>{
                body: {error: "Failed to process ticket request"}
            };
        }
        
        log:printInfo("Ticket created successfully with ID: " + ticketId);
        
        return <http:Created>{
            body: {
                id: ticketId,
                price: price,
                status: "CREATED",
                message: "Ticket created successfully. Payment processing initiated."
            }
        };
    }
    
    resource function get tickets/[string id]() returns http:Ok|http:NotFound|http:InternalServerError {
        Ticket? ticket = mongoClient->findTicketById(id);
        if (ticket is ()) {
            return <http:NotFound>{
                body: {error: "Ticket not found"}
            };
        }
        
        return <http:Ok>{
            body: ticket
        };
    }
    
    resource function get tickets/passenger/[string passengerId]() returns http:Ok|http:InternalServerError {
        Ticket[]|error tickets = mongoClient->getTicketsByPassenger(passengerId);
        if (tickets is error) {
            log:printError("Failed to retrieve tickets", tickets);
            return <http:InternalServerError>{
                body: {error: "Failed to retrieve tickets"}
            };
        }
        
        return <http:Ok>{
            body: {
                passengerId: passengerId,
                tickets: tickets
            }
        };
    }
    
    resource function get tickets/trip/[string tripId]() returns http:Ok|http:InternalServerError {
        Ticket[]|error tickets = mongoClient->getTicketsByTrip(tripId);
        if (tickets is error) {
            log:printError("Failed to retrieve tickets", tickets);
            return <http:InternalServerError>{
                body: {error: "Failed to retrieve tickets"}
            };
        }
        
        return <http:Ok>{
            body: {
                tripId: tripId,
                tickets: tickets
            }
        };
    }
    
    resource function post tickets/[string id]/validate(http:Request req) returns http:Ok|http:NotFound|http:BadRequest|http:InternalServerError {
        map<json>|error validationData = req.getJsonPayload();
        if (validationData is error) {
            log:printError("Invalid request payload", validationData);
            return <http:BadRequest>{
                body: {error: "Invalid request payload"}
            };
        }
        
        string? vehicleId = validationData["vehicleId"]?.toString();
        string? validatorId = validationData["validatorId"]?.toString();
        
        if (vehicleId is () || validatorId is ()) {
            return <http:BadRequest>{
                body: {error: "Vehicle ID and Validator ID are required"}
            };
        }
        
        // Find ticket
        Ticket? ticket = mongoClient->findTicketById(id);
        if (ticket is ()) {
            return <http:NotFound>{
                body: {error: "Ticket not found"}
            };
        }
        
        // Check if ticket is valid for validation
        if (ticket.status != "PAID") {
            return <http:BadRequest>{
                body: {error: "Ticket is not paid and cannot be validated"}
            };
        }
        
        if (ticket.validationCount >= ticket.maxValidations) {
            return <http:BadRequest>{
                body: {error: "Ticket has reached maximum validation limit"}
            };
        }
        
        // Create validation record
        TicketValidation validation = {
            ticketId: id,
            tripId: ticket.tripId,
            vehicleId: vehicleId,
            validatorId: validatorId,
            validationTime: time:utcNow(),
            isValid: true,
            reason: ()
        };
        
        // Increment validation count
        boolean|error incrementResult = mongoClient->incrementValidationCount(id);
        if (incrementResult is error) {
            log:printError("Failed to increment validation count", incrementResult);
            return <http:InternalServerError>{
                body: {error: "Failed to validate ticket"}
            };
        }
        
        // Update ticket status if it's a single ride ticket
        if (ticket.ticketType == "SINGLE_RIDE") {
            boolean|error updateResult = mongoClient->updateTicketStatus(id, "VALIDATED");
            if (updateResult is error) {
                log:printError("Failed to update ticket status", updateResult);
            }
        }
        
        // Publish validation to Kafka
        kafka:ProducerResult|error result = ticketValidationProducer->send({
            topic: "ticket.validations",
            key: id,
            value: validation.toString()
        });
        
        if (result is error) {
            log:printError("Failed to publish ticket validation", result);
        } else {
            log:printInfo("Ticket validation published: " + id);
        }
        
        log:printInfo("Ticket validated successfully: " + id);
        
        return <http:Ok>{
            body: {
                ticketId: id,
                isValid: true,
                validationCount: ticket.validationCount + 1,
                maxValidations: ticket.maxValidations,
                message: "Ticket validated successfully"
            }
        };
    }
    
    resource function get tickets/[string id]/status() returns http:Ok|http:NotFound|http:InternalServerError {
        Ticket? ticket = mongoClient->findTicketById(id);
        if (ticket is ()) {
            return <http:NotFound>{
                body: {error: "Ticket not found"}
            };
        }
        
        return <http:Ok>{
            body: {
                ticketId: id,
                status: ticket.status,
                validationCount: ticket.validationCount,
                maxValidations: ticket.maxValidations,
                createdAt: ticket.createdAt,
                updatedAt: ticket.updatedAt
            }
        };
    }
}
