function findRequiredIdxs(A::LagrangeInterpolation, t)
    idxs = sortperm(A.t, by = x -> abs(t - x))
    idxs[1:(A.n + 1)]
end

function spline_coefficients(n, d, k, u::Number)
    N = zeros(eltype(u), n)
    if u == k[1]
        N[1] = one(u)
    elseif u == k[end]
        N[end] = one(u)
    else
        i = findfirst(x -> x > u, k) - 1
        N[i] = one(u)
        for deg in 1:d
            N[i - deg] = (k[i + 1] - u) / (k[i + 1] - k[i - deg + 1]) * N[i - deg + 1]
            for j in (i - deg + 1):(i - 1)
                N[j] = (u - k[j]) / (k[j + deg] - k[j]) * N[j] +
                       (k[j + deg + 1] - u) / (k[j + deg + 1] - k[j + 1]) * N[j + 1]
            end
            N[i] = (u - k[i]) / (k[i + deg] - k[i]) * N[i]
        end
    end
    N
end

function spline_coefficients(n, d, k, u::AbstractVector)
    N = zeros(eltype(u), n, n)
    for i in 1:n
        N[i, :] .= spline_coefficients(n, d, k, u[i])
    end
    N
end

# helper function for data manipulation
function munge_data(u::AbstractVector{<:Real}, t::AbstractVector{<:Real}, safetycopy::Bool)
    if safetycopy
        u = copy(u)
        t = copy(t)
    end
    return readonly_wrap(u), readonly_wrap(t)
end

function munge_data(u::AbstractVector, t::AbstractVector, safetycopy::Bool)
    Tu = Base.nonmissingtype(eltype(u))
    Tt = Base.nonmissingtype(eltype(t))
    @assert length(t) == length(u)
    non_missing_indices = collect(i
    for i in 1:length(t)
    if !ismissing(u[i]) && !ismissing(t[i]))

    if safetycopy
        u = Tu.([u[i] for i in non_missing_indices])
        t = Tt.([t[i] for i in non_missing_indices])
    else
        !isempty(non_missing_indices) && throw(MustCopyError())
    end

    return readonly_wrap(u), readonly_wrap(t)
end

function munge_data(U::StridedMatrix, t::AbstractVector, safetycopy::Bool)
    TU = Base.nonmissingtype(eltype(U))
    Tt = Base.nonmissingtype(eltype(t))
    @assert length(t) == size(U, 2)
    non_missing_indices = collect(i
    for i in 1:length(t)
    if !any(ismissing, U[:, i]) && !ismissing(t[i]))

    if safetycopy
        U = hcat([TU.(U[:, i]) for i in non_missing_indices]...)
        t = Tt.([t[i] for i in non_missing_indices])
    else
        !isempty(non_missing_indices) && throw(MustCopyError())
    end

    return readonly_wrap(U), readonly_wrap(t)
end

# Don't nest ReadOnlyArrays
readonly_wrap(a::AbstractArray) = ReadOnlyArray(a)
readonly_wrap(a::ReadOnlyArray) = a
