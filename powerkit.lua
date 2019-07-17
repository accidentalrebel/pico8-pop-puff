function fflr(num)
   return flr(num*100)/100
end

function fceil(num)
   return ceil(num*100)/100
end

function assert(cond,message)
   if not cond then
      rbl_error(message)
   end
end

function log(message)
   printh(message)
end

function error(message)
   printh(">>>>>>> ERROR: "..message)
end

function split_string(s,sep)
   ret = {}
   bffr=""
   for i=1, #s do
      if (sub(s,i,i)==sep)then
	 add(ret,bffr)
	 bffr=""
      else
	 bffr = bffr..sub(s,i,i)
      end
   end
   if bffr ~= "" then
      add(ret,bffr)
   end
   return ret
end

function get_table_index(t,k)
   for i=1, #t do
      if t[i] == k then
	 return i
      end
   end
   return nil
end
