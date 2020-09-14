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

BATCHSIZE=512

opt = ADAM()

# Loading Dataset
xtrain, ytrain = MLDatasets.MNIST.traindata(Float32)
xtest, ytest = MLDatasets.MNIST.testdata(Float32)

# Reshape Data in order to flatten each image into a linear array
xtrain = xtrain |> gpu
xtest = xtest |> gpu

# model = Chain(
#     x->reshape(x, 28, 28, 1, :),
#     Conv((5,5), 1=>6, relu),
#     MaxPool((2, 2)),
#     Conv((5, 5), 6=>16, relu),
#     MaxPool((2, 2)),
#     x -> reshape(x, :, size(x, 4)),
#     Dense(256, 128, relu),
#     Dense(128, 64, relu),
#     Dense(64, 10)
# ) |> gpu

# model = Chain(
#     x->reshape(x, 28, 28, 1, :),
#     Conv((5,5), 1=>20, relu),
#     Dropout(0.5),
#     Conv((5, 5), 20=>50, relu),
#     x -> reshape(x, :, size(x, 4)),
#     Dropout(0.5),
#     Dense(20_000, 500, relu),
#     Dropout(0.5),
#     Dense(500, 10)
# ) |> gpu

# model = Chain(
#     #x->reshape(x, 28, 28, 1, :),
#     Flux.flatten,
#     Dense(28*28, 128, relu),
#     # Dropout(0.5),
#     Dense(128, 10),
# ) |> gpu

model = Chain(
    x->reshape(x, 28, 28, 1, :),
    Conv((5,5), 1=>8; stride = 2, pad = 1),
    BatchNorm(8, relu),
    Conv((3,3), 8=>16; stride = 2, pad = 1),
    BatchNorm(16, relu),
    Conv((3,3), 16=>32; stride = 2, pad = 1),
    BatchNorm(32, relu),
    Conv((3,3), 32=>64; stride = 2, pad = 1),
    BatchNorm(64, relu),
    Conv((3,3), 64=>10; stride = 2, pad = 1),
    BatchNorm(10),
    Flux.flatten
) |> gpu


@time model(xtrain[:, :,  1:2])

#@time model(xtrain);

# One-hot-encode the labels
ytrain_onehot = onehotbatch(ytrain, 0:9) |> collect .|> Float32 |> gpu
# ytest_onehot = onehotbatch(ytrain, 0:9) |> collect .|> Float32 |> gpu

# define
loss(x,y) = logitcrossentropy(model(x), y)

p = params(model)



train_dataloader = DataLoader(xtrain, ytrain_onehot, batchsize=BATCHSIZE, shuffle=true)


function accuracy(x, y)
    predictions = model(x) |> softmax |> collect |> onecold .|> x->x-1
    mean(predictions .== y)
end

function train_until_no_improvement(epochs=8)
    pcopy, re = Flux.destructure(model)
    pcopy = pcopy |> collect |> copy

    has_not_improved_count = 0
    cnt  = 0
    prev_accurray = accuracy(xtest, ytest)

    while (cnt < epochs) || (has_not_improved_count < 8)
        cnt += 1
        Flux.train!(loss, p, train_dataloader, opt)
        new_accurray = accuracy(xtest, ytest)

        # if cnt ÷ 10 == 0
            println("accuracy (test set): $new_accurray")
        # end

        if prev_accurray < new_accurray
            prev_accurray = new_accurray
            pcopy, re = Flux.destructure(model)
            pcopy = pcopy |> collect |> copy
        else
            has_not_improved_count += 1
        end
    end
    re(pcopy)
end

@time best_model = train_until_no_improvement()

model = best_model |> gpu

accuracy(xtrain, ytrain), accuracy(xtest, ytest)


xtest_wrong = xtest[:,:, findall(model(xtest) |>  softmax |> collect |> onecold |> x->x.-1 .!= ytest)]

using Images

xtest_wrong = cpu(xtest_wrong)

Gray.(xtest_wrong[:, :, 10]) |> transpose

# for i in 1:size(xtest_wrong,3)
#     print(Gray.(xtest_wrong[:,:, i]))
# end



