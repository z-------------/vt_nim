import wNim / [wApp, wFrame, wPanel, wButton, wFileDialog, wStaticText, wListCtrl]
import json
from os import splitPath
import strformat
import strutils
import asyncdispatch
import ./sha
import ./vt

const
  Key = staticRead("../key").strip()
  Margin = 10
  PlaceholderText = "--"

type State = object
  filename: string

var state = State()

let
  vtc = newVTClient(Key)

  app = App()
  frame = Frame(title="vt_nim", size=(500, 300))
  panel = Panel(frame)

  fileChooseBtn = Button(panel, label="Choose file...")
  filenameTxt = StaticText(panel, label=PlaceholderText)

  hashLabelTxt = StaticText(panel, label="Hash: ")
  hashTxt = StaticText(panel, label=PlaceholderText)

  reportLabelTxt = StaticText(panel, label="Report: ")
  reportTxt = StaticText(panel, label=PlaceholderText)
  reportList = ListCtrl(panel, size=(100,100), style=wLcReport)

  uploadBtn = Button(panel, label="Upload for scanning")
  uploadTxt = StaticText(panel, style=wAlignLeft)

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
  uploadBtn:
    left = panel.left + Margin
    bottom = panel.bottom - Margin
    width = uploadBtn.label.len * 7
    height = fileChooseBtn.height
  reportList:
    top = reportLabelTxt.bottom
    bottom = uploadBtn.top - Margin
    left = panel.left + Margin
    right = panel.right - Margin
  uploadTxt:
    left = uploadBtn.right + Margin
    top = uploadBtn.top
    height = uploadBtn.height
    right = panel.right

reportList.appendColumn(text="Engine")
reportList.appendColumn(text="Result")

uploadBtn.disable()

# data helpers #

proc getReportResponseCode(report: JsonNode): int {.inline.} =
  report["response_code"].getInt()

proc reportIsOk(report: JsonNode): bool {.inline.} =
  getReportResponseCode(report) == vtOk

# ui stuff #

proc clearFilename() =
  filenameTxt.label = PlaceholderText

proc displayFilename(filename: string) =
  filenameTxt.label = splitPath(filename).tail

proc clearHash() =
  hashTxt.label = PlaceholderText

proc displayHash(hash: string) =
  hashTxt.label = hash

proc clearReportSummary() =
  reportTxt.label = PlaceholderText

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

proc enableUploadBtn() =
  uploadBtn.enable()

proc resetUploadBtn() =
  uploadBtn.disable()

proc displayUploadTxt(text: string) =
  uploadTxt.label = text

proc clearUploadTxt() =
  uploadTxt.label = ""

proc clearReport() =
  clearReportSummary()
  clearReportList()
  resetUploadBtn()
  clearUploadTxt()

proc displayReport(report: JsonNode) =
  let responseCode = getReportResponseCode(report)

  displayReportSummary(report)
  if responseCode == vtOk:
    displayReportList(report)
  if responseCode == vtError:
    enableUploadBtn()

# event handlers #

fileChooseBtn.wEvent_Button do ():
  let
    dialog = FileDialog(frame, message="Choose a file", style=(wFdOpen or wFdFileMustExist))
    filenames = dialog.display()
  if filenames.len > 0:
    clearFilename()
    clearHash()
    clearReport()

    let filename = filenames[0]
    state.filename = filename
    displayFilename(filename)

    let hash = getSHA256(filename)
    displayHash(hash)

    let report = waitFor vtc.report(hash)
    displayReport(report)

uploadBtn.wEvent_Button do ():
  doAssert(state.filename.len > 0)
  let result = waitFor vtc.scan(state.filename)
  let
    responseText = result["verbose_msg"].getStr()
    responseCode = result["response_code"].getInt()
  displayUploadTxt(responseText)
  if responseCode == vtOk:
    resetUploadBtn()

# main #

frame.center()
frame.show()
app.mainLoop()
