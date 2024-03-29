pico-8 cartridge // http://www.pico-8.com
version 18
__lua__
-- pop puff and away!
-- by accidental rebel

#include powerkit.lua

printh("Peeked: "..peek(0x1000))
printh("Peeked: "..peek(0x1004))

-- globals
char_array = { "-", "0", "P", "F", "B", "^", ">", "V", "<", "S", "!", "]", ";", "[", "X" }
alpha_array = { "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z" }

levels = {"DRHRGTBQBESIRFRC2",
	  --"DRHRGTBQBTIRFRC2",
	  "DRBHRBIQESBQCBFTBI2",
	  --"DRBHRBIUBQCBFTBI2",
	  "VDFHQBRBQHSCU2",
	  "RBHRGRIQBSCSFQDBFQ2",
	  "RHQCDRHSBBTFBBQFR2",
	  "QHFSHFRBHFQIQHFSBDQC2",
	  "QGQIRBQBTFCDFTBQBQ2",
	  "RGQBUGQCQFBQBRDT2",
	  "BHBITFDQBQCWGBIQ2",
	  "DQHQHRBRGBCBFRBRFQGQB1",
	  "QFBBBQBSBQCQITBFFDQF2",
	  "QBHIQBGBFWDVCQ2",
	  "HIIIIHHICFHHBIFBGGFFDGGGF1",
	  "BGHGHDFBFRFBFRFBFCGFGFB2",
	  "QBYGDBITCQFBBI1",
	  "GQBQICRHBGDQBBHSBGGGGF1",
	  "GBGBSBRGBBBSBRDBCBF3",
	  "UGBHBIRDRGBQBIRCR2",
	  "DSGRCRHQHQHBQBQHFBGBI1",
	  "QBRBGQHBIFCBQFDQGBFU2" }

board_rows = 5
board_cols = 5
board_pad_x = 4.5
board_pad_y = 5
slide_speed = 0.2
moves_left = 3
current_player_index = 1
current_level_index = 1

tile_highlight = nil
char_highlight = nil
cupcake_counter_label = nil
moves_left_label = nil
is_highlight_mode = false
has_switched_player = false
tiles = {}
board_tiles = {}
cupcakes = {}
players = {}
tweens = {}
t_pool = {}
ui = {}

-- enums
_x=1
_y=2

_all_types="all_types"
_pop="pop"
_puff="puff"
_cupcake="cupcake"
_arrow="arrow"
_arrow_p="arrow_p"
_box="box"
_hole="hole"
_highlight="highlight"
_switch="switch"
_ui_label="ui_label"

_spr_pop=33
_spr_puff=49
_spr_cupcake=7
_spr_arrow=3
_spr_arrow_p=19
_spr_box=45
_spr_hole=46
_spr_switch=47
_spr_tile_highlight=64
_spr_char_highlight=80

_up=1
_right=2
_down=3
_left=4

log("##################################")
-- SETUP ====
function _init()
   setup_board()

   setup_map(current_level_index)
   setup_ui()
end

function setup_board()
   local a
   for row = 1,board_rows,1 do
      for col = 1,board_cols,1 do
	 a = make_actor("tile",(col+board_pad_x)*8,(row+board_pad_y)*8,0,0,col,row,18)	
	 add(board_tiles,a)
      end
   end
end

function debug_tiles()
   local debug_string = "Debug Tiles: "
   
   for board_tile in all(board_tiles) do
      if #board_tile.children > 0 then
	 debug_string = debug_string.."("..board_tile.col..","..board_tile.row..")"
	 
	 for child in all(board_tile.children) do
	    debug_string = debug_string..child.tag
	 end
	 debug_string = debug_string.." - "
      end
   end
   log(debug_string)
end

