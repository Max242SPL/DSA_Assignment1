// MongoDB initialization script
db = db.getSiblingDB('transport_db');

// Create collections with validation
db.createCollection('passengers', {
    validator: {
        $jsonSchema: {
            bsonType: 'object',
            required: ['email', 'password', 'firstName', 'lastName', 'phoneNumber'],
            properties: {
                email: { bsonType: 'string', pattern: '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$' },
                password: { bsonType: 'string', minLength: 6 },
                firstName: { bsonType: 'string', minLength: 1 },
                lastName: { bsonType: 'string', minLength: 1 },
                phoneNumber: { bsonType: 'string' },
                isActive: { bsonType: 'bool' },
                createdAt: { bsonType: 'date' },
                updatedAt: { bsonType: 'date' }
            }
        }
    }
});

db.createCollection('routes', {
    validator: {
        $jsonSchema: {
            bsonType: 'object',
            required: ['routeNumber', 'name', 'startLocation', 'endLocation', 'stops'],
            properties: {
                routeNumber: { bsonType: 'string' },
                name: { bsonType: 'string' },
                startLocation: { bsonType: 'string' },
                endLocation: { bsonType: 'string' },
                stops: { bsonType: 'array' },
                isActive: { bsonType: 'bool' },
                createdAt: { bsonType: 'date' },
                updatedAt: { bsonType: 'date' }
            }
        }
    }
});

db.createCollection('trips', {
    validator: {
        $jsonSchema: {
            bsonType: 'object',
            required: ['routeId', 'departureTime', 'arrivalTime', 'vehicleId', 'driverId'],
            properties: {
                routeId: { bsonType: 'objectId' },
                departureTime: { bsonType: 'date' },
                arrivalTime: { bsonType: 'date' },
                vehicleId: { bsonType: 'string' },
                driverId: { bsonType: 'string' },
                status: { bsonType: 'string', enum: ['SCHEDULED', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED'] },
                createdAt: { bsonType: 'date' },
                updatedAt: { bsonType: 'date' }
            }
        }
    }
});

db.createCollection('tickets', {
    validator: {
        $jsonSchema: {
            bsonType: 'object',
            required: ['passengerId', 'tripId', 'ticketType', 'price', 'status'],
            properties: {
                passengerId: { bsonType: 'objectId' },
                tripId: { bsonType: 'objectId' },
                ticketType: { bsonType: 'string', enum: ['SINGLE_RIDE', 'MULTIPLE_RIDES', 'WEEKLY_PASS', 'MONTHLY_PASS'] },
                price: { bsonType: 'decimal' },
                status: { bsonType: 'string', enum: ['CREATED', 'PAID', 'VALIDATED', 'EXPIRED'] },
                validationCount: { bsonType: 'int' },
                maxValidations: { bsonType: 'int' },
                createdAt: { bsonType: 'date' },
                updatedAt: { bsonType: 'date' }
            }
        }
    }
});

db.createCollection('payments', {
    validator: {
        $jsonSchema: {
            bsonType: 'object',
            required: ['ticketId', 'amount', 'paymentMethod', 'status'],
            properties: {
                ticketId: { bsonType: 'objectId' },
                amount: { bsonType: 'decimal' },
                paymentMethod: { bsonType: 'string', enum: ['CARD', 'CASH', 'MOBILE_MONEY'] },
                status: { bsonType: 'string', enum: ['PENDING', 'COMPLETED', 'FAILED'] },
                transactionId: { bsonType: 'string' },
                createdAt: { bsonType: 'date' },
                updatedAt: { bsonType: 'date' }
            }
        }
    }
});

db.createCollection('notifications', {
    validator: {
        $jsonSchema: {
            bsonType: 'object',
            required: ['recipientId', 'type', 'title', 'message', 'status'],
            properties: {
                recipientId: { bsonType: 'objectId' },
                type: { bsonType: 'string', enum: ['TRIP_UPDATE', 'TICKET_VALIDATION', 'PAYMENT_CONFIRMATION', 'SERVICE_DISRUPTION'] },
                title: { bsonType: 'string' },
                message: { bsonType: 'string' },
                status: { bsonType: 'string', enum: ['PENDING', 'SENT', 'DELIVERED', 'FAILED'] },
                createdAt: { bsonType: 'date' },
                updatedAt: { bsonType: 'date' }
            }
        }
    }
});

// Create indexes for better performance
db.passengers.createIndex({ email: 1 }, { unique: true });
db.passengers.createIndex({ phoneNumber: 1 });

db.routes.createIndex({ routeNumber: 1 }, { unique: true });
db.routes.createIndex({ isActive: 1 });

db.trips.createIndex({ routeId: 1 });
db.trips.createIndex({ departureTime: 1 });
db.trips.createIndex({ status: 1 });

db.tickets.createIndex({ passengerId: 1 });
db.tickets.createIndex({ tripId: 1 });
db.tickets.createIndex({ status: 1 });
db.tickets.createIndex({ createdAt: 1 });

db.payments.createIndex({ ticketId: 1 });
db.payments.createIndex({ transactionId: 1 }, { unique: true });
db.payments.createIndex({ status: 1 });

db.notifications.createIndex({ recipientId: 1 });
db.notifications.createIndex({ type: 1 });
db.notifications.createIndex({ status: 1 });
db.notifications.createIndex({ createdAt: 1 });

print('Database initialization completed successfully!');

