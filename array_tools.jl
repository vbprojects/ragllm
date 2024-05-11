using Serialization

# File implements methods for fast prototyping for working with tensors and performing common operations
# I would recomend not using any of these functions in code that you want to share with others as they are not optimized for performance and hinder readability

# Iterate through a tensor along the given axis, returning a vector of the slices along that axis.
axis(x) = D -> [D[[k != x ? (:) : i for k in 1:length(size(D))]...] for i in axes(D, x)]
axis(D, x) = axis(x)(D)

# methods that reshape tensors
rs(x, y) = w -> reshape(w, (x, y)) # defined in this way so that 2 dimensions will not use variadic function call
rs(d...) = x -> reshape(x, d...)

# Taken from http://npaul.co/a/Operator_Flexibility_in_Julia.html

import Base./

# Meant to make working with reduce operations in arrays easier
"""
    /(l::AbstractArray{T}, f::Function) where {T}


/ is a function that takes a function and an array and applies the function to the array in a reduce operation 

/(l::AbstractArray{T}, f::Function) where {T} = foldr(f,l) 

/(l::Vector{T}, f::Function) where {T} = foldr(f,l) 

/(f::Function, l::AbstractArray{T}) where {T} = foldl(f,l)
"""
/(l::AbstractArray{T}, f::Function) where {T} = foldr(f,l) 
/(l::Vector{T}, f::Function) where {T} = foldr(f,l)
/(f::Function, l::AbstractArray{T}) where {T} = foldl(f,l)
import Base.∘

"""
    (∘)(l::AbstractArray{T,1}, o::AbstractArray{O,1}) where {T} where {O}


Composing on Arrays gives an array of all possible combinations of the elements in the arrays, useful for parameter search grids 

(∘)(l::AbstractArray{T,1}, o::AbstractArray{O,1}) where {T} where {O} = [[l[i] o[j]] for i in 1:length(l) for j in 1:length(o)]
"""
(∘)(l::AbstractArray{T,1}, o::AbstractArray{O,1}) where {T} where {O} = [[l[i] o[j]] for i in 1:length(l) for j in 1:length(o)]


import Base.vec

# Changes vec so that you don't need to use collect for ranges
vec(x :: AbstractRange) = Vector(x)

# can make turning floats into ints less of a pain
toint(x) = floor(x) |> Int

# Allows for getting slices from an array in pipe
function inds(arr)
  return (x -> arr[x])
end

"""
    ι(x :: Any)

Stores variable into global variable ANS, basically the same as ans in repl 

ι(x :: Any) 
"""
ι(x :: Any) = begin
  global ANS
  ANS = x
  return x
end

"""
    lι(v :: Any, w :: Any)

 Allows for storing a variable into local location 
 
lι(v :: Any, w :: Any)
"""
lι(v :: Any, w :: Any) = begin
  f = x -> begin
    v[w] = x
    return x
  end
  return f
end

"""
    at(i)

 Allows for array access in a pipe 

at(i) = x -> x[i]
"""
function at(i)
  return x -> x[i]
end

"""
    qfun(func, args)


qfun is a way of storing the results of a function calls into a file with arguments, results, and the function itself 
 
 

This method if for testing if the function works, it returns the results of the function call, useful when using do notation 

qfun(func, args) 
 
this method saves the results of qfun into a the file fname 

function qfun(func, args, fname) 
"""
function qfun(func, args)
  return func(args...)
end

# this method saves the results of qfun into a the file fname
function qfun(func, args, fname)
  res = func(args...)
  open(fname, "w+") do f
      serialize(fname, (args, res, func))
  end
  return res
end


# This method loads the results of qfun from a file
function qload(fname)
  open(fname, "r") do f
      (args, res, func) = deserialize(fname)
      return (args, res, func)
  end
end

"""
    ⋉(x, f :: Function)

Fixes an argument for a function, useful for making anonymous functions in pipe, ltimes and 
rtimes for the char 

⋉(x, f :: Function) = y -> f(x, y) 

⋊(x, f :: Function) = y -> f(y, x) 

⋉(x :: AbstractArray{T, 1}, f :: Function) where {T} = y -> f(x..., y...) 
 
⋊(x :: AbstractArray{T, 1}, f :: Function) where {T} = y -> f(y..., x...) 

"""
⋉(x, f :: Function) = y -> f(x, y)
⋊(x, f :: Function) = y -> f(y, x)
⋉(x :: AbstractArray{T, 1}, f :: Function) where {T} = y -> f(x..., y...)
⋊(x :: AbstractArray{T, 1}, f :: Function) where {T} = y -> f(y..., x...)

# sample n arrs from across some axis without replacement
# function sample(n, axis)
#   inds = rand(1:size(arrs, axis), n)
#   return arrs[inds]
# end 

dump(fn) = o -> begin
  open(fn, "w+") do io
    println(io, o)
  end
end

# func(x :: AbstractDict) = i -> x[i]

