import glob
import time

while True:
    linkFiles = glob.glob("../cache/*.link")
    for linkFile in linkFiles:
        print(linkFile)
        linkFileParts = linkFile.split(".")
        file = open(linkFile)
        link = file.read()
        print(link)
        tempFileURL = linkFileParts[0] + "-temp.html"
        subprocess.call(["torsocks", "wget", "-O", tempFileURL, link])
        subprocess.call(["cp", tempFileURL, linkFileParts[0] + ".html"])
        subprocess.call(["rm", tempFileURL])
    time.sleep(60)
