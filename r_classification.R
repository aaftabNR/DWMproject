# Load required libraries
library(tidyverse)
library(randomForest)
library(cluster)
library(caret)
library(ggplot2)
library(gridExtra)

# Set seed for reproducibility
set.seed(123)

# Load the data
stroke_data <- read.csv("C:\Users\charv\Downloads\stroke_data.csv")

# Data preprocessing
# Drop ID column
stroke_data <- stroke_data[-1]

# Convert categorical variables to factors
stroke_data$gender <- as.factor(stroke_data$gender)
stroke_data$ever_married <- as.factor(stroke_data$ever_married)
stroke_data$work_type <- as.factor(stroke_data$work_type)
stroke_data$Residence_type <- as.factor(stroke_data$Residence_type)
stroke_data$smoking_status <- as.factor(stroke_data$smoking_status)

# Handle missing values
stroke_data[is.na(stroke_data)] <- 0  # Replace NA with 0 for simplicity

# Split the data into training and testing sets
set.seed(123) # For reproducibility
train_index <- sample(1:nrow(stroke_data), 0.7 * nrow(stroke_data))
train_data <- stroke_data[train_index, ]
test_data <- stroke_data[-train_index, ]

# Define target variable
target <- "stroke"

# Random Forest Implementation Steps:

# Set parameters
n <- nrow(train_data)
p <- ncol(train_data) - 1  # Exclude target variable
m <- round(sqrt(p))  # Square root of total features is often used
ntree <- 500  # Number of trees

# Initialize an empty list to store decision trees
trees <- list()

# Train the Random Forest model
for (i in 1:ntree) {
  # Random Sampling
  bootstrap_sample <- sample(1:n, replace = TRUE, size = n)
  
  # Random Feature Selection
  selected_features <- sample(1:p, size = m)
  
  # Decision Tree Construction
  tree <- randomForest(
    formula = as.factor(stroke) ~ .,
    data = train_data[bootstrap_sample, selected_features],
    ntree = 1,
    importance = FALSE,
    do.trace = FALSE
  )
  
  # Store the decision tree
  trees[[i]] <- tree
}

# Ensemble Prediction (Voting)
rf_pred <- matrix(0, nrow = nrow(test_data), ncol = ntree)
for (i in 1:ntree) {
  rf_pred[, i] <- predict(trees[[i]], newdata = test_data)
}
rf_pred <- apply(rf_pred, 1, function(x) {
  as.factor(names(sort(table(x), decreasing = TRUE)[1]))
})

# Evaluate the Random Forest model
accuracy_rf <- mean(rf_pred == test_data[[target]])
cat("Accuracy of Random Forest model:", accuracy_rf, "\n")

# Davies-Bouldin Index for Random Forest
rf_clusters <- as.integer(rf_pred)
db_rf <- cluster.stats(dist(test_data[, 1:2]), rf_clusters)$dunn
cat("Davies-Bouldin Index for Random Forest:", db_rf, "\n")

# Confusion Matrix for Random Forest
confusionMatrix(rf_pred, test_data[[target]])

# Plot Random Forest variable importance
varImpPlot(randomForest(as.factor(stroke) ~ ., data = train_data, ntree = ntree, importance = TRUE), main = "Random Forest Variable Importance")

# Plot decision boundaries for Random Forest
plot2 <- ggplot(train_data, aes(x = train_data[, 1], y = train_data[, 2], color = as.factor(Kmeans_Cluster))) +
  geom_point() +
  geom_point(data = test_data, aes(x = test_data[, 1], y = test_data[, 2], color = as.factor(rf_clusters + 1)), pch = 20) +
  ggtitle("Random Forest Decision Boundaries") +
  labs(color = "Cluster") +
  theme_minimal()

# Display the plots side by side
grid.arrange(plot2, ncol = 1)

#KNN
# Install and load required packages
install.packages(c("plotly", "tensorflow", "pROC", "tidyverse", "naniar", "caTools", "caret", "ROSE", "reshape2", "magrittr", "dplyr", "keras"))

# Importing packages
library(plotly)
library(tensorflow)
library(pROC)
library(tidyverse)
library(naniar)
library(caTools) 
library(caret)
library(ROSE)
library(reshape2)
library(magrittr)
library(dplyr)
library(keras)
library(class)


#reading the csv file
data = read.csv("C:/Users/Asus/Desktop/stroke_data.csv")
str(data)


# Converting character values to numeric values

clean_data <- data %>% mutate(gender = if_else(gender == "Female", 0, if_else(gender == "Male", 1, 2)), ever_married = if_else(ever_married == "Yes", 1, 0), Residence_type = if_else(Residence_type == "Rural", 0, 1), smoking_status = if_else(smoking_status == "never smoked", 0, if_else(smoking_status == "formerly smoked", 1, if_else(smoking_status == "smokes", 2, 3))))
summary(clean_data)
glimpse(clean_data)

# Handling missing values

miss_scan_count(data = data, search = list("N/A", "Unknown"))

# There are 201 "N/A" values in the bmi column that likely caused this column 
# to be parsed as character, although it should be numerical.   
#  replacing those values with actual NAs. 
# lot of "Unknown" values in smoking_status  
#  We see that we have 1544 unknown values for smoking status and 
# replace those values with 
# NAs.

clean_data <- replace_with_na(data = clean_data, replace = list(bmi = c("N/A"), smoking_status = c(3))) %>% mutate(bmi = as.numeric(bmi))

# Split the data into training and testing sets (e.g., 80% training, 20% testing)
set.seed(99)
index <- createDataPartition(clean_data$stroke, p = 0.8, list = FALSE)
train_data <- clean_data[index, ]
test_data <- clean_data[-index, ]

# Normalize numerical features
scaler <- preProcess(train_data[c("age", "avg_glucose_level", "bmi")], method = c("center", "scale"))
train_data[c("age", "avg_glucose_level", "bmi")] <- predict(scaler, train_data[c("age", "avg_glucose_level", "bmi")])
test_data[c("age", "avg_glucose_level", "bmi")] <- predict(scaler, test_data[c("age", "avg_glucose_level", "bmi")])

# Handle missing values (if any)
train_data[is.na(train_data)] <- 0
test_data[is.na(test_data)] <- 0
# Update the input shape in your LSTM layer to match your data


# Train the KNN model
knn_model <- knn(train = train_data[, -10], test = test_data[, -10], cl = train_data$stroke, k = 100)
# Convert predictions to binary
knn_predictions_binary <- ifelse(knn_model == "Yes", 1, 0)

# Calculate accuracy
accuracy <- mean(knn_predictions_binary == test_data$stroke)
print(paste("Accuracy of KNN model:", round(accuracy * 100, 2), "%"))

