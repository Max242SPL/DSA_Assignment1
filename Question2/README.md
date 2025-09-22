# Car Rental System - gRPC Service

A Ballerina-based gRPC service for car rental management with both server and client implementations.

## Project Structure

- `main.bal` - Main entry point that can run server or client
- `car_rental_server.bal` - gRPC server implementation
- `car_rental_client.bal` - gRPC client implementation  
- `car_rental_pb.bal` - Generated protobuf definitions and client
- `car_rental.proto` - Protocol buffer definition file
- `client_test/` - Test client implementation
- `server_test/` - Test server implementation

## How to Run

### Run Server
   ```bash
bal run main.bal server
   ```

### Run Client Tests
   ```bash
bal run main.bal client
   ```

### Run Individual Tests
   ```bash
# Run server test
bal run server_test/server.bal

# Run client test  
bal run client_test/client.bal
```

## Features

### Admin Operations
- Add new cars to inventory
- Create multiple users (admin/customer)
- Update car details
- Remove cars from inventory
- List all reservations

### Customer Operations
- List available cars (with filtering)
- Search for specific cars
- Add cars to cart with rental dates
- Place reservations
- View reservation details

## gRPC Service Methods

1. `AddCar` - Add a new car to the system
2. `CreateUsers` - Create admin and customer users
3. `UpdateCar` - Update car information
4. `RemoveCar` - Remove car from inventory
5. `ListAvailableCars` - Stream available cars (with optional filter)
6. `SearchCar` - Find specific car by plate number
7. `AddToCart` - Add car to customer's cart
8. `PlaceReservation` - Convert cart to confirmed reservation
9. `ListReservations` - Admin view of all reservations



## Notes

- Server runs on port 9090
- In-memory storage (data resets on restart)
- Supports streaming responses for car listings
- Includes date validation for reservations
- Role-based access control (Admin/Customer)

bal build
bal run target/bin/car_rental.jar -- server
bal run target/bin/car_rental.jar -- server
