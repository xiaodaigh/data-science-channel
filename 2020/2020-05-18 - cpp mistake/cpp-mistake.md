## Intro

Bjarne Stroustrup is one of most well known computer scientists in the world having invented C++ in the 1980's. In 2020, C++ remains one of the pre-eminent programming languages on the planet; and I doesn't feel like it's going to go away any time soon despite many complaints about it, for example it's easy to find complaints about C++'s immense complexity on that Orange site. But you what Mr Stroustrup's response to that those complaints is? 

"There are only two kinds of languages: the ones people complain about and the ones nobody uses". Yes. Again, I very much doubt that the sentiment is original. Of course, all "there are only two" quotes have to be taken with a grain of salt." see http://www.stroustrup.com/bs_faq.html


However, Bjarne admitted to making a "mistake" with C++'s design. The "mistake" he made has something to with Object-oriented programming, or OO programming for short. The "mistaken" design choice was __"extremely"__ fashionable at the time.

In this video, I will show you what the "mistake" was. And how Julia's avoided that "mistake" by embracing a feature that is rarely implemented in other programming languages.

## What's the mistake?

In a Nov-2019 Bjarne published a [C++ Standards committee paper title "How can you be so certain?"](http://www.open-std.org/jtc1/sc22/wg21/docs/papers/2019/p1962r0.pdf). In that paper, Bjarne wrote:

"When I am pretty certain, my conviction is usually based on decades of prior art, theory, experience, and
thought. For example:"

and he goes through a list of bullets points, but I want to focus on this one 

"Unified function call: The notational distinction between x.f(y) and f(x,y) comes from the flawed
OO notion that there always is a single most important object for an operation. I made a mistake
adopting that. It was a shallow understanding at the time (but extremely fashionable). Even
then, I pointed to sqrt(2) and x+y as examples of problems caused by that view. With generic
programming, the x.f(y) vs. f(x,y) distinction becomes a library design and usage issue (an
inflexibility). With concepts, such problems get formalized. Again, the issues and solutions go
back decades. Allowing virtual arguments for f(x,y,z) gives us multimethods."

Let's breakdown the paragraph,

* In Object-oriented programming: if `x` is an object. The most common syntax is to let `x.fn(..)` to run a function associated with `x`. 
