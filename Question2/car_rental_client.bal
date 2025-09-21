import ballerina/grpc;
import ballerina/io;
import ballerina/os;

// gRPC client for Car Rental System
public function runClient() returns error? {
    // Get server URL from environment variable or use default
    string serverUrl = os:getEnv("GRPC_SERVER_URL");
    if serverUrl == "" {
        serverUrl = "http://localhost:9090";
    }
    
    io:println("Connecting to server at: " + serverUrl);
    
    // Create the gRPC client using the generated client class
    CarRentalServiceClient carRentalClient = check new (serverUrl);
    
    io:println("=== Interactive Car Rental System Client ===");
    io:println("Welcome to the Car Rental System!");
    io:println("You can perform various operations interactively.\n");
    
    // Main menu loop
    while true {
        io:println("\n=== MAIN MENU ===");
        io:println("1. Create Users (Admin/Customer)");
        io:println("2. Add Car to Inventory");
        io:println("3. List Available Cars");
        io:println("4. Search for a Car");
        io:println("5. Add Car to Cart");
        io:println("6. Place Reservation");
        io:println("7. List All Reservations (Admin)");
        io:println("8. Update Car Details");
        io:println("9. Remove Car from Inventory");
        io:println("0. Exit");
        
        string choice = io:readln("Enter your choice (0-9): ");
        
        match choice.trim() {
            "1" => {
                check createUsersInteractive(carRentalClient);
            }
            "2" => {
                check addCarInteractive(carRentalClient);
            }
            "3" => {
                check listCarsInteractive(carRentalClient);
            }
            "4" => {
                check searchCarInteractive(carRentalClient);
            }
            "5" => {
                check addToCartInteractive(carRentalClient);
            }
            "6" => {
                check placeReservationInteractive(carRentalClient);
            }
            "7" => {
                check listReservationsInteractive(carRentalClient);
            }
            "8" => {
                check updateCarInteractive(carRentalClient);
            }
            "9" => {
                check removeCarInteractive(carRentalClient);
            }
            "0" => {
                io:println("Thank you for using Car Rental System!");
                break;
            }
            _ => {
                io:println("Invalid choice. Please try again.");
            }
        }
    }
}
// Interactive function to create users
function createUsersInteractive(CarRentalServiceClient carRentalClient) returns error? {
    io:println("\n=== CREATE USERS ===");
    io:println("Enter user details:");
    
    string userId = io:readln("User ID: ");
    string name = io:readln("Name: ");
    string email = io:readln("Email: ");
    io:println("Role: 1=Customer, 2=Admin");
    string roleChoice = io:readln("Choose role (1 or 2): ");
    
    UserRole role = CUSTOMER;
    if roleChoice.trim() == "2" {
        role = ADMIN;
    }
    
    CreateUsersRequest req = {
        users: [{
            user_id: userId,
            name: name,
            email: email,
            role: role
        }]
    };
    
    CreateUsersResponse resp = check carRentalClient->CreateUsers(req);
    io:println(" " + resp.message + " - Users created: " + resp.users_created.toString());
}

// Interactive function to add a car
function addCarInteractive(CarRentalServiceClient carRentalClient) returns error? {
    io:println("\n=== ADD CAR ===");
    
    string plate = io:readln("Car plate number: ");
    string make = io:readln("Make (e.g., Toyota, Honda): ");
    string model = io:readln("Model (e.g., Camry, Civic): ");
    int year = check int:fromString(io:readln("Year: "));
    float dailyPrice = check float:fromString(io:readln("Daily price: $"));
    int mileage = check int:fromString(io:readln("Mileage: "));
    
    AddCarRequest req = {
        car: {
            plate: plate,
            make: make,
            model: model,
            year: year,
            daily_price: dailyPrice,
            mileage: mileage,
            status: AVAILABLE
        }
    };
    
    AddCarResponse resp = check carRentalClient->AddCar(req);
    io:println(" " + resp.message + " - Car: " + resp.plate);
}

// Interactive function to list available cars
function listCarsInteractive(CarRentalServiceClient carRentalClient) returns error? {
    io:println("\n=== LIST AVAILABLE CARS ===");
    
    string filter = io:readln("Enter filter (brand, model, or year) or press Enter for all: ");
    
    ListAvailableCarsRequest req = {
        filter: filter
    };
    
    stream<Car, grpc:Error?> cars = check carRentalClient->ListAvailableCars(req);
    io:println("Available cars:");
    
    error? result = cars.forEach(function(Car car) {
        io:println(" " + car.plate + ": " + car.make + " " + car.model + 
                   " (" + car.year.toString() + ") - $" + car.daily_price.toString() + "/day");
    });
    
    if result is error {
        io:println(" Error: " + result.toString());
    }
}

