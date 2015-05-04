
#-------------------------------------------------------# Type and Constructors
type Variance{W<:Weighting} <: OnlineStat
    μ::Float64
    biasedvar::Float64    # BIASED variance (makes for easier update)
    n::Int64
    weighting::W
end


function Variance{T <: Real}(y::Vector{T}, wgt::Weighting = default(Weighting))
    o = Variance(wgt)
    update!(o, y)  # apply the weighting scheme, as opposed to initializing with classic variance
    o
end

Variance(y::Float64, wgt::Weighting = default(Weighting)) = Variance([y], wgt)
Variance(wgt::Weighting = default(Weighting)) = Variance(0., 0., 0, wgt)


#-----------------------------------------------------------------------# state

statenames(o::Variance) = [:μ, :σ², :nobs]
state(o::Variance) = Any[mean(o), var(o), nobs(o)]

Base.mean(o::Variance) = o.μ
Base.var(o::Variance) = (n = nobs(o); (n < 2 ? 0. : o.biasedvar * n / (n - 1)))
Base.std(o::Variance) = sqrt(var(o))

#-----------------------------------------------------------------------# normalize

if0then1(x::Float64) = (x == 0. ? 1. : x)

normalize(o::Variance, y::Float64) = (y - mean(o)) / if0then1(std(o))
denormalize(o::Variance, y::Float64) = y * std(o) + mean(o)

function normalize!(o::Variance, y::Float64)
    update!(o, y)
    normalize(o, y)
end

normalize!(os::Vector{Variance}, y::VecF) = map(normalize!, os, y)

#---------------------------------------------------------------------# update!


function update!(o::Variance, y::Float64)
    λ = weight(o)
    μ = mean(o)

    o.μ = smooth(μ, y, λ)
    o.biasedvar = smooth(o.biasedvar, (y - μ) * (y - mean(o)), λ)
    o.n += 1
    return
end

# Base.copy(o::Variance) = Variance(o.μ, o.biasedvar, o.n, o.weighting)

# NOTE:
function Base.empty!(o::Variance)
    o.μ = 0.
    o.biasedvar = 0.
    o.n = 0
    return
end

function Base.merge!(o1::Variance, o2::Variance)
    λ = mergeweight(o1, o2)
    o1.μ = smooth(o1.μ, o2.μ, λ)
    o1.biasedvar = smooth(o1.biasedvar, o2.biasedvar, λ)
    o1.n += nobs(o2)
    o1
end



