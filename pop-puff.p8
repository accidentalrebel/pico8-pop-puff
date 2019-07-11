pico-8 cartridge // http://www.pico-8.com
version 18
__lua__
rectfill(0,0,127,127,5)

-- globals
tiles = {}
players = {}
tweens = {}
tpool = {}
board_rows = 5
board_cols = 5
board_pad_x = 4.5
board_pad_y = 5
i_index_arrows=19

-- enums
_x=1
_y=2

_pop=1
_puff=2
_cake=3
_arrow=4

_up=1
_right=2
_down=3
_left=4

printh("##################################")
function make_actor(tag,x,y,x_offset,y_offset,col,row,sprite)
   x = x or 0
   y = y or 0
   x_offset = x_offset or 0
   col = col or 0
   row = row or 0
   y_offset = y_offset or 0
   
   a = {}
   a.col = col
   a.row = row
   a.x = x
   a.y = y
   a.x_offset = x_offset
   a.y_offset = y_offset
   a.spr = sprite
   a.tag = tag
   a.parent = nil
   a.children = {}
   return a
end

function make_arrow(pointing,col,row)
   local a = make_actor(_arrow,0,0,0,0,col,row,19+pointing-1)
   a.pointing=pointing
   
   attach(a,tile_at(col,row))
   add(tiles,a)
   return a
end

function make_player(id,col,row)
			local sprite = nil
			if id == _pop then
				sprite = 1
			else
				sprite = 2
			end
			local a = make_actor(id,0,0,0,-1,col,row,sprite)
			add(players,a)
   attach(a,tile_at(col,row))
   
   a.pointing = nil
		
			return a
end

function detach(a)
   if a.parent == nil then
      return
   end
   del(a.parent.children,a)
   a.parent = nil
end

function attach(a,b)
   detach(a)
   a.parent = b
   add(b.children,a)
   a.col = b.col
   a.row = b.row
   a.x = (a.col+board_pad_x)*8
   a.y = (a.row+board_pad_y)*8
   printh("5>>"..a.x..";"..a.y..";"..b.col..";"..b.row)
end

function tile_at(x,y)
   local index = ((y-1)*(board_cols))+x
   return tiles[index]
end

function _init()
   local a
   for row = 1,board_rows do
      for col = 1,board_cols do
	 a = make_actor("tile",(col+board_pad_x)*8,(row+board_pad_y)*8,0,0,col,row,18)	
	 add(tiles,a)
      end
   end
   
   make_player(_pop,2,1)
   
   a = make_player(_puff,1,1)
   make_tween(a,_y,(5+board_pad_y)*8,0.02)

   a = make_actor(_cake,8,8,0,-1,1,1,3)
   attach(a,tile_at(1,4))
   add(tiles,a)
   make_tween(a,_x,(5+board_pad_x)*8,0.02)
   make_tween(a,_y,(1+board_pad_y)*8,0.02)

--   make_arrow(_down,3,1)
   make_arrow(_right,3,4)
   make_arrow(_down,5,4)
   make_arrow(_left,5,5)
   make_arrow(_left,4,5)
   make_arrow(_up,2,5)
   make_arrow(_right,2,2)
   make_arrow(_down,4,2)
end

function pool(obj)
	detach(obj)
	add(tpool,obj)
	if obj.tag == _cake 
		or obj.tag == _arrow then
		del(tiles,obj)
	elseif obj.tag == _pop
		or obj.tag == _puff then
		del(players,obj)
	end
end

function on_cake_stepped(cake,stepper)
			pool(cake)
			printh("got cake")
--			put_pool(cake)
end

function on_arrow_stepped(arrow,stepper)
   printh("7>>stepped on arrow pointing "..arrow.pointing)
   local xory = nil
   local to_use=nil
   if arrow.pointing == _left or arrow.pointing == _right then
      xory = _x
      to_use = arrow.x
   elseif arrow.pointing == _up or arrow.pointing == _down then
      xory = _y
      to_use = arrow.y
   end
   
   local direction = 1
   if arrow.pointing == _left or arrow.pointing == _up then
      direction = -1;
   end
   
   stepper.pointing = arrow.pointing
			printh("<<<<<<<"..stepper.pointing)

   make_tween(stepper,xory,to_use+(8*direction),0.1,on_tween_reached)
