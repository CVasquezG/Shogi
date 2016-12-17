#=
Helper functions
=#
tracePrints = true
tracePrintKeys = Dict([("ControlFlow", true), ("Example2", false), ("legal", false)])

#Only prints while tracePrints == true, or tracePrintKeys["Key"] == true
function tracePrint(input)
  if tracePrints
    println(input)
  end
end

function tracePrint(input, key::AbstractString)
  if tracePrints && tracePrintKeys[key]
    println(input)
  end
end
