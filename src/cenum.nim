import macros

template constDecl(n, t, v): untyped =
  const n: t = v

macro cenum*(t, body: untyped): untyped =
  var
    i: BiggestInt = 0
    curBaseExpr = newIntLitNode(0)
  
  result = newStmtList()
  for node in body.children:
    if node.kind == nnkAsgn: # explicit value
      let
        name = node[0]
        rhs = node[1]
      curBaseExpr = rhs
      i = 0
      result.add(getAst(constDecl(name, t, rhs)))
    elif node.kind == nnkIdent: # implicit value, i.e. increment previous
      let name = node
      var addedExpr = newNimNode(nnkInfix)
      addedExpr.add(
        newIdentNode("+"),
        curBaseExpr,
        newIntLitNode(i),
      )
      result.add(getAst(constDecl(name, t, addedExpr)))
    i.inc()
