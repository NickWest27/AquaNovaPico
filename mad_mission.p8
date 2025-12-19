pico-8 cartridge // http://www.pico-8.com
version 43
__lua__
-- mission generating mad lib

--list of coords
x={14, 29, 34, 40, 52, 67, 73}
y={11, 26, 32, 54, 67, 83, 99}

--list of variables and range
var={
	{name="speed",range={0,100}, task = "make your ", units = " knots"},
	{name="depth", range={0,1000}, task = "dive to ", units = " meters"},
	{name="heading", range={0,360}, task = "turn to ", units = " degrees"},
}
--list of task types
task={
	{type="area", prfx = {"procede to ", "patrol at ", "scan at ", "search area at "}},
	{type="point",prfx = {"proceed to ", "take a sample at ", "rescue survivors at "}},
	{type="target"}
}

--number of tasks to make
length = 2

--list of tasks
tasks={}

-- mission list
missions={}

function make_tasks()
	for i=1,length do
		tasks[i]={}
		--make individual tasks
		local t = rnd(task)

		if t.type == "area" or t.type == "point" then
			tasks[i].type = t.type
			tasks[i].x = rnd(x)
			tasks[i].y = rnd(y)
			tasks[i].prfx = rnd(t.prfx)
			tasks[i].brief = tasks[i].prfx.." "..tasks[i].x..","..tasks[i].y
		elseif t.type == "target" then
			local v = rnd(var)
			tasks[i].task = v.task
			tasks[i].var = v.name
			tasks[i].value = flr(rnd(v.range[2] - v.range[1] +1)) + v.range[1]
			tasks[i].brief = tasks[i].task..tasks[i].var.." "..tasks[i].value..v.units
		end
	end
	return tasks
end

function make_missions()
	--make individual missions
	make_tasks()
	brief = "mission assignment:\n"
	for i=1,#tasks do
		brief = brief..i..". "..tasks[i].brief.."\n"
	end
	return brief
end

function _init()
	mission_text = make_missions()
end

function _update()
	-- update
end

function _draw()
	cls()
	print(mission_text, 2, 2, 7)
end
__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
