pico-8 cartridge // http://www.pico-8.com
version 18
__lua__
rectfill(0,0,127,127,5)

tiles={}
players={}
tweens={}
board_rows=5
board_cols=5
board_pad_x=4.5
board_pad_y=5

function make_actor(tag,x,y,x_offset,y_offset,col,row,sprite)
	x=x or 0
	y=y or 0
	x_offset=x_offset or 0
	col=col or 0
	row=row or 0
	y_offset=y_offset or 0
	
	a={}
	a.col=col
	a.row=row
	a.x=x
	a.y=y
	a.x_offset=x_offset
	a.y_offset=y_offset
	a.spr=sprite
	a.tag=tag
	a.parent=nil
	a.children={}
	return a
end

function detach(a)
	if a.parent == nil then
		return
	end
	del(a.parent.children,a)
	a.parent=nil
end

function attach(a,b)
	detach(a)
	a.parent=b
	add(b.children,a)
	a.col=b.col
	a.row=b.row
	a.x=(a.col+board_pad_x)*8
	a.y=(a.row+board_pad_y)*8
	printh("5>>"..a.x..";"..a.y..";"..b.col..";"..b.row)
end

function tile_at(x,y)
	local index=((y-1)*(board_cols))+x
	return tiles[index]
end

function _init()
 local a;
 for row=1,board_rows do
	 for col=1,board_cols do
		 a=make_actor("tile",(col+board_pad_x)*8,(row+board_pad_y)*8,0,0,col,row,18)	
	 	add(tiles,a)
	 end
 end
 
 a=make_actor("pop",8,8,0,-1,1,1,1)
 add(players,a)
 attach(a,tile_at(3,3))
 
 a=make_actor("puff",8,8,0,-1,1,1,2)
 add(players,a)
 attach(a,tile_at(2,1))
 make_tween(a,"y",(5+board_pad_y)*8,0.02)

	a=make_actor("cake",8,8,0,-1,1,1,3)
	attach(a,tile_at(1,4))
	add(tiles,a)
	make_tween(a,"x",(5+board_pad_x)*8,0.02)
	make_tween(a,"y",(1+board_pad_y)*8,0.02)

	a=make_actor("arrow",8,8,0,0,1,1,19)
	attach(a,tile_at(4,3))
 add(tiles,a)	
end

function on_arrow_stepped(arrow,stepper)
		
end

function on_tween_reached()
	printh("tween reached!")
	local p=players[1]
	for i=1,#p.parent.children,1 do
	 if p.parent.children[i].tag=="arrow" then
	 	on_arrow_stepped(p.parent.children[i],p)
	 end
	end
end

function control_player(player_num,dx,dy)
	dx=dx or 0
	dy=dy or 0
	local a=players[player_num]
	local t=tile_at(a.parent.col+dx,a.parent.row+dy);
	printh("-1>>"..a.parent.col..";"..a.parent.row..";"..t.col..";"..t.row)
	local x_or_y=nil
	local to_use=nil
	if dx!=0 then
		x_or_y="x"
		to_use=t.x
	elseif dy!=0 then
		x_or_y="y"
		to_use=t.y
	end
	if t != nil then
		make_tween(a,x_or_y,to_use,0.1,on_tween_reached)
		printh("0>>"..t.col..","..t.row)
	end
end

function handle_tween(tween)
	if tween__handle_reached(tween) then
		return
	end	
	if tween.xory=="x" then
		tween.obj.x=rbl__fflr(tween.obj.x+tween.steps);
	elseif tween.xory=="y" then
		tween.obj.y=rbl__fflr(tween.obj.y+tween.steps);
	end
	printh("steps:"..tween.steps)
	printh("obj.x:"..tween.obj.x..";obj.y:"..tween.obj.y)
	
	tween.obj.col=flr((tween.obj.x/8)-board_pad_x)
	tween.obj.row=flr((tween.obj.y/8)-board_pad_y)
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
	local sx=a.x+a.x_offset
	local sy=a.y+a.y_offset
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
	local tween={}
	
	tween.obj=a
	tween.xory=xory
	tween.on_reached=on_reached
	
	local current=nil
	if xory=="x" then
		current=a.x
	elseif xory=="y" then
		current=a.y
	end
	if target>current then
		tween.direction=1
	elseif target<current then
		tween.direction=-1
	else
		rbl__error("target should not be equal to current")
		return
	end
	printh("-4>>"..tween.direction..";"..current..";"..target)
	tween.steps=(target-current)*seconds
	printh("-3>>"..tween.steps..";"..current..";"..target..";"..seconds)
	tween.target=target
	add(tweens,tween)
	return tween
end

function tween__handle_reached(tween)
	local to_check=nil
	if tween.xory=="x" then
		to_check=tween.obj.x
	else
		to_check=tween.obj.y
	end
	if (tween.direction > 0 
			and to_check >= tween.target) 
		or (tween.direction < 0	
			and to_check <= tween.target)
	 then
		if tween.xory=="x" then
			tween.obj.x=tween.target
		else
			tween.obj.y=tween.target
		end
		printh("3.5>>"..tween.obj.col..";"..tween.obj.row)
		local t=tile_at(tween.obj.col,tween.obj.row)
		printh("4>>finding tile at:"..tween.obj.col..";"..tween.obj.row..";"..t.col..";"..t.row)
		attach(tween.obj,t)
	
		del(tweens,tween)
		printh("tweendestroyed:"..#tweens)		
		
		if tween.on_reached != nil then
			tween.on_reached()
		end
		return true
	end
	return false
end
-->8
function rbl__fflr(num)
	return flr(num*100)/100
end

function rbl__error(message)
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
0000000060000006b33333330778887700000000000000000000000044bbbbbbbbbbbbbbbbbbbbbbbbbbbb44cc33353533ccccccccc55ccc4544444554444454
0000000060000006b33333330778887700000000000000000000000044bbbbbbbbbbbbbbbbbbbbbbbbbbbb44c5335335335ccccccccccccc4455445445444445
0000000060000006b33333330778887700000000000000000000000044bbbbbbbbbbbbbbbbbb7bbbbbbbbb44335533535533cccccccccccc4444554444544444
0000000060000006b33333330878887800000000000000000000000044bbbb7bbbbbbbbbbbb767bbb6dbb644533355353335cccccccccccc5445444444454455
0000000060000006b33333330788888700000000000000000000000044bbb767bbbbbbbbbbb575bbb55bb544c5335553555ccccccccccccc4544444444445544
0000000060000006b333333307788877000000000000000000000000c444457544444444444454444444444ccc55453335cccccccccccccc4454444444454444
0000000006666660b333333307778777000000000000000000000000cc4444544444444444444444444444cccccc44055ccccccccccccccc5444444555555555
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
011200000e0700e0000e0500e0500e0500c0500e0501005010050110500f0500e050100501f050100500c0500c0500c0500c0500e0500e0500e0500e0500e0500c0500e050100500e050100500e0500000000000
011000000c350113501a350173501a350173501735010030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
04 00014344

