# Windows:
# set JULIA_NUM_THREADS=4

# Linux:
# export JULIA_NUM_THREADS=4

using Random

Threads.nthreads()

Threads.@threads for i in 1:10
    println("i = $i on thread $(Threads.threadid())")
end

Threads.@threads for i in 1:10
    println(Threads.threadid()=>pointer_from_objref(Random.default_rng()))
end

function fib1(n)
    if n < 2
        return n
    end
    return fib1(n - 1) + fib1(n - 2)
end

function fib2(n)
    if n < 2
        return n
    end
    t = Threads.@spawn fib2(n - 2)
    return fib2(n - 1) + fetch(t)
end

function fib3(n, cutoff)
    if n < cutoff
        return fib1(n)
    end
    t = Threads.@spawn fib3(n - 2, cutoff)
    return fib3(n - 1, cutoff) + fetch(t)
end

fib1(31)
fib2(31)
fib3(31, 28)

@time fib1(31)
@time fib2(31)
@time fib3(31, 28)

@time fib1(43)
@time fib3(43, 40)

function f_bad(n)
    x = 0
    Threads.@threads for i in 1:n
        x += rand() < 0.5
    end
    x / n
end

function f_good_slow1(n)
    r = ReentrantLock()
    x = 0
    Threads.@threads for i in 1:n
        lock(r)
        x += rand() < 0.5
        unlock(r)
    end
    x / n
end

function f_good_slow2(n)
    x = Threads.Atomic{Int}(0)
    Threads.@threads for i in 1:n
        Threads.atomic_add!(x, Int(rand() < 0.5))
    end
    x[] / n
end

function f_good_slow3(n)
    x = zeros(Int, Threads.nthreads())
    Threads.@threads for i in 1:n
        @inbounds x[Threads.threadid()] += rand() < 0.5
    end
    sum(x) / n
end

function f_good_slow4(n)
    x = zeros(Int, 4*Threads.nthreads())
    Threads.@threads for i in 1:n
        @inbounds x[4*Threads.threadid()] += rand() < 0.5
    end
    sum(x) / n
end

function f_good_fast1(n)
    nt = Threads.nthreads()
    x = zeros(Int, nt)
    Threads.@threads for i in 1:nt
        tid = Threads.threadid()
        v = 0
        for j in 1:(div(n, nt) + (tid <= mod(n, nt)))
            v += rand() < 0.5
        end
        x[tid] = v
    end
    sum(x) / n
end

function f_good_fast2(n)
    nt = Threads.nthreads()
    x = 0
    r = ReentrantLock()
    Threads.@threads for i in 1:nt
        tid = Threads.threadid()
        v = 0
        for j in 1:(div(n, nt) + (tid <= mod(n, nt)))
            v += rand() < 0.5
        end
        lock(r)
        x += v
        unlock(r)
    end
    x / n
end

f_bad(10^8)
f_good_slow1(10^6)
f_good_slow2(10^8)
f_good_slow3(10^8)
f_good_slow4(10^8)
f_good_fast1(10^8)
f_good_fast2(10^8)


@time f_bad(10^8)
@time f_good_slow1(10^6)
@time f_good_slow2(10^8)
@time f_good_slow3(10^8)
@time f_good_slow4(10^8)
@time f_good_fast1(10^8)
@time f_good_fast2(10^8)
