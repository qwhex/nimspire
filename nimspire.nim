import strformat
from os import existsOrCreateDir, fileExists, fileNewer, sameFileContent, getHomeDir, joinPath, copyFileWithPermissions, paramStr, paramCount
from streams import newFileStream, readLine, writeLine, close
from terminal import getch, styledWriteLine, fgCyan, fgYellow, fgRed, resetStyle
from strutils import toLowerAscii

proc info(msg: string) =
  styledWriteLine(stdout, fgYellow, "- " & msg, resetStyle)

proc question(msg: string) =
  styledWriteLine(stdout, fgCyan, "? " & msg, resetStyle)

proc problem(msg: string) =
  styledWriteLine(stdout, fgRed, "! " & msg, resetStyle)

proc loadConfig(configPath: string, defaultBackupDir: string): string =
  var configRFS = newFileStream(configPath, fmRead)
  if not isNil(configRFS):
    # read existing config
    let backupDir = readLine(configRFS)
    configRFS.close()
    return backupDir
  else:
    # create default config
    var configWFS = newFileStream(configPath, fmWrite)
    configWFS.writeLine(defaultBackupDir)
    configWFS.close()
    info("Created config file: " & configPath)
    configRFS.close()
    return defaultBackupDir

proc loadIdeas(dbPath: string): seq[string] =
  var
    ideas: seq[string] = @[]
    ideasRFS = newFileStream(dbPath, fmRead)
    line = ""

  if isNil(ideasRFS):
    # populate with some ideas
    ideas.add("use h, j, k, l, o to rate this idea")
    ideas.add("use d if you want to delete an idea")
    ideas.add("you can set up a backup directory in ~/.nimspire/nimspire.ini")
    ideas.add("backup directory can be e.g. google drive or keybase")
    ideas.add("try out nim, it's a fun and fast lang")
  else:
    # load ideas
    while ideasRFS.readLine(line):
      ideas.add(line)
  
  ideasRFS.close()
  return ideas

proc saveIdeas(dbPath: string, ideas: seq[string]) =
  var wfs = newFileStream(dbPath, fmWrite)
  for i in 0..<ideas.len:
    wfs.writeLine(ideas[i])
  wfs.close()

proc newIdea(ideas: var seq[string]): seq[string] =
  # enter new idea
  question("Enter your idea:")
  var idea: string = readLine(stdin)
  ideas.add(idea)
  info("Idea incubated.")
  return ideas

proc getRatingInput(idea: string): int =
  info("Rate this idea:")
  echo idea

  question("h / j / k / l / o / (d)elete")
  while true:
    case toLowerAscii(getch())
    of 'd': return 0 # delete
    of 'h': return 5
    of 'j': return 4
    of 'k': return 3
    of 'l': return 2
    of 'o': return 1
    else: problem("Please select:\nh 5☆\nj 4☆\nk 3☆\nl 2☆\no 1☆\nd: delete")

proc rate(ideas: var seq[string]): seq[string] =
  # show the next idea in the queue (top of file) and rate
  let
    shownIdea = ideas[0] # make a copy of the shown idea
    rating = getRatingInput(ideas[0])

  # delete shown idea (first line of txt)
  ideas.delete(0)

  if rating == 0:
    info("Idea deleted.")
  else:
    info(fmt"Your rating: {rating}☆")
    
    var newIndexForIdea = 0
    
    if rating == 1:
      # at the worst rating, we insert it at the end
      newIndexForIdea = ideas.len
    else:
      # we insert at at 0.6 at 5 star, at 0.7 at 4 star, etc
      newIndexForIdea = (ideas.len div 10) * (11-rating)

    # based on the rating, the idea moves down a certain amount
    info(fmt"New position: {newIndexForIdea}/{ideas.len}")
    ideas.insert(shownIdea, newIndexForIdea)
  
  return ideas

proc main() =
  let
    nimspireHomeDir = joinPath(getHomeDir(), ".nimspire")
    defaultBackupDir = joinPath(nimspireHomeDir, "backup")
    ideasFilename = "nimspire.db.txt"
    dbPath = joinPath(nimspireHomeDir, ideasFilename)
    configPath = joinPath(nimspireHomeDir, "nimspire.ini")

  # create home directory if doesn't exist yet
  if not existsOrCreateDir(nimspireHomeDir):
    info("Created nimspire home directory: " & nimspireHomeDir)

  let
    backupDir = loadConfig(configPath, defaultBackupDir)

  # create backup directory if doesn't exist yet
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

  var ideas = loadIdeas(dbPath)

  if paramCount() == 0 or (paramCount() > 0 and paramStr(1) != "review"):
    ideas = newIdea(ideas)

  if paramCount() == 0 or (paramCount() > 0 and paramStr(1) != "add"):
    ideas = rate(ideas)

  # Save ideas
  saveIdeas(dbPath, ideas)

  # Backup ideas
  copyFileWithPermissions(dbPath, backupDbPath)

main()