// Description: Create measurement with randomized values
{    
    type: "c8y_Weather",
    c8y_Weather: {
        temperature: {
            value: _.Int(40, 10),
            unit: "°C",
        },
        barometricPressure: {
            value: _.Float(1030, 980),
            unit: "hPa",
        },
    },
}