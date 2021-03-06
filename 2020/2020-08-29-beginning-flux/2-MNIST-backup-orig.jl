using Pkg
Pkg.activate("flux-tutorial")

using Flux

using Flux, Statistics
using Flux.Data: DataLoader
using Flux: onehotbatch, onecold, logitcrossentropy, throttle, @epochs
using Base.Iterators: repeated
using Parameters: @with_kw
using CUDA
using MLDatasets

if has_cuda()		# Check if CUDA is available
    @info "CUDA is on"
    CUDA.allowscalar(false)
end

@with_kw mutable struct Args
    η::Float64 = 3e-4       # learning rate
    batchsize::Int = 1024   # batch size
    epochs::Int = 10        # number of epochs
    device::Function = gpu  # set as gpu, if gpu available
end

xtrain, ytrain = MLDatasets.MNIST.traindata(Float32)

using Images: Gray

xtrain[:, :, 1] .|> Gray
ytrain[1]

xtrain[:, :, 1] |> transpose .|> Gray
ytrain[1]

xtrain[:, :, 2] |> transpose .|> Gray
ytrain[2]


args = (batchsize=128, )

function getdata(args)
    # Loading Dataset
    xtrain, ytrain = MLDatasets.MNIST.traindata(Float32)
    xtest, ytest = MLDatasets.MNIST.testdata(Float32)

    # Reshape Data in order to flatten each image into a linear array
    xtrain = Flux.flatten(xtrain) |> gpu
    xtest = Flux.flatten(xtest) |> gpu

    # One-hot-encode the labels
    ytrain, ytest = onehotbatch(ytrain, 0:9) |> collect .|> Float32 |> gpu,
                    onehotbatch(ytest, 0:9) |> collect .|> Float32 |> gpu

    # Batching
    train_data = DataLoader(xtrain, ytrain, batchsize=args.batchsize, shuffle=true)
    test_data = DataLoader(xtest, ytest, batchsize=args.batchsize)

    return train_data, test_data
end

model = Chain(
    Dense(28*28, 32, relu),
    Dense(32, 10))

loss(x,y) = logitcrossentropy(model(x), y)


p = params(model)

Flux.train!(loss, p, train_data, opt, cb = evalcb)

iterate(train_data)


function build_model(; imgsize=(28,28,1), nclasses=10)
    return Chain(
 	    Dense(prod(imgsize), 32, relu),
            Dense(32, nclasses))
end

function loss_all(dataloader, model)
    l = 0f0
    for (x,y) in dataloader
        l += logitcrossentropy(model(x), y)
    end
    l/length(dataloader)
end

function accuracy(data_loader, model)
    acc = 0
    for (x,y) in data_loader
        acc += sum(onecold(cpu(model(x))) .== onecold(cpu(y)))*1 / size(x,2)
    end
    acc/length(data_loader)
end

function train(; kws...)
    # Initializing Model parameters
    args = Args(; kws...)

    # Load Data
    train_data,test_data = getdata(args)

    # Construct model
    m = build_model()
    # train_data = args.device.(train_data)
    # test_data = args.device.(test_data)
    # m = args.device(m)
    loss(x,y) = logitcrossentropy(m(x), y)

    ## Training
    evalcb = () -> @show(loss_all(train_data, m))
    opt = ADAM(args.η)

    @epochs args.epochs Flux.train!(loss, params(m), train_data, opt, cb = evalcb)

    @show accuracy(train_data, m)

    @show accuracy(test_data, m)
end

cd(@__DIR__)
train()