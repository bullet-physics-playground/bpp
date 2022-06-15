--
-- Print Lua classes
--

printf = function(s,...) print(s:format(...)) end 
printf("Hello from %s!\n", _VERSION)

info = function(c)
  printf("%s", c)

  printf("  * properties")
  for k, f in pairs(class_info(c).attributes) do
    printf("   * %s %s", f, class_info(c[f]).name)
  end

  printf("  * functions")
  for k, f in pairs(class_info(c).methods) do
    printf("   * %s", k)
  end
end

classes = function()
  printf("Registered classes:")
  for i, f in ipairs(class_names()) do
    printf(" * %s", f)
  end
end

--- lists all available classes
classes()

--- print attributes of class v
info(v)
