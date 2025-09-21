import ballerina/http;
import nust.model;

map<model:Asset> assetDB = {};

service /assets on new http:Listener(8080) {

    resource function post .(model:Asset asset) returns string {
        assetDB[asset.assetTag] = asset;
        return "Asset saved";
    }

    resource function get .() returns model:Asset[] {
        return assetDB.values();
    }

    resource function get tag/[string assetTag]() returns model:Asset|error {
        if assetDB.hasKey(assetTag) {
            return assetDB[assetTag];
        }
        return error("Asset not found");
    }

    resource function delete tag/[string assetTag]() returns string|error {
        if assetDB.hasKey(assetTag) {
            assetDB.remove(assetTag);
            return "Asset deleted";
        }
        return error("Asset not found");
    }

    resource function get faculty/[string faculty]() returns model:Asset[] {
        return assetDB.values().filter(function(model:Asset a) returns boolean {
            return a.faculty == faculty;
        });
    }

    resource function get overdue() returns model:Asset[] {
        return assetDB.values().filter(function(model:Asset a) returns boolean {
            foreach var s in a.schedules.values() {
                if checkpanic time:parse(s.nextDueDate) < time:currentTime() {
                    return true;
                }
            }
            return false;
        });
    }

    resource function post component/[string assetTag](model:Component component) returns string|error {
        if assetDB.hasKey(assetTag) {
            assetDB[assetTag].components[component.id] = component;
            return "Component added";
        }
        return error("Asset not found");
    }

    resource function delete component/[string assetTag]/[string componentId]() returns string|error {
        if assetDB.hasKey(assetTag) {
            assetDB[assetTag].components.remove(componentId);
            return "Component removed";
        }
        return error("Asset not found");
    }

    resource function post schedule/[string assetTag](model:Schedule schedule) returns string|error {
        if assetDB.hasKey(assetTag) {
            assetDB[assetTag].schedules[schedule.id] = schedule;
            return "Schedule added";
        }
        return error("Asset not found");
    }

    resource function delete schedule/[string assetTag]/[string scheduleId]() returns string|error {
        if assetDB.hasKey(assetTag) {
            assetDB[assetTag].schedules.remove(scheduleId);
            return "Schedule removed";
        }
        return error("Asset not found");
    }

    resource function post workorder/[string assetTag](model:WorkOrder workOrder) returns string|error {
        if assetDB.hasKey(assetTag) {
            assetDB[assetTag].workOrders[workOrder.id] = workOrder;
            return "Work order added";
        }
        return error("Asset not found");
    }

    resource function put workorder/[string assetTag]/[string workOrderId]/status(string status) returns string|error {
        if assetDB.hasKey(assetTag) {
            assetDB[assetTag].workOrders[workOrderId].status = status;
            return "Status updated";
        }
        return error("Asset not found");
    }

    resource function post task/[string assetTag]/[string workOrderId](model:Task task) returns string|error {
        if assetDB.hasKey(assetTag) {
            assetDB[assetTag].workOrders[workOrderId].tasks.push(task);
            return "Task added";
        }
        return error("Asset not found");
    }
}
