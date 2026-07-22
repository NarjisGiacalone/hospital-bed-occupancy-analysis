# Load necessary libraries
library(dplyr)
library(lubridate)
library(pastecs)

# Read the dataset
data <- read.csv("Weekly Hospital Beds occupancy - Regional level.csv", stringsAsFactors = FALSE)

# Set threshold: Remove rows with more than 30% missing values
threshold <- 0.3 * ncol(data)
data_cleaned <- data[rowSums(is.na(data)) <= threshold, ]

# Select relevant columns based on business questions
data_cleaned <- data_cleaned %>% 
  select(
    `Week.Ending.Date`, 
    `Geographic.aggregation`,
    `Number.of.Inpatient.Beds.Occupied`, 
    `Total.COVID.19.Admissions`, 
    `Total.Influenza.Admissions`, 
    `Total.RSV.Admissions`,
    `Total.Adult.RSV.Admissions`
  )

# Check the structure of cleaned dataset
str(data_cleaned)

# Save cleaned dataset
write.csv(data_cleaned, "cleaned_hospital_data.csv", row.names = FALSE)

## Descriptive Statistics
Stats <- stat.desc(data_cleaned)
print(Stats)


## Hypothesis Testing (considering states and not regions)

# Q1: Do hospitals that report higher total new RSV admissions also have a significantly higher inpatient bed occupancy rate?
# Read the dataset
data_cleaned_states <- read.csv("cleaned_hospital_data_states.csv", stringsAsFactors = FALSE)

# Create a median split for RSV admissions (High vs. Low)
median_RSV <- median(data_cleaned_states$`Total.RSV.Admissions`, na.rm = TRUE)
data_cleaned_states$RSV_Group <- ifelse(data_cleaned_states$`Total.RSV.Admissions` > median_RSV, "High", "Low")

# Perform Independent t-test
t_test_q1 <- t.test(`Number.of.Inpatient.Beds.Occupied` ~ RSV_Group, data = data_cleaned_states)

# Print results
print(t_test_q1)

# Q2: Is there a significant difference in the number of influenza admissions between different weeks of the year 2024?
# Read the dataset (new dataset with only year 2024)
data_cleaned_states_2024 <- read.csv("cleaned_hospital_data_states_2024.csv", stringsAsFactors = FALSE)

# Convert 'Week.Ending.Date' to a Date format
data_cleaned_states_2024$Week.Ending.Date <- mdy(data_cleaned_states_2024$Week.Ending.Date)

# Convert 'Week.Ending.Date' to a factor if needed for ANOVA (grouping by week)
data_cleaned_states_2024$Week.Ending.Date <- as.factor(data_cleaned_states_2024$Week.Ending.Date)

# Perform the ANOVA test
anova_result <- aov(Total.Influenza.Admissions ~ Week.Ending.Date, data = data_cleaned_states_2024)

# Summary of the ANOVA test
summary(anova_result)


## Visualization of two hypothesis testing questions

# Load necessary libraries
library(ggplot2)
library(lubridate)

# Visualization 1: Boxplot for RSV Admissions vs. Inpatient Bed Occupancy
ggplot(data_cleaned_states, aes(x = RSV_Group, y = `Number.of.Inpatient.Beds.Occupied`, fill = RSV_Group)) +
  geom_boxplot() +
  labs(title = "Inpatient Bed Occupancy by RSV Admission Level",
       x = "RSV Admission Group",
       y = "Inpatient Bed Occupancy") +
  theme_minimal() +
  scale_fill_manual(values = c("Low" = "skyblue", "High" = "tomato")) +
  theme(legend.position = "none")

# Visualization 2: Line Plot for Weekly Influenza Admissions
ggplot(data_cleaned_states_2024, aes(x = Week.Ending.Date, y = Total.Influenza.Admissions, group = 1)) +
  geom_line(color = "blue", size = 1) +
  geom_point(color = "red", size = 2) +
  labs(title = "Weekly Influenza Admissions (2024)",
       x = "Week Ending Date",
       y = "Total Influenza Admissions") +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))
