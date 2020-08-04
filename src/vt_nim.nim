import wNim / [wApp, wFrame, wPanel, wButton, wFileDialog, wStaticText, wListCtrl]
import json
import strformat
import strutils
import asyncdispatch
import ./sha
import ./vt

const
  Key = staticRead("../key").strip()
  Margin = 10
  PlaceholderText = "--"

let vtc = newVTClient(Key)

let
  app = App()
  frame = Frame(title="vt_nim", size=(500, 300))
  panel = Panel(frame)

  fileChooseBtn = Button(panel, label="Choose file...")
  filenameTxt = StaticText(panel, label=PlaceholderText)

  hashLabelTxt = StaticText(panel, label="Hash: ")
  hashTxt = StaticText(panel, label=PlaceholderText)

  reportLabelTxt = StaticText(panel, label="Detected: ")
  reportTxt = StaticText(panel, label=PlaceholderText)
  reportList = ListCtrl(panel, size=(100,100), style=wLcReport)

# layout #

panel.layout:
  fileChooseBtn:
    top = panel.top + Margin
    left = panel.left + Margin
  filenameTxt:
    top = fileChooseBtn.top
    left = fileChooseBtn.right + Margin
    right = panel.right

  hashLabelTxt:
    top = fileChooseBtn.bottom + Margin
    left = panel.left + Margin
  hashTxt:
    top = hashLabelTxt.top
    left = hashLabelTxt.right
    right = panel.right

  reportLabelTxt:
    top = hashLabelTxt.bottom
    left = panel.left + Margin
  reportTxt:
    top = reportLabelTxt.top
    left = reportLabelTxt.right
    right = panel.right
  reportList:
    top = reportLabelTxt.bottom
    bottom = panel.bottom - Margin
    left = panel.left + Margin
    right = panel.right - Margin

reportList.appendColumn(text="Engine")
reportList.appendColumn(text="Result")

# data helpers #

proc reportIsOk(report: JsonNode): bool =
  report["response_code"].getInt() == vtOk

# ui stuff #

proc displayFilename(filename: string) =
  filenameTxt.label = filename

proc displayHash(hash: string) =
  hashTxt.label = hash

proc displayReportSummary(report: JsonNode) =
  var text: string

  if reportIsOk(report):
    let
      # scanDate = report["scan_date"].getStr()
      countTotal = report["total"].getInt()
      countPositive = report["positives"].getInt()
    text = &"{countPositive} / {countTotal}"
  else:  # vtError or vtQueued
    text = report["verbose_msg"].getStr()
  
  reportTxt.label = text

proc clearReportList() =
  reportList.deleteAllItems()

proc displayReportList(report: JsonNode) =
  clearReportList()

  let scans = report["scans"]
  for engineName in scans.keys:
    if scans[engineName]["detected"].getBool():
      let result = scans[engineName]["result"].getStr()
      reportList.appendItem(texts=[engineName, result])

proc displayReport(report: JsonNode) =
  displayReportSummary(report)
  if reportIsOk(report):
    displayReportList(report)

# event handlers #

fileChooseBtn.wEvent_Button do ():
  let
    dialog = FileDialog(frame, message="Choose a file", style=(wFdOpen or wFdFileMustExist))
    filenames = dialog.display()
  if filenames.len > 0:
    let filename = filenames[0]
    displayFilename(filename)

    let hash = getSHA256(filename)  # blocking!
    displayHash(hash)

    let report = waitFor vtc.report(hash)  # blocking!
    displayReport(report)

# main #

frame.center()
frame.show()
app.mainLoop()
