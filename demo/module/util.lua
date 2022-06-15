--
-- assorted helper functions
--
-- feel free to add your own.
--

module("utils", package.seeall);

function string.starts(String,Start)
 return string.sub(String,1,string.len(Start))==Start
end

function string.ends(String,End)
 return End=='' or string.sub(String,-string.len(End))==End
end

function string.cutbegin(String, Start)
 return string.sub(String,Start, string.len(String))
end

