// Device
local randomType() = ["c8y_Linux", "c8y_MacOS", "c8y_Windows"][_.Int(3)];

{
    name: var("name", "exampledevice_") + std.format("%04d", input.index),
    type: randomType(),
    c8y_IsDevice: {},
}