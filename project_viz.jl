include("./graph_viz/metagraphinterface.jl")

begin
graph_str = """
digraph graphname{

    concentrate=true
    edge [fontname="FreeSans",fontsize="12",labelfontname="FreeSans",labelfontsize="10"];
    overlap = compress
    clusterrank= local
    layout = dot
    splines = ortho
    rank = same
    node [fontname="FreeSans",fontsize="14",shape=record,height=0.2]
    
    node[fillcolor=mediumaquamarine, style=filled]
    Documents
    Query

    node[fillcolor=violet, style=filled]
    ArrowStorage
    VectorDB

    node[fillcolor=lightgreen, style=filled, fillcolor=lightgreen]
    CrossEncoder
    ChatModel
    DBEmbeddingModel
    
    node[fillcolor=lightcyan, style=filled]
    VectorSearch
    QueryDBEmbedder
    Retriever
    DBEmbedder
    Chunker
    ChatFormatter
    CEQueryTopK
    CERanker
    Chat

    node[fillcolor=lightblue, style=filled]
    


    subgraph cluster_0{
        style=filled;
        color=aliceblue;

        ChatModel
        DBEmbeddingModel

        label = "LlamaCPP Interface"
    }

    subgraph cluster_1{
        style=filled;
        color=aquamarine;

        CrossEncoder
        label = "SentenceTransformer Interface"
    }

    subgraph cluster_2 {
        style=filled;
		color=darkseagreen;
        
        Documents
        Chunker
        Chunks
        ArrowStorage
        DBEmbedder
        DocumentEmbeddings
        VectorDB

        label = "Document Process"
    }

    subgraph cluster_3 {
        style=filled;
        color=powderblue;

        Query
        QueryDBEmbedder
        QueryEmbeddings
        VectorSearch
        DBTopKIndices
        Retriever
        DBTopKText

        label = "Query Process"
    }

    subgraph cluster_5{
        style=filled;
        color=lavender;

        CEQueryScores
        CEQueryTopK
        Context
        CERanker

        label = "Rerank Process"
    }

    subgraph cluster_6{
        style=filled;
        color=thistle;

        ChatFormatter
        ChatRequest
        Chat
        ChatResponse

        label = "Chat Process"
    }

    subgraph cluster_7{
        style=filled;
        color=salmon;

        ChunkSize
        Overlap
        documentsPath
        dbEmbeddingPath
        crossEncoderPath
        chatModelPath
        ArrowStoragePath

        label = "Config"
    }

    Documents -> Chunker -> Chunks -> ArrowStorage
    Chunks -> DBEmbedder -> DocumentEmbeddings -> VectorDB
    DBEmbeddingModel -> DBEmbedder

    ArrowStorage -> Retriever
    VectorDB -> VectorSearch

    Query -> QueryDBEmbedder -> QueryEmbeddings -> VectorSearch -> DBTopKIndices -> Retriever -> DBTopKText

    DBEmbeddingModel -> QueryDBEmbedder [constraint=false]

    DBTopKText -> CERanker -> CEQueryScores -> CEQueryTopK -> Context
    DBTopKText -> CEQueryTopK
    CrossEncoder -> CERanker
    Query -> CERanker

    ChatFormatter -> ChatRequest -> Chat -> ChatResponse
    Context -> ChatFormatter
    Query -> ChatFormatter

    ChunkSize -> Chunker
    Overlap -> Chunker
    documentsPath -> Documents
    dbEmbeddingPath -> DBEmbeddingModel
    crossEncoderPath -> CrossEncoder
    chatModelPath -> ChatModel 
    ArrowStoragePath -> ArrowStorage
    ChatModel -> Chat
    rankdir=TD

}
"""

GraphViz.Graph(graph_str) 
end