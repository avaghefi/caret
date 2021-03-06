timestamp <- Sys.time()
library(caret)
library(plyr)
library(recipes)
library(dplyr)

model <- "hda"

for(i in getModelInfo(model)[[1]]$library)
  do.call("require", list(package = i))

#########################################################################

set.seed(2)
training <- twoClassSim(50, linearVars = 2)
testing <- twoClassSim(500, linearVars = 2)
trainX <- training[, -ncol(training)]
trainY <- training$Class

rec_cls <- recipe(Class ~ ., data = training) %>%
  step_center(all_predictors()) %>%
  step_scale(all_predictors())

cctrl1 <- trainControl(method = "cv", number = 3, returnResamp = "all",
                       classProbs = TRUE, 
                       summaryFunction = twoClassSummary)
cctrl2 <- trainControl(method = "LOOCV",
                       classProbs = TRUE, summaryFunction = twoClassSummary)
cctrl3 <- trainControl(method = "none",
                       classProbs = TRUE, summaryFunction = twoClassSummary)
cctrlR <- trainControl(method = "cv", number = 3, returnResamp = "all", search = "random")

set.seed(849)
test_class_cv_model <- train(trainX, trainY, 
                             method = "hda", 
                             trControl = cctrl1,
                             metric = "ROC", 
                             preProc = c("center", "scale"),
                             verbose = FALSE)

set.seed(849)
test_class_cv_form <- train(Class ~ ., data = training, 
                            method = "hda", 
                            trControl = cctrl1,
                            metric = "ROC", 
                            preProc = c("center", "scale"),
                            verbose = FALSE)

test_class_pred <- predict(test_class_cv_model, testing[, -ncol(testing)])
test_class_prob <- predict(test_class_cv_model, testing[, -ncol(testing)], type = "prob")
test_class_pred_form <- predict(test_class_cv_form, testing[, -ncol(testing)])
test_class_prob_form <- predict(test_class_cv_form, testing[, -ncol(testing)], type = "prob")

set.seed(849)
test_class_rand <- train(trainX, trainY, 
                         method = "hda", 
                         trControl = cctrlR,
                         tuneLength = 4, 
                         preProc = c("center", "scale"))

set.seed(849)
test_class_loo_model <- train(trainX, trainY, 
                              method = "hda", 
                              trControl = cctrl2,
                              metric = "ROC", 
                              preProc = c("center", "scale"),
                              verbose = FALSE)

set.seed(849)
test_class_none_model <- train(trainX, trainY, 
                               method = "hda", 
                               trControl = cctrl3,
                               tuneGrid = expand.grid(gamma = .5, 
                                                      lambda =  .5,
                                                      newdim = 2),
                               metric = "ROC", 
                               preProc = c("center", "scale"),
                               verbose = FALSE)

test_class_none_pred <- predict(test_class_none_model, testing[, -ncol(testing)])
test_class_none_prob <- predict(test_class_none_model, testing[, -ncol(testing)], type = "prob")

set.seed(849)
test_class_rec <- train(recipe = rec_cls,
                        data = training,
                        method = "hda", 
                        trControl = cctrl1,
                        metric = "ROC",
                        verbose = FALSE)


if(
  !isTRUE(
    all.equal(test_class_cv_model$results, 
              test_class_rec$results))
)
  stop("CV weights not giving the same results")


test_class_pred_rec <- predict(test_class_rec, testing[, -ncol(testing)])
test_class_prob_rec <- predict(test_class_rec, testing[, -ncol(testing)], 
                               type = "prob")

test_levels <- levels(test_class_cv_model)
if(!all(levels(trainY) %in% test_levels))
  cat("wrong levels")

#########################################################################

tests <- grep("test_", ls(), fixed = TRUE, value = TRUE)

sInfo <- sessionInfo()
timestamp_end <- Sys.time()

save(list = c(tests, "sInfo", "timestamp", "timestamp_end"),
     file = file.path(getwd(), paste(model, ".RData", sep = "")))

q("no")


