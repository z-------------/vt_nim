import nimsha2

export SHA256Digest, toHex

proc getSHA256*(filename: string): SHA256Digest =
  var h = initSHA[SHA256]()

  let file = open(filename)
  let data = file.readAll()
  h.update(data)

  return h.final()
