import fileinput
import feedparser

for fileinput_line in fileinput.input():
    if 'Exit' == fileinput_line.rstrip():
        break
    feed=feedparser.parse(fileinput_line)
    for entry in feed.entries:
      #print("Entry Title:", entry.title)
      #print("Entry Link:", entry.link)
      if "link" in entry:
        print(entry.link)
      #print("Entry Published Date:", entry.published)
      #print("Entry Summary:", entry.summary)
      #print("\n")
