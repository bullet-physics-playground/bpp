printf = function(s,...) print(s:format(...)) end 

info = function(c)
  printf("Attributes")

  for k, f in pairs(class_info(c).attributes) do
    printf(" - %s %s", f, class_info(c[f]).name)
  end

  printf("Methods")

  for k, f in pairs(class_info(c).methods) do
    printf(" - %s", k)
  end
end

classes = function()
  printf("Registered classes:")
  for i, f in ipairs(class_names()) do
    printf(" - %s", f)
  end
end

printf("Hello from %s!\n", _VERSION)

-- lists all available classes
-- classes()

-- print attributes of class v
info(v)