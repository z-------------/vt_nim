import nimsha2

const BufSize = 256

proc getSHA256*(filename: string): string =
  var h = initSHA[SHA256]()

  let file = open(filename)
  var buf = newString(BufSize)
  
  while not file.endOfFile:
    let bytesRead = file.readChars(buf, 0, BufSize)
    h.update(buf[0..<bytesRead])

  return h.final().toHex()
