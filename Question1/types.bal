module nust.model;

public type Component record {
    string id;
    string name;
};

public type Schedule record {
    string id;
    string type;
    string nextDueDate;
};

public type Task record {
    string id;
    string description;
};

public type WorkOrder record {
    string id;
    string status;
    Task[] tasks;
};

public type Asset record {
    string assetTag;
    string name;
    string faculty;
    string department;
    string status;
    string acquiredDate;
    map<Component> components;
    map<Schedule> schedules;
    map<WorkOrder> workOrders;
};
