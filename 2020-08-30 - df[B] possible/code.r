df1 = data.frame(a = rep(1, 100), b="a")
df2 = data.frame(a = rep(2, 100), b="b")


B = matrix(sample(c(T,F), 200, replace=T), ncol=2)

str(df1)

df1[B] = df2[B]

df1[B]

df1
str(df1)
