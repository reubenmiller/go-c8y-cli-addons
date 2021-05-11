local mType = var("type", "c8y_Temparature");

{
    type: mType,
    [mType]: {
        temperature: {
            value: _.Int(40, 15),
            unit: "°C",
        },
        barometricPressure: {
            value: _.Float(1030, 980),
            unit: "hPa",
        },
    },
}