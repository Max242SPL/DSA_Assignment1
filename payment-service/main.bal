import ballerina/http;
import ballerina/log;
import ballerina/time;
import ballerina/uuid;
import ballerinax/kafka;

// Database configuration
configurable string MONGODB_URI = "mongodb://localhost:27017/transport_db";
configurable string KAFKA_BROKERS = "localhost:9092";

// Types
type PaymentMethod "CARD"|"CASH"|"MOBILE_MONEY";
type PaymentStatus "PENDING"|"COMPLETED"|"FAILED";

type Payment record {
    string id?;
    string ticketId;
    decimal amount;
    PaymentMethod paymentMethod;
    PaymentStatus status;
    string? transactionId;
    time:Utc createdAt?;
    time:Utc updatedAt?;
};

type TicketRequest record {
    string ticketId;
    string passengerId;
    string tripId;
    string ticketType;
    decimal price;
    string paymentMethod;
};

type PaymentConfirmation record {
    string ticketId;
    string paymentId;
    boolean success;
    string? errorMessage;
    time:Utc timestamp;
};

type PaymentRequest record {
    string ticketId;
    decimal amount;
    string paymentMethod;
    string? cardNumber;
    string? cvv;
    string? expiryDate;
};

// Database client
client class MongoClient {
    private final string connectionString;
    
    public function init(string connectionString) {
        self.connectionString = connectionString;
    }
    
    public function insertPayment(Payment payment) returns string|error {
        string id = uuid:createType1AsString();
        log:printInfo("Inserting payment with ID: " + id);
        return id;
    }
    
    public function findPaymentById(string id) returns Payment?|error {
        // Simulate MongoDB find
        if (id == "payment-1") {
            return {
                id: id,
                ticketId: "ticket-1",
                amount: 15.50,
                paymentMethod: "CARD",
                status: "COMPLETED",
                transactionId: "TXN-123456789",
                createdAt: time:utcNow(),
                updatedAt: time:utcNow()
            };
        }
        return ();
    }
    
    public function updatePaymentStatus(string paymentId, PaymentStatus status, string? transactionId) returns boolean|error {
        log:printInfo("Updating payment " + paymentId + " status to " + status);
        return true;
    }
    
    public function getPaymentsByTicket(string ticketId) returns Payment[]|error {
        return [
            {
                id: "payment-1",
                ticketId: ticketId,
                amount: 15.50,
                paymentMethod: "CARD",
                status: "COMPLETED",
                transactionId: "TXN-123456789",
                createdAt: time:utcNow(),
                updatedAt: time:utcNow()
            }
        ];
    }
    
    public function getAllPayments() returns Payment[]|error {
        return [
            {
                id: "payment-1",
                ticketId: "ticket-1",
                amount: 15.50,
                paymentMethod: "CARD",
                status: "COMPLETED",
                transactionId: "TXN-123456789",
                createdAt: time:utcNow(),
                updatedAt: time:utcNow()
            },
            {
                id: "payment-2",
                ticketId: "ticket-2",
                amount: 100.00,
                paymentMethod: "MOBILE_MONEY",
                status: "COMPLETED",
                transactionId: "TXN-987654321",
                createdAt: time:utcNow(),
                updatedAt: time:utcNow()
            }
        ];
    }
}

// Kafka consumer for ticket requests
kafka:Consumer ticketRequestConsumer = check new (kafka:DEFAULT_URL, {
    topics: ["ticket.requests"],
    groupId: "payment-service"
});

// Kafka producer for payment confirmations
kafka:Producer paymentConfirmationProducer = check new (kafka:DEFAULT_URL, {
    topics: ["payments.processed"]
});

// Initialize database client
final MongoClient mongoClient = new(MONGODB_URI);

