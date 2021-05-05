# Description: Update operation status PENDING => EXECUTING => rand SUCCESSFUL/FAILED
local GetNextStatus() = if input.value == 'PENDING' then 'EXECUTING' else ['SUCCESSFUL', 'FAILED'][_.Int(2)];
local failureReason(status) = if status == 'FAILED' then { failureReason: 'Unexpected error' } else {};
local status = GetNextStatus();

failureReason(status) + {
    status: status,
}