
plan_flag = false

module nodes
    abstract type base_node end
    mutable struct func_node <: base_node
        name :: Symbol
        from :: Union{Vector{Symbol}, Nothing}
        to :: Union{Vector{Symbol}, Nothing}
        globals :: Union{Vector{Symbol}, Nothing}
    end
    func_node(func_name :: Symbol, args = nothing, outs = nothing, globals = nothing) = func_node(func_name, args, outs, globals)
    mutable struct sym_node <: base_node
        name :: Symbol
        from :: Union{func_node, Nothing}
        to :: Union{Vector{func_node}, Nothing}
    end
    sym_node(name :: Symbol, from = nothing, to = nothing) = sym_node(name, from, to)
    mutable struct const_node <: base_node
        name :: Symbol
        from :: Nothing
        to :: Union{Vector{func_node}, Nothing}
    end
    const_node(name :: Symbol, from = nothing, to = nothing) = const_node(name, from, to)
end

sym_node = nodes.sym_node
func_node = nodes.func_node
base_node = nodes.base_node

node_registry = Dict{Symbol, sym_node}()

function append_to(node :: sym_node, fnode :: func_node)
    if node.to === nothing
        node.to = Vector{func_node}([fnode])
    else
        push!(node.to, fnode)
    end
end

function tracker(expr :: Expr)

    global node_registry
    global plan_flag

    @assert expr.head == :(=)
    lhs = expr.args[1]
    rhs = expr.args[2]

    to_syms = nothing
    if(typeof(lhs) == Symbol)
        to_syms = Vector{Symbol}([lhs])
    elseif(lhs.head == :(tuple))
        to_syms = Vector{Symbol}([lhs.args...])
    end

    # println(lhs.head == :(tuple))

    @assert rhs.head == :(call)
    println(lhs)
    func_name = rhs.args[1]

    from_syms = nothing
    if(length(rhs.args) > 1)
        from_syms = Vector{Symbol}(rhs.args[2:end])
    end

    node = func_node(func_name)

    # node.globals = Vector{Symbol}(args)

    if from_syms !== nothing
        # from_nodes = Vector{sym_node}()
        for sym in from_syms
            @assert haskey(node_registry, sym)
            snode = node_registry[sym]
            append_to(snode, node)
            # push!(from_nodes, snode)
        end
        node.from = from_syms
    end
    # println(from_syms)
    if(to_syms !== nothing)
        for sym in to_syms
            if sym in keys(node_registry)
                tnode = node_registry[sym]
                tnode.from = node
            else
                tnode = sym_node(sym)
                node_registry[sym] = tnode
                tnode.from = node
            end
        end
        node.to = to_syms
    end
    # node_registry[func_name] = node
    return node
end

!macro track(expr :: Expr, args...)
    global plan_flag

    node = tracker(expr)
    globals = Vector{Symbol}()
    for arg in args
        @assert typeof(arg) == Symbol
        @assert haskey(node_registry, arg)
        push!(globals, arg)
    end

    node.globals = globals

    if(!plan_flag)
        return expr
    end
end

!macro track(expr :: Expr)
    node = tracker(expr)
    if(!plan_flag)
        return expr
    end
end

plan_flag = true

macro clear()
    global exprs
    global node_registry
    node_registry = Dict{Symbol, Union{sym_node, func_node}}()
    exprs = []
end


function from(node :: func_node)
    return map(x -> typeof(x) == Symbol ? node_registry[x] : x, filter(!isnothing, [node.from; node.globals]))
end

function from(node :: sym_node)
    return [node.from]
end

function from(node :: Symbol)
    return [from(node_registry[node])]
end

function from(node :: Nothing)
    return [nothing]
end

macro plan(flag :: Bool)
    global plan_flag
    plan_flag = flag
end
macro plan()
    global plan_flag
    return plan_flag
end

function register(expr)
    if expr isa Symbol
        if !(expr in keys(node_registry))
            node_registry[expr] = sym_node(expr)
        end
    elseif (expr.head == :(tuple))
        for sym in expr.args
            if sym isa Symbol && !(sym in keys(node_registry))
                node_registry[sym] = sym_node(sym)
            end
        end
    elseif !(expr isa Symbol) && expr.head == :(call)
        rhs = expr
        name = rhs.args[1]
        node = func_node(name)
        from_syms = nothing
        if (length(rhs.args) > 1)
            from_syms = Vector{Symbol}(rhs.args[2:end])
        end
        if from_syms !== nothing
            # from_nodes = Vector{sym_node}()
            for sym in from_syms
                @assert haskey(node_registry, sym)
                snode = node_registry[sym]
                append_to(snode, node)
                # push!(from_nodes, snode)
            end
            node.from = from_syms
        end
        return node
    end
end

!macro register(expr)
    register(expr)
end

!macro register(expr, args...)
    node = register(expr)
    if node isa func_node
        globals = Vector{Symbol}()
        for arg in args
            @assert typeof(arg) == Symbol
            @assert haskey(node_registry, arg)
            push!(globals, arg)
        end
        node.globals = globals
    end
end