// Interactive function to search for a car
function searchCarInteractive(CarRentalServiceClient carRentalClient) returns error? {
    io:println("\n=== SEARCH CAR ===");
    
    string plate = io:readln("Enter car plate number: ");
    
    SearchCarRequest req = {
        plate: plate
    };
    
    SearchCarResponse resp = check carRentalClient->SearchCar(req);
    
    if resp.available {
        io:println("   Car found!");
        io:println("   Make: " + resp.car.make);
        io:println("   Model: " + resp.car.model);
        io:println("   Year: " + resp.car.year.toString());
        io:println("   Daily Price: $" + resp.car.daily_price.toString());
        io:println("   Mileage: " + resp.car.mileage.toString());
        io:println("   Status: Available");
    } else {
        io:println(" " + resp.message);
    }
}

// Interactive function to add car to cart
function addToCartInteractive(CarRentalServiceClient carRentalClient) returns error? {
    io:println("\n=== ADD TO CART ===");
    
    string customerId = io:readln("Customer ID: ");
    string plate = io:readln("Car plate number: ");
    string startDate = io:readln("Start date (YYYY-MM-DD): ");
    string endDate = io:readln("End date (YYYY-MM-DD): ");
    
    AddToCartRequest req = {
        customer_id: customerId,
        item: {
            plate: plate,
            rental_dates: {
                start_date: startDate,
                end_date: endDate
            }
        }
    };
    
    AddToCartResponse resp = check carRentalClient->AddToCart(req);
    io:println(" " + resp.message);
    io:println("   Items in cart: " + resp.cart_items.length().toString());
}

// Interactive function to place reservation
function placeReservationInteractive(CarRentalServiceClient carRentalClient) returns error? {
    io:println("\n=== PLACE RESERVATION ===");
    
    string customerId = io:readln("Customer ID: ");
    
    PlaceReservationRequest req = {
        customer_id: customerId
    };
    
    PlaceReservationResponse resp = check carRentalClient->PlaceReservation(req);
    io:println(" " + resp.message);
    io:println("   Reservation ID: " + resp.reservation.reservation_id);
    io:println("   Total Price: $" + resp.reservation.total_price.toString());
    io:println("   Date: " + resp.reservation.reservation_date);
    io:println("   Status: " + resp.reservation.status);
}

// Interactive function to list reservations (Admin)
function listReservationsInteractive(CarRentalServiceClient carRentalClient) returns error? {
    io:println("\n=== LIST RESERVATIONS (Admin) ===");
    
    string adminId = io:readln("Admin ID: ");
    
    ListReservationsRequest req = {
        admin_id: adminId
    };
    
    ListReservationsResponse resp = check carRentalClient->ListReservations(req);
    io:println("Total reservations: " + resp.reservations.length().toString());
    
    foreach Reservation reservation in resp.reservations {
        io:println("\n Reservation " + reservation.reservation_id + ":");
        io:println("   Customer: " + reservation.customer_id);
        io:println("   Total: $" + reservation.total_price.toString());
        io:println("   Date: " + reservation.reservation_date);
        io:println("   Status: " + reservation.status);
        io:println("   Cars: " + reservation.items.length().toString());
    }
}

// Interactive function to update car
function updateCarInteractive(CarRentalServiceClient carRentalClient) returns error? {
    io:println("\n=== UPDATE CAR ===");
    
    string plate = io:readln("Car plate number to update: ");
    string make = io:readln("New make: ");
    string model = io:readln("New model: ");
    int year = check int:fromString(io:readln("New year: "));
    float dailyPrice = check float:fromString(io:readln("New daily price: $"));
    int mileage = check int:fromString(io:readln("New mileage: "));
    
    UpdateCarRequest req = {
        plate: plate,
        car: {
            plate: plate,
            make: make,
            model: model,
            year: year,
            daily_price: dailyPrice,
            mileage: mileage,
            status: AVAILABLE
        }
    };
    
    UpdateCarResponse resp = check carRentalClient->UpdateCar(req);
    io:println(" " + resp.message);
    io:println("   Updated price: $" + resp.updated_car.daily_price.toString());
}

// Interactive function to remove car
function removeCarInteractive(CarRentalServiceClient carRentalClient) returns error? {
    io:println("\n=== REMOVE CAR ===");
    
    string plate = io:readln("Car plate number to remove: ");
    
    RemoveCarRequest req = {
        plate: plate
    };
    
    RemoveCarResponse resp = check carRentalClient->RemoveCar(req);
    io:println(" " + resp.message);
    io:println("   Remaining cars: " + resp.remaining_cars.length().toString());
    
    foreach Car car in resp.remaining_cars {
        io:println("    " + car.plate + ": " + car.make + " " + car.model);
    }
}