import ballerina/http;
import ballerina/log;
import ballerina/time;
import ballerina/uuid;
import ballerinax/kafka;

// Database configuration
configurable string MONGODB_URI = "mongodb://localhost:27017/transport_db";
configurable string KAFKA_BROKERS = "localhost:9092";

// Types
type NotificationType "TRIP_UPDATE"|"TICKET_VALIDATION"|"PAYMENT_CONFIRMATION"|"SERVICE_DISRUPTION";
type NotificationStatus "PENDING"|"SENT"|"DELIVERED"|"FAILED";

type Notification record {
    string id?;
    string recipientId;
    NotificationType type;
    string title;
    string message;
    NotificationStatus status;
    time:Utc createdAt?;
    time:Utc updatedAt?;
};

type ScheduleUpdate record {
    string tripId;
    string routeId;
    string updateType;
    string message;
    time:Utc? newDepartureTime;
    time:Utc? newArrivalTime;
    time:Utc timestamp;
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

type ServiceDisruption record {
    string id?;
    string routeId?;
    string type;
    string description;
    string severity;
    time:Utc startTime;
    time:Utc? endTime;
    boolean isActive?;
    time:Utc createdAt?;
};

// Database client
client class MongoClient {
    private final string connectionString;
    
    public function init(string connectionString) {
        self.connectionString = connectionString;
    }
    
    public function insertNotification(Notification notification) returns string|error {
        string id = uuid:createType1AsString();
        log:printInfo("Inserting notification with ID: " + id);
        return id;
    }
    
    public function findNotificationById(string id) returns Notification?|error {
        // Simulate MongoDB find
        if (id == "notification-1") {
            return {
                id: id,
                recipientId: "passenger-123",
                type: "TRIP_UPDATE",
                title: "Trip Update",
                message: "Your trip has been delayed by 15 minutes",
                status: "SENT",
                createdAt: time:utcNow(),
                updatedAt: time:utcNow()
            };
        }
        return ();
    }
    
    public function getNotificationsByRecipient(string recipientId) returns Notification[]|error {
        return [
            {
                id: "notification-1",
                recipientId: recipientId,
                type: "TRIP_UPDATE",
                title: "Trip Update",
                message: "Your trip has been delayed by 15 minutes",
                status: "SENT",
                createdAt: time:utcNow(),
                updatedAt: time:utcNow()
            },
            {
                id: "notification-2",
                recipientId: recipientId,
                type: "PAYMENT_CONFIRMATION",
                title: "Payment Confirmed",
                message: "Your payment of N$15.50 has been processed successfully",
                status: "DELIVERED",
                createdAt: time:utcNow(),
                updatedAt: time:utcNow()
            }
        ];
    }
    
    public function updateNotificationStatus(string notificationId, NotificationStatus status) returns boolean|error {
        log:printInfo("Updating notification " + notificationId + " status to " + status);
        return true;
    }
    
    public function getPassengersByTrip(string tripId) returns string[]|error {
        // Simulate getting passenger IDs for a trip
        return ["passenger-123", "passenger-456", "passenger-789"];
    }
    
    public function getPassengersByRoute(string routeId) returns string[]|error {
        // Simulate getting passenger IDs for a route
        return ["passenger-123", "passenger-456", "passenger-789", "passenger-101"];
    }
}

// Kafka consumers for different event types
kafka:Consumer scheduleUpdateConsumer = check new (kafka:DEFAULT_URL, {
    topics: ["schedule.updates"],
    groupId: "notification-service"
});

kafka:Consumer ticketValidationConsumer = check new (kafka:DEFAULT_URL, {
    topics: ["ticket.validations"],
    groupId: "notification-service"
});

kafka:Consumer paymentConfirmationConsumer = check new (kafka:DEFAULT_URL, {
    topics: ["payments.processed"],
    groupId: "notification-service"
});

kafka:Consumer serviceDisruptionConsumer = check new (kafka:DEFAULT_URL, {
    topics: ["service.disruptions"],
    groupId: "notification-service"
});

// Initialize database client
final MongoClient mongoClient = new(MONGODB_URI);

// Notification sending simulation
function sendNotification(Notification notification) returns boolean {
    // Simulate notification sending (SMS, Email, Push notification)
    log:printInfo("Sending notification to " + notification.recipientId + ": " + notification.title);
    
    // Simulate 95% success rate
    boolean success = (time:utcNow().epochSecond % 100) < 95;
    
    if (success) {
        log:printInfo("Notification sent successfully: " + notification.id);
    } else {
        log:printError("Failed to send notification: " + notification.id);
    }
    
    return success;
}

// Kafka consumer service for schedule updates
service kafka:Service on scheduleUpdateConsumer {
    
    remote function onConsumerRecord(kafka:ConsumerRecord[] records) returns error? {
        foreach kafka:ConsumerRecord record in records {
            ScheduleUpdate|error update = record.value.toString().fromJsonString();
            if (update is ScheduleUpdate) {
                log:printInfo("Processing schedule update for trip: " + update.tripId);
                
                // Get passengers for this trip
                string[]|error passengerIds = mongoClient->getPassengersByTrip(update.tripId);
                if (passengerIds is error) {
                    log:printError("Failed to get passengers for trip", passengerIds);
                    continue;
                }
                
                // Create notifications for each passenger
                foreach string passengerId in passengerIds {
                    Notification notification = {
                        recipientId: passengerId,
                        type: "TRIP_UPDATE",
                        title: "Trip Update",
                        message: update.message,
                        status: "PENDING",
                        createdAt: time:utcNow(),
                        updatedAt: time:utcNow()
                    };
                    
                    string|error notificationId = mongoClient->insertNotification(notification);
                    if (notificationId is error) {
                        log:printError("Failed to create notification", notificationId);
                        continue;
                    }
                    
                    // Send notification
                    boolean sent = sendNotification(notification);
                    NotificationStatus status = sent ? "SENT" : "FAILED";
                    
                    // Update notification status
                    boolean|error updateResult = mongoClient->updateNotificationStatus(notificationId, status);
                    if (updateResult is error) {
                        log:printError("Failed to update notification status", updateResult);
                    }
                }
            }
        }
    }
}

// Kafka consumer service for ticket validations
service kafka:Service on ticketValidationConsumer {
    
    remote function onConsumerRecord(kafka:ConsumerRecord[] records) returns error? {
        foreach kafka:ConsumerRecord record in records {
            TicketValidation|error validation = record.value.toString().fromJsonString();
            if (validation is TicketValidation) {
                log:printInfo("Processing ticket validation notification for ticket: " + validation.ticketId);
                
                // Get passenger ID from ticket (in real implementation, query ticket service)
                string passengerId = "passenger-123"; // Simulated
                
                Notification notification = {
                    recipientId: passengerId,
                    type: "TICKET_VALIDATION",
                    title: "Ticket Validated",
                    message: "Your ticket has been successfully validated on vehicle " + validation.vehicleId,
                    status: "PENDING",
                    createdAt: time:utcNow(),
                    updatedAt: time:utcNow()
                };
                
                string|error notificationId = mongoClient->insertNotification(notification);
                if (notificationId is error) {
                    log:printError("Failed to create notification", notificationId);
                    continue;
                }
                
                // Send notification
                boolean sent = sendNotification(notification);
                NotificationStatus status = sent ? "SENT" : "FAILED";
                
                // Update notification status
                boolean|error updateResult = mongoClient->updateNotificationStatus(notificationId, status);
                if (updateResult is error) {
                    log:printError("Failed to update notification status", updateResult);
                }
            }
        }
    }
}

// Kafka consumer service for payment confirmations
service kafka:Service on paymentConfirmationConsumer {
    
    remote function onConsumerRecord(kafka:ConsumerRecord[] records) returns error? {
        foreach kafka:ConsumerRecord record in records {
            PaymentConfirmation|error confirmation = record.value.toString().fromJsonString();
            if (confirmation is PaymentConfirmation) {
                log:printInfo("Processing payment confirmation notification for ticket: " + confirmation.ticketId);
                
                // Get passenger ID from ticket (in real implementation, query ticket service)
                string passengerId = "passenger-123"; // Simulated
                
                string title = confirmation.success ? "Payment Confirmed" : "Payment Failed";
                string message = confirmation.success ? 
                    "Your payment has been processed successfully" : 
                    "Your payment failed: " + (confirmation.errorMessage ?: "Unknown error");
                
                Notification notification = {
                    recipientId: passengerId,
                    type: "PAYMENT_CONFIRMATION",
                    title: title,
                    message: message,
                    status: "PENDING",
                    createdAt: time:utcNow(),
                    updatedAt: time:utcNow()
                };
                
                string|error notificationId = mongoClient->insertNotification(notification);
                if (notificationId is error) {
                    log:printError("Failed to create notification", notificationId);
                    continue;
                }
                
                // Send notification
                boolean sent = sendNotification(notification);
                NotificationStatus status = sent ? "SENT" : "FAILED";
                
                // Update notification status
                boolean|error updateResult = mongoClient->updateNotificationStatus(notificationId, status);
                if (updateResult is error) {
                    log:printError("Failed to update notification status", updateResult);
                }
            }
        }
    }
}

// Kafka consumer service for service disruptions
service kafka:Service on serviceDisruptionConsumer {
    
    remote function onConsumerRecord(kafka:ConsumerRecord[] records) returns error? {
        foreach kafka:ConsumerRecord record in records {
            ServiceDisruption|error disruption = record.value.toString().fromJsonString();
            if (disruption is ServiceDisruption) {
                log:printInfo("Processing service disruption notification: " + disruption.id);
                
                // Get passengers for affected route
                string[]|error passengerIds = mongoClient->getPassengersByRoute(disruption.routeId ?: "");
                if (passengerIds is error) {
                    log:printError("Failed to get passengers for route", passengerIds);
                    continue;
                }
                
                // Create notifications for each passenger
                foreach string passengerId in passengerIds {
                    Notification notification = {
                        recipientId: passengerId,
                        type: "SERVICE_DISRUPTION",
                        title: "Service Disruption Alert",
                        message: disruption.description,
                        status: "PENDING",
                        createdAt: time:utcNow(),
                        updatedAt: time:utcNow()
                    };
                    
                    string|error notificationId = mongoClient->insertNotification(notification);
                    if (notificationId is error) {
                        log:printError("Failed to create notification", notificationId);
                        continue;
                    }
                    
                    // Send notification
                    boolean sent = sendNotification(notification);
                    NotificationStatus status = sent ? "SENT" : "FAILED";
                    
                    // Update notification status
                    boolean|error updateResult = mongoClient->updateNotificationStatus(notificationId, status);
                    if (updateResult is error) {
                        log:printError("Failed to update notification status", updateResult);
                    }
                }
            }
        }
    }
}

// HTTP service
service /notification on new http:Listener(8085) {
    
    resource function post notifications(http:Request req) returns http:Created|http:BadRequest|http:InternalServerError {
        Notification|error notification = req.getJsonPayload();
        if (notification is error) {
            log:printError("Invalid request payload", notification);
            return <http:BadRequest>{
                body: {error: "Invalid request payload"}
            };
        }
        
        // Validate required fields
        if (notification.recipientId == "" || notification.title == "" || 
            notification.message == "") {
            return <http:BadRequest>{
                body: {error: "All required fields must be provided"}
            };
        }
        
        // Create notification
        Notification newNotification = {
            recipientId: notification.recipientId,
            type: notification.type,
            title: notification.title,
            message: notification.message,
            status: "PENDING",
            createdAt: time:utcNow(),
            updatedAt: time:utcNow()
        };
        
        string|error notificationId = mongoClient->insertNotification(newNotification);
        if (notificationId is error) {
            log:printError("Failed to create notification", notificationId);
            return <http:InternalServerError>{
                body: {error: "Failed to create notification"}
            };
        }
        
        // Send notification
        boolean sent = sendNotification(newNotification);
        NotificationStatus status = sent ? "SENT" : "FAILED";
        
        // Update notification status
        boolean|error updateResult = mongoClient->updateNotificationStatus(notificationId, status);
        if (updateResult is error) {
            log:printError("Failed to update notification status", updateResult);
        }
        
        log:printInfo("Notification created and sent with ID: " + notificationId);
        
        return <http:Created>{
            body: {
                id: notificationId,
                status: status,
                message: "Notification created and sent successfully"
            }
        };
    }
    
    resource function get notifications/[string id]() returns http:Ok|http:NotFound|http:InternalServerError {
        Notification? notification = mongoClient->findNotificationById(id);
        if (notification is ()) {
            return <http:NotFound>{
                body: {error: "Notification not found"}
            };
        }
        
        return <http:Ok>{
            body: notification
        };
    }
    
    resource function get notifications/recipient/[string recipientId]() returns http:Ok|http:InternalServerError {
        Notification[]|error notifications = mongoClient->getNotificationsByRecipient(recipientId);
        if (notifications is error) {
            log:printError("Failed to retrieve notifications", notifications);
            return <http:InternalServerError>{
                body: {error: "Failed to retrieve notifications"}
            };
        }
        
        return <http:Ok>{
            body: {
                recipientId: recipientId,
                notifications: notifications
            }
        };
    }
    
    resource function put notifications/[string id]/status(http:Request req) returns http:Ok|http:NotFound|http:BadRequest|http:InternalServerError {
        map<json>|error statusUpdate = req.getJsonPayload();
        if (statusUpdate is error) {
            log:printError("Invalid request payload", statusUpdate);
            return <http:BadRequest>{
                body: {error: "Invalid request payload"}
            };
        }
        
        string? status = statusUpdate["status"]?.toString();
        if (status is ()) {
            return <http:BadRequest>{
                body: {error: "Status is required"}
            };
        }
        
        // Validate status
        if (status != "PENDING" && status != "SENT" && 
            status != "DELIVERED" && status != "FAILED") {
            return <http:BadRequest>{
                body: {error: "Invalid status"}
            };
        }
        
        Notification? notification = mongoClient->findNotificationById(id);
        if (notification is ()) {
            return <http:NotFound>{
                body: {error: "Notification not found"}
            };
        }
        
        // Update notification status
        boolean|error updateResult = mongoClient->updateNotificationStatus(id, <NotificationStatus>status);
        if (updateResult is error) {
            log:printError("Failed to update notification status", updateResult);
            return <http:InternalServerError>{
                body: {error: "Failed to update notification status"}
            };
        }
        
        return <http:Ok>{
            body: {
                message: "Notification status updated successfully"
            }
        };
    }
}
