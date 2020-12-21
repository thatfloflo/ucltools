#!/usr/bin/env python

import re
from bs4 import BeautifulSoup
import csv
from string import Template
import os

HtmlIn = "./SMO Class List - with Photos.html"
CsvIn = "./tutorial-assignments.csv"
OutDir = "./tutorial-assignments"

#
# EXTRACT THE HTML DIVS FOR EACH STUDENT AND SORT BY STUDENT NUMBER
#

HtmlHandle = open(HtmlIn, "r")
HtmlData = HtmlHandle.read()
HtmlHandle.close()

StudentBoxes = {}
soup = BeautifulSoup(HtmlData, 'lxml')
StudentDivs = soup.findAll("div", {"class" : "sv-panel"}) #The divs with student data have the class "sv-panel"
for StudentDiv in StudentDivs:
    m = re.search("\d{8}", StudentDiv.text)
    StudentNumber = m.group(0)
    StudentBoxes[StudentNumber] = StudentDiv

print("Extracted Data for the following students:")
print(StudentBoxes.keys())
print("That's", len(StudentBoxes), "students overall.")
print("")

#
# EXTRACT TUTORIAL ASSIGNMENTS FROM CSV
#

StudentAssignments = {}
StudentCount = 0
with open(CsvIn, "r") as CsvFile:
    r = csv.reader(CsvFile, delimiter=",", quotechar='"')
    for row in r:
        if(row[0].isdigit()):
            StudentNumber = row[0]
            StudentGroup = row[-1]
            StudentCount += 1
            if(StudentGroup not in StudentAssignments):
                StudentAssignments[StudentGroup] = [StudentNumber]
            else:
                StudentAssignments[StudentGroup].append(StudentNumber)

print("Extracted the following tutorial assignments:")
print(StudentAssignments)
print("That's", StudentCount, "students who've been assigned altogether.")
print("")

#
# GENERATE HTML OUTPUT
#

file_tpl = Template("""<html>
<head>
  <title>Student Tutorial Assignments</title>
  <link rel="stylesheet" type="text/css" href="style.css" />
</head>
<body>
  <div id="groupspace">
  <h1>Group: $group</h1>
    <div id="studentdivs">
      $studentdivs
    </div>
    <div id="leftovers">
      $leftovers
    </div>
  </div>
</body>
</html>""")

div_tpl = Template("""<div class="studentdiv">
  $studentdiv
  <div class="weekly-sign-in">
      <table class="sign-in-table">
       <tr>
        <th>W1</t1><th>W2</t1><th>W3</t1><th>W4</t1><th>W5</t1>
       </tr>
       <tr>
        <td></td><td></td><td></td><td></td><td></td>
       </tr>
       <tr>
        <th>W6</t1><th>W7</t1><th>W8</t1><th>W9</t1><th>WX</t1>
       </tr>
       <tr>
        <td></td><td></td><td></td><td></td><td></td>
       </tr>
      </table>
  </div>
</div>""")

for TutorialGroup, GroupMembers in StudentAssignments.items():
    output_divs = ""
    leftovers = ""
    for Student in GroupMembers:
        if(Student in StudentBoxes):
            div = StudentBoxes[Student].prettify()
            div = div_tpl.substitute(studentdiv=div)
            output_divs += "\n\n" + div
        else:
            leftovers += " " + Student
    if(leftovers != ""):
        leftovers = "Not found:" + leftovers
    output = file_tpl.substitute(group=TutorialGroup, studentdivs=output_divs, leftovers=leftovers)
    outfile = os.path.join(OutDir, TutorialGroup+".html")
    with open(outfile, "w") as outfh:
        outfh.write(output)

    #print(output)
