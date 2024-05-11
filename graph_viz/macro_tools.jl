function get_func(expr :: Expr)
    println(get_name(expr))
end

function get_name(expr :: Expr)
    if expr.head == :(.)
        return get_name(expr.args[1])
    end
    return String(expr.args[1])
end

function get_name(sym :: Symbol)
    return sym
end

function get_name(str :: String)
    return Symbol(str)
end

!macro test(expr :: Expr)
    # if expr isa Expr
        # if expr.head == :call
            # get_func(expr)
        # end
    # end
    println(expr.args[1].args[1])
end

@test Hee.foo(x)