// Payment processing simulation
function processPayment(PaymentRequest paymentReq) returns PaymentConfirmation {
    // Simulate payment processing with different success rates based on payment method
    boolean success = true;
    string? errorMessage = ();
    string? transactionId = ();
    
    match paymentReq.paymentMethod {
        "CARD" => {
            // Simulate card payment processing
            if (paymentReq.cardNumber is () || paymentReq.cvv is () || paymentReq.expiryDate is ()) {
                success = false;
                errorMessage = "Card details are required for card payments";
            } else {
                // Simulate 95% success rate for card payments
                success = (time:utcNow().epochSecond % 100) < 95;
                if (success) {
                    transactionId = "TXN-" + uuid:createType1AsString();
                } else {
                    errorMessage = "Card payment declined";
                }
            }
        }
        "MOBILE_MONEY" => {
            // Simulate 90% success rate for mobile money
            success = (time:utcNow().epochSecond % 100) < 90;
            if (success) {
                transactionId = "MM-" + uuid:createType1AsString();
            } else {
                errorMessage = "Mobile money payment failed";
            }
        }
        "CASH" => {
            // Cash payments are always successful (handled by driver)
            success = true;
            transactionId = "CASH-" + uuid:createType1AsString();
        }
    }
    
    return {
        ticketId: paymentReq.ticketId,
        paymentId: "",
        success: success,
        errorMessage: errorMessage,
        timestamp: time:utcNow()
    };
}

// Kafka consumer service for ticket requests
service kafka:Service on ticketRequestConsumer {
    
    remote function onConsumerRecord(kafka:ConsumerRecord[] records) returns error? {
        foreach kafka:ConsumerRecord record in records {
            TicketRequest|error ticketReq = record.value.toString().fromJsonString();
            if (ticketReq is TicketRequest) {
                log:printInfo("Processing payment for ticket: " + ticketReq.ticketId);
                
                // Create payment record
                Payment payment = {
                    ticketId: ticketReq.ticketId,
                    amount: ticketReq.price,
                    paymentMethod: <PaymentMethod>ticketReq.paymentMethod,
                    status: "PENDING",
                    transactionId: (),
                    createdAt: time:utcNow(),
                    updatedAt: time:utcNow()
                };
                
                string|error paymentId = mongoClient->insertPayment(payment);
                if (paymentId is error) {
                    log:printError("Failed to create payment record", paymentId);
                    continue;
                }
                
                // Process payment
                PaymentRequest paymentReq = {
                    ticketId: ticketReq.ticketId,
                    amount: ticketReq.price,
                    paymentMethod: <PaymentMethod>ticketReq.paymentMethod,
                    cardNumber: (),
                    cvv: (),
                    expiryDate: ()
                };
                
                PaymentConfirmation confirmation = processPayment(paymentReq);
                confirmation.paymentId = paymentId;
                
                // Update payment status
                PaymentStatus status = confirmation.success ? "COMPLETED" : "FAILED";
                boolean|error updateResult = mongoClient->updatePaymentStatus(paymentId, status, confirmation.transactionId);
                if (updateResult is error) {
                    log:printError("Failed to update payment status", updateResult);
                }
                
                // Publish payment confirmation
                kafka:ProducerResult|error result = paymentConfirmationProducer->send({
                    topic: "payments.processed",
                    key: ticketReq.ticketId,
                    value: confirmation.toString()
                });
                
                if (result is error) {
                    log:printError("Failed to publish payment confirmation", result);
                } else {
                    log:printInfo("Payment confirmation published for ticket: " + ticketReq.ticketId);
                }
            }
        }
    }
}

