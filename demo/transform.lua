module("transform", package.seeall);

function move(o, v)
   trans1 = btTransform(btQuaternion(0,0,0,1), v)
   trans2 = o.trans
   trans2:mult(trans1, trans2)
   o.trans = trans2
end

function rotate(o, q, v)
   trans1 = btTransform(q, v)
   trans2 = o.trans
   trans2:mult(trans1, trans2)
   o.trans = trans2
end
