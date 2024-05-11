ENV["JULIA_CONDAPKG_BACKEND"] = "Null"
ENV["JULIA_PYTHONCALL_EXE"] = "transformers_env/Scripts/python.exe"  # optional
# ENV["JULIA_PYTHONCALL_EXE"] = "@PyCall"  # optional
using PythonCall
using SimilaritySearch
using HTTP
using URIs
using JSON
using Pandoc
using WordTokenizers
using Arrow

include("array_tools.jl")

llama = pyimport("llama_cpp")

uri = URI("https://en.wikipedia.org/wiki/Oxygen")
response = HTTP.get(uri)
body = String(response.body)
c = Pandoc.Converter(input = body)
c.from = "html"
c.to ="plain"
resp = run(c)
resp |> dump("resp.txt")

# inputs = filter(!=(""), map(strip, split_sentences(resp)))
embedding_model = llama.Llama(model_path="embedding_models/bge-base-en-v1.5.Q8_0.gguf", embedding=true)

function recursive_chunker(text, chunk_size, overlap)
    return [rev_detokenize(
                    text[
                        max(1, i-overlap):min(i + chunk_size, length(text))
                    ] .|> String,
                )
            for i in 1:chunk_size:length(text)
        ]
end

function tokenize_text(text)
    return Iterators.flatten(rev_tokenize.(filter(x -> length(strip(x)) != 0, split_sentences(text)))) |> collect
end


function embed(inputs)
    pyconvert(Vector{Vector{Float32}}, map(x -> x["embedding"], embedding_model.create_embedding(inputs |> pylist)["data"]))
end


inputs = recursive_chunker(tokenize_text(resp), 500, 100)
embeds = embed(inputs)
embed_mat = embeds / hcat

sizeof(embed_mat) .- reduce((+), sizeof(input) for input in inputs) + sizeof(inputs)

vdb = DynamicMatrixDatabase(Float32, 768)
append_items!(vdb, MatrixDatabase(embed_mat))
dist = AngleDistance()
G = SearchGraph(;dist, db = vdb)
index!(G)


topk = KnnResult(30)
search(G, embed(["Who Isolated Oxygen?"])[1], topk)
top_resp = [inputs[x.id] for x in topk.items]

ce_query = [("Who Isolated Oxygen?", x) for x in top_resp]
sentence_transformers = pyimport("sentence_transformers")
CrossEncoder = sentence_transformers.CrossEncoder
ce_model = CrossEncoder("cross-encoder/ms-marco-TinyBERT-L-2-v2")
scores = ce_model.predict(ce_query)

ce_top_resp = top_resp[sortperm(pyconvert(Vector{Float32}, scores), rev=true)[1:3]]

context_query = join(ce_top_resp, "\n")

chat_model = llama.Llama(model_path="chat_model/Phi-3-mini-4k-instruct-q4.gguf", n_ctx=1000)

output = chat_model(
      """<|system> Give a brief answer to the users question (singular) from the context, if you cannot answer the question with the given context say that you cannot answer the question with the given context. Do not generate any further text after answering the question" <|end> <|user|> \n Who Isolated Oxygen? <|end|> <|context> $(context_query)
       <|end> \n <|assistant|> """, # Prompt
      max_tokens=200, # Generate up to 32 tokens, set to None to generate up to the end of the context window
      stop=["<|end>", "\n", "<|system>"])

println(output["choices"][0]["text"])

GC.gc(false)

