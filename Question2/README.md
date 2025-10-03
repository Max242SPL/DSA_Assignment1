# Smart Public Transport Ticketing System

A distributed microservices-based ticketing system for public transport (buses & trains) built with Ballerina, featuring event-driven architecture using Kafka, persistent storage with MongoDB, and containerized deployment.

## 🚀 Overview

This system addresses the challenges of traditional public transport ticketing by providing a modern, scalable, and fault-tolerant solution. It supports multiple user roles (passengers, administrators, validators) and provides seamless experiences across devices.

## 🏗️ Architecture

The system follows a microservices architecture with the following components:

### Core Services

1. **Passenger Service** (Port: 8081)
   - User registration and authentication
   - Profile management
   - Ticket viewing and management
   - JWT-based security

2. **Transport Service** (Port: 8082)
   - Route and trip management
   - Schedule updates
   - Real-time trip status updates
   - Service disruption management

3. **Ticketing Service** (Port: 8083)
   - Ticket lifecycle management (CREATED → PAID → VALIDATED → EXPIRED)
   - Ticket validation on vehicles
   - Multiple ticket types support

4. **Payment Service** (Port: 8084)
   - Payment processing simulation
   - Multiple payment methods (Card, Cash, Mobile Money)
   - Transaction confirmation via Kafka events

5. **Notification Service** (Port: 8085)
   - Real-time notifications for trip updates
   - Payment confirmations
   - Service disruption alerts
   - Ticket validation notifications

6. **Admin Service** (Port: 8086)
   - Administrative dashboard
   - Sales and traffic reports
   - Service disruption management
   - System monitoring

### Infrastructure Components

- **Apache Kafka**: Event-driven communication between services
- **MongoDB**: Persistent data storage with schema validation
- **Docker**: Containerization and orchestration
- **Docker Compose**: Multi-service deployment

## 🛠️ Technology Stack

- **Language**: Ballerina 2201.8.0
- **Message Broker**: Apache Kafka 7.4.0
- **Database**: MongoDB 7.0
- **Containerization**: Docker & Docker Compose
- **Authentication**: JWT tokens
- **API**: RESTful HTTP services

## 📋 Prerequisites

- Docker and Docker Compose
- Git
- At least 4GB RAM available for containers

## 🚀 Quick Start

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd DSA_Assignment2
   ```

2. **Start the system**
   ```bash
   docker-compose up -d
   ```

3. **Verify services are running**
   ```bash
   docker-compose ps
   ```

4. **Check service health**
   ```bash
   # Passenger Service
   curl http://localhost:8081/passenger/routes
   
   # Transport Service
   curl http://localhost:8082/transport/routes
   
   # Admin Dashboard
   curl http://localhost:8086/admin/dashboard
   ```

## 📊 API Documentation

### Passenger Service APIs

#### Register a new passenger
```http
POST /passenger/register
Content-Type: application/json

{
  "email": "john.doe@example.com",
  "password": "securepassword",
  "firstName": "John",
  "lastName": "Doe",
  "phoneNumber": "+264811234567"
}
```

#### Login
```http
POST /passenger/login
Content-Type: application/json

{
  "email": "john.doe@example.com",
  "password": "securepassword"
}
```

#### Get passenger profile
```http
GET /passenger/profile/{passengerId}
Authorization: Bearer <jwt-token>
```

#### Get passenger tickets
```http
GET /passenger/tickets/{passengerId}
Authorization: Bearer <jwt-token>
```

### Transport Service APIs

<<<<<<< HEAD:README.md
#### Create a route
```http
POST /transport/routes
Content-Type: application/json

{
  "routeNumber": "R001",
  "name": "City Center to Airport",
  "startLocation": "City Center",
  "endLocation": "Hosea Kutako Airport",
  "stops": ["City Center", "Katutura", "Eros Airport", "Hosea Kutako Airport"]
}
```
=======

>>>>>>> bd34cd45ebc318bbaf34d9c2180d401a9331ea2e:Question2/README.md

#### Get all routes
```http
GET /transport/routes
```

#### Create a trip
```http
POST /transport/trips
Content-Type: application/json

