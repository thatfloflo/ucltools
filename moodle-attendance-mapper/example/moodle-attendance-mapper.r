#!/usr/bin/env Rscript
#
# UCL MOODLE ATTENDANCE MAPPER
#
# Automates extraction of BB Collaborate and Zoom attendance data from UCL moodle logs.
#
# Author:  Florian Breit <florian.breit.12@ucl.ac.uk>
# Version: 1.1.2

#
# USER VARIABLES
#

# CHANGE THESE TO THE CORRECT VALUES FOR YOUR MODULE
MODULE_CODE <- "PLIN1234"
FIRST_WEEK_NUMBER <- 6
FIRST_WEEK_DATE <- "2020-10-05"
EXTRACT_BB_COLLAB <- TRUE
EXTRACT_ZOOM_CLICKS <- TRUE


#
# SET UP DEPENDENCIES AND GLOBALS
#

# Take care of dependencies
options(tidyverse.quiet = TRUE)
if(!require("tidyverse")) {
  install.packages("tidyverse")
  library("tidyverse")
}
if(!require("readxl")) {
  install.packages("readxl")
  library("readxl")
}
if(!require("writexl")) {
  install.packages("writexl")
  library("writexl")
}

# Parse first week date
FIRST_WEEK_DATE <- parse_date(FIRST_WEEK_DATE) #Format: YYYY-MM-DD
# Set path to attendance spreadsheet
ATTENDANCE_SHEET_PATH <- paste(MODULE_CODE, "attendance.xlsx")


#
# FUNCTIONS
#

# Returns the UCL week number for x_date, based on
# the globals FIRST_WEEK_NUMBER and FIRST_WEEK_DATE
date_to_ucl_week <- function(x_date) {
  date_diff <- x_date - FIRST_WEEK_DATE # Returns difference in days
  add_weeks <- floor(as.numeric(date_diff) / 7)
  
  x_week <- FIRST_WEEK_NUMBER + add_weeks
  
  return(x_week)
}

# Converts the timestamp from moodle logs into a POSIXlt date (not datetime!)
log_time_to_date <- function(x_time) {
  x_date <- parse_datetime(x_time, format = "%d/%m/%y, %H:%M")
  x_date <- parse_date(
    as.character(
      as.Date(x_date, format="%Y-%m-%d", tz=Sys.timezone())
    )
  )
  return(x_date)
}

# Turns a name of form "First Middle Last" into "LAST, FIRST MIDDLE"
reformat_log_user_name <- function(x_user) {
  if(!length(x_user)) {
    return("")
  }
  x_user <- toupper(x_user)
  x_user_parts <- strsplit(x_user, split = " ")[[1]]
  last_name   <- tail(x_user_parts, 1)
  first_names <- head(x_user_parts, length(x_user_parts)-1)
  first_names <- paste(first_names, collapse = " ")
  user_name <- paste(c(last_name, first_names), collapse = ", ")
  return(user_name)
}

# Turns a name of form "LAST_A ... LAST_X, FIRST MIDDLE" into "LAST_X, FIRST LAST_A ..."
# Note that middle names are deleted, as these don't appear on moodle logs
reformat_attendance_user_name <- function(x_user) {
  x_user <- toupper(x_user)
  x_user_parts <- strsplit(x_user, split = ", ")[[1]]
  last_names  <- head(x_user_parts, 1)
  first_names <- tail(x_user_parts, 1)
  first_name_parts <- strsplit(first_names, split = " ")[[1]]
  first_name <- head(first_name_parts, 1)
  log_user_name <- paste(c(first_name, last_names), collapse = " ")
  user_name <- reformat_log_user_name(log_user_name)
  return(user_name)
}


#
# PROCEDURE TO EXTRACT ATTENDANCE
#

# Read attendance sheet
message("Opening attendance spreadsheet: `", ATTENDANCE_SHEET_PATH, "`.", sep="")
attendance <- read_excel(ATTENDANCE_SHEET_PATH) %>%
  rowwise() %>%
  mutate(`Name_normalised` = reformat_attendance_user_name(Name)) %>%
  mutate_all(as.character)

# Variables for keeping track of missing attendees and weeks
MISSING_WEEKS <- c()
MISSING_ATTENDEES <- c()

