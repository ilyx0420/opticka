print("Set a DIO based on voltage. Digital I/O is FIO5, voltage measured on AIN0.")
local InputVoltage = 0
local ThresholdVoltageUp = 0.15
local ThresholdVoltageDown = 0.8
local currentState = 0

local mbRead=MB.R			--local functions for faster processing
local mbWrite=MB.W

local outPin = 2005;    --FIO5

LJ.IntervalConfig(0, 0.2)   --set interval to 0.1ms
local checkInterval=LJ.CheckInterval

mbWrite(48006, 0, 4) -- Manual LED Control
mbWrite(2990, 0, 1) -- Comm LED ON
mbWrite(2991, 0, 0) -- Status LED Off

while true do
  if checkInterval(0) then              --interval completed
    InputVoltage = mbRead(0, 3)         --read AIN0. Address is 0, type is 3
    if currentState = 0 then
      if InputVoltage > ThresholdVoltageUp then
        currentState = 1
        mbWrite(outPin, 0, 1)
        mbWrite(2991, 0, 1)
      else
        currentState = 0
        mbWrite(outPin, 0, 0)
        mbWrite(2991, 0, 0)
      end
    elseif currentState = 1 then
      if InputVoltage < ThresholdVoltageDown then
        currentState = 0
        mbWrite(outPin, 0, 0)
        mbWrite(2991, 0, 0) 
      else
        currentState = 1
        mbWrite(outPin, 0, 1)
        mbWrite(2991, 0, 1)
      end
    end
  end
end

--LJ.IntervalConfig(1, 2)   --set interval to 0.1ms
--doFlip = true -- flip high?
--i = 0

        --this next section triggers low after ~2ms
        --while i < 1000 do --pause for a bit
        --  i = i + 1
        --end
        --mbWrite(outPin, 0, 0)
        --mbWrite(2991, 0, 0) 
        --doFlip = false
        --i = 0