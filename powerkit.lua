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

function error(message)
   printh(">>>>>>> ERROR: "..message)
end
