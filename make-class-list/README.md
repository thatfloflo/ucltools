# Make Class Lists

A script that transforms the unwieldy default class-list with pictures from
UCL Portico into a set of attendance sheets with better formatting and split
by tutorial group.

## Requirements

The script requires you to have [Python](https://python.org) installed. Either
version 2.7 or version 3+ will do.

You also need the Python packages BeautifulSoup4 and LXML. You can easily install
these via `pip`. Just head to the terminal (cmd.exe on Windows) and type:
```bash
pip install lxml
pip install bs4
```

## Usage

1. Copy all the files into some directory of your choice.
2. Use Excel to open the file tutorial-assignments.csv and here enter your
   class information. The format is as follows:
   | Student Number | Student Name | Student Identifier | Tutorial Group |
   | -------------- | ------------ | ------------------ | -------------- |

   This is fairly easy to create by copy and pasting various columns from the
   CSV file you get if you click on `Download` at the same stage where you
   are instructed to go to the class list with photos in the next step, but
   experience shows that many programme administrators will be happy to provide
   you with such a list including tutorial assignments if you ask nicely.
    
   There is some sample data contained in the file when you download first,
   which should of course be removed/overwritten before continuing.
3. On [UCL Portico](https://ucl.ac.uk/portico) go to `Module registration lists`,
   select the appropriate module code and year, and hit `Search`. Click on the
   link with the module name on the left, then on the next page on
   `Confirmed List with Photos`.
4. Right click in the page, choose `Save as` and save the page to the directory
   in which you have the script. It should be saved with the name
   `SMO Class List - with Photos.html` (which will likely be suggested as default).
5. Open a terminal (cmd.exe on Windows), go to the directory in which the
   script and the SMO Class List with Photos are stored, and run the script.    

   To do this on Linux, BSD, or macOS, just type:
   ```bash
   ./make-class-list.py
   ```    

   On Windows, type the following instead:
   ```
   python make-class-list.py
   ```
6. Copy or move the directory "SMO Class List - with Photos_files" (which your
   web browser should have saved automatically alongside the webpage from portico)
   into the directory "tutorial-assignments".
7. Inside the directory "tutorial-assignments" you will now find an HTML documentat
   for each of the groups. You can open these with your web browser and either
   print them directly or save them as PDF files from there.

## Reporting issues

   If you encounter any issues with the script, find bugs, have suggestions for
   improvement or have any other questions feel free to get in touch with me. The
   best way will be by raising an issue here on GitHub, followed closely by sending
   me an email on <florian.breit.12@ucl.ac.uk>.


## License
[Affero General Public License v3](https://www.gnu.org/licenses/agpl-3.0.en.html)    
(If this doesn't fit your needs just get in touch!)
