import nimsha2

proc getSHA256*(filename: string): string =
  var h = initSHA[SHA256]()

  let file = open(filename)
  let data = file.readAll()
  h.update(data)

  return h.final().toHex()
