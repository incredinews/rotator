import json
import os

with open('current.json') as f:
    data = json.load(f)

for item in data:
    day=item["publishedParsed"].split('T')[0]
    targetfile="./"+day+".json"
    #print(item)
    #print (targetfile)
    check_file = os.path.isfile(targetfile)
    dayitems=[]
    if(check_file):
        with open(targetfile) as f:
           dayitems=json.load(f)
        seen = set()
        new_l = []
        dayitems.append(item)
        for d in dayitems:
            t = d["link"]
            if "guid" in d:
                t = t+d["guid"]
            #print("debug:tuple"+t)
            if t not in seen:
                seen.add(t)
                new_l.append(d)
        #print(new_l)
        with open(targetfile, 'w') as f:
            json.dump(new_l, f)
    if not check_file:
        #print("create")
        dayitems=[]
        dayitems.append(item)
        with open(targetfile, 'w') as f:
            json.dump(dayitems, f)
