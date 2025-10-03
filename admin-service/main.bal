import ballerina/http;
import ballerina/log;
import ballerina/time;
import ballerina/uuid;
import ballerinax/kafka;

// Database configuration
configurable string MONGODB_URI = "mongodb://localhost:27017/transport_db";
configurable string KAFKA_BROKERS = "localhost:9092";

// Types
type Route record {
    string id?;
    string routeNumber;
    string name;
    string startLocation;
    string endLocation;
    string[] stops;
    boolean isActive?;
    time:Utc createdAt?;
    time:Utc updatedAt?;
};

type Trip record {
    string id?;
    string routeId;
    time:Utc departureTime;
    time:Utc arrivalTime;
    string vehicleId;
    string driverId;
    string status?;
    time:Utc createdAt?;
    time:Utc updatedAt?;
};

type Ticket record {
    string id?;
    string passengerId;
    string tripId;
    string ticketType;
    decimal price;
    string status;
    int validationCount?;
    int maxValidations?;
    time:Utc createdAt?;
    time:Utc updatedAt?;
};

type Payment record {
    string id?;
    string ticketId;
    decimal amount;
    string paymentMethod;
    string status;
    string? transactionId;
    time:Utc createdAt?;
    time:Utc updatedAt?;
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

type SalesReport record {
    time:Utc date;
    int totalTickets;
    decimal totalRevenue;
    int totalPassengers;
    map<int> ticketTypeBreakdown;
    map<decimal> paymentMethodBreakdown;
};

type TrafficReport record {
    time:Utc date;
    string routeId;
    int totalTrips;
    int totalPassengers;
    int averageOccupancy;
    map<int> hourlyBreakdown;
};

// Database client
client class MongoClient {
    private final string connectionString;
    
    public function init(string connectionString) {
        self.connectionString = connectionString;
    }
    
    public function getAllRoutes() returns Route[]|error {
        return [
            {
                id: "route-1",
                routeNumber: "R001",
                name: "City Center to Airport",
                startLocation: "City Center",
                endLocation: "Hosea Kutako Airport",
                stops: ["City Center", "Katutura", "Eros Airport", "Hosea Kutako Airport"],
                isActive: true,
                createdAt: time:utcNow(),
                updatedAt: time:utcNow()
            },
            {
                id: "route-2",
                routeNumber: "R002",
                name: "Windhoek to Swakopmund",
                startLocation: "Windhoek Central",
                endLocation: "Swakopmund Station",
                stops: ["Windhoek Central", "Okahandja", "Karibib", "Swakopmund Station"],
                isActive: true,
                createdAt: time:utcNow(),
                updatedAt: time:utcNow()
            }
        ];
    }
    
    public function getAllTrips() returns Trip[]|error {
        return [
            {
                id: "trip-1",
                routeId: "route-1",
                departureTime: time:utcNow(),
                arrivalTime: time:utcAddSeconds(time:utcNow(), 3600),
                vehicleId: "BUS-001",
                driverId: "DRIVER-001",
                status: "SCHEDULED",
                createdAt: time:utcNow(),
                updatedAt: time:utcNow()
            },
            {
                id: "trip-2",
                routeId: "route-2",
                departureTime: time:utcAddSeconds(time:utcNow(), 7200),
                arrivalTime: time:utcAddSeconds(time:utcNow(), 10800),
                vehicleId: "BUS-002",
                driverId: "DRIVER-002",
                status: "IN_PROGRESS",
                createdAt: time:utcNow(),
                updatedAt: time:utcNow()
            }
        ];
    }
    
    public function getAllTickets() returns Ticket[]|error {
        return [
            {
                id: "ticket-1",
                passengerId: "passenger-123",
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
                passengerId: "passenger-456",
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
    
    public function getTicketsByDateRange(time:Utc startDate, time:Utc endDate) returns Ticket[]|error {
        // Simulate filtering tickets by date range
        return [
            {
                id: "ticket-1",
                passengerId: "passenger-123",
                tripId: "trip-1",
                ticketType: "SINGLE_RIDE",
                price: 15.50,
                status: "PAID",
                validationCount: 0,
                maxValidations: 1,
                createdAt: startDate,
                updatedAt: startDate
            }
        ];
    }
    
    public function getPaymentsByDateRange(time:Utc startDate, time:Utc endDate) returns Payment[]|error {
        // Simulate filtering payments by date range
        return [
            {
                id: "payment-1",
                ticketId: "ticket-1",
                amount: 15.50,
                paymentMethod: "CARD",
                status: "COMPLETED",
                transactionId: "TXN-123456789",
                createdAt: startDate,
                updatedAt: startDate
            }
        ];
    }
    
    public function insertServiceDisruption(ServiceDisruption disruption) returns string|error {
        string id = uuid:createType1AsString();
        log:printInfo("Inserting service disruption with ID: " + id);
        return id;
    }
    
    public function getAllServiceDisruptions() returns ServiceDisruption[]|error {
        return [
            {
                id: "disruption-1",
                routeId: "route-1",
                type: "VEHICLE_BREAKDOWN",
                description: "Bus breakdown on Route R001",
                severity: "HIGH",
                startTime: time:utcNow(),
                endTime: time:utcAddHours(time:utcNow(), 2),
                isActive: true,
                createdAt: time:utcNow()
            }
        ];
    }
}

// Kafka producer for service disruptions
kafka:Producer serviceDisruptionProducer = check new (kafka:DEFAULT_URL, {
    topics: ["service.disruptions"]
});

// Initialize database client
final MongoClient mongoClient = new(MONGODB_URI);

// HTTP service
service /admin on new http:Listener(8086) {
    
    resource function get routes() returns http:Ok|http:InternalServerError {
        Route[]|error routes = mongoClient->getAllRoutes();
        if (routes is error) {
            log:printError("Failed to retrieve routes", routes);
            return <http:InternalServerError>{
                body: {error: "Failed to retrieve routes"}
            };
        }
        
        return <http:Ok>{
            body: {
                routes: routes
            }
        };
    }
    
    resource function get trips() returns http:Ok|http:InternalServerError {
        Trip[]|error trips = mongoClient->getAllTrips();
        if (trips is error) {
            log:printError("Failed to retrieve trips", trips);
            return <http:InternalServerError>{
                body: {error: "Failed to retrieve trips"}
            };
        }
        
        return <http:Ok>{
            body: {
                trips: trips
            }
        };
    }
    
    resource function get tickets() returns http:Ok|http:InternalServerError {
        Ticket[]|error tickets = mongoClient->getAllTickets();
        if (tickets is error) {
            log:printError("Failed to retrieve tickets", tickets);
            return <http:InternalServerError>{
                body: {error: "Failed to retrieve tickets"}
            };
        }
        
        return <http:Ok>{
            body: {
                tickets: tickets
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
    
    resource function get reports/sales(http:Request req) returns http:Ok|http:BadRequest|http:InternalServerError {
        map<json>|error queryParams = req.getQueryParams();
        if (queryParams is error) {
            return <http:BadRequest>{
                body: {error: "Invalid query parameters"}
            };
        }
        
        // Get date range from query parameters
        string? startDateStr = queryParams["startDate"]?.toString();
        string? endDateStr = queryParams["endDate"]?.toString();
        
        time:Utc startDate = time:utcNow();
        time:Utc endDate = time:utcNow();
        
        if (startDateStr is string) {
            time:Utc|error parsedStart = time:utcFromString(startDateStr);
            if (parsedStart is time:Utc) {
                startDate = parsedStart;
            }
        }
        
        if (endDateStr is string) {
            time:Utc|error parsedEnd = time:utcFromString(endDateStr);
            if (parsedEnd is time:Utc) {
                endDate = parsedEnd;
            }
        }
        
        // Get tickets and payments for the date range
        Ticket[]|error tickets = mongoClient->getTicketsByDateRange(startDate, endDate);
        Payment[]|error payments = mongoClient->getPaymentsByDateRange(startDate, endDate);
        
        if (tickets is error || payments is error) {
            log:printError("Failed to retrieve data for sales report", tickets is error ? tickets : payments);
            return <http:InternalServerError>{
                body: {error: "Failed to generate sales report"}
            };
        }
        
        // Calculate sales statistics
        int totalTickets = tickets.length();
        decimal totalRevenue = 0.0;
        int totalPassengers = 0;
        map<int> ticketTypeBreakdown = {};
        map<decimal> paymentMethodBreakdown = {};
        
        foreach Ticket ticket in tickets {
            totalPassengers += 1;
            
            int? currentCount = ticketTypeBreakdown[ticket.ticketType];
            if (currentCount is int) {
                ticketTypeBreakdown[ticket.ticketType] = currentCount + 1;
            } else {
                ticketTypeBreakdown[ticket.ticketType] = 1;
            }
        }
        
        foreach Payment payment in payments {
            if (payment.status == "COMPLETED") {
                totalRevenue += payment.amount;
                
                decimal? currentAmount = paymentMethodBreakdown[payment.paymentMethod];
                if (currentAmount is decimal) {
                    paymentMethodBreakdown[payment.paymentMethod] = currentAmount + payment.amount;
                } else {
                    paymentMethodBreakdown[payment.paymentMethod] = payment.amount;
                }
            }
        }
        
        SalesReport report = {
            date: time:utcNow(),
            totalTickets: totalTickets,
            totalRevenue: totalRevenue,
            totalPassengers: totalPassengers,
            ticketTypeBreakdown: ticketTypeBreakdown,
            paymentMethodBreakdown: paymentMethodBreakdown
        };
        
        return <http:Ok>{
            body: report
        };
    }
    
    resource function get reports/traffic(http:Request req) returns http:Ok|http:BadRequest|http:InternalServerError {
        map<json>|error queryParams = req.getQueryParams();
        if (queryParams is error) {
            return <http:BadRequest>{
                body: {error: "Invalid query parameters"}
            };
        }
        
        string? routeId = queryParams["routeId"]?.toString();
        if (routeId is ()) {
            return <http:BadRequest>{
                body: {error: "Route ID is required"}
            };
        }
        
        // Get trips and tickets for the route
        Trip[]|error trips = mongoClient->getAllTrips();
        Ticket[]|error tickets = mongoClient->getAllTickets();
        
        if (trips is error || tickets is error) {
            log:printError("Failed to retrieve data for traffic report", trips is error ? trips : tickets);
            return <http:InternalServerError>{
                body: {error: "Failed to generate traffic report"}
            };
        }
        
        // Filter trips by route
        Trip[] routeTrips = [];
        foreach Trip trip in trips {
            if (trip.routeId == routeId) {
                routeTrips.push(trip);
            }
        }
        
        // Count passengers for this route
        int totalPassengers = 0;
        foreach Ticket ticket in tickets {
            foreach Trip trip in routeTrips {
                if (ticket.tripId == trip.id) {
                    totalPassengers += 1;
                }
            }
        }
        
        int totalTrips = routeTrips.length();
        int averageOccupancy = totalTrips > 0 ? totalPassengers / totalTrips : 0;
        
        // Simulate hourly breakdown
        map<int> hourlyBreakdown = {
            "06:00": 15,
            "07:00": 45,
            "08:00": 60,
            "09:00": 35,
            "10:00": 25,
            "11:00": 20,
            "12:00": 30,
            "13:00": 25,
            "14:00": 20,
            "15:00": 25,
            "16:00": 40,
            "17:00": 55,
            "18:00": 50,
            "19:00": 30,
            "20:00": 15
        };
        
        TrafficReport report = {
            date: time:utcNow(),
            routeId: routeId,
            totalTrips: totalTrips,
            totalPassengers: totalPassengers,
            averageOccupancy: averageOccupancy,
            hourlyBreakdown: hourlyBreakdown
        };
        
        return <http:Ok>{
            body: report
        };
    }
    
    resource function post disruptions(http:Request req) returns http:Created|http:BadRequest|http:InternalServerError {
        ServiceDisruption|error disruption = req.getJsonPayload();
        if (disruption is error) {
            log:printError("Invalid request payload", disruption);
            return <http:BadRequest>{
                body: {error: "Invalid request payload"}
            };
        }
        
        // Validate required fields
        if (disruption.type == "" || disruption.description == "" || 
            disruption.severity == "") {
            return <http:BadRequest>{
                body: {error: "All required fields must be provided"}
            };
        }
        
        // Create service disruption
        ServiceDisruption newDisruption = {
            routeId: disruption.routeId,
            type: disruption.type,
            description: disruption.description,
            severity: disruption.severity,
            startTime: disruption.startTime,
            endTime: disruption.endTime,
            isActive: true,
            createdAt: time:utcNow()
        };
        
        string|error disruptionId = mongoClient->insertServiceDisruption(newDisruption);
        if (disruptionId is error) {
            log:printError("Failed to create service disruption", disruptionId);
            return <http:InternalServerError>{
                body: {error: "Failed to create service disruption"}
            };
        }
        
        // Publish disruption notification to Kafka
        kafka:ProducerResult|error result = serviceDisruptionProducer->send({
            topic: "service.disruptions",
            key: disruptionId,
            value: newDisruption.toString()
        });
        
        if (result is error) {
            log:printError("Failed to publish service disruption", result);
        } else {
            log:printInfo("Service disruption published: " + disruptionId);
        }
        
        log:printInfo("Service disruption created successfully with ID: " + disruptionId);
        
        return <http:Created>{
            body: {
                id: disruptionId,
                message: "Service disruption created successfully"
            }
        };
    }
    
    resource function get disruptions() returns http:Ok|http:InternalServerError {
        ServiceDisruption[]|error disruptions = mongoClient->getAllServiceDisruptions();
        if (disruptions is error) {
            log:printError("Failed to retrieve service disruptions", disruptions);
            return <http:InternalServerError>{
                body: {error: "Failed to retrieve service disruptions"}
            };
        }
        
        return <http:Ok>{
            body: {
                disruptions: disruptions
            }
        };
    }
    
    resource function get dashboard() returns http:Ok|http:InternalServerError {
        // Get all data for dashboard
        Route[]|error routes = mongoClient->getAllRoutes();
        Trip[]|error trips = mongoClient->getAllTrips();
        Ticket[]|error tickets = mongoClient->getAllTickets();
        Payment[]|error payments = mongoClient->getAllPayments();
        ServiceDisruption[]|error disruptions = mongoClient->getAllServiceDisruptions();
        
        if (routes is error || trips is error || tickets is error || 
            payments is error || disruptions is error) {
            log:printError("Failed to retrieve dashboard data");
            return <http:InternalServerError>{
                body: {error: "Failed to retrieve dashboard data"}
            };
        }
        
        // Calculate dashboard statistics
        int activeRoutes = 0;
        foreach Route route in routes {
            if (route.isActive) {
                activeRoutes += 1;
            }
        }
        
        int activeTrips = 0;
        foreach Trip trip in trips {
            if (trip.status == "IN_PROGRESS") {
                activeTrips += 1;
            }
        }
        
        int totalTickets = tickets.length();
        int paidTickets = 0;
        foreach Ticket ticket in tickets {
            if (ticket.status == "PAID" || ticket.status == "VALIDATED") {
                paidTickets += 1;
            }
        }
        
        decimal totalRevenue = 0.0;
        foreach Payment payment in payments {
            if (payment.status == "COMPLETED") {
                totalRevenue += payment.amount;
            }
        }
        
        int activeDisruptions = 0;
        foreach ServiceDisruption disruption in disruptions {
            if (disruption.isActive) {
                activeDisruptions += 1;
            }
        }
        
        return <http:Ok>{
            body: {
                summary: {
                    totalRoutes: routes.length(),
                    activeRoutes: activeRoutes,
                    totalTrips: trips.length(),
                    activeTrips: activeTrips,
                    totalTickets: totalTickets,
                    paidTickets: paidTickets,
                    totalRevenue: totalRevenue,
                    activeDisruptions: activeDisruptions
                },
                recentActivity: {
                    lastUpdated: time:utcNow(),
                    routes: routes,
                    trips: trips,
                    tickets: tickets,
                    payments: payments,
                    disruptions: disruptions
                }
            }
        };
    }
}
