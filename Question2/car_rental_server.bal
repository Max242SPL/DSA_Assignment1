import ballerina/grpc;
import ballerina/log;
import ballerina/time;

// In-memory storage
map<Car> carDatabase = {};
map<User> userDatabase = {};
map<CartItem[]> customerCarts = {};
map<Reservation> reservations = {};
int reservationCounter = 1;

// gRPC service implementation
listener grpc:Listener carRentalListener = new (9090);
@grpc:ServiceDescriptor {
    descriptor: CAR_RENTAL_DESC
}
service "CarRentalService" on carRentalListener {
    
    // Admin operation: Add a new car
    remote function AddCar(AddCarRequest req) returns AddCarResponse|grpc:Error {
        Car car = req.car;
        
        if carDatabase.hasKey(car.plate) {
            return error grpc:Error("Car with plate " + car.plate + " already exists");
        }
        
        carDatabase[car.plate] = car;
        log:printInfo("Car added: " + car.plate);
        
        return {
            plate: car.plate,
            message: "Car added successfully"
        };
    }
    
    // Admin operation: Create multiple users
    remote function CreateUsers(CreateUsersRequest req) returns CreateUsersResponse|grpc:Error {
        int usersCreated = 0;
        
        foreach User user in req.users {
            if !userDatabase.hasKey(user.user_id) {
                userDatabase[user.user_id] = user;
                usersCreated += 1;
                log:printInfo("User created: " + user.user_id);
            }
        }
        
        return {
            message: "Users created successfully",
            users_created: usersCreated
        };
    }
    
    // Admin operation: Update car details
    remote function UpdateCar(UpdateCarRequest req) returns UpdateCarResponse|grpc:Error {
        if !carDatabase.hasKey(req.plate) {
            return error grpc:Error("Car with plate " + req.plate + " not found");
        }
        
        Car updatedCar = req.car;
        updatedCar.plate = req.plate; // Ensure plate matches
        carDatabase[req.plate] = updatedCar;
        
        log:printInfo("Car updated: " + req.plate);
        
        return {
            message: "Car updated successfully",
            updated_car: updatedCar
        };
    }
    
    // Admin operation: Remove a car
    remote function RemoveCar(RemoveCarRequest req) returns RemoveCarResponse|grpc:Error {
        if !carDatabase.hasKey(req.plate) {
            return error grpc:Error("Car with plate " + req.plate + " not found");
        }
        
        _ = carDatabase.remove(req.plate);
        
        // Return remaining cars
        Car[] remainingCars = [];
        foreach Car car in carDatabase {
            remainingCars.push(car);
        }
        
        log:printInfo("Car removed: " + req.plate);
        
        return {
            message: "Car removed successfully",
            remaining_cars: remainingCars
        };
    }
    
    // Customer operation: List available cars (streaming)
    remote function ListAvailableCars(ListAvailableCarsRequest req) returns stream<Car, error?> {
        Car[] availableCars = [];
        
        // Collect available cars
        foreach Car car in carDatabase {
            if car.status == AVAILABLE {
                // Apply filter if provided
                if req.filter != "" {
                    if car.make.toLowerAscii().includes(req.filter.toLowerAscii()) || 
                       car.model.toLowerAscii().includes(req.filter.toLowerAscii()) ||
                       car.year.toString().includes(req.filter) {
                        availableCars.push(car);
                    }
                } else {
                    availableCars.push(car);
                }
            }
        }
        
        // Convert array to stream
        return availableCars.toStream();
    }
    
    // Customer operation: Search for a specific car
    remote function SearchCar(SearchCarRequest req) returns SearchCarResponse|grpc:Error {
        if !carDatabase.hasKey(req.plate) {
            return {
                available: false,
                car: {
                    plate: "",
                    make: "",
                    model: "",
                    year: 0,
                    daily_price: 0.0,
                    mileage: 0,
                    status: UNAVAILABLE
                },
                message: "Car not found"
            };
        }
        
        Car car = carDatabase.get(req.plate);
        boolean available = car.status == AVAILABLE;
        
        return {
            available: available,
            car: car,
            message: available ? "Car is available" : "Car is not available"
        };
    }
    
    // Customer operation: Add car to cart
    remote function AddToCart(AddToCartRequest req) returns AddToCartResponse|grpc:Error {
        // Validate customer exists
        if !userDatabase.hasKey(req.customer_id) {
            return error grpc:Error("Customer not found");
        }
        
        User customer = userDatabase.get(req.customer_id);
        if customer.role != CUSTOMER {
            return error grpc:Error("User is not a customer");
        }
        
        // Validate car exists and is available
        if !carDatabase.hasKey(req.item.plate) {
            return error grpc:Error("Car not found");
        }
        
        Car car = carDatabase.get(req.item.plate);
        if car.status != AVAILABLE {
            return error grpc:Error("Car is not available");
        }
        
        // Validate dates
        if req.item.rental_dates.start_date >= req.item.rental_dates.end_date {
            return error grpc:Error("Invalid date range");
        }
        
        // Add to cart
        if !customerCarts.hasKey(req.customer_id) {
            customerCarts[req.customer_id] = [];
        }
        
        CartItem[] currentCart = customerCarts.get(req.customer_id);
        currentCart.push(req.item);
        customerCarts[req.customer_id] = currentCart;
        
        log:printInfo("Car added to cart for customer: " + req.customer_id);
        
        CartItem[] finalCart = customerCarts.get(req.customer_id);
        AddToCartResponse response = {
            message: "Car added to cart successfully",
            cart_items: finalCart
        };
        return response;
    }
    
    // Customer operation: Place reservation
    remote function PlaceReservation(PlaceReservationRequest req) returns PlaceReservationResponse|grpc:Error {
        // Validate customer exists
        if !userDatabase.hasKey(req.customer_id) {
            return error grpc:Error("Customer not found");
        }
        
        User customer = userDatabase.get(req.customer_id);
        if customer.role != CUSTOMER {
            return error grpc:Error("User is not a customer");
        }
        
        // Check if customer has items in cart
        if !customerCarts.hasKey(req.customer_id) || customerCarts.get(req.customer_id).length() == 0 {
            return error grpc:Error("Cart is empty");
        }
        
        CartItem[] cartItems = customerCarts.get(req.customer_id);
        
        // Verify all cars are still available for the requested dates
        foreach CartItem item in cartItems {
            if !carDatabase.hasKey(item.plate) {
                return error grpc:Error("Car " + item.plate + " no longer exists");
            }
            
            Car car = carDatabase.get(item.plate);
            if car.status != AVAILABLE {
                return error grpc:Error("Car " + item.plate + " is no longer available");
            }
            
            // Check for date conflicts with existing reservations
            foreach Reservation existingReservation in reservations {
                foreach CartItem existingItem in existingReservation.items {
                    if existingItem.plate == item.plate {
                        // Check for date overlap
                        if !(item.rental_dates.end_date <= existingItem.rental_dates.start_date ||
                             item.rental_dates.start_date >= existingItem.rental_dates.end_date) {
                            return error grpc:Error("Car " + item.plate + " is not available for the requested dates");
                        }
                    }
                }
            }
        }
        
        // Calculate total price (simple calculation: assume daily rate * number of days)
        float totalPrice = 0.0;
        foreach CartItem item in cartItems {
            Car car = carDatabase.get(item.plate);
            // For simplicity, calculate as 5 days * daily price
            totalPrice += car.daily_price * 5.0;
        }
        
        // Create reservation
        string reservationId = "RES-" + reservationCounter.toString();
        reservationCounter += 1;
        
        time:Utc currentTime = time:utcNow();
        string currentDate = time:utcToString(currentTime).substring(0, 10);
        
        Reservation reservation = {
            reservation_id: reservationId,
            customer_id: req.customer_id,
            items: cartItems,
            total_price: totalPrice,
            reservation_date: currentDate,
            status: "confirmed"
        };
        
        reservations[reservationId] = reservation;
        
        // Mark cars as rented
        foreach CartItem item in cartItems {
            Car car = carDatabase.get(item.plate);
            car.status = RENTED;
            carDatabase[item.plate] = car;
        }
        
        // Clear customer's cart
        _ = customerCarts.remove(req.customer_id);
        
        log:printInfo("Reservation created: " + reservationId);
        
        return {
            message: "Reservation placed successfully",
            reservation: reservation
        };
    }
    
    // Admin operation: List all reservations
    remote function ListReservations(ListReservationsRequest req) returns ListReservationsResponse|grpc:Error {
        // Validate admin exists
        if !userDatabase.hasKey(req.admin_id) {
            return error grpc:Error("Admin not found");
        }
        
        User admin = userDatabase.get(req.admin_id);
        if admin.role != ADMIN {
            return error grpc:Error("User is not an admin");
        }
        
        Reservation[] allReservations = [];
        foreach Reservation reservation in reservations {
            allReservations.push(reservation);
        }
        
        return {
            reservations: allReservations
        };
    }
}
