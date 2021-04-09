local mType = var("type", "c8y_Temparature");

{
    type: mType,
    ["c8y_" + mType]: {
        sensor1: {
            value: _.Int(40),
            unit: "°C",
        },
        barometricPressure: {
            value: _.Float() * 100 + 1000,
            unit: "Pa",
        },
    },
}