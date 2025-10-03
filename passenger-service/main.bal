import ballerina/http;
import ballerina/log;
import ballerina/time;
import ballerina/uuid;

// Database configuration
configurable string MONGODB_URI = "mongodb://localhost:27017/transport_db";
configurable string KAFKA_BROKERS = "localhost:9092";

// JWT configuration
configurable string JWT_SECRET = "transport-system-secret-key-2025";
configurable int JWT_VALIDITY_PERIOD = 3600; // 1 hour in seconds

// Types
type Passenger record {
    string id?;
    string email;
    string password;
    string firstName;
    string lastName;
    string phoneNumber;
    boolean isActive?;
    time:Utc createdAt?;
    time:Utc updatedAt?;
};

type PassengerResponse record {
    string id;
    string email;
    string firstName;
    string lastName;
    string phoneNumber;
    boolean isActive;
    time:Utc createdAt;
};

type LoginRequest record {
    string email;
    string password;
};

type LoginResponse record {
    string token;
    PassengerResponse passenger;
};

type TicketInfo record {
    string id;
    string tripId;
    string ticketType;
    decimal price;
    string status;
    int validationCount;
    int maxValidations;
    time:Utc createdAt;
};

// Database client
client class MongoClient {
    private final string connectionString;
    
    public function init(string connectionString) {
        self.connectionString = connectionString;
    }
    
    public function insertPassenger(Passenger passenger) returns string|error {
        // Simulate MongoDB insert
        string id = uuid:createType1AsString();
        log:printInfo("Inserting passenger with ID: " + id);
        return id;
    }
    
    public function findPassengerByEmail(string email) returns Passenger?|error {
        // Simulate MongoDB find
        if (email == "test@example.com") {
            return {
                id: "passenger-123",
                email: email,
                password: "$2a$10$encrypted_password_hash",
                firstName: "John",
                lastName: "Doe",
                phoneNumber: "+264811234567",
                isActive: true,
                createdAt: time:utcNow(),
                updatedAt: time:utcNow()
            };
        }
        return ();
    }
    
    public function findPassengerById(string id) returns Passenger?|error {
        // Simulate MongoDB find
        if (id == "passenger-123") {
            return {
                id: id,
                email: "test@example.com",
                password: "$2a$10$encrypted_password_hash",
                firstName: "John",
                lastName: "Doe",
                phoneNumber: "+264811234567",
                isActive: true,
                createdAt: time:utcNow(),
                updatedAt: time:utcNow()
            };
        }
        return ();
    }
    
    public function getPassengerTickets(string passengerId) returns TicketInfo[]|error {
        // Simulate MongoDB find
        return [
            {
                id: "ticket-1",
                tripId: "trip-1",
                ticketType: "SINGLE_RIDE",
                price: 15.50,
                status: "PAID",
                validationCount: 0,
                maxValidations: 1,
                createdAt: time:utcNow()
            },
            {
                id: "ticket-2",
                tripId: "trip-2",
                ticketType: "WEEKLY_PASS",
                price: 100.00,
                status: "VALIDATED",
                validationCount: 3,
                maxValidations: 20,
                createdAt: time:utcNow()
            }
        ];
    }
}

// Simple authentication utilities
function generateToken(Passenger passenger) returns string {
    // Simple token generation for demo purposes
    return "token_" + passenger.id + "_" + time:utcNow().epochSecond.toString();
}

function verifyToken(string token) returns boolean {
    // Simple token verification for demo purposes
    return token.startsWith("token_");
}

// Password utilities
function hashPassword(string password) returns string {
    // Simple password hashing for demo purposes
    return "hashed_" + password;
}

function verifyPassword(string password, string hashedPassword) returns boolean {
    // Simple password verification for demo purposes
    return hashedPassword == "hashed_" + password;
}

// Initialize database client
final MongoClient mongoClient = new(MONGODB_URI);