// HTTP service
service /payment on new http:Listener(8084) {
    
    resource function post payments(http:Request req) returns http:Created|http:BadRequest|http:InternalServerError {
        PaymentRequest|error paymentReq = req.getJsonPayload();
        if (paymentReq is error) {
            log:printError("Invalid request payload", paymentReq);
            return <http:BadRequest>{
                body: {error: "Invalid request payload"}
            };
        }
        
        // Validate required fields
        if (paymentReq.ticketId == "" || paymentReq.paymentMethod == "") {
            return <http:BadRequest>{
                body: {error: "Ticket ID and payment method are required"}
            };
        }
        
        // Create payment record
        Payment payment = {
            ticketId: paymentReq.ticketId,
            amount: paymentReq.amount,
            paymentMethod: <PaymentMethod>paymentReq.paymentMethod,
            status: "PENDING",
            transactionId: (),
            createdAt: time:utcNow(),
            updatedAt: time:utcNow()
        };
        
        string|error paymentId = mongoClient->insertPayment(payment);
        if (paymentId is error) {
            log:printError("Failed to create payment", paymentId);
            return <http:InternalServerError>{
                body: {error: "Failed to create payment"}
            };
        }
        
        // Process payment
        PaymentConfirmation confirmation = processPayment(paymentReq);
        confirmation.paymentId = paymentId;
        
        // Update payment status
        PaymentStatus status = confirmation.success ? "COMPLETED" : "FAILED";
        boolean|error updateResult = mongoClient->updatePaymentStatus(paymentId, status, confirmation.transactionId);
        if (updateResult is error) {
            log:printError("Failed to update payment status", updateResult);
            return <http:InternalServerError>{
                body: {error: "Failed to process payment"}
            };
        }
        
        log:printInfo("Payment processed successfully with ID: " + paymentId);
        
        return <http:Created>{
            body: {
                paymentId: paymentId,
                success: confirmation.success,
                transactionId: confirmation.transactionId,
                errorMessage: confirmation.errorMessage,
                message: confirmation.success ? "Payment completed successfully" : "Payment failed"
            }
        };
    }
    
    resource function get payments/[string id]() returns http:Ok|http:NotFound|http:InternalServerError {
        Payment? payment = mongoClient->findPaymentById(id);
        if (payment is ()) {
            return <http:NotFound>{
                body: {error: "Payment not found"}
            };
        }
        
        return <http:Ok>{
            body: payment
        };
    }
    
    resource function get payments/ticket/[string ticketId]() returns http:Ok|http:InternalServerError {
        Payment[]|error payments = mongoClient->getPaymentsByTicket(ticketId);
        if (payments is error) {
            log:printError("Failed to retrieve payments", payments);
            return <http:InternalServerError>{
                body: {error: "Failed to retrieve payments"}
            };
        }
        
        return <http:Ok>{
            body: {
                ticketId: ticketId,
                payments: payments
            }
        };
    }
    
    resource function get payments() returns http:Ok|http:InternalServerError {
        Payment[]|error payments = mongoClient->getAllPayments();
        if (payments is error) {
            log:printError("Failed to retrieve payments", payments);
            return <http:InternalServerError>{
                body: {error: "Failed to retrieve payments"}
            };
        }
        
        return <http:Ok>{
            body: {
                payments: payments
            }
        };
    }
    
    resource function get payments/stats() returns http:Ok|http:InternalServerError {
        Payment[]|error allPayments = mongoClient->getAllPayments();
        if (allPayments is error) {
            log:printError("Failed to retrieve payments for stats", allPayments);
            return <http:InternalServerError>{
                body: {error: "Failed to retrieve payment statistics"}
            };
        }
        
        // Calculate statistics
        int totalPayments = allPayments.length();
        int completedPayments = 0;
        int failedPayments = 0;
        decimal totalAmount = 0.0;
        map<int> paymentMethodCount = {};
        
        foreach Payment payment in allPayments {
            if (payment.status == "COMPLETED") {
                completedPayments += 1;
                totalAmount += payment.amount;
            } else if (payment.status == "FAILED") {
                failedPayments += 1;
            }
            
            int? currentCount = paymentMethodCount[payment.paymentMethod];
            if (currentCount is int) {
                paymentMethodCount[payment.paymentMethod] = currentCount + 1;
            } else {
                paymentMethodCount[payment.paymentMethod] = 1;
            }
        }
        
        decimal successRate = totalPayments > 0 ? (completedPayments * 100.0 / totalPayments) : 0.0;
        
        return <http:Ok>{
            body: {
                totalPayments: totalPayments,
                completedPayments: completedPayments,
                failedPayments: failedPayments,
                successRate: successRate,
                totalAmount: totalAmount,
                paymentMethodBreakdown: paymentMethodCount
            }
        };
    }
}
