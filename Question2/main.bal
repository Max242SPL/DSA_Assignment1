import ballerina/io;

public function main(string... args) {
    string mode = (args.length() > 0) ? args[0] : "server";
    match mode.toLowerAscii() {
        "server" => {
            io:println("Starting Car Rental gRPC Server");
            io:println("Server is now running.");
            io:println("Press Ctrl+C to stop the server.");
            // Import and start the server
            startServer();
        }
        "client" => {
            io:println("Running Car Rental Client tests...");
            error? result = runClient();
            if result is error {
                io:println("Client error: " + result.toString());
            }
        }
        _ => {
            io:println("Unknown mode: '" + mode + "'. Use 'server' or 'client'.");
        }
    }
}

function startServer() {
    // The server will be started by importing car_rental_server.bal
    // The gRPC listener will keep the server running
}