end

function handle_sliding(slider)
			local xory = nil
			local target_pos = nil
			if slider.pointing == _right
				and slider.col+1 <= board_cols then
				xory = _x
				target_pos = slider.x+8
			elseif slider.pointing == _left
				and slider.col-1 >= 1 then
				xory = _x
				target_pos = slider.x-8
			elseif slider.pointing == _up
				and slider.row-1 >= 1 then
					xory = _y
					target_pos = slider.y-8
			elseif slider.pointing == _down
				and slider.row+1 <= board_rows then
					xory = _y
					target_pos = slider.y+8
			end
			
			if xory != nil then
				make_tween(slider,xory,target_pos,0.1,on_tween_reached)
			end
end

function on_tween_reached(tween)
   printh("tween reached!")
   local p = tween.obj
   for i = 1,#p.parent.children,1 do 
      local child = p.parent.children[i]
      if child.tag == _arrow then
	 						on_arrow_stepped(child,p)
	 						break
	 				elseif child.tag == _cake then
		 					on_cake_stepped(child,p)
	 						break	
      else
	      	printh("testb")
	      	handle_sliding(p)
      end
   end
end

function control_player(player_num,dx,dy)
   dx = dx or 0
   dy = dy or 0
   local a = players[player_num]
   local t = tile_at(a.parent.col+dx,a.parent.row+dy);
   printh("-1>>"..a.parent.col..";"..a.parent.row..";"..t.col..";"..t.row)
   local x_or_y = nil
   local to_use = nil
   if dx != 0 then
      x_or_y = _x
      to_use = t.x
   elseif dy != 0 then
      x_or_y = _y
      to_use = t.y
   end
   if x_or_y == _x then
   	if dx > 0 then
   		a.pointing = _right
   	else
   		a.pointing = _left
   	end
   else
   	if dy > 0 then
   		a.pointing = _down
   	else
   		a.pointing = _up
   	end
   end
   if t !=  nil then
      make_tween(a,x_or_y,to_use,0.1,on_tween_reached)
      printh("0>>"..t.col..","..t.row)
   end
end

function handle_tween(tween)
   if tween_handle_reached(tween) then
      return
   end	
   if tween.xory == _x then
      tween.obj.x = rbl_fflr(tween.obj.x+tween.steps);
   elseif tween.xory == _y then
      tween.obj.y = rbl_fflr(tween.obj.y+tween.steps);
   end
   printh("steps:"..tween.steps)
   printh("obj.x:"..tween.obj.x..";obj.y:"..tween.obj.y)
   
   tween.obj.col = flr((tween.obj.x/8)-board_pad_x)
   tween.obj.row = flr((tween.obj.y/8)-board_pad_y)
   printh("3>>"..tween.obj.col..";"..tween.obj.row)
end

function _update()
   if btnp(0) then
      control_player(1,-1,0)
   elseif btnp(1) then
      control_player(1,1,0)
   elseif btnp(2) then
      control_player(1,0,-1)
   elseif btnp(3) then
      control_player(1,0,1)
   end
   
   foreach(tweens,handle_tween)
end

function draw_actor(a)
   local sx = a.x+a.x_offset
   local sy = a.y+a.y_offset
   spr(a.spr, sx, sy)
end

function _draw()
   cls()
   map(0,0,4,0,16,16)
   foreach(tiles,draw_actor)
   foreach(players,draw_actor)
end
-->8
function make_tween(a,xory,target,seconds,on_reached)
   local tween = {}
   
   tween.obj = a
   tween.xory = xory
   tween.on_reached = on_reached
   
   local current = nil
   if xory == _x then
      current = a.x
   elseif xory == _y then
      current = a.y
   end
   
   if current == nil then
   	printh("current is nil: >"..a.tag.."<")
   end
   
   if target > current then
      tween.direction = 1
   elseif target < current then
      tween.direction = -1
   else
      rbl_error("target should not be equal to current")
      return
   end
   printh("-4>>"..tween.obj.tag..": "..tween.direction..";"..current..";"..target)
   tween.steps = (target-current)*seconds
   printh("-3>>"..tween.steps..";"..current..";"..target..";"..seconds)
   tween.target = target
   add(tweens,tween)
   return tween
