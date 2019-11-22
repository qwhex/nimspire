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

# TODO: styledWriteLine without newline
proc info(msg: string) =
  styledWriteLine(stdout, fgYellow, "◉ " & msg, resetStyle)

proc question(msg: string) =
  styledWriteLine(stdout, fgCyan, "▲ " & msg, resetStyle)

proc problem(msg: string) =
  styledWriteLine(stdout, fgRed, "▼ " & msg, resetStyle)


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
  ideas.add("write down your ideas daily")
  ideas.add("execute your ideas with deep care")
  ideas.add("support the development of nimspire with your love")

proc new_idea() =
  # enter new idea
  question("Enter your idea:")
  var newIdea: string = readLine(stdin)
  ideas.add(newIdea)
  info("Good one!\n")


if paramCount() == 0 or (paramCount() > 0 and paramStr(1) != "review"):
  new_idea()

# show the next idea in the queue and rate
info("Your daily idea dose:")
echo ideas[0]

proc rate(): int =
  question("Rate it, please\n> h > j > k > l > o")
  while true:
    case toLowerAscii(getch())
    of 'h': return 1
    of 'j': return 2
    of 'k': return 3
    of 'l': return 4
    of 'o': return 5
    else: problem("Please select 'h', 'j', 'k', 'l' or 'o'!")

let
  shownIdea = ideas[0]
  rating = rate()
  fifth = ideas.len div 5
  newIndexForIdea = fifth * rating

info(fmt"Your rating (lower is better): {rating}")

ideas.delete(0)
if rating != 5:  # delete if omg
  ideas.insert(shownIdea, newIndexForIdea)
else:
  info("Idea deleted.")

info("Thanks!")


# save ideas
var wfs = newFileStream(dbPath, fmWrite)
for i in 0..<ideas.len:
  wfs.writeLine(ideas[i])
wfs.close()


# backup ideas
copyFileWithPermissions(dbPath, backupDbPath)
