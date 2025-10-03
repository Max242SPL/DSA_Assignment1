import ballerina/grpc;
import ballerina/log;
import ballerina/time;

const string STATUS_AVAILABLE = "AVAILABLE";
const string STATUS_RENTED = "RENTED";
const string STATUS_UNAVAILABLE = "UNAVAILABLE";

map<Car> carDatabase = {};
map<User> userDatabase = {};
map<CartItem[]> customerCarts = {};
map<Reservation> reservations = {};
int reservationCounter = 1;

listener grpc:Listener carRentalListener = new (9090);

@grpc:ServiceDescriptor {
    descriptor: CAR_RENTAL_DESC
}
service "CarRentalService" on carRentalListener {

    remote function AddCar(AddCarRequest req) returns AddCarResponse|grpc:Error {
        Car car = req.car;
        if carDatabase.hasKey(car.plate) {
            return grpc:Error(grpc:ALREADY_EXISTS,
                "Car with plate " + car.plate + " already exists");
        }
        lock {
            carDatabase[car.plate] = car;
        }
        log:printInfo("Car added: " + car.plate);
        return {
            plate: car.plate,
            message: "Car added successfully"
        };
    }

    remote function CreateUsers(CreateUsersRequest req) returns CreateUsersResponse|grpc:Error {
        int usersCreated = 0;
        foreach User user in req.users {
            if !userDatabase.hasKey(user.user_id) {
                lock {
                    userDatabase[user.user_id] = user;
                }
                usersCreated += 1;
                log:printInfo("User created: " + user.user_id);
            }
        }
        return {
            message: "Users created successfully",
            users_created: usersCreated
        };
    }

    remote function UpdateCar(UpdateCarRequest req) returns UpdateCarResponse|grpc:Error {
        if !carDatabase.hasKey(req.plate) {
            return grpc:Error(grpc:NOT_FOUND,
                "Car with plate " + req.plate + " not found");
        }
        Car updatedCar = req.car;
        updatedCar.plate = req.plate;
        lock {
            carDatabase[req.plate] = updatedCar;
        }
        log:printInfo("Car updated: " + req.plate);
        return {
            message: "Car updated successfully",
            updated_car: updatedCar
        };
    }

    remote function RemoveCar(RemoveCarRequest req) returns RemoveCarResponse|grpc:Error {
        if !carDatabase.hasKey(req.plate) {
            return grpc:Error(grpc:NOT_FOUND,
                "Car with plate " + req.plate + " not found");
        }
        lock {
            _ = carDatabase.remove(req.plate);
        }
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

    remote function ListAvailableCars(ListAvailableCarsRequest req)
            returns stream<Car, error?> {
        Car[] availableCars = [];
        foreach Car car in carDatabase {
            if car.status == STATUS_AVAILABLE {
                if req.filter != "" {
                    string f = req.filter.toLowerAscii();
                    if car.make.toLowerAscii().includes(f) ||
                        car.model.toLowerAscii().includes(f) ||
                        car.year.toString().includes(f) {
                        availableCars.push(car);
                    }
                } else {
                    availableCars.push(car);
                }
            }
        }
        return availableCars.toStream();
    }

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
                    status: STATUS_UNAVAILABLE
                },
                message: "Car not found"
            };
        }
        Car car = carDatabase.get(req.plate);
        boolean available = car.status == STATUS_AVAILABLE;
        return {
            available: available,
            car: car,
            message: available ? "Car is available" : "Car is not available"
        };
    }

    remote function AddToCart(AddToCartRequest req) returns AddToCartResponse|grpc:Error {
        if !userDatabase.hasKey(req.customer_id) {
            return grpc:Error(grpc:NOT_FOUND, "Customer not found");
        }
        User customer = userDatabase.get(req.customer_id);
        if customer.role != CUSTOMER {
            return grpc:Error(grpc:PERMISSION_DENIED, "User is not a customer");
        }
        if !carDatabase.hasKey(req.item.plate) {
            return grpc:Error(grpc:NOT_FOUND, "Car not found");
        }
        Car car = carDatabase.get(req.item.plate);
        if car.status != STATUS_AVAILABLE {
            return grpc:Error(grpc:FAILED_PRECONDITION, "Car is not available");
        }
        if req.item.rental_dates.start_date >= req.item.rental_dates.end_date {
            return grpc:Error(grpc:INVALID_ARGUMENT, "Invalid date range");
        }
        lock {
            if !customerCarts.hasKey(req.customer_id) {
                customerCarts[req.customer_id] = [];
            }
            CartItem[] currentCart = customerCarts.get(req.customer_id);
            currentCart.push(req.item);
            customerCarts[req.customer_id] = currentCart;
        }
        log:printInfo("Car added to cart for customer: " + req.customer_id);
        return {
            message: "Car added to cart successfully",
            cart_items: customerCarts.get(req.customer_id)
        };
    }

    remote function PlaceReservation(PlaceReservationRequest req)
            returns PlaceReservationResponse|grpc:Error {
        if !userDatabase.hasKey(req.customer_id) {
            return grpc:Error(grpc:NOT_FOUND, "Customer not found");
        }
        User customer = userDatabase.get(req.customer_id);
        if customer.role != CUSTOMER {
            return grpc:Error(grpc:PERMISSION_DENIED, "User is not a customer");
        }
        if !customerCarts.hasKey(req.customer_id)
            || customerCarts.get(req.customer_id).length() == 0 {
            return grpc:Error(grpc:FAILED_PRECONDITION, "Cart is empty");
        }
        CartItem[] cartItems = customerCarts.get(req.customer_id);
        foreach CartItem item in cartItems {
            if !carDatabase.hasKey(item.plate)) {
                return grpc:Error(grpc:NOT_FOUND, "Car " + item.plate + " no longer exists");
            }
            Car car = carDatabase.get(item.plate);
            if car.status != STATUS_AVAILABLE {
                return grpc:Error(grpc:FAILED_PRECONDITION,
                    "Car " + item.plate + " is no longer available");
            }
            foreach Reservation existingReservation in reservations {
                foreach CartItem existingItem in existingReservation.items {
                    if existingItem.plate == item.plate {
                        if !(item.rental_dates.end_date <= existingItem.rental_dates.start_date ||
                            item.rental_dates.start_date >= existingItem.rental_dates.end_date) {
                            return grpc:Error(grpc:FAILED_PRECONDITION,
                                "Car " + item.plate + " is not available for the requested dates");
                        }
                    }
                }
            }
        }
        float totalPrice = 0.0;
        foreach CartItem item in cartItems {
            Car car = carDatabase.get(item.plate);
            int days = (item.rental_dates.end_date - item.rental_dates.start_date)
                       / (24*60*60);
            if days <= 0 {
                days = 1;
            }
            totalPrice += car.daily_price * days.toFloat();
        }
        string reservationId = "RES-" + reservationCounter.toString();
        reservationCounter += 1;
        time:Utc currentTime = time:utcNow();
        string currentDate = time:format(currentTime, "yyyy-MM-dd");
        Reservation reservation = {
            reservation_id: reservationId,
            customer_id: req.customer_id,
            items: cartItems,
            total_price: totalPrice,
            reservation_date: currentDate,
            status: "confirmed"
        };
        lock {
            reservations[reservationId] = reservation;
            foreach CartItem item in cartItems {
                Car car = carDatabase.get(item.plate);
                car.status = STATUS_RENTED;
                carDatabase[item.plate] = car;
            }
            _ = customerCarts.remove(req.customer_id);
        }
        log:printInfo("Reservation created: " + reservationId);
        return {
            message: "Reservation placed successfully",
            reservation: reservation
        };
    }

    remote function ListReservations(ListReservationsRequest req)
            returns ListReservationsResponse|grpc:Error {
        if !userDatabase.hasKey(req.admin_id) {
            return grpc:Error(grpc:NOT_FOUND, "Admin not found");
        }
        User admin = userDatabase.get(req.admin_id);
        if admin.role != ADMIN {
            return grpc:Error(grpc:PERMISSION_DENIED, "User is not an admin");
        }
        Reservation[] allReservations = [];
        foreach Reservation reservation in reservations {
            allReservations.push(reservation);
        }
        return { reservations: allReservations };
    }
}
