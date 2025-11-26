"""
    error_handling(s::String)

Esto es una prueba

# Examples
```julia-repl
julia> error("Archivo error_handling.jl")
Archivo error_handling.jl
```
"""
function error_handling(s::String)
    println(s)
    println("Tercer cambio")
end