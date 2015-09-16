using Images
using Colors
using ImageView
using Gadfly

function normalize(x)
    x=(x-minimum(x)) ./ (maximum(x) - minimum(x))
    return x
end

function chart_weights(W, imsize; padding=0, annotation="", filename="")
    h, w = imsize
    n = size(W, 1)
    rows = round(Int,floor(sqrt(n)))
    cols = round(Int,ceil(n / rows))
    halfpad = div(padding, 2)
    dat = zeros(rows * (h + padding), cols * (w + padding))
    for i=1:n
        wt = W[i, :]
        wim = reshape(wt, imsize)
        wim = wim ./ (maximum(wim) - minimum(wim))
        r = div(i - 1, cols) + 1
        c = rem(i - 1, cols) + 1
        dat[(r-1)*(h+padding)+halfpad+1 : r*(h+padding)-halfpad,
            (c-1)*(w+padding)+halfpad+1 : c*(w+padding)-halfpad] = wim
    end

    dat=normalize(dat)

    # Make the image view
    imgc,img = ImageView.view(dat)
    ImageView.annotate!(imgc,img,ImageView.AnnotationText(20,20,annotation,color=RGB(1,1,1),fontsize=14,halign="left"))

    # Write to file
    if length(filename) > 0
        Images.imwrite(dat,filename,quality=100)
    end
end

function chart_weights_distribution(W;bincount=100,filename="")
    if length(filename) > 0
        # Write to file if filename specified
        DistributionPlot = plot(x=vec(W),Geom.histogram(bincount=bincount))
        draw(PDF(filename, 10inch, 6inch), DistributionPlot)
    else
        # Draw plot if no filename given
        plot(x=vec(W),Geom.histogram(bincount=bincount))
    end
end

function chart_activation_distribution(rbm,X;bincount=100,filename="")
    Activations = transform(rbm,X)

    if length(filename) > 0
        # Write to file if filename specified
        DistributionPlot = plot(x=vec(Activations),Geom.histogram(bincount=bincount))
        draw(PDF(filename, 10inch, 6inch), DistributionPlot)
    else
        # Draw plot if no filename given
        plot(x=vec(Activations),Geom.histogram(bincount=bincount))
    end
end