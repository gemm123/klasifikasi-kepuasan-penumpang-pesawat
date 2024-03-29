library(dplyr)
library(partykit)
library(rpart)
library(rpart.plot)
library(caret)


train_data <- read.csv("/home/patsac/kuliah/smt6/daming-kom1338/prak/tugasakhir/train.csv")
test_data <- read.csv("/home/patsac/kuliah/smt6/daming-kom1338/prak/tugasakhir/test.csv")

# hapus pencilan
for (cn in c("Cleanliness", "Inflight.service", "Checkin.service", "Leg.room.service", "On.board.service", "Inflight.entertainment", "Seat.comfort", "Food.and.drink", "Gate.location")){
  train_data <- subset(train_data, !(train_data[[cn]] == 0))
  test_data <- subset(test_data, !(test_data[[cn]] == 0))
}

# hapus missing value
train_data <- subset(train_data, !(is.na(train_data$Arrival.Delay.in.Minutes)))
test_data <- subset(test_data, !(is.na(test_data$Arrival.Delay.in.Minutes)))


# convert char ke factor
`%!in%` = Negate(`%in%`)
for (cn in colnames(train_data)) {
  if (cn %!in% c("no", "id", "Age", "Flight.Distance", "Departure.Delay.in.Minutes", "Arrival.Delay.in.Minutes")) {
    train_data[[cn]] = as.factor(train_data[[cn]])
  }
}

for (cn in colnames(test_data)) {
  if (cn %!in% c("no", "id", "Age", "Flight.Distance", "Departure.Delay.in.Minutes", "Arrival.Delay.in.Minutes")) {
    test_data[[cn]] = as.factor(test_data[[cn]])
  }
}

get_sample <- function(dataset, n) {
  set.seed(1333337)
  strata <- split(dataset, dataset$satisfaction)
  # Menentukan jumlah sampel yang diinginkan untuk setiap strata
  samp_size <- c(n/2, n/2)
  # Mengambil sampel dari setiap strata secara acak
  samp <- lapply(names(strata), function(x) {
    stratum <- strata[[x]]
    if(x == 'satisfied') { idx = 1 }
    else { idx = 2 }
    stratum[sample(nrow(stratum), size = samp_size[idx]), ]
    })
  # Menggabungkan sampel dari setiap strata menjadi satu data frame
  sampled_data <- do.call(rbind, samp)
  return(sampled_data)
}

# hapus kolom id dan no
traindata <- select(train_data, -one_of("id", "no"))
testdata <- select(test_data, -one_of("id", "no"))
summary(testdata)
summary(traindata)

# sampling
traindata <- get_sample(traindata, 50000)
testdata <- get_sample(testdata, 15000)


formula <- satisfaction ~ Gender+Customer.Type+Age+Type.of.Travel+Class+Flight.Distance+Inflight.wifi.service+Departure.Arrival.time.convenient+Ease.of.Online.booking+Gate.location+Food.and.drink+Online.boarding+Seat.comfort+Inflight.entertainment+On.board.service+Leg.room.service+Baggage.handling+Checkin.service+Inflight.service+Cleanliness+Departure.Delay.in.Minutes+Arrival.Delay.in.Minutes

# ctree
hasil_ctree <- ctree(formula, data=traindata, mincriterion = 0, maxdepth = 4)
plot(hasil_ctree)
ctree_pred <- predict(hasil_ctree, newdata = testdata)
confusionMatrix(ctree_pred, testdata$satisfaction)

# rpart
hasil_rpart <- rpart(formula, data = traindata,control = rpart.control(minsplit = 100))
rpart.plot(hasil_rpart)
rpart_pred <- predict(hasil_rpart, newdata = testdata, type ="class")
confusionMatrix(rpart_pred, testdata$satisfaction)