{
  "routeId": "route-1",
  "departureTime": "2025-01-20T08:00:00Z",
  "arrivalTime": "2025-01-20T09:00:00Z",
  "vehicleId": "BUS-001",
  "driverId": "DRIVER-001"
}
```

### Ticketing Service APIs

#### Purchase a ticket
```http
POST /ticketing/tickets
Content-Type: application/json

{
  "passengerId": "passenger-123",
  "tripId": "trip-1",
  "ticketType": "SINGLE_RIDE",
  "paymentMethod": "CARD"
}
```

#### Validate a ticket
```http
POST /ticketing/tickets/{ticketId}/validate
Content-Type: application/json

{
  "vehicleId": "BUS-001",
  "validatorId": "VALIDATOR-001"
}
```

### Payment Service APIs

#### Process payment
```http
POST /payment/payments
Content-Type: application/json

{
  "ticketId": "ticket-1",
  "amount": 15.50,
  "paymentMethod": "CARD",
  "cardNumber": "4111111111111111",
  "cvv": "123",
  "expiryDate": "12/25"
}
```

#### Get payment statistics
```http
GET /payment/payments/stats
```

### Admin Service APIs

#### Get sales report
```http
GET /admin/reports/sales?startDate=2025-01-01&endDate=2025-01-31
```

#### Get traffic report
```http
GET /admin/reports/traffic?routeId=route-1
```

#### Create service disruption
```http
POST /admin/disruptions
Content-Type: application/json

{
  "routeId": "route-1",
  "type": "VEHICLE_BREAKDOWN",
  "description": "Bus breakdown on Route R001",
  "severity": "HIGH",
  "startTime": "2025-01-20T10:00:00Z",
  "endTime": "2025-01-20T12:00:00Z"
}
```

## 🔄 Event-Driven Communication

The system uses Kafka topics for asynchronous communication:

### Kafka Topics

- `ticket.requests`: Ticket purchase requests
- `payments.processed`: Payment confirmation events
- `ticket.validations`: Ticket validation events
- `schedule.updates`: Trip schedule updates
- `service.disruptions`: Service disruption notifications

### Event Flow

1. **Ticket Purchase Flow**:
   ```
   Passenger → Ticketing Service → Kafka (ticket.requests) → Payment Service → Kafka (payments.processed) → Ticketing Service
   ```

2. **Ticket Validation Flow**:
   ```
   Validator → Ticketing Service → Kafka (ticket.validations) → Notification Service
   ```

3. **Schedule Update Flow**:
   ```
   Admin → Transport Service → Kafka (schedule.updates) → Notification Service
   ```

## 🗄️ Database Schema

### Collections

- **passengers**: User accounts and profiles
- **routes**: Transport routes and stops
- **trips**: Scheduled trips and vehicles
- **tickets**: Ticket lifecycle and validation
- **payments**: Payment transactions
- **notifications**: Notification history

### Key Indexes

- Email uniqueness for passengers
- Route number uniqueness
- Trip and ticket lookups by passenger/route
- Payment transaction tracking

## 🐳 Docker Configuration

The system is fully containerized with:

- **Infrastructure containers**: Kafka, Zookeeper, MongoDB
- **Service containers**: All 6 microservices
- **Network isolation**: Services communicate via Docker network
- **Volume persistence**: MongoDB data persistence
- **Environment configuration**: Configurable via environment variables

## 📈 Monitoring and Observability

- **Structured logging**: All services use structured logging
- **Health endpoints**: Each service exposes health check endpoints
- **Metrics**: Built-in Ballerina observability features
- **Error handling**: Comprehensive error handling and reporting

## 🧪 Testing

### Manual Testing with cURL

The system can be tested using standard HTTP tools like cURL or Postman. All services communicate through Kafka for real-time event processing.

#### 1. Register a Passenger
```bash
curl -X POST http://localhost:8081/passenger/register \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"password123","firstName":"Test","lastName":"User","phoneNumber":"+264811234567"}'
```

#### 2. Login a Passenger
```bash
curl -X POST http://localhost:8081/passenger/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"password123"}'
```

#### 3. Get Available Routes
```bash
curl -X GET http://localhost:8082/transport/routes
```

#### 4. Get Trips for a Route
```bash
curl -X GET http://localhost:8082/transport/trips/route/route-1
```

#### 5. Create a Ticket
```bash
curl -X POST http://localhost:8083/ticketing/tickets \
  -H "Content-Type: application/json" \
  -d '{"passengerId":"passenger-123","tripId":"trip-1","ticketType":"SINGLE_RIDE","paymentMethod":"CARD"}'