# Go through and integrate logs
log_files <- list.files(pattern = ".*\\.csv$", ignore.case = TRUE)
if(!length(log_files)) {
  message("No log files found in current directory.")
}
for(log_file in log_files) {
  message("Processing log file: `", log_file, "`.", sep="")
  # Read in log
  message("  Loading log file into memory.")
  log <- read_delim(log_file, delim=",", col_types = cols(
    Time = col_character(),
    `User full name` = col_character(),
    `Affected user` = col_character(),
    `Event context` = col_character(),
    Component = col_character(),
    `Event name` = col_character(),
    Description = col_character(),
    Origin = col_character(),
    `IP address` = col_character()
  ))
  
  # Tidy up the log
  message("  Tidying up the logs.")
  log <- log %>%
    select(Time, `User full name`, `Event name`, Component)%>%
    rowwise() %>%
    mutate(Time = log_time_to_date(Time)) %>%
    mutate(`User full name` = reformat_log_user_name(`User full name`)) %>%
    mutate(Week = date_to_ucl_week(Time))
  
  # Set up an empty combined log, we will then merge collab and zoom data into it
  combined_log <- log[NULL,]
  
  # Tidy and filter for launching of collaborate sessions
  if(EXTRACT_BB_COLLAB) {
    message("  Extracting BB Collaborate launch data.")
    collab_log <- log %>%
      filter(`Event name` == "Collab session launched")
    combined_log <- bind_rows(combined_log, collab_log)
  }
  
  # Tidy and filter for launching of zoom links
  if(EXTRACT_ZOOM_CLICKS) {
    message("  Extracting clicks on Zoom links.")
    zoom_log <- log %>%
      filter(`Event name` == "Clicked join meeting button" & `Component` == "Zoom meeting")
    combined_log <- bind_rows(combined_log, zoom_log)
  }
  
  # Collapse log to just show name and week attended for each event
  attendance_by_week <- combined_log %>%
    group_by(`User full name`, Week) %>%
    summarise_all(list())
  
  # Iterate through weekly attendance and check this off in attendance sheet
  message("  Extracting weekly attendance records.")
  if(nrow(attendance_by_week)) {
    pb = txtProgressBar(min = 0, max = nrow(attendance_by_week), initial = 0, style = 3)
    for(i in 1:nrow(attendance_by_week)) {
      # Extract attendee name and week of attendance
      attendee_name <- attendance_by_week[i,]$`User full name`
      attendee_week <- attendance_by_week[i,]$Week
      
      # Figure out the filter values to get the right cell in attendance sheet
      target_name <- attendee_name
      target_col_name <- paste("Week", attendee_week, sep=" ")
      target_col_index <- grep(target_col_name, colnames(attendance))
      
      # Check if there is a column for that week
      if(!length(target_col_index)) {
        if(!(attendee_week %in% MISSING_WEEKS)) {
          MISSING_WEEKS <- append(MISSING_WEEKS, attendee_week)
        }
      }
      
      # Check if target_name exists in attendance sheet
      if(sum(attendance$Name_normalised==target_name)) {
        # Overwrite that cell in attendance sheet with "Present"
        attendance[attendance$Name_normalised==target_name, target_col_index] <- "Present"
      } else {
        # Couldn't match normalised name, try matching with raw attendance sheet name
        # (Sometimes compund surnames and middle names are not distinct on moodle,
        #  so this is a good fallback where a surname was assumed to be a middle)
        if(sum(attendance$Name==target_name)) {
          attendance[attendance$Name==target_name, target_col_index] <- "Present"
        }
        else {
          if(!(target_name %in% MISSING_ATTENDEES)) {
            MISSING_ATTENDEES <- append(MISSING_ATTENDEES, target_name)
          }
        }
      }
      setTxtProgressBar(pb, i)
    }
    message("\n  Found ", i, " attendance records in current log file.")
  } else {
    message("  No attendees found in current log file.")
  }
}
message("Completed processing all log files.")

# Report on missing attendees and missing weeks
if(length(MISSING_ATTENDEES)) {
  message("Couldn't find matches in attandance spreadsheet for the following attendees:")
  for(missing_attendee in MISSING_ATTENDEES) {
    message("  ", missing_attendee)
  }
}
if(length(MISSING_WEEKS)) {
  message("There were log entries but no corresponding column in the attendance spreadsheet for these weeks:")
  for(missing_week in MISSING_WEEKS) {
    message("  Week ", missing_week)
  }
}

# Remove normalised names and save attendance sheet
message("Writing updated attendance spreadsheet: `", ATTENDANCE_SHEET_PATH, "`.")
attendance %>%
  select(-Name_normalised) %>%
  write_xlsx(paste(MODULE_CODE, "attendance.xlsx"))

#EOF
