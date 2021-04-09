local severity(idx) = ["MAJOR", "CRITICAL", "MINOR", "WARNING"][idx];
{    
    severity: severity(_.Int(4)),
}