```

#### 6. Process Payment
```bash
curl -X POST http://localhost:8084/payment/payments \
  -H "Content-Type: application/json" \
  -d '{"ticketId":"ticket-123","amount":15.50,"paymentMethod":"CARD","cardNumber":"1234567890123456","cvv":"123","expiryDate":"12/25"}'
```

#### 7. Validate Ticket
```bash
curl -X POST http://localhost:8083/ticketing/tickets/ticket-123/validate \
  -H "Content-Type: application/json" \
  -d '{"vehicleId":"BUS-001","validatorId":"VALIDATOR-001"}'
```

#### 8. Check Notifications
```bash
curl -X GET http://localhost:8085/notification/notifications/recipient/passenger-123
```

#### 9. View Admin Dashboard
```bash
curl -X GET http://localhost:8086/admin/dashboard
```

### Complete Workflow Test

1. **Start the system**:
   ```bash
   docker-compose up -d
   ```

2. **Wait for services to be ready** (check logs):
   ```bash
   docker-compose logs -f
   ```

3. **Test the complete workflow** using the cURL commands above in sequence

4. **Monitor Kafka events** (optional):
   ```bash
   docker exec -it kafka kafka-console-consumer --bootstrap-server localhost:9092 --topic ticket.requests --from-beginning
   ```

### Service Health Checks

Check if all services are running:
```bash
# Check all containers
docker-compose ps

# Check individual services
curl http://localhost:8081/passenger/profile/test
curl http://localhost:8082/transport/routes
curl http://localhost:8083/ticketing/tickets/test
curl http://localhost:8084/payment/payments/test
curl http://localhost:8085/notification/notifications/test
curl http://localhost:8086/admin/routes
```

## 🔧 Configuration

### Environment Variables

- `MONGODB_URI`: MongoDB connection string
- `KAFKA_BROKERS`: Kafka broker addresses
- `JWT_SECRET`: JWT signing secret
- `JWT_VALIDITY_PERIOD`: JWT token validity in seconds

### Service Ports

- Passenger Service: 8081
- Transport Service: 8082
- Ticketing Service: 8083
- Payment Service: 8084
- Notification Service: 8085
- Admin Service: 8086

## 🚨 Troubleshooting

### Common Issues

1. **Services not starting**:
   ```bash
   docker-compose logs <service-name>
   ```

2. **Database connection issues**:
   ```bash
   docker-compose logs mongodb
   ```

3. **Kafka connection issues**:
   ```bash
   docker-compose logs kafka
   ```

### Health Checks

```bash
# Check all services
docker-compose ps

# Check specific service logs
docker-compose logs passenger-service

# Restart a service
docker-compose restart passenger-service
```

## 📝 Development

### Adding New Features

1. Create new Ballerina service files
2. Update Docker Compose configuration
3. Add new Kafka topics if needed
4. Update database schema
5. Add API documentation

### Code Structure

```
├── passenger-service/
│   ├── main.bal
│   ├── Ballerina.toml
│   └── Dockerfile
├── transport-service/
├── ticketing-service/
├── payment-service/
├── notification-service/
├── admin-service/
├── docker-compose.yml
├── init-mongo.js
└── README.md
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📄 License

This project is part of the DSA612S Distributed Systems and Applications course assignment.

## 👥 Team

This project was developed as a group assignment for the DSA612S course.

---

**Note**: This is a demonstration system for educational purposes. In a production environment, additional security measures, monitoring, and scalability considerations would be required.

<<<<<<< HEAD:README.md
=======
bal build
bal run target/bin/car_rental.jar -- server
bal run target/bin/car_rental.jar -- server
>>>>>>> bd34cd45ebc318bbaf34d9c2180d401a9331ea2e:Question2/README.md
