using Pkg
Pkg.activate("flux-tutorial")

using Flux
using Flux.Optimise: Descent

using Statistics
using Flux.Data: DataLoader
using Flux: onehotbatch, onecold, logitcrossentropy, throttle, @epochs
using Base.Iterators: repeated
using CUDA
using MLDatasets

# Check if CUDA is available
if has_cuda()
    @info "CUDA is on"
    CUDA.allowscalar(false)
end

# Loading Dataset
xtrain, ytrain = MLDatasets.MNIST.traindata(Float32)
xtest, ytest = MLDatasets.MNIST.testdata(Float32)

# Reshape Data in order to flatten each image into a linear array
xtrain = xtrain |> gpu
xtest = xtest |> gpu


model = Chain(
    x->reshape(x, 28, 28, 1, :),
    Conv((5,5), 1=>20, relu),
    Conv((5,5), 20=>50, relu),
    Flux.flatten,
    Dense(20000, 500, relu),
    Dense(500, 10)
) |> gpu


model(xtrain[:, :,  1:1]);

# One-hot-encode the labels
ytrain_onehot = onehotbatch(ytrain, 0:9) |> collect .|> Float32 |> gpu
ytest_onehot = onehotbatch(ytrain, 0:9) |> collect .|> Float32 |> gpu

# define
loss(x,y) = logitcrossentropy(model(x), y)

p = params(model)

opt = ADAM()

function accuracy(x, y)
    predictions = model(x) |> softmax |> collect |> onecold .|> x->x-1
    mean(predictions .== y)
end

function train_until_no_improvement()
    pcopy, re = Flux.destructure(model)
    pcopy = pcopy |> collect |> copy

    has_not_improved_count = 0
    cnt  = 0
    prev_accurray = accuracy(xtest, ytest)

    while has_not_improved_count < 100
        cnt += 1
        Flux.train!(loss, p, [(xtrain, ytrain_onehot)], opt)
        new_accurray = accuracy(xtest, ytest)

        if cnt ÷ 1000 == 0
            println("accuracy (test set): $new_accurray")
        end

        if prev_accurray < new_accurray
            prev_accurray = new_accurray
            pcopy, re = Flux.destructure(model)
            pcopy = pcopy |> collect |> copy
        else
            has_not_improved_count += 1
        end
    end
    pcopy, re
end

@time best_p, re = train_until_no_improvement()

model = re(best_p) |> gpu


accuracy(xtrain, ytrain)

