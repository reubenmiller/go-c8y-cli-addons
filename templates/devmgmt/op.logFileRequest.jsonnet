// Request log file
{
    "c8y_LogfileRequest": {
        "logFile": var("type"),
        "dateFrom": _.Now(var("dateFrom", "-8h")),
        "dateTo": _.Now(var("dateTo", "0s")),
        "searchText": var("searchText", ""),
        "maximumLines": var("maximumLines", 1000)
    }
}