// HTTP service
service /passenger on new http:Listener(8081) {
    
    resource function post register(http:Request req) returns http:Created|http:BadRequest|http:InternalServerError {
        Passenger|error passenger = req.getJsonPayload();
        if (passenger is error) {
            log:printError("Invalid request payload", passenger);
            return <http:BadRequest>{
                body: {error: "Invalid request payload"}
            };
        }
        
        // Validate required fields
        if (passenger.email == "" || passenger.password == "" || 
            passenger.firstName == "" || passenger.lastName == "" || 
            passenger.phoneNumber == "") {
            return <http:BadRequest>{
                body: {error: "All fields are required"}
            };
        }
        
        // Check if passenger already exists
        Passenger? existingPassenger = mongoClient->findPassengerByEmail(passenger.email);
        if (existingPassenger is Passenger) {
            return <http:BadRequest>{
                body: {error: "Passenger with this email already exists"}
            };
        }
        
        // Hash password
        string hashedPassword = hashPassword(passenger.password);
        
        // Create passenger
        Passenger newPassenger = {
            email: passenger.email,
            password: hashedPassword,
            firstName: passenger.firstName,
            lastName: passenger.lastName,
            phoneNumber: passenger.phoneNumber,
            isActive: true,
            createdAt: time:utcNow(),
            updatedAt: time:utcNow()
        };
        
        string|error passengerId = mongoClient->insertPassenger(newPassenger);
        if (passengerId is error) {
            log:printError("Failed to create passenger", passengerId);
            return <http:InternalServerError>{
                body: {error: "Failed to create passenger"}
            };
        }
        
        log:printInfo("Passenger registered successfully with ID: " + passengerId);
        
        return <http:Created>{
            body: {
                id: passengerId,
                message: "Passenger registered successfully"
            }
        };
    }
    
    resource function post login(http:Request req) returns http:Ok|http:BadRequest|http:Unauthorized|http:InternalServerError {
        LoginRequest|error loginReq = req.getJsonPayload();
        if (loginReq is error) {
            log:printError("Invalid request payload", loginReq);
            return <http:BadRequest>{
                body: {error: "Invalid request payload"}
            };
        }
        
        // Find passenger by email
        Passenger? passenger = mongoClient->findPassengerByEmail(loginReq.email);
        if (passenger is ()) {
            return <http:Unauthorized>{
                body: {error: "Invalid email or password"}
            };
        }
        
        // Verify password
        if (!verifyPassword(loginReq.password, passenger.password)) {
            return <http:Unauthorized>{
                body: {error: "Invalid email or password"}
            };
        }
        
        // Generate token
        string token = generateToken(passenger);
        
        // Create response
        PassengerResponse passengerResponse = {
            id: passenger.id,
            email: passenger.email,
            firstName: passenger.firstName,
            lastName: passenger.lastName,
            phoneNumber: passenger.phoneNumber,
            isActive: passenger.isActive,
            createdAt: passenger.createdAt
        };
        
        LoginResponse loginResponse = {
            token: token,
            passenger: passengerResponse
        };
        
        log:printInfo("Passenger logged in successfully: " + passenger.email);
        
        return <http:Ok>{
            body: loginResponse
        };
    }
    
    resource function get profile(string id) returns http:Ok|http:NotFound|http:Unauthorized|http:InternalServerError {
        // In a real implementation, verify JWT token from Authorization header
        Passenger? passenger = mongoClient->findPassengerById(id);
        if (passenger is ()) {
            return <http:NotFound>{
                body: {error: "Passenger not found"}
            };
        }
        
        PassengerResponse passengerResponse = {
            id: passenger.id,
            email: passenger.email,
            firstName: passenger.firstName,
            lastName: passenger.lastName,
            phoneNumber: passenger.phoneNumber,
            isActive: passenger.isActive,
            createdAt: passenger.createdAt
        };
        
        return <http:Ok>{
            body: passengerResponse
        };
    }
    
    resource function get tickets(string id) returns http:Ok|http:NotFound|http:Unauthorized|http:InternalServerError {
        // In a real implementation, verify JWT token from Authorization header
        Passenger? passenger = mongoClient->findPassengerById(id);
        if (passenger is ()) {
            return <http:NotFound>{
                body: {error: "Passenger not found"}
            };
        }
        
        TicketInfo[]|error tickets = mongoClient->getPassengerTickets(id);
        if (tickets is error) {
            log:printError("Failed to retrieve tickets", tickets);
            return <http:InternalServerError>{
                body: {error: "Failed to retrieve tickets"}
            };
        }
        
        return <http:Ok>{
            body: {
                passengerId: id,
                tickets: tickets
            }
        };
    }
    
    resource function put profile(string id, http:Request req) returns http:Ok|http:NotFound|http:BadRequest|http:Unauthorized|http:InternalServerError {
        // In a real implementation, verify JWT token from Authorization header
        Passenger|error updateData = req.getJsonPayload();
        if (updateData is error) {
            log:printError("Invalid request payload", updateData);
            return <http:BadRequest>{
                body: {error: "Invalid request payload"}
            };
        }
        
        Passenger? existingPassenger = mongoClient->findPassengerById(id);
        if (existingPassenger is ()) {
            return <http:NotFound>{
                body: {error: "Passenger not found"}
            };
        }
        
        // Update passenger data (excluding password and email)
        Passenger updatedPassenger = {
            id: existingPassenger.id,
            email: existingPassenger.email, // Email cannot be changed
            password: existingPassenger.password, // Password cannot be changed here
            firstName: updateData.firstName,
            lastName: updateData.lastName,
            phoneNumber: updateData.phoneNumber,
            isActive: existingPassenger.isActive,
            createdAt: existingPassenger.createdAt,
            updatedAt: time:utcNow()
        };
        
        // In a real implementation, update in database
        log:printInfo("Passenger profile updated: " + id);
        
        PassengerResponse passengerResponse = {
            id: updatedPassenger.id,
            email: updatedPassenger.email,
            firstName: updatedPassenger.firstName,
            lastName: updatedPassenger.lastName,
            phoneNumber: updatedPassenger.phoneNumber,
            isActive: updatedPassenger.isActive,
            createdAt: updatedPassenger.createdAt
        };
        
        return <http:Ok>{
            body: passengerResponse
        };
    }
}
