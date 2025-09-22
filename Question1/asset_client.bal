import ballerina/http;
import nust.model;

http:Client assetClient = check new ("http://localhost:8080/assets");

public function main() returns error? {
    model:Asset asset = {
        assetTag: "EQ-001",
        name: "3D Printer",
        faculty: "Computing & Informatics",
        department: "Software Engineering",
        status: "ACTIVE",
        acquiredDate: "2024-03-10",
        components: {},
        schedules: {},
        workOrders: {}
    };

    check assetClient->post("/", asset);

    asset.status = "UNDER_REPAIR";
    check assetClient->post("/", asset);

    model:Asset[] allAssets = check assetClient->get("/");

    model:Asset[] facultyAssets = check assetClient->get("/faculty/Computing & Informatics");

    model:Asset[] overdueAssets = check assetClient->get("/overdue");

    model:Component comp = { id: "C1", name: "Motor" };
    check assetClient->post("/component/EQ-001", comp);

    model:Schedule sched = { id: "S1", type: "Quarterly", nextDueDate: "2024-06-01" };
    check assetClient->post("/schedule/EQ-001", sched);
}
