using Pkg
Pkg.activate("flux-tutorial")

using Flux

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

using Images: Gray

xtrain[:, :, 1] .|> Gray
ytrain[1]

xtrain[:, :, 1] |> transpose .|> Gray
ytrain[1]

xtrain[:, :, 2] |> transpose .|> Gray
ytrain[2]

model_cpu = Chain(
    Dense(28*28, 10)
)

model = model_cpu |> gpu

model_cpu = Chain(
    Dense(28*28, 10)
) |> gpu


# Reshape Data in order to flatten each image into a linear array
xtrain = Flux.flatten(xtrain) |> gpu
#xtest = Flux.flatten(xtest) |> gpu

# One-hot-encode the labels
ytrain_onehot = onehotbatch(ytrain, 0:9) |> collect .|> Float32 |> gpu

xtrain = Flux.flatten(xtrain) |> gpu

# using logitcrossentropy as a measure of loss
logitcrossentropy(model(xtrain), ytrain_onehot)

# define
loss(x,y) = logitcrossentropy(model(x), y)

# using logitcrossentropy
loss(xtrain, ytrain_onehot)

modelx = model(xtrain[:, 1])

ytrain[1]

ytrain_onehot[:, 1]

exp.(modelx) ./ sum(exp, modelx)

# Number of parameters is
# Number of Inputs * number of outputs = (28 * 28) * 10 + 10 = 7840

p = params(model)

@time g = gradient(() -> loss(xtrain, ytrain_onehot), p)


p[1] .= p[1] - 0.0001*g[p[1]]

p[1] .-= 0.0001*g[p[1]]

p[2] .-= 0.0001*g[p[2]]

# ?Flux.update!

using Flux.Optimise: Descent

opt = Descent()

Flux.update!(opt, p, g)



Flux.train!(loss, p, [(xtrain, ytrain_onehot)], opt)

modelx = model(xtrain[:, 1])
exp.(modelx) ./ sum(exp, modelx)


@time Flux.@epochs 10 Flux.train!(loss, p, [(xtrain, ytrain_onehot)], opt)

modelx = model(xtrain[:, 1])
exp.(modelx) ./ sum(exp, modelx)

model(xtrain)

prediction = model(xtrain) |> softmax |> collect |> onecold .|> x->x-1

mean(prediction .== ytrain)


@time Flux.@epochs 100 Flux.train!(loss, p, [(xtrain, ytrain_onehot)], opt)

prediction = model(xtrain) |> softmax |> collect |> onecold .|> x->x-1

mean(prediction .== ytrain)

function accuracy(x, y)
    predictions = model(x) |> softmax |> collect |> onecold .|> x->x-1
    mean(predictions .== y)
end

accuracy(xtrain, ytrain)

function callback_accuracy()
    @show accuracy(xtrain, ytrain)
end

function callback_loss()
    @show loss(xtrain, ytrain_onehot)
end

@time Flux.@epochs 100 Flux.train!(loss, p, [(xtrain, ytrain_onehot)], opt; cb = [callback_accuracy, callback_loss])

prev_accuracy = accuracy(xtrain, ytrain)


xtest, ytest = MLDatasets.MNIST.testdata(Float32)

xtest = Flux.flatten(xtest) |> gpu

accuracy(xtest, ytest)


function callback_accuracy()
    @show new_acc = accuracy(xtest, ytest)
    if new_acc < prev_accuracy
        println(new_acc)
        no_improvement_counter += 1
    else
        prev_accuracy = new_acc
    end

    if no_improvement_counter  == 10
        Flux.stop()
    end
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

        if cnt ÷ 100 == 0
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

