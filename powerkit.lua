function rbl_fflr(num)
   return flr(num*100)/100
end

function rbl_fceil(num)
   return ceil(num*100)/100
end

function rbl_assert(cond,message)
   if not cond then
      rbl_error(message)
   end
end

function rbl_error(message)
   printh(">>>>>>> ERROR: "..message)
end
