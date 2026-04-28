local startup = fs.open("startup.lua", "w")
startup.write [[
shell.run("wget run https://raw.githubusercontent.com/BlueMoonJune/mechatronics/refs/heads/master/jointSetup.lua")
]]
startup.close()

fs.remove("joint.lua")
shell.run("wget https://raw.githubusercontent.com/BlueMoonJune/mechatronics/refs/heads/master/joint.lua")
shell.setDir("/")
shell.run("joint")

