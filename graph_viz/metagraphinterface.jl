include("graph_assembler.jl")
using GraphViz



g, vertex_map = make_graph()

function dotstr(g, vertex_map)
    res = """
    edge [fontname="FreeSans",fontsize="12",labelfontname="FreeSans",labelfontsize="10"];
    overlap = false;
    node [fontname="FreeSans",fontsize="14",shape=record,height=0.2];\n"""
    for i in 1:nv(g)
        res *= "V$(i) [label=\"$(get_vertex_name(i))\""
        if vertex_map(i) isa sym_node
            res *= ",style=filled,fillcolor=lightblue"
        else
            res *= ",style=filled,fillcolor=lightgreen"
        end
        res *= "]\n"
    end
    for e in edges(g)
        res *= "V$(src(e)) -> V$(dst(e)) "
        dn = vertex_map(dst(e))
        sn = vertex_map(src(e))
        if vertex_map(src(e)) isa sym_node
            if vertex_map(dst(e)) isa func_node
                if dn.globals !== nothing && sn.name in dn.globals
                    res *= "[color=red]"
                end
            end
        end
        res *= "\n"
    end
    res = """digraph graphname{
    $(res)}"""
end

function plot_graph(res, args...)
    GraphViz.Graph(res, args...)
end


function plot_graph()
    g, vertex_map = make_graph()
    res = dotstr(g, vertex_map)
    plot_graph(res)
end