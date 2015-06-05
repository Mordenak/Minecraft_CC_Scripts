 --Device detection
isError=0
 
function detectDevice(DeviceName)
DeviceSide="none"
for k,v in pairs(redstone.getSides()) do
 if peripheral.getType(v)==DeviceName then
   DeviceSide = v
   break
 end
end
  return(DeviceSide)
end
 
function get_average(t)
    local sum = 0
    local count = 0
 
    for k,v in pairs(t) do
        if type(v) == 'number' then
            sum = sum + v
            count = count + 1
        end
    end
 
    return (sum / count)
end
 
 
cell="none"
monitor="none"
local peripheralList = peripheral.getNames()
 
CellSide=detectDevice("cofh_thermalexpansion_energycell")
 
if CellSide~="none" then
   cell=peripheral.wrap(CellSide)
   print ("TE Energy cell on the " .. CellSide .. " connected.")
   else
        CellSide=detectDevice("tile_enderio_blockcapacitorbank_name")
        if CellSide~="none" then
                cell=peripheral.wrap(CellSide)
                print ("EnderIO capacitorbank on the " .. CellSide .. " connected.")
        else
                        for Index = 1, #peripheralList do
                                if string.find(peripheralList[Index], "cofh_thermalexpansion_energycell") then
                                        cell=peripheral.wrap(peripheralList[Index])
                                        print ("TE Energy cell on wired modem: "..peripheralList[Index].." connected.")
                                elseif string.find(peripheralList[Index], "tile_enderio_blockcapacitorbank_name") then
                                        cell=peripheral.wrap(peripheralList[Index])
                                        print ("EnderIO capacitorbank on wired modem: "..peripheralList[Index].." connected.")
                                end
                        end --for
                        if cell == "none" then
                                print("No Energy storage found. Halting script!")
                                return
                        end
 
        end
end
 
 
MonitorSide=detectDevice("monitor")
 
if MonitorSide~="none" then
      monitor=peripheral.wrap(MonitorSide)
   print ("Monitor on the " .. MonitorSide .. " connected.")
   else
        for Index = 1, #peripheralList do
                if string.find(peripheralList[Index], "monitor") then
                        monitor=peripheral.wrap(peripheralList[Index])
                        print ("Monitor on wired modem: "..peripheralList[Index].." connected.")
                end
        end --for
        if monitor == "none" then
                print ("Warning - No Monitor attached, continuing without.")
        end
end
 
lastVal = 0
iterator = 0
allVals = {}
avg = 0
 
--Main loop
while true do
    --Get storage values
    -- monitor.setBackgroundColour((colours.green))
    eNow = cell.getEnergyStored("unknown")
    eMax = cell.getMaxEnergyStored("unknown")
 
    perc = ((eNow / eMax) * 100 )
 
    diff = 0
 
 
    if lastVal > 0 then
        diff = (eNow - lastVal) / 20
    end
 
    table.insert(allVals, diff)
 
    reportTime = false
    if (iterator % 5) == 1 then
        -- this is a 5 sec loop
        reportTime = true
        avg = math.floor( get_average(allVals) )
        allVals = {}
    end
 
 
    --If monitor is attached, write data on monitor
    if monitor ~= "none" then
        monitor.clear()
        monitor.setTextScale(2)
        monitor.setCursorPos(1,1)
        monitor.write("Storage:")
        monitor.setCursorPos(1,2)
        monitor.write(perc.."% RF")
 
        -- monitor.setCursorPos(1,3)
        -- monitor.write("Of:")
        -- monitor.setCursorPos(1,4)
        -- monitor.write(eMax.." RF")
        monitor.setCursorPos(1,3)
        if avg > 0 then
            monitor.setBackgroundColour((colours.green))
            monitor.write("RF/t:"..avg)
        elseif avg == 0 then
            monitor.write("RF/t:"..avg)
        else
            monitor.setBackgroundColour((colours.red))
            monitor.write("RF/t:"..avg)
        end
        monitor.setBackgroundColour((colours.black))
 
        -- estimate seconds
        monitor.setCursorPos(1,4)
        remaining = eMax - eNow
        if remaining > 0 then
            if avg > 0 then
                sec = math.floor( (remaining / (avg * 20)) )
                hrs = 0
                mins = 0
                if sec > 60 then
                    mins = math.floor( (sec / 60) )
                    sec = sec - (mins * 60)
                end
                if mins > 60 then
                    hrs = math.floor( (mins / 60) )
                    mins = mins - (hrs * 60)
                end
                if hrs > 0 then
                    monitor.write("Time left: "..hrs.."h"..mins.."m"..sec.."s")
                elseif mins > 0 then
                    monitor.write("Time left: "..mins.."m"..sec.."s")
                else
                    monitor.write("Time left: "..sec.."s")
                end
                -- monitor.write("Time left: "..sec.." sec")
            else
                -- 200 eNow
                -- -10 avg
                -- 20 seconds
                sec = math.floor( eNow / (avg * -20) )
                hrs = 0
                mins = 0
                if sec > 60 then
                    mins = math.floor( (sec / 60) )
                    sec = sec - (mins * 60)
                end
                if mins > 60 then
                    hrs = math.floor( (mins / 60) )
                    mins = mins - (hrs * 60)
                end
                if hrs > 0 then
                    monitor.write("Time left: "..hrs.."h"..mins.."m"..sec.."s")
                elseif mins > 0 then
                    monitor.write("Time left: "..mins.."m"..sec.."s")
                else
                    monitor.write("Time left: "..sec.."s")
                end
            end
        else
            monitor.write("No time remaining.")
        end
 
        --  reset cursor
        monitor.setCursorPos(1,1)
    end
 
 
    lastVal = cell.getEnergyStored("unknown")  
     
    iterator = iterator + 1
    sleep(1)
end --while