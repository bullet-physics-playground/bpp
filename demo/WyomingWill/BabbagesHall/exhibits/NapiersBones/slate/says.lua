-- the slate's steps, in words (made by make-slate.py)
return {
  ["lay"] = { "The rods for the number, laid on the board", "each turned to show its digit, the first beside the index" },
  ["row"] = { "Read the row beside the index's digit", "each rod's cell: its tens above the diagonal, its units below" },
  ["diag"] = { "Add along each diagonal, from the right", "a units digit and the next rod's tens; carry any ten left" },
  ["next"] = { "The multiplier's next digit: its row", "a place further left than the row before" },
  ["add"] = { "Add the rows up", "each row moved a place left of the one after it" },
  ["grow"] = { "The row's top number on the last rod", "the carry into the last place is always 0" },
  ["gfollow"] = { "Follow each triangle to the next rod", "it points at the number the carry selects; no adding" },
  ["gone"] = { "Times 1: the number itself", "Genaille's rods have no row for 1" },
  ["clear"] = { "The rods back in their tray", "turned back to their first faces" },
  ["cannot"] = { "The set can't lay this number", "it needs one digit on more rods than carry it" },
}
