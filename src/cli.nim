import asyncdispatch
import json
import os
import rdstdin
import strutils
import ./vt
import ./sha

const Key = staticRead("../key").strip()

# get filename

assert(paramCount() > 0, "No filename provided.")
let filename = paramStr(1)
let filepath = joinPath(getCurrentDir(), filename)
echo "path: ", filepath

# compute hash

let hash = getSHA256(filepath)
echo "hash: ", hash

# request report

let vtc = newVTClient(Key)
let report = waitFor vtc.report(hash)
var reportExists = false
let reportResponseCode = report["response_code"].getInt()

# display report

if reportResponseCode == vtError:
  echo "No report for this file."
elif reportResponseCode == vtQueued:
  reportExists = true
  echo report["verbose_msg"].getStr()
else:
  reportExists = true
  let
    scanDate = report["scan_date"].getStr()
    countTotal = report["total"].getInt()
    countPositive = report["positives"].getInt()
  echo "Report (", scanDate, "):"
  echo "\tPositive: ", countPositive, " / ", countTotal

# upload and scan file if report doesn't exist

if not reportExists:
  let answer = readLineFromStdin("Request a scan? (y/N): ")
  if answer.strip().toLowerAscii() == "y":
    let response = waitFor vtc.scan(filepath)
    echo response["verbose_msg"].getStr()
