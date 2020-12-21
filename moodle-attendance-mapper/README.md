# UCL moodle attendance mapper

The attendance mapper automates extraction of BB Collaborate and Zoom attendance
data from UCL moodle logs.

This script will parse the logs from a moodle module page, extract all the
occurrences of people launching a BB Collaborate session or clicking on a
Zoom link to launch a Zoom session. These will then be grouped by week
(numbered following the UCL academic year). For each week where a person
in this list launched at least one BB Collaborate or Zoom session they are
then marked as "Present" on the attendance sheet. The script can be set to be
sensitive to both BB Collaborate and Zoom or selectively to only one of them
by setting the variables (see description of variables below).

<a id="contents"></a>
## 1. Contents

- \1. [ Contents ](#contents)
- \2. [ Requirements ](#requirements)
- \3. [ Setup and usage ](#setup)    
  * 3.1. [ Setting up the folder structure ](#setup-folder)    
  * 3.2. [ Setting up the attendance sheet ](#setup-attendance-sheet)    
  * 3.3. [ Setting up the script ](#setup-script)    
  * 3.4. [ Obtaining the log files  ](#setup-logs)    
  * 3.5. [ Running the attendance mapper ](#setup-run)    
    + 3.5.1 [ From the terminal on *nix systems (including macOS) ](#setup-run-unix)    
    + 3.5.2 [ On Windows ](#setup-run-windows)    
    + 3.5.3 [ The first time running the moodle attendance mapper ](#setup-run-first-time)
- \4. [ Reporting issues ](#report-issues)
- \5. [ License ](#license)

<a id="requirements"></a>
## 2. Requirements

You must have [R](https://www.r-project.org/) installed on your system to run this script.

Ideally you have R added to your PATH environment, so that you can run
R scripts straight from the terminal, but you can of course also open the script
with your chosen R environemnt (e.g. [RStudio](https://rstudio.com/)). To test
if R is available on your PATH just open a terminal (cmd.exe on Windows) and
type `Rscript --version`. If you get a version number as a response you're good.

<a id="setup"></a>
## 3. Setup and usage

At first glance, the below instructions might seem quite involved and if you've
never done much scripting or worked on the terminal it may seem a bit daunting,
but it's really quite straight forward, and once everything is set up the
workflow will only take you about 2 minutes a week to download your log, run
the script and (if you're required to) share your updated attendance sheet, so
the time you invest in setting this up will pay off very quickly.

<a id="setup-folder"></a>
### 3.1. Setting up the folder structure

Make a folder for your module's attendance. This folder can be named anything
you like, but it shouldn't contain anything that isn't to do with mapping
student attendance.

Inside this new folder, place a copy of `moodle-attendance-mapper.r`, and if
you are on Windows also a copy of `map-attendance.bat`.

The next two steps will explain what other files to create/place inside this
folder. By the end of it, your folder structure will look something like this:

     ./PLIN1234_attendance/
        |
        +-- moodle-attendance-mapper.r
        +-- map-attendance.bat (Optional; if on Windows)
        +-- PLIN1234 attendance.xlsx
        +-- logs_PLIN1234_20_21_20201015-1234.csv
        +-- logs_PLIN1234_20_21_20201022-5678.csv
        +-- ...
        +-- ...

<a id="setup-attendance-sheet"></a>
### 3.2. Setting up the attendance sheet

If you are in the Linguistics department at UCL, just save the attendance
sheet template you are provided with inside the directory. Make sure its
name conforms to the pattern `MODULE_CODE attendance.xlsx`, e.g.
`PLIN1234 attendance.xlsx`. The sheets are already formatted as below, so you
can skip straight ahead to step 3.

If you have to set up your own attendance sheet, just create a new Excel file
called `MODULE_CODE attendance.xlsx` inside the directory you created in step
1 above (obviously replace MODULE_CODE with your module code, e.g. PLIN1234).

Inside the Excel file, create a sheet with the following format:

| Student   | Name               | Week 1 | Week 2 | ... | Week N |
| --------- | ------------------ | ------ | ------ | --- | ------ |
| 012345678 | LAST, FIRST MIDDLE |        |        |     |        |
| 123456780 | SECOND, STUDENT    |        |        |     |        |
| ...       | ...                |        |        |     |        |
| ...       | ...                |        |        |     |        |

Here "Student" refers to the student number, and "Name" is the student's name in
the form "LAST_NAME, FIRST_NAME MIDDLE_NAME" (MIDDLE_NAME obviously only
for students that have one). It's important that the names here fit the name
that the students have on moodle (which is based on their _preferred_ name when
they register, not their _legal_ name which is used in portico registers).

The columns "Week 1" through "Week N" are the consecutive teaching weeks,
starting with the UCL academic week in which teaching commences, usually Week 6
for modules in Term 1, and Week 20 for modules in Term 2.

The table can contain any number of additional columns, which won't be touched
by the script, they just **must not** be named "Name", "Name_normalised", or
"Week N" (where N is a number), as those are columns with special meaning to
the script. Column order is also irrelevant and will be preserved.

<a id="setup-script"></a>
### 3.3. Setting up the script

Open the script in a text editor (e.g. Notepad), and adjust the settings of the
five UPPERCASE variables at the top of the script, as follows below if necessary.
The variables encode the following:

-   MODULE_CODE: The code of your module, e.g. `"PLIN1234"`, used to determine
    the name of the attendance spreadsheet.
-   FIRST_WEEK_NUMBER: The UCL week number of the first week of teaching on
    your module. You can see this on the module timetable. Normally `6` for
    modules in term 1, and `20` for modules in term 2.
-   FIRST_WEEK_DATE: The Monday of the first week of teaching, e.g. the Monday
    of Week 6 2020 would be `"2020-10-05"`. The format of this **must** be
    YYYY-MM-DD.
-   EXTRACT_BB_COLLAB: Whether or not to accept the launching of a BB Collab
    session as being present/in attendance. Value can be `TRUE` or `FALSE`.<br />
    You only need to modify this one if you have BB Collaborate activities on
    your moodle and you _don't_ want these to count for attendance.
-   EXTRACT_ZOOM_CLICKS: Whether or not to accept the launching of a Zoom link
    from moodle as being present/in attendance. Value can be `TRUE` or `FALSE`.<br />
    You only need to modify this one if you have Zoom activities on
    your moodle and you _don't_ want these to count for attendance.

The default values for the variables are as follows:

```r
MODULE_CODE <- "PLIN1234"
FIRST_WEEK_NUMBER <- 6
FIRST_WEEK_DATE <- "2020-10-05"
EXTRACT_BB_COLLAB = TRUE
EXTRACT_ZOOM_CLICKS = TRUE
```

<a id="setup-logs"></a>
### 3.4. Obtaining the log files

Once you've set up the directory and script as per the instructions above,
you're ready to start tracking attendance. After your first day of teaching
go to your module's moodle page, and in the panels on the right click on
`Administration` > `Reports` > `Logs`.

On the Logs page, where the dropdown field says "All days" select the day
of teaching for which you want to check attendance records and then click
on `Get these logs`. Once log entries start to be displayed, scroll to the
bottom of the page and click on `Download` next to the dropdown field that
says "Comma separated values (.csv)". Save the downloaded file to the
attendance directory you've created in step 1.

As teaching progresses, you can just add more logs to the folder. The script
will parse all the log files that are in the same folder. If you just want
to create a retrospective attendance sheet after several weeks are over, you
can also download a log spanning a larger time scale and place that in the
directory — the script will look through it on a week by week basis. The
important thing is that the log files are all in the same folder and end with
the file extension `.csv`. The name of the files is otherwise not important.

<a id="setup-run"></a>
### 3.5. Running the attendance mapper

<a id="setup-run-unix"></a>
#### 3.5.1. From the terminal on *nix systems (including macOS)

If you are on Linux, BSD, or macOS and happy enough to work on the terminal
just go the the your attendance directory in the console and type the
following command:

```bash
chmod +x ./moodle-attendance-mapper.r
```

This will tell your operating system that the file is a script that can be
executed, and you only have to do it once when you set everything up.

Now to run the attendance mapper, just enter the command

```bash
./moodle-attendance-mapper.r
```

and the script should start spitting out a report as it processes your log
files. You'll just run this command every time you want to update the attendance
sheet.

<a id="setup-run-windows"></a>
#### 3.5.2. On Windows

If you are on Windows, and you have R installed and on the PATH, just go
to the attendance directory and double click on `map-attendance.bat`,
which will run the script.

If you get the message `'Rscript' is not recognized as an internal or external command,
operable program or batch file.` this means you don't have R available on your
PATH, so you will have to open the script `moodle-attendance-mapper.r` with
R or RStudio and then run the script from there (or, of course, [you can add
`RScript.exe` to your PATH](https://info201.github.io/r-intro.html#:~:text=In%20Windows,%20You%20can%20add%20the%20) and then double
click the `map-attendance.bat` script again).

<a id="setup-run-first-time"></a>
#### 3.5.3. The first time running the moodle attendance mapper

The script does a few things to try its best to match up names from the logs
with the attendance sheet (normalised ordering, dropping middle names),
but because moodle uses different names to portico this is not always
possible. A list will be printed during the running of the script for any
names that cannot be matched up. Usually this is the case where a student
uses a different first name than their legal name. For example the poet
*Rilke* would be `RILKE, RENE KARL MARIA` on portico, but
`Rainer Maria Rilke` on moodle. If Rilke was a student on your module, and the
script couldn't match Rilke on the register, it would print the following
message the first time he turns up in a log file:

```
Couldn't find match for attendee with name RILKE, RAINER.
```

To fix this, you would change Rilke's name in the Excel attendance sheet to match
what is shown in the message, in this case `RILKE, RAINER` (or `RILKE, RAINER MARIA`
if you like). After adjusting these names in the Excel attendance file the only
messages remaining should be those of the module tutors (lecturer, TA, ...), who
of course won't be on the attendance sheet and therefore the script won't be able
to match them up.

It's worth to check these messages every time you run the script though,
because a student with a problematic name may not have attended a session before
(e.g. if they miss the first three weeks, then they'll only show up in week four
of teaching).

<a id="report-issues"></a>
## 4. Reporting issues

If you encounter any issues with the script, find bugs, have suggestions for
improvement or have any other questions feel free to get in touch with me. The
best way will be by raising an issue here on GitHub, followed closely by sending
me an email on <florian.breit.12@ucl.ac.uk>.

<a id="license"></a>
## 5. License
[Affero General Public License v3](https://www.gnu.org/licenses/agpl-3.0.en.html)    
(If this doesn't fit your needs just get in touch!)
