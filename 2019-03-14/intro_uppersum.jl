function uppersum(M)
    n = size(M, 1)
    s = zero(eltype(M))
    for i in 2:n
        @simd for j in 1:(i-1)
            @inbounds s += M[j, i]
        end
    end
    s
end

@time m = randn(10_000, 10_000);
m
@time sum(m)
@time uppersum(M)
