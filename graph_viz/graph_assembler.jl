include("node_macros.jl")
using MetaGraphs, Graphs, Bijections

# function create_graph(g, node::sym_node, i)
#     add_vertices!(g, i)
#     set_props!(g, i, Dict(:name => node.name, :type => typeof(node)))
#     return 1
# end


function map_vertices(g, node_registry)
    vertex_map = Dict{base_node,Int}()
    # 
    node_names = keys(node_registry) |> collect
    add_vertices!(g, length(node_names))

    vertex_map = Bijection(Dict{base_node,Int}(node_registry[node_names[i]] => i for i in 1:length(node_names)))

    i = length(node_names)
    for node_name in node_names
        node = node_registry[node_name]
        fnode = from(node) |> first
        if fnode === nothing
            continue
        end
        if !(fnode in keys(vertex_map))
            i += 1
            vertex_map[fnode] = i
            add_vertex!(g)
        end
    end
    vertex_map
end

function map_edges(g, vertex_map)
    for v in keys(vertex_map)
        for n in from(v)
            if n === nothing
                continue
            end
            add_edge!(g, vertex_map[n], vertex_map[v])
        end
    end
end

get_vertex_name(i) = replace(String(vertex_map(i).name), "_" => " ")

function make_graph()
    g = MetaDiGraph(SimpleGraph(), 1)
    vertex_map = map_vertices(g, node_registry)
    map_edges(g, vertex_map)
    return g, vertex_map
end


