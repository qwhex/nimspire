from os import existsOrCreateDir, fileExists, fileNewer, sameFileContent, getHomeDir, joinPath, copyFileWithPermissions, paramStr, paramCount
from streams import newFileStream, readLine, writeLine, close
from terminal import getch, styledWriteLine, fgCyan, fgYellow, fgRed, resetStyle
from strutils import toLowerAscii
import strformat

let
  nimspireHomeDir = joinPath(getHomeDir(), ".nimspire")
  ideasFilename = "nimspire.db.txt"
  dbPath = joinPath(nimspireHomeDir, ideasFilename)
  configPath = joinPath(nimspireHomeDir, "nimspire.ini")
  defaultBackupDir = joinPath(nimspireHomeDir, "backup")


proc info(msg: string) =
  styledWriteLine(stdout, fgYellow, "- " & msg, resetStyle)

proc question(msg: string) =
  styledWriteLine(stdout, fgCyan, "? " & msg, resetStyle)

proc problem(msg: string) =
  styledWriteLine(stdout, fgRed, "! " & msg, resetStyle)


# check nimspire home dir
if not existsOrCreateDir(nimspireHomeDir):
  info("Created nimspire home directory: " & nimspireHomeDir)


# load config
var backupDir: string

var configRFS = newFileStream(configPath, fmRead)
if not isNil(configRFS):
  # is it ok this way?
  backupDir = readLine(configRFS)
  configRFS.close()
else:
  var configWFS = newFileStream(configPath, fmWrite)
  configWFS.writeLine(defaultBackupDir)
  configWFS.close()
  backupDir = defaultBackupDir
  info("Created config file: " & configPath)


# check nimspire backup dir
if not existsOrCreateDir(backupDir):
  info("Created nimspire backup directory: " & backupDir)


# sync backup
let
  backupDbPath = joinPath(backupDir, ideasFilename)

if fileExists(backupDbPath) and
    fileNewer(backupDbPath, dbPath) and
    not sameFileContent(backupDbPath, dbPath):
  copyFileWithPermissions(backupDbPath, dbPath)
  info("Copied ideas from backup: " & backupDbPath)


# load ideas
var
  ideas: seq[string] = @[]
  fs = newFileStream(dbPath, fmRead)
  line = ""

if not isNil(fs):
  while fs.readLine(line):
    ideas.add(line)
  fs.close()
else:
  ideas.add("use h, j, k, l, o to rate this idea")
  ideas.add("use d if you want to delete an idea")
  ideas.add("you can set up a backup directory in ~/.nimspire/nimspire.ini")
  ideas.add("backup directory can be e.g. google drive or keybase")
  ideas.add("try out nim, it's a fun and fast lang")

proc new_idea() =
  # enter new idea
  question("Enter your idea:")
  var newIdea: string = readLine(stdin)
  ideas.add(newIdea)
  info("Saved.")


if paramCount() == 0 or (paramCount() > 0 and paramStr(1) != "review"):
  new_idea()

# show the next idea in the queue (top of file) and rate
info("Rate this idea:")
echo ideas[0]

proc rate(): int =
  question("h / j / k / l / o or (d)elete")
  while true:
    case toLowerAscii(getch())
    of 'd': return 0 # delete
    of 'h': return 5
    of 'j': return 4
    of 'k': return 3
    of 'l': return 2
    of 'o': return 1
    else: problem("Please select:\nh 5☆\nj 4☆\nk 3☆\nl 2☆\no 1☆\nor d for delete")

let
  shownIdea = ideas[0] # make a copy of the shown idea
  rating = rate()

# delete shown idea (first line of txt)
ideas.delete(0)

if rating != 0:
  info(fmt"Your rating: {rating}☆")
  
  # we insert at at 0.6 at 5 star, at 0.7 at 4 star, etc
  # at the worst rating, we insert it at the end
  var newIndexForIdea = 0
  
  if rating==1:
    newIndexForIdea = ideas.len
  else:
    newIndexForIdea = (ideas.len div 10) * (11-rating)

  # based on the rating, the idea moves down a certain amount
  info(fmt"New position: {newIndexForIdea}/{ideas.len}")
  ideas.insert(shownIdea, newIndexForIdea)
else:
  info("Idea deleted.")

info("Thanks!")


# Save ideas
var wfs = newFileStream(dbPath, fmWrite)
for i in 0..<ideas.len:
  wfs.writeLine(ideas[i])
wfs.close()


# Backup ideas
copyFileWithPermissions(dbPath, backupDbPath)
