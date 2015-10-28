using Distributions
using Base.LinAlg.BLAS
using Devectorize

import Base.getindex
# import StatsBase.fit

typealias Gaussian Normal

abstract AbstractRBM
@runonce type RBM{V,H} <: AbstractRBM
    W::Matrix{Float64}
    W2::Matrix{Float64}
    W3::Matrix{Float64}
    vbias::Vector{Float64}
    hbias::Vector{Float64}
    dW::Matrix{Float64}
    dW_prev::Matrix{Float64}
    persistent_chain_vis::Matrix{Float64}
    persistent_chain_hid::Matrix{Float64}
    momentum::Float64
    VisShape::Tuple{Int,Int}
end


function RBM(V::Type, H::Type,
             n_vis::Int, n_hid::Int,
             visshape::Tuple{Int,Int}; sigma=0.1, momentum=0.0, dataset=[])

    W = rand(Normal(0, sigma), (n_hid, n_vis))


    if isempty(dataset)
        RBM{V,H}(W,                                             # W
         W.*W,                              # W2
         W.*W.*W,                         # W3
                 zeros(n_vis),                                  # vbias
                 zeros(n_hid),                                  # hbias
                 zeros(n_hid, n_vis),                           # dW
                 zeros(n_hid, n_vis),                           # dW_prev
                 Array(Float64, 0, 0),                          # persistent_chain_vis
                 Array(Float64, 0, 0),                          # persistent_chain_hid
                 momentum,                                      # momentum
                 visshape)                                      # Shape of the visible units (for display)
    else
        ProbVis = mean(dataset,2)   # Mean across samples
        ProbVis = max(ProbVis,1e-8)
        ProbVis = min(ProbVis,1 - 1e-8)
        @devec InitVis = log(ProbVis ./ (1-ProbVis))

      RBM{V,H}(W,                                           # W
         W.*W,                              # W2
         W.*W.*W,                         # W3
                 vec(InitVis),                                  # vbias
                 zeros(n_hid),                                  # hbias
                 zeros(n_hid, n_vis),                           # dW
                 zeros(n_hid, n_vis),                           # dW_prev
                 Array(Float64, 0, 0),                          # persistent_chain_vis
                 Array(Float64, 0, 0),                          # persistent_chain_hid
                 momentum,                                      # momentum
                 visshape)                                      # Shape of the visible units (for display)
    end
end


function Base.show{V,H}(io::IO, rbm::RBM{V,H})
    n_vis = size(rbm.vbias, 1)
    n_hid = size(rbm.hbias, 1)
    print(io, "RBM{$V,$H}($n_vis, $n_hid)")
end


typealias BernoulliRBM RBM{Bernoulli, Bernoulli}
BernoulliRBM(n_vis::Int, n_hid::Int, visshape::Tuple{Int,Int}; sigma=0.1, momentum=0.0, dataset=[]) =
    RBM(Bernoulli, Bernoulli, n_vis, n_hid, visshape; sigma=sigma, momentum=momentum, dataset=dataset)
typealias GRBM RBM{Gaussian, Bernoulli}
GRBM(n_vis::Int, n_hid::Int, visshape::Tuple{Int,Int}; sigma=0.1, momentum=0.0, dataset=[]) =
    RBM(Gaussian, Bernoulli, n_vis, n_hid, visshape; sigma=sigma, momentum=momentum, dataset=dataset)


function hid_means(rbm::RBM, vis::Mat{Float64})
    p = rbm.W * vis .+ rbm.hbias
    return logsig(p)
end

function vis_means(rbm::RBM, hid::Mat{Float64})
    p = rbm.W' * hid .+ rbm.vbias
    return logsig(p)
end