end

function tween_handle_reached(tween)
   local to_check = nil
   if tween.xory == _x then
      to_check = tween.obj.x
   else
      to_check = tween.obj.y
   end
   if (tween.direction > 0 
	  and to_check >=  tween.target) 
      or (tween.direction < 0	
	     and to_check <= tween.target)
   then
      if tween.xory == _x then
	 tween.obj.x = tween.target
      else
	 tween.obj.y = tween.target
      end
      printh("3.5>>"..tween.obj.col..";"..tween.obj.row)
      local t = tile_at(tween.obj.col,tween.obj.row)
      printh("4>>finding tile at:"..tween.obj.col..";"..tween.obj.row..";"..t.col..";"..t.row)
      attach(tween.obj,t)
      
      del(tweens,tween)
      printh("tweendestroyed:"..#tweens)		
      
      if tween.on_reached != nil then
	 tween.on_reached(tween)
      end
      return true
   end
   return false
end
-->8
function rbl_fflr(num)
   return flr(num*100)/100
end

function rbl_error(message)
   printh(">>> error: "..message)
end
__gfx__
000000000940094000227770088e2e002e00088e000000000000000000000000cccccccccccccccccccccccccccccccccc4444445445444444445444444455cc
000000000999999002222220088eeee0eee0088e000000000000000000000000ccccccccccccccccccc7777ccccccccccc554445444455444444454445445ccc
007007009991919922212122eeeee2e4e2e4eeee000000000000000000000000cccccccccccccc777777777777ccccccccc5554444444454544444544455cccc
000770009ee995ee2ee222ee4e2eeee4eee44e2e000000000000000000000000cccccccccccc7777777777777777cccccccccc54454444455444444555cccccc
00077000999944990222552254eeee45ee4554ee000000000000000000000000cccccccccc77777777777777777777ccccccccc5555445544554555ccccccccc
0070070099999999202222200444444044400444000000000000000000000000ccccccccc6666666666666666666666ccccccccccc5555544555cccccccccccc
0000000000499400225225000444444044400444000000000000000000000000ccccccccccccccccccccccccccccccccccccccccccccccc55ccccccccccccccc
0000000000900900002002000544445044500544000000000000000000000000cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
0000000006666660bbbbbbbb0000000000000000000000000000000044bbbbbbbbbbbbbbbbbbbbbbbbbbbb44cccc3353ccccccccc554455c5444444444444544
0000000060000006b33333330777877707778777077888770777877744bbbbbbbbbbbbbbbbbbbbbbbbbbbb44cc33353533ccccccccc55ccc4544444554444454
0000000060000006b33333330778887707777877077888770778777744bbbbbbbbbbbbbbbbbbbbbbbbbbbb44c5335335335ccccccccccccc4455445445444445
0000000060000006b33333330788888708888887077888770788888844bbbbbbbbbbbbbbbbbb7bbbbbbbbb44335533535533cccccccccccc4444554444544444
0000000060000006b33333330878887808888888087888780888888844bbbb7bbbbbbbbbbbb767bbb6dbb644533355353335cccccccccccc5445444444454455
0000000060000006b33333330778887708888887078888870788888844bbb767bbbbbbbbbbb575bbb55bb544c5335553555ccccccccccccc4544444444445544
0000000060000006b333333307788877077778770778887707787777c444457544444444444454444444444ccc55453335cccccccccccccc4454444444454444
0000000006666660b333333307788877077787770777877707778777cc4444544444444444444444444444cccccc44055ccccccccccccccc5444444555555555
00000000094009400000000009400940000000000000000000000000cc44444444444444444444444444444444454050544444cc000000000000000000000000
00000000099999900940094009999990000000000000000000000000c4474444444444444444444444466d44444545054547444c000000000000000000000000
0000000099919199099999909991919900000000000000000000000044767bbbbbbbbbbbbbbbbbbbbbb6dd3bbb54545445767b44000000000000000000000000
000000009ee995ee999191999ee995ee00000000000000000000000044373bbbbbbbbbbbbbbbbbbbbbb3333bbb55353545575b44000000000000000000000000
00000000999944999ee995ee9999449900000000000000000000000044b3bbbbbbbbbbbbbbbbbbbbbbbbbbbbbb33b3b35bb5b744000000000000000000000000
0000000099999999999944999999999900000000000000000000000044bbbbbbbbbbbbbbb65bb65bbbbbbbbbbbbbbbbbbbbb7674000000000000000000000000
0000000000499400949999490499400000000000000000000000000044bbbbbbbbbbbbbbb65bb33bbbbbbbbbbbbbbbbbbbbb5754000000000000000000000000
0000000000900900009009000900900000000000000000000000000044bbbbbbbbbbbbbbb33bbbbbbbbbbbbbbbbbbbbbbbbbb544000000000000000000000000
0000000000227770000000000022777000000000000000000000000044bbbbbb44bbbbbbbbb6bbb6bbb6bbbfbbbbbb44bbbbbb44000000000000000000000000
0000000002222220002277700222222000000000000000000000000044bbbbbb44bbbbbbb6bbb6bbb6bbb6bbbbbbbb44bbbbbb44000000000000000000000000
0000000022212122022222202221212200000000000000000000000044bbbbbb44b7bbbbbbbfbbb6bbb6bbb6bbbbbb44bbbbbb44000000000000000000000000
000000002ee222ee222121222ee222ee00000000000000000000000044bbbbbb44767bbbb6bbb6bbbfbbb6bbbbbbbb44bbbbbb44000000000000000000000000
000000000222bb222ee222ee0222bb2200000000000000000000000044bbbbbb44373bbbbbb6bbb7bbb6bbb6b7bbbb44bbbbbb44000000000000000000000000
00000000202222200222bb220222222000000000000000000000000044bbbbbb44b3bbbbb6bbbfbbb6bbb6bb767bbb44bbbbbb44000000000000000000000000
0000000022522500252222502522500000000000000000000000000044bbbbbb44bbbbbbbbb6bbb6bbb6bbb6575bbb44bbbbbb44000000000000000000000000
0000000000200200002002000200200000000000000000000000000044bbbbbb44bbbbbbbfbbb6bbb6bbbfbbb5bbbb44bbbbbb44000000000000000000000000
__label__
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
888888888888888888888888888888888888888888888888888888888888888888888888888888888882282288882288228882228228888888ff888888228888
888882888888888ff8ff8ff88888888888888888888888888888888888888888888888888888888888228882288822222288822282288888ff8f888888222888
88888288828888888888888888888888888888888888888888888888888888888888888888888888882288822888282282888222888888ff888f888888288888
888882888282888ff8ff8ff888888888888888888888888888888888888888888888888888888888882288822888222222888888222888ff888f888822288888
8888828282828888888888888888888888888888888888888888888888888888888888888888888888228882288882222888822822288888ff8f888222288888
888882828282888ff8ff8ff8888888888888888888888888888888888888888888888888888888888882282288888288288882282228888888ff888222888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555500000000000055555555555555555555555555555555555555500000000000055000000000000555
555555e555566656665555e555555555555665666566555506600606000055555555555555555555565555665566566655506660666000055066606660000555
55555ee555565655565555ee55555555556555656565655500600606000055555555555555555555565556565656565655506060606000055060606060000555
5555eee555565655565555eee5555555556665666565655500600666000055555555555555555555565556565656566655506060606000055060606060000555
55555ee555565655565555ee55555555555565655565655500600006000055555555555555555555565556565656565555506060606000055060606060000555
555555e555566655565555e555555555556655655566655506660006000055555555555555555555566656655665565555506660666000055066606660000555
55555555555555555555555555555555555555555555555500000000000055555555555555555555555555555555555555500000000000055000000000000555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555566666566666577777566666555555588888888566666666566666666566666666566666666566666666566666666566666666555555555
55555665566566655565566565556575557565656555555588877888566666766566666677566777776566667776566766666566766676566677666555dd5555
5555656565555655556656656665657775756565655555558878878856667767656666776756676667656666767656767666657676767656677776655d55d555
5555656565555655556656656555657755756555655555558788887856776667656677666756676667656666767657666767657777777756776677655d55d555
55556565655556555566566565666577757566656555555578888887576666667577666667577766677577777677576667767567676767577666677555dd5555
55556655566556555565556565556575557566656555555588888888566666666566666666566666666566666666566666666567666667566666666555555555
55555555555555555566666566666577777566666555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
555555555555555555005005005005dd500500566555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
555565655665655555005005005005dd5005665665555555777777775dddddddd5dddddddd5dddddddd5dddddddd5dddddddd5dddddddd5dddddddd555555555
555565656565655555005005005005dd5665665665555555777777775d55ddddd5dd5dd5dd5ddd55ddd5ddddd5dd5dd5ddddd5dddddddd5dddddddd555555555
555565656565655555005005005005775665665665555555777777775d555dddd5d55d55dd5dddddddd5dddd55dd5dd55dddd55d5d5d5d5d55dd55d555555555
555566656565655555005005005665775665665665555555777557775dddd555d5dd55d55d5d5d55d5d5ddd555dd5dd555ddd55d5d5d5d5d55dd55d555555555
555556556655666555005005665665775665665665555555777777775ddddd55d5dd5dd5dd5d5d55d5d5dd5555dd5dd5555dd5dddddddd5dddddddd555555555
555555555555555555005665665665775665665665555555777777775dddddddd5dddddddd5dddddddd5dddddddd5dddddddd5dddddddd5dddddddd555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55500000000000000000000000000000550000000000000000000000000000055000000000000000000000000000005500000000000000000000000000000555
55500000000000000000000000000000550000000000000000000000000000055000000000000000000000000000005500000000000000000000000000000555
55507700707066600eee00c0c00000005507700707066600eee00c0c00000005507770000066600eee00c0c00000005500770000066600eee00c0c0000000555
55507070777000600e0e00c0c00000005507070777000600e0e00c0c00000005507000000000600e0e00c0c00000005507000000000600e0e00c0c0000000555
55507070707006600e0e00ccc00000005507070707006600e0e00ccc00000005507700000006600e0e00ccc00000005507000000006600e0e00ccc0000000555
55507070777000600e0e0000c00000005507070777000600e0e0000c00000005507000000000600e0e0000c00000005507070000000600e0e0000c0000000555
55507770707066600eee0000c000d0005507770707066600eee0000c000d0005507770000066600eee0000c000d0005507770000066600eee0000c000d001555
55500000000000000000000000000000550000000000000000000000000000055000000000000000000000000000005500000000000000000000000000017155
55500000000000000000000000000000550000000000000000000000000000055000000000000000000000000000005500000000000000000000000000017715
55500000000000000000000000000000550000000000000000000000000000055000000000000000000000000000005500000000000000000000000000017771
55507700707066600eee00ccc00000005507700707066600eee00ccc00000005507770000066600eee00cc000000005500770000066600eee00ccc0000017777
55507070777000600e0e0000c00000005507070777000600e0e0000c00000005507000000000600e0e000c000000005507000000000600e0e0000c0000017711
55507070707006600e0e00ccc00000005507070707006600e0e00ccc00000005507700000006600e0e000c000000005507000000006600e0e000cc0000001171
55507070777000600e0e00c0000000005507070777000600e0e00c0000000005507000000000600e0e000c000000005507070000000600e0e0000c0000000555
55507770707066600eee00ccc000d0005507770707066600eee00ccc000d0005507770000066600eee00ccc000d0005507770000066600eee00ccc000d000555
55500000000000000000000000000000550000000000000000000000000000055000000000000000000000000000005500000000000000000000000000000555
55500000000000000000000000000000550000000000000000000000000000055000000000000000000000000000005500000000000000000000000000000555
55500000000000000000000000000000550000000000000000000000000000055000000000000000000000000000005501111111111111111111111aaaaa0555
55507700707066600eee00cc000ddd005507700707066600eee00cc000ddd0055000000000000000000000000000005501771111166611eee11cc11aaaaa0555
55507070777000600e0e000c000d00005507070777000600e0e000c000d000055000000000000000000000000000005507111111111611e1e111c11aaaaa0555
55507070707006600e0e000c000ddd005507070707006600e0e000c000ddd0055000000000000000000000000000005507111111116611e1e111c11aaaaa0555
55507070777000600e0e000c00000d005507070777000600e0e000c00000d0055000000000000000000000000000005507171111111611e1e111c11aaaaa0555
55507770707066600eee00ccc00ddd005507770707066600eee00ccc00ddd0055001000100010000100001000010005507771111166611eee11ccc1aadaa0555
55500000000000000000000000000000550000000000000000000000000000055000000000000000000000000000005501111111111111111111111aaaaa0555
55500000000000000000000000000000550000000000000000000000000000055000000000000000000000000000005500000000000000000000000000000555
55500000000000000000000000000000550000000000000000000000000000055000000000000000000000000000005500000000000000000000000000000555
55500000000000000000000000000000550000000000000000000000000000055000000000000000000000000000005500000000000000000000000000000555
55500000000000000000000000000000550000000000000000000000000000055000000000000000000000000000005500000000000000000000000000000555
55500000000000000000000000000000550000000000000000000000000000055000000000000000000000000000005500000000000000000000000000000555
55500000000000000000000000000000550000000000000000000000000000055000000000000000000000000000005500000000000000000000000000000555
55500100010001000010000100001000550010001000100001000010000100055001000100010000100001000010005500100010001000010000100001000555
55500000000000000000000000000000550000000000000000000000000000055000000000000000000000000000005500000000000000000000000000000555
55500000000000000000000000000000550000000000000000000000000000055000000000000000000000000000005500000000000000000000000000000555
55500000000000000000000000000000550000000000000000000000000000055000000000000000000000000000005500000000000000000000000000000555
5550000000000000000000000000000055000000000000000000000000000005507770000066600eee00c0c00000005500000000000000000000000000000555
5550000000000000000000000000000055000000000000000000000000000005507000000000600e0e00c0c00000005500000000000000000000000000000555
5550000000000000000000000000000055000000000000000000000000000005507700000006600e0e00ccc00000005500000000000000000000000000000555
5550000000000000000000000000000055000000000000000000000000000005507000000000600e0e0000c00000005500000000000000000000000000000555
5550010001000100001000010000100055001000100010000100001000010005507000000066600eee0000c000d0005500100010001000010000100001000555
55500000000000000000000000000000550000000000000000000000000000055000000000000000000000000000005500000000000000000000000000000555
55500000000000000000000000000000550000000000000000000000000000055000000000000000000000000000005500000000000000000000000000000555
55500000000000000000000000000000550000000000000000000000000000055000000000000000000000000000005500000000000000000000000000000555
55500000000000000000000000000000550000000000000000000000000000055000000000000000000000000000005500000000000000000000000000000555
55500000000000000000000000000000550000000000000000000000000000055000000000000000000000000000005500000000000000000000000000000555
55500000000000000000000000000000550000000000000000000000000000055000000000000000000000000000005500000000000000000000000000000555
55500000000000000000000000000000550000000000000000000000000000055000000000000000000000000000005500000000000000000000000000000555
55500100010001000010000100001000550010001000100001000010000100055001000100010000100001000010005500100010001000010000100001000555
55500000000000000000000000000000550000000000000000000000000000055000000000000000000000000000005500000000000000000000000000000555
55500000000000000000000000000000550000000000000000000000000000055000000000000000000000000000005500000000000000000000000000000555
55500000000000000000000000000000550000000000000000000000000000055000000000000000000000000000005500000000000000000000000000000555
555000000000000000000000000000005507700707066600eee00c0c000000055000000000000000000000000000005500000000000000000000000000000555
555000000000000000000000000000005507070777000600e0e00c0c000000055000000000000000000000000000005500000000000000000000000000000555
555000000000000000000000000000005507070707006600e0e00ccc000000055000000000000000000000000000005500000000000000000000000000000555
555000000000000000000000000000005507070777000600e0e0000c000000055000000000000000000000000000005500000000000000000000000000000555
555001000100010000100001000010005507770707066600eee0000c000d00055001000100010000100001000010005500100010001000010000100001000555
55500000000000000000000000000000550000000000000000000000000000055000000000000000000000000000005500000000000000000000000000000555
55500000000000000000000000000000550000000000000000000000000000055000000000000000000000000000005500000000000000000000000000000555
55500000000000000000000000000000550000000000000000000000000000055000000000000000000000000000005500000000000000000000000000000555
55500000000000000000000000000000550000000000000000000000000000055000000000000000000000000000005500000000000000000000000000000555
55500000000000000000000000000000550000000000000000000000000000055000000000000000000000000000005500000000000000000000000000000555
55500000000000000000000000000000550000000000000000000000000000055000000000000000000000000000005500000000000000000000000000000555
55500000000000000000000000000000550000000000000000000000000000055000000000000000000000000000005500000000000000000000000000000555
55500100010001000010000100001000550010001000100001000010000100055001000100010000100001000010005500100010001000010000100001000555
55500000000000000000000000000000550000000000000000000000000000055000000000000000000000000000005500000000000000000000000000000555
55500000000000000000000000000000550000000000000000000000000000055000000000000000000000000000005500000000000000000000000000000555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888

__map__
0808080808080808080808080808080800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
08080808080808090b0808080808080800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
090a0b0808080808080808080808080800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
080808080808080808080808090a0a0b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0808080808080808081b1c080808080800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
080808082729282a282b2c080808080800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0808080837393a3a3a393c080808080800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
08080808373a3a3a3a3a3b080808080800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
08080808373a3a3a3a3a3c080808080800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0808080838393a3a3a393c080808080800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
08080808373a39393a393c080808080800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
080808081718181918181a080808080800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
080808080c0d1f1e1f0e0f080808080800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
080808080808081d080808080808080800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0808080808080808080808080808080800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0808080808080808080808080808080800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
010d00000c0331700007000100000c033000000700024000246150000007000000000c0000000007000000000c0330000007000000000c033000000700000000246150000007000000000c000000000700000000
010d00000705007000000000b000090500d000070000b0000d050070000b0000d0000f0500d0000f00010000100511205111051120551000007000100000b000100510f051110510f0450d0000f0000f0000d000
010d00000704007000000000b000090400d000070000b0000d040070000b0000d0000f0400d0000f000100001204000000000001200010040100000e040100000c0410c0310b0210c0150b0000d0000f00000000
010d000025030260000000011000290300000000000000002c030000002903005000280402900029030000002503000000000000000029030110002c030120002a03000000000000000000000000000000000000
010d000025030260000000011000290300000000000000002c030000002903005000280400f00029030000002503000000000000000025030000001d0001100025030120001e0000000000000000000000000000
010d00002704027020270151b00000000000001b0001e000270402702027015000000000000000000001b0002104000000230401b000270400000000000000002704027020270151e7001b7001b7000000000000
010d00002704027020270151b00000000000001b0001e00027040270202701500000000001b00027040000002e0400000000000000002b04027000270001e7002704027030270250000000000000000000000000
010d00002704027020270151b00000000000001b0001e00027040270202701500000000001b00027040000002804000000000000000029040000002a0002c0002b0402b0302b0152700027000000000000000000
010d00000500000000020000200004000040000500005000050000400002000080000a0000a000080000700007000000000000009000070000b07000000080700000007070000000000000000000000000000000
__music__
00 00014344
00 00024344
01 00010344
00 00020448
00 00054344
00 00064344
00 00054344
00 00074344

