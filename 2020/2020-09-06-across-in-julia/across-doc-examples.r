library(dplyr)

View(iris)

# examples from
?dplyr::across

# across() -----------------------------------------------------------------
iris %>%
  group_by(Species) %>%
  summarise(across(starts_with("Sepal"), mean))


iris %>%
  group_by(Species) %>%
  summarise(across(starts_with("Sepal"), mean))

iris %>%
  as_tibble() %>%
  mutate(across(where(is.factor), as.character))

# A purrr-style formula
iris %>%
  group_by(Species) %>%
  summarise(across(starts_with("Sepal"), ~mean(.x, na.rm = TRUE)))

# A named list of functions
iris %>%
  group_by(Species) %>%
  summarise(across(starts_with("Sepal"), list(mean = mean, sd = sd)))

# Use the .names argument to control the output names
iris %>%
  group_by(Species) %>%
  summarise(across(starts_with("Sepal"), mean, .names = "mean_{col}"))

iris %>%
  group_by(Species) %>%
  summarise(across(starts_with("Sepal"), list(mean = mean, sd = sd), .names = "{col}.{fn}"))

iris %>%
  group_by(Species) %>%
  summarise(across(starts_with("Sepal"), list(mean, sd), .names = "{col}.fn{fn}"))

