import json
import httpclient
import asyncdispatch

const NimblePkgVersion {.strdefine.} = "Unknown"
const Base = "https://www.virustotal.com/vtapi/v2/"

# private #

type VTClient = object
  apikey: string

proc client(): AsyncHttpClient =
  var c = newAsyncHttpClient()
  c.headers = newHttpHeaders({ "User-Agent": "vt_nim/" & NimblePkgVersion })
  return c

proc buildUrl(vtc: VTClient; endpoint: string): string =
  Base & endpoint & "?apikey=" & vtc.apikey

# public #

const
  vtQueued* = -2
  vtError* = 0
  vtOk* = 1

proc newVTClient*(apikey: string): VTClient =
  assert(apikey.len > 0)
  VTClient(apikey: apikey)

proc report*(vtc: VTClient; resource: string): Future[JsonNode] {.async.} =
  let url = buildUrl(vtc, "file/report") & "&resource=" & resource
  let respBody = await client().getContent(url)
  return parseJson(respBody)

proc scan*(vtc: VTClient; filename: string): Future[JsonNode] {.async.} =
  let url = Base & "file/scan"  # apikey in form data

  var mpData = newMultipartData()
  mpData["apikey"] = vtc.apikey
  mpData.addFiles({ "file": filename })

  let respBody = await client().postContent(url, "", mpData)
  return parseJson(respBody)