function setup_map(level_num)
   local map_string = levels[level_num]
   moves_left = sub(map_string, #map_string, #map_string)
   map_string = sub(map_string, 1, #map_string - 1)
   map_string = decompress_map_string(map_string)

   local a = nil
   local c = nil
   local bit_index = 1
   local col = 1
   local row = 1
   
   for i=2,#map_string,2 do
      c = sub(map_string,i,i)
      if c == "F" then
	 make_player(_puff,col,row)
      elseif c == "P" then
	 make_player(_pop,col,row)
      elseif c == "0" then
	 make_cupcake(col,row)
      elseif c == "B" then
	 make_box(col,row)
      elseif c == "X" then
	 a=make_actor(_hole,8,8,0,0,0,0,_spr_hole)
	 attach(a,get_tile_at(2,2))
	 add(tiles,a)
      elseif c == "^" then
	 make_arrow(_arrow,_up,col,row)
      elseif c == ">" then
	 make_arrow(_arrow,_right,col,row)
      elseif c == "V" then
	 make_arrow(_arrow,_down,col,row)
      elseif c == "<" then
	 make_arrow(_arrow,_left,col,row)
      elseif c == "!" then
	 make_arrow(_arrow_p,_up,col,row)
      elseif c == "]" then
	 make_arrow(_arrow_p,_right,col,row)
      elseif c == ";" then
	 make_arrow(_arrow_p,_down,col,row)
      elseif c == "[" then
	 make_arrow(_arrow_p,_left,col,row)
      end

      col = col + 1
      if col > board_cols then
	 col = 1
	 row = row + 1
      end
   end
end

function clear_map()
   for tile in all(tiles) do
      if tile.tag == _box then
	 pool(tile)
      end
   end
end

function setup_ui()
   tile_highlight = make_highlight(2,3,2,3,_spr_tile_highlight,3,3)
   tile_highlight.visible = false

   char_highlight = make_highlight(3,3,3,3,_spr_char_highlight)
   char_highlight.x = 4
   char_highlight.y = 4

   a=make_actor("ui_cupcake",108,2,0,0,0,0,_spr_cupcake)
   add(ui,a)
   a=make_actor("ui_puff",4,4,0,0,0,0,_spr_puff)
   add(ui,a)
   a=make_actor("ui_pop",16,4,0,0,0,0,_spr_pop)
   add(ui,a)

   cupcake_counter_label = make_ui_label("x"..#cupcakes,118,4)
   moves_left_label = make_ui_label(moves_left.." moves left",41,4)
end

function make_ui_label(text,x,y)
   a = {}
   a.x = x
   a.y = y
   a.text = text
   a.tag = _ui_label
   a.on_draw = draw_ui
   add(ui,a)
   return a
end

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
   a.anim_index = 0
   a.anim_elapsed = 0
   a.tag = tag
   a.visible = true
   a.parent = nil
   a.children = {}
   return a
end

function make_arrow(arrow_type, pointing,col,row)
   local spr_index = _spr_arrow
   if arrow_type == _arrow_p then
      spr_index = _spr_arrow_p
   end
   spr_index = spr_index + pointing - 1
   
   local arrow = pool_fetch(arrow_type)
   if arrow == nil then
      arrow = make_actor(arrow_type,0,0,0,0,col,row,spr_index)
   end
   arrow.spr = spr_index
   arrow.pointing=pointing
   arrow.type = arrow_type
   
   attach(arrow,get_tile_at(col,row))
   add(tiles,arrow)
   return arrow
end

function make_cupcake(col,row)
   local cupcake = pool_fetch(_cupcake)
   if cupcake == nil then
      cupcake = make_actor(_cupcake,8,8,0,-1,0,0,_spr_cupcake)
   end
   attach(cupcake,get_tile_at(col,row))
   add(cupcakes,cupcake)   
end

function make_player(id,col,row)
   local player = nil
   local sprite = nil
   local player_index = 0
   if id == _pop then
      sprite = _spr_pop
      player_index = 2
   else
      sprite = _spr_puff
      player_index = 1
   end
   player = players[player_index]
   if player == nil then
      player = make_actor(id,0,0,0,-1,col,row,sprite)
      players[player_index] = player
   end

   attach(player,get_tile_at(col,row))

   player.anim_index = 0
   player.pointing = nil
   player.stop_on_next_tile = false
   player.is_traveling = false
   
   return player
end

function make_box(col,row)
   local box = pool_fetch(_box)
   if box == nil then
      box = make_actor(_box,8,8,0,-1,0,0,_spr_box)
   end
   attach(box,get_tile_at(col,row))
   add(tiles,box)
   return box
end

function make_switch(col,row)
   local switch = make_actor(_switch,8,8,1,1,0,0,_spr_switch)
   add(tiles,switch)
   attach(switch,get_tile_at(col,row))

   switch.slaves = {}
   return switch
end

function add_switch_slave(switch,col,row)
   local t = get_tile_at(col,row)
   assert(t != nil, "Tile at "..col..","..row.." could not be found!")

   local slave = get_child_of_type(t,{_arrow,_arrow_p})
   assert(slave != nil,"Slave should not be null!")

   add(switch.slaves,slave)
end

function make_highlight(x_offset_left,x_offset_right,y_offset_up,y_offset_down,sprite,col,row)
   local highlight = make_actor(_highlight,8,8,1,1,0,0,0)
   highlight.top_left = make_actor(_highlight,8,8,-x_offset_left,-y_offset_up,0,0,sprite)
   highlight.top_right = make_actor(_highlight,8,8,x_offset_right,-y_offset_up,0,0,sprite+1)
   highlight.bottom_right = make_actor(_highlight,8,8,x_offset_right,y_offset_down,0,0,sprite+2)
   highlight.bottom_left = make_actor(_highlight,8,8,-x_offset_left,y_offset_down,0,0,sprite+3)
   add(ui,highlight)
   if col != nil and row != nil then
      attach(highlight,get_tile_at(col,row))
   end

   highlight.on_draw = draw_highlight
   return highlight
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
end

function get_tile_at(col,row)
   if col < 1 or col > board_cols
      or row < 1 or row > board_rows
   then
      return nil
   end
   local index = ((row-1)*(board_cols))+col
   return board_tiles[index]
end

function pool(obj)
   detach(obj)
   add(t_pool,obj)
   if obj.tag == nil then
      log("pooladded:"..tostr(obj))
   else
      log("pooladded: "..obj.tag)
   end
   if obj.tag == _cupcake then
      del(cupcakes,obj)
   elseif obj.tag == _pop
   or obj.tag == _puff then
      del(players,obj)
   elseif obj.tag == _arrow or obj.tag == _box then
      del(tiles,obj)
   else
      del(tiles,obj)
   end
end

function pool_fetch(tag)
   for obj in all(t_pool) do
      if obj.tag != nil then
	 if obj.tag == tag then
	    del(t_pool,obj)
	    log("Pool fetched: "..obj.tag)
	    return obj
	 end
      end
   end
   return nil
end

function on_hole_stepped(hole,stepper)
   
end

function on_switch_stepped(switch,stepper)
   for slave in all(switch.slaves) do
      if slave.tag == _arrow or slave.tag == _arrow_p then
	 rotate_arrow(slave)
      end
   end
end

function on_cupcake_stepped(cake,stepper)
   pool(cake)
   cupcake_counter_label.text = "x"..#cupcakes
end

function on_arrow_stepped(arrow,stepper)
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

   if arrow.type == _arrow then
      pool(arrow)
   end

   local next_tile = get_next_tile(stepper,stepper.pointing)
   if next_tile == nil then
      on_reached_destination(stepper)
      return
   end
   stepper.is_traveling = true
   slide_to_tile(stepper, next_tile.col, next_tile.row)
end

function switch_to_next_player()
   if has_switched_player then
      return
   end
   has_switched_player = true
   local current_player = players[current_player_index]
   current_player_index += 1
   if current_player_index > 2 then
      current_player_index = 1
   end

   if current_player_index == 1 then
      char_highlight.x = 4
   else
      char_highlight.x = 16
   end
end

function on_reached_destination(obj)
   obj.is_traveling = false

   if obj.tag == _pop or obj.tag == _puff then
      if obj.tag == players[current_player_index].tag then
	 if #cupcakes <= 0 then
	    on_level_cleared()
	 else
	    switch_to_next_player()
	 end
	 debug_tiles()
      end
   end
end

function continue_sliding(slider)
   local next_tile=get_next_tile(slider,slider.pointing)
   if next_tile != nil and can_move_to_tile(slider,next_tile) then
      slider.is_traveling = true
      slide_to_tile(slider,next_tile.col,next_tile.row)
   else
      on_reached_destination(slider)
   end
end

function on_level_cleared()
   clear_map()
   current_level_index = current_level_index + 1
   setup_map(current_level_index)
   current_player_index = 1
end

function on_tween_reached(tween)
   local p = tween.obj

   if p.tag == _highlight then
      return
   end

   for child in all(p.parent.children) do
      if child.tag == _switch then
	 on_switch_stepped(child,p)
      end

      if child.tag == _cupcake then
	 on_cupcake_stepped(child,p)
      end
      
      if child.tag == _arrow or child.tag == _arrow_p then
	 on_arrow_stepped(child,p)
	 break
      elseif child.tag == _hole then
	 on_hole_stepped(child,p)
	 break
      else
	 if p.stop_on_next_tile then
	    on_reached_destination(p)
	    p.stop_on_next_tile = false
	    return
	 end
	 
	 continue_sliding(p)
	 break
      end
   end
end

function get_next_tile(obj,direction)
   if direction == _up then
      return get_tile_at(obj.col,obj.row-1)
   elseif direction == _right then
      return get_tile_at(obj.col+1,obj.row)
   elseif direction == _down then
      return get_tile_at(obj.col,obj.row+1)
   elseif direction == _left then
      return get_tile_at(obj.col-1,obj.row)
   end
   return nil
end

function get_child_of_type(tile, types)
   if type(types) != "table" then
      types = {types}
   end
   local child = nil
   local typ = nil
   for child in all(tile.children) do
      for typ in all(types) do
	 if child != nil and child.tag == typ then
	    return child
	 end
      end
   end
   return nil
end

function get_direction(a,b)
   if a.col < b.col then
      return _right
   elseif a.col > b.col then
      return _left
   elseif a.row < b.row then
      return _down
   elseif a.row > b.row then
      return _up
   end
   return nil
end
   
function can_move_to_tile(obj,target_tile)
   if target_tile == nil then
      return false
   else
      if #target_tile.children <= 0 then
      	 return true
      else
	 local child = get_child_of_type(target_tile,{_box,_pop,_puff})
	 if child == nil then
	    return true
	 else
	    local direction = get_direction(obj,target_tile)
	    return can_move_to_tile(target_tile, get_next_tile(target_tile,direction))
	 end
      end
   end
end

function slide_to_tile(a,col,row)
   local target_tile = get_tile_at(col,row)
   if a.tag != _pop and a.tag != _puff then
      a.stop_on_next_tile = true
   end
   
   if a.col != col then
      make_tween(a,_x,target_tile.x,slide_speed,on_tween_reached)
   end
   if a.row != row then
      make_tween(a,_y,target_tile.y,slide_speed,on_tween_reached)
   end

   if a.tag != _highlight then
      local child = get_child_of_type(target_tile, {_box,_pop,_puff})
      if child != nil then
	 local t = get_next_tile(child,get_direction(a,child))
	 child.pointing = a.pointing
	 child.is_traveling = true
	 slide_to_tile(child,t.col,t.row)

	 a.stop_on_next_tile = true
      end
   end
end

function is_anyone_traveling()
   for obj in all(players) do
      if obj.is_traveling then
	 return true
      end
   end
   for obj in all(tiles) do
      if obj.is_traveling then
	 return true
      end
   end
   return false
end

function control_player(player_num,dx,dy)
   dx = dx or 0
   dy = dy or 0
   local a = players[player_num]
   if is_anyone_traveling() or a.is_traveling then
      return
   end
   
   local t = get_tile_at(a.parent.col+dx,a.parent.row+dy);
   if t == nil then
      return
   end
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
   if can_move_to_tile(a,t) then
      moves_left -= 1
      moves_left_label.text = moves_left.." moves left"
      
      a.is_traveling = true
      has_switched_player = false
      slide_to_tile(a,t.col,t.row)
   end
end

function handle_tween(tween)
   if tween.xory == _x then
      if tween.direction < 0 then
	 tween.obj.x = fceil(tween.obj.x+tween.steps);
      else
	 tween.obj.x = fflr(tween.obj.x+tween.steps);
      end
   elseif tween.xory == _y then
      if tween.direction < 0 then
	 tween.obj.y = fceil(tween.obj.y+tween.steps);
      else
	 tween.obj.y = fflr(tween.obj.y+tween.steps);
      end
   end

   if tween.direction < 0 then
      tween.obj.col = ceil((tween.obj.x/8)-board_pad_x)
      tween.obj.row = ceil((tween.obj.y/8)-board_pad_y)
   else
      tween.obj.col = flr((tween.obj.x/8)-board_pad_x)
      tween.obj.row = flr((tween.obj.y/8)-board_pad_y)
   end

   tween_handle_reached(tween)
end

function control_highlight(dx,dy)
   slide_to_tile(tile_highlight,tile_highlight.col+dx,tile_highlight.row+dy)
end

function rotate_arrow(arrow)
   arrow.spr += 1
   if arrow.tag == _arrow then
      if arrow.spr >= _spr_arrow + 4 then
	 arrow.spr = _spr_arrow
      end
   elseif arrow.tag == _arrow_p then
      if arrow.spr >= _spr_arrow_p + 4 then
	 arrow.spr = _spr_arrow_p
      end
   end
   
   if arrow.tag == _arrow then
      arrow.pointing = arrow.spr - _spr_arrow + 1
   elseif arrow.tag == _arrow_p then
      arrow.pointing = arrow.spr - _spr_arrow_p + 1
   end
end

function _update()
   if btnp(0) then
      if is_highlight_mode then
	 control_highlight(-1,0)
      else
	 control_player(current_player_index,-1,0)
      end
   elseif btnp(1) then
      if is_highlight_mode then
	 control_highlight(1,0)
      else
	 control_player(current_player_index,1,0)
      end
   elseif btnp(2) then
      if is_highlight_mode then      
	 control_highlight(0,-1)
      else
	 control_player(current_player_index,0,-1)
      end
   elseif btnp(3) then
      if is_highlight_mode then
	 control_highlight(0,1)
      else
	 control_player(current_player_index,0,1)
      end
   elseif btnp(4) then
      if is_anyone_traveling() then
	 return
      end
      if is_highlight_mode then
	 is_highlight_mode = false
	 tile_highlight.visible = false
	 char_highlight.visible = true
      else
	 is_highlight_mode = true
	 tile_highlight.visible = true
	 char_highlight.visible = false
      end
   elseif btnp(5) then
      if is_highlight_mode then
	 local tile = get_tile_at(tile_highlight.col,tile_highlight.row)
	 local child = get_child_of_type(tile,{_arrow,_arrow_p})
	 if child != nil then
	    rotate_arrow(child)
	 end
      end
   end
   
   foreach(tweens,handle_tween)

   local p = players[current_player_index]
   p.anim_elapsed += 1
   if p.anim_elapsed >= 7 then
      p.anim_index += 1
      if p.anim_index >= 2 then
	 p.anim_index = 0
      end
      p.anim_elapsed = 0
   end
end

function draw_actor(a)
   if a.on_draw == nil then
      local sx = a.x+a.x_offset
      local sy = a.y+a.y_offset
      spr(a.spr + a.anim_index, sx, sy)
   else
      a.on_draw(a)
   end
end

function draw_highlight(c)
   if not c.visible then
      return
   end

   local sx = c.x
   local sy = c.y
   
   spr(c.top_left.spr, c.x + c.top_left.x_offset, c.y + c.top_left.y_offset)
   spr(c.top_right.spr, c.x + c.top_right.x_offset, c.y + c.top_right.y_offset)
   spr(c.bottom_right.spr, c.x + c.bottom_right.x_offset, c.y + c.bottom_right.y_offset)
   spr(c.bottom_left.spr, c.x + c.bottom_left.x_offset, c.y + c.bottom_left.y_offset)
end

function draw_ui(ui)
   if ui.tag == _ui_label then
      print(ui.text,ui.x,ui.y,1)
   end
end

function _draw()
   cls()
   rectfill(-4,0,127,127,12)   
   map(0,0,4,0,16,16)
   foreach(board_tiles,draw_actor)
   foreach(tiles,draw_actor)
   foreach(cupcakes,draw_actor)
   foreach(players,draw_actor)
   foreach(ui,draw_actor)

   -- if is_highlight_mode then
   --    print("cursor mode",2,2,1)
   -- elseif current_player_index == 1 then
   --    print("current player: pop",2,2,1)
   -- else
   --    print("current player: puff",2,2,1)
   -- end
end

-->8
-- tween
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
   end
   
   if target > current then
      tween.direction = 1
   elseif target < current then
      tween.direction = -1
   else
      error("target should not be equal to current")
      return
   end
   tween.steps = fflr((target-current)*seconds)

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
	  and to_check >= tween.target) 
      or (tween.direction < 0	
	     and to_check <= tween.target)
   then
      if tween.xory == _x then
	 if tween.direction > 0 then
	    tween.obj.x = tween.target
	 else
	    tween.obj.x = tween.target
	 end
      else
	 tween.obj.y = tween.target
      end

      local t = get_tile_at(tween.obj.col,tween.obj.row)
      if t != nil then
	 attach(tween.obj,t)
      end
      
      del(tweens,tween)
      
      if tween.on_reached != nil then
	 tween.on_reached(tween)
      end
      return true
   end
   return false
end
-->8
-- levels
function compress_map_string(map_string)
   log(map_string)
   
   local new_string = ""
   local bit_index = 1
   for i=1, #map_string do
      local data = sub(map_string,i,i)

      if bit_index == 1 then
	 local first_int = tonum(data)
	 if first_int != nil then
	    data = first_int
	 end

	 if data != '-' then
	    new_string = new_string..data
	 end

	 bit_index += 1
      else
	 data = get_table_index(char_array,data)

	 if data != nil then
	    new_string = new_string..alpha_array[data]
	 end

	 bit_index = 1
      end
   end

   log(new_string)

   map_string = new_string
   local c = nil

   local current_char = nil
   new_string = ""
   count = 0
   for i=1, #map_string+1 do
      current_char = sub(map_string,i,i)
      if current_char == "A" then
	 count = count + 1
	 if count + 15 >= 25 then
	    new_string = new_string..alpha_array[count+16]
	    count = 0
	 end
      else
	 if count > 0 then
	    new_string = new_string..alpha_array[count+16]
	    count = 0
	 end
	 new_string = new_string..current_char
      end
   end
   log(new_string)
   return new_string
end

function decompress_map_string(map_data)
   local new_string = ""
   local current_char = nil
   local is_continue = false
   local index = 0
   for i=1, #map_data do
      is_continue = false
      current_char = sub(map_data,i,i)
      if tonum(current_char) != nil then
	 new_string = new_string..current_char
	 is_continue = true
      end

      if not is_continue then
	 index = get_table_index(alpha_array, current_char)
	 if index >= 16 then
	    for j=1, index-16 do
	       new_string = new_string.."A"
	    end
	 else
	    new_string = new_string..current_char
	 end
      end
   end
   log(new_string)

   map_data = new_string
   new_string = ""
   index = 0

   local was_digit = false
   for i=1, #map_data do
      current_char = sub(map_data,i,i)
      if tonum(current_char) != nil then
	 new_string = new_string..current_char
	 was_digit = true
      else
	 if not was_digit then
	    new_string = new_string.."-"
	 end

	 index = get_table_index(alpha_array, current_char)
	 current_char = char_array[index]

	 new_string = new_string..current_char
	 was_digit = false
      end
   end

   log(new_string)
   return new_string
end

__gfx__
00000000094009400022777000000000000000000000000000000000088e2e00cccccccccccccccccccccccccccccccccc4444445445444444445444444455cc
00000000099999900222222007778777077787770778887707778777088eeee0ccccccccccccccccccc7777ccccccccccc554445444455444444454445445ccc
00e00e00999191992221212207788877077778770778887707787777eeeee2e4cccccccccccccc777777777777ccccccccc5554444444454544444544455cccc
000ee0009ee995ee2ee222ee078888870888888707788877078888884e2eeee4cccccccccccc7777777777777777cccccccccc54454444455444444555cccccc
000ee00099994499022255220878887808888888087888780888888854eeee45cccccccccc77777777777777777777ccccccccc5555445544554555ccccccccc
00e00e0099999999202222200778887708888887078888870788888804444440ccccccccc6666666666666666666666ccccccccccc5555544555cccccccccccc
0000000000499400225225000778887707777877077888770778777704444440ccccccccccccccccccccccccccccccccccccccccccccccc55ccccccccccccccc
0000000000900900002002000778887707778777077787770777877705444450cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
00000000aaaaaaa5bbbbbbbb0000000000000000000000000000000044bbbbbbbbbbbbbbbbbbbbbbbbbbbb44cccc3353ccccccccc554455c5444444444444544
00000000a90009a5b33333330777977707779777077999770777977744bbbbbbbbbbbbbbbbbbbbbbbbbbbb44cc33353533ccccccccc55ccc4544444554444454
00000000a00000a5b33333330779997707777977077999770779777744bbbbbbbbbbbbbbbbbbbbbbbbbbbb44c5335335335ccccccccccccc4455445445444445
00000000a00000a5b33333330799999709999997077999770799999944bbbbbbbbbbbbbbbbbb7bbbbbbbbb44335533535533cccccccccccc4444554444544444
00000000a00000a5b33333330979997909999999097999790999999944bbbb7bbbbbbbbbbbb767bbb6dbb644533355353335cccccccccccc5445444444454455
00000000a90009a5b33333330779997709999997079999970799999944bbb767bbbbbbbbbbb575bbb55bb544c5335553555ccccccccccccc4544444444445544
00000000aaaaaaa5b333333307799977077779770779997707797777c444457544444444444454444444444ccc55453335cccccccccccccc4454444444454444
0000000055555555b333333307799977077797770777977707779777cc4444544444444444444444444444cccccc44055ccccccccccccccc5444444555555555
00000000094009400000000009400940000000000000000000000000cc44444444444444444444444444444444454050544444cc000000000000000000000000
00000000099999900940094009999990000000000000000000000000c4474444444444444444444444466d44444545054547444c044444440444444406666600
0000000099919199099999909991919900000000000000000000000044767bbbbbbbbbbbbbbbbbbbbbb6dd3bbb54545445767b44044fff440444444406888d00
000000009ee995ee999191999ee995ee00000000000000000000000044373bbbbbbbbbbbbbbbbbbbbbb3333bbb55353545575b4404f4f4f40454545406888d00
00000000999944999ee995ee9999449900000000000000000000000044b3bbbbbbbbbbbbbbbbbbbbbbbbbbbbbb33b3b35bb5b74404ff4ff40545454506888d00
0000000099999999999944999999999900000000000000000000000044bbbbbbbbbbbbbbb65bb65bbbbbbbbbbbbbbbbbbbbb767404f4f4f40454545406dddd00
0000000000499400949999490499400000000000000000000000000044bbbbbbbbbbbbbbb65bb33bbbbbbbbbbbbbbbbbbbbb5754044fff440555555500000000
0000000000900900009009000900900000000000000000000000000044bbbbbbbbbbbbbbb33bbbbbbbbbbbbbbbbbbbbbbbbbb544044444440555555500000000
0000000000227770000000000022777000000000000000000000000044bbbbbb44bbbbbbbbb6bbb6bbb6bbbfbbbbbb44bbbbbb44000000000000000000000000
0000000002222220002277700222222000000000000000000000000044bbbbbb44bbbbbbb6bbb6bbb6bbb6bbbbbbbb44bbbbbb44000000000000000000000000
0000000022212122022222202221212200000000000000000000000044bbbbbb44b7bbbbbbbfbbb6bbb6bbb6bbbbbb44bbbbbb44000000000000000000000000
000000002ee222ee222121222ee222ee00000000000000000000000044bbbbbb44767bbbb6bbb6bbbfbbb6bbbbbbbb44bbbbbb44000000000000000000000000
000000000222bb222ee222ee0222bb2200000000000000000000000044bbbbbb44373bbbbbb6bbb7bbb6bbb6b7bbbb44bbbbbb44000000000000000000000000
00000000202222200222bb220222222000000000000000000000000044bbbbbb44b3bbbbb6bbbfbbb6bbb6bb767bbb44bbbbbb44000000000000000000000000
0000000022522500252222502522500000000000000000000000000044bbbbbb44bbbbbbbbb6bbb6bbb6bbb6575bbb44bbbbbb44000000000000000000000000
0000000000200200002002000200200000000000000000000000000044bbbbbb44bbbbbbbfbbb6bbb6bbbfbbb5bbbb44bbbbbb44000000000000000000000000
0000000000000000000000a00a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0aaaaaaaaaaaaaa0000000a00a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0aa0000000000aa0000000a00a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0a0aa000000aa0a00000a0a00a0a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0a0a00000000a0a0000aa0a00a0aa000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0a000000000000a000000aa00aa00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0a000000000000a0aaaaaaa00aaaaaaa000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0a000000000000a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000dddddda00adddddd000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0aaaaaaaaaaaaaa0dddddda00adddddd000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0aaddddddddddaa0dddddda00adddddd000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0adddddddddddda0dddddda00adddddd000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0adddddddddddda0dddddda00adddddd000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0adddddddddddda0dddddaa00aaddddd000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0adddddddddddda0aaaaaaa00aaaaaaa000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0adddddddddddda00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
55000000300000600000600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003219
__label__
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888ffffff882222228888888888888888888888888888888888888888888888888888888888888888228228888ff88ff888222822888888822888888228888
88888f8888f882888828888888888888888888888888888888888888888888888888888888888888882288822888ffffff888222822888882282888888222888
88888ffffff882888828888888888888888888888888888888888888888888888888888888888888882288822888f8ff8f888222888888228882888888288888
88888888888882888828888888888888888888888888888888888888888888888888888888888888882288822888ffffff888888222888228882888822288888
88888f8f8f88828888288888888888888888888888888888888888888888888888888888888888888822888228888ffff8888228222888882282888222288888
888888f8f8f8822222288888888888888888888888888888888888888888888888888888888888888882282288888f88f8888228222888888822888222888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555550000000000000000000000000000000000000000000000000000000000000000005555550000000000000000000000000000000000000000005555555
55555550aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa05555550000000000011111111112222222222333333333305555555
55555550aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa05555550000000000011111111112222222222333333333305555555
55555550aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa05555550000000000011111111112222222222333333333305555555
55555550aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa05555550000000000011111111112222222222333333333305555555
55555550aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa05555550000000000011111111112222222222333333333305555555
55555550aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa05555550000000000011111111112222222222333333333305555555
55555550aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa05555550000000000011111111112222222222333333333305555555
55555550aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa05555550000000000011111111112222222222333333333305555555
55555550aaaaaaaa5555555555555555555555555555555555555555555555550000000005555550000000000777777777777222222222333333333305555555
55555550aaaaaaaa5555555555555555555555555555555555555555555555550000000005555550444444444700000000007666666666777777777705555555
55555550aaaaaaaa5555555555555555555555555555555555555555555555550000000005555550444444444705555555507666666666777777777705555555
55555550aaaaaaaa5555555555555555555555555555555555555555555555550000000005555550444444444705555555507666666666777777777705555555
55555550aaaaaaaa5555555555555555555555555555555555555555555555550000000005555550444444444705555555507666666666777777777705555555
55555550aaaaaaaa5555555555555555555555555555555555555555555555550000000005555550444444444705555555507666666666777777777705555555
55555550aaaaaaaa5555555555555555555555555555555555555555555555550000000005555550444444444705555555507666666666777777777705555555
55555550aaaaaaaa5555555555555555555555555555555555555555555555550000000005555550444444444705555555507666666666777777777705555555
55555550aaaaaaaa55555555aaaaaaaaaaaaaaaaaaaaaaaa00000000000000000000000005555550444444444705555555507666666666777777777705555555
55555550aaaaaaaa55555555aaaaaaaaaaaaaaaaaaaaaaaa00000000000000000000000005555550444444444700000000007666666666777777777705555555
55555550aaaaaaaa55555555aaaaaaaaaaaaaaaaaaaaaaaa00000000000000000000000005555550888888888777777777777aaaaaaaaabbbbbbbbbb05555555
55555550aaaaaaaa55555555aaaaaaaaaaaaaaaaaaaaaaaa0000000000000000000000000555555088888888889999999999aaaaaaaaaabbbbbbbbbb05555555
55555550aaaaaaaa55555555aaaaaaaaaaaaaaaaaaaaaaaa0000000000000000000000000555555088888888889999999999aaaaaaaaaabbbbbbbbbb05555555
55555550aaaaaaaa55555555aaaaaaaaaaaaaaaaaaaaaaaa0000000000000000000000000555555088888888889999999999aaaaaaaaaabbbbbbbbbb05555555
55555550aaaaaaaa55555555aaaaaaaaaaaaaaaaaaaaaaaa0000000000000000000000000555555088888888889999999999aaaaaaaaaabbbbbbbbbb05555555
55555550aaaaaaaa55555555aaaaaaaaaaaaaaaaaaaaaaaa0000000000000000000000000555555088888888889999999999aaaaaaaaaabbbbbbbbbb05555555
55555550aaaaaaaa55555555aaaaaaaa00000000000000000000000000000000000000000555555088888888889999999999aaaaaaaaaabbbbbbbbbb05555555
55555550aaaaaaaa55555555aaaaaaaa00000000000000000000000000000000000000000555555088888888889999999999aaaaaaaaaabbbbbbbbbb05555555
55555550aaaaaaaa55555555aaaaaaaa00000000000000000000000000000000000000000555555088888888889999999999aaaaaaaaaabbbbbbbbbb05555555
55555550aaaaaaaa55555555aaaaaaaa000000000000000000000000000000000000000005555550ccccccccccddddddddddeeeeeeeeeeffffffffff05555555
55555550aaaaaaaa55555555aaaaaaaa000000000000000000000000000000000000000005555550ccccccccccddddddddddeeeeeeeeeeffffffffff05555555
55555550aaaaaaaa55555555aaaaaaaa000000000000000000000000000000000000000005555550ccccccccccddddddddddeeeeeeeeeeffffffffff05555555
55555550aaaaaaaa55555555aaaaaaaa000000000000000000000000000000000000000005555550ccccccccccddddddddddeeeeeeeeeeffffffffff05555555
55555550aaaaaaaa55555555aaaaaaaa000000000000000000000000000000000000000005555550ccccccccccddddddddddeeeeeeeeeeffffffffff05555555
55555550aaaaaaaa55555555aaaaaaaa000000000000000000000000000000000000000005555550ccccccccccddddddddddeeeeeeeeeeffffffffff05555555
55555550aaaaaaaa55555555aaaaaaaa000000000000000000000000000000000000000005555550ccccccccccddddddddddeeeeeeeeeeffffffffff05555555
55555550aaaaaaaa55555551aaaaaaaa000000000000000000000000000000000000000005555550ccccccccccddddddddddeeeeeeeeeeffffffffff05555555
55555550aaaaaaaa555555171aaaaaaa000000000000000000000000000000000000000005555550ccccccccccddddddddddeeeeeeeeeeffffffffff05555555
55555550aaaaaaaa55555155a1aaaaaa000000000000000000000000000000000000000005555550000000000000000000000000000000000000000005555555
55555550aaaaaaaa55551755a71aaaaa000000000000000000000000000000000000000005555555555555555555555555555555555555555555555555555555
55555550aaaaaaaa55555155a1aaaaaa000000000000000000000000000000000000000005555555555555555555555555555555555555555555555555555555
55555550aaaaaaaa555555171aaaaaaa000000000000000000000000000000000000000005555555555555555555555555555555555555555555555555555555
55555550aaaaaaaa5555555100000000000000000000000000000000000000000000000005555550000000555556667655555555555555555555555555555555
55555550aaaaaaaa5555555500000000000000000000000000000000000000000000000005555550000000555555666555555555555555555555555555555555
55555550aaaaaaaa555555550000000000000000000000000000000000000000000000000555555000000055555556dddddddddddddddddddddddd5555555555
55555550aaaaaaaa55555555000000000000000000000000000000000000000000000000055555500050005555555655555555555555555555555d5555555555
55555550aaaaaaaa5555555500000000000000000000000000000000000000000000000005555550000000555555576666666d6666666d666666655555555555
55555550aaaaaaaa5555555500000000000000000000000000000000000000000000000005555550000000555555555555555555555555555555555555555555
55555550aaaaaaaa5555555500000000000000000000000000000000000000000000000005555550000000555555555555555555555555555555555555555555
55555550aaaaaaaa5555555500000000000000000000000000000000000000000000000005555555555555555555555555555555555555555555555555555555
55555550aaaaaaaa5555555500000000000000000000000000000000000000000000000005555555555555555555555555555555555555555555555555555555
55555550aaaaaaaa5555555500000000000000000000000000000000000000000000000005555556665666555556667655555555555555555555555555555555
55555550aaaaaaaa5555555500000000000000000000000000000000000000000000000005555556555556555555666555555555555555555555555555555555
55555550aaaaaaaa555555550000000000000000000000000000000000000000000000000555555555555555555556dddddddddddddddddddddddd5555555555
55555550aaaaaaaa55555555000000000000000000000000000000000000000000000000055555565555565555555655555555555555555555555d5555555555
55555550aaaaaaaa5555555500000000000000000000000000000000000000000000000005555556665666555555576666666d6666666d666666655555555555
55555550aaaaaaaa5555555500000000000000000000000000000000000000000000000005555555555555555555555555555555555555555555555555555555
55555550aaaaaaaa5555555500000000000000000000000000000000000000000000000005555555555555555555555555555555555555555555555555555555
55555550aaaaaaaa0000000000000000000000000000000000000000000000000000000005555555555555555555555555555555555555555555555555555555
55555550aaaaaaaa0000000000000000000000000000000000000000000000000000000005555555555555555555555555555555555555555555555555555555
55555550aaaaaaaa0000000000000000000000000000000000000000000000000000000005555550005550005550005550005550005550005550005550005555
55555550aaaaaaaa00000000000000000000000000000000000000000000000000000000055555011d05011d05011d05011d05011d05011d05011d05011d0555
55555550aaaaaaaa0000000000000000000000000000000000000000000000000000000005555501110501110501110501110501110501110501110501110555
55555550aaaaaaaa0000000000000000000000000000000000000000000000000000000005555501110501110501110501110501110501110501110501110555
55555550aaaaaaaa0000000000000000000000000000000000000000000000000000000005555550005550005550005550005550005550005550005550005555
55555550aaaaaaaa0000000000000000000000000000000000000000000000000000000005555555555555555555555555555555555555555555555555555555
55555550000000000000000000000000000000000000000000000000000000000000000005555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
5555555555555555555555555555555555555555555555555555555555555555555555aaaaaaaa55555555555555555555555555555555555555555555555555
55555555555555555555555557555555ddd5555d5d5d5d5555d5d55555555d55555555a555555056666666666666555555555555577777555555555555555555
55555555555555555555555577755555ddd555555555555555d5d5d5555555d5555555a5aaa00056ddd6d666d6d655555666665577dd77755666665556666655
55555555555555555555555777775555ddd5555d55555d5555d5d5d55555555d555555a5a0000056d6d6d666d6d6555566ddd665777d777566ddd66566ddd665
55555555555555555555557777755555ddd555555555555555ddddd555ddddddd55555a5a0000056d6d6ddd6ddd6555566d6d665777d77756666d665666dd665
555555555555555555555757775555ddddddd55d55555d55d5ddddd55d5ddddd555555a500000056d6d6d6d666d6555566d6d66577ddd77566d666656666d665
555555555555555555555755755555d55555d555555555555dddddd55d55ddd5555555a500000056ddd6ddd666d6555566ddd6657777777566ddd66566ddd665
555555555555555555555777555555ddddddd55d5d5d5d55555ddd555d555d55555555a000000056666666666666555566666665777777756666666566666665
555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555ddddddd566666665ddddddd5ddddddd5
77777777700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
aaaaaaaa70aaaaaa0000000aa0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
a55555507099999a0000000aa0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
a5aaa000700aaa9a0000000aa0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
a5a0000070000a9a00000a0aa0a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
a5a0000070000a9a00000a0aa0a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
a50000007000009a000aaa0aa0aaa000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
a50000007000000a0000000aa0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
a00000007000000aaaaaaaaaaaaaaaaa000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
77777777700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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

