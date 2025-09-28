sub init()
  m.top.functionName = "go"
end sub

function u32str_any(x as dynamic) as string
  t = type(x)
  if t = "Integer" or t = "roInt" or t = "LongInteger" then
    n = x
  else if t = "roString" or t = "String" then
    s = x
    ' Trim spaces
    while Len(s) > 0 and Left(s,1) = " "
      s = Mid(s,2)
    end while
    ' Parse optional sign + digits
    re = CreateObject("roRegex", "^-?\d+$", "i")
    if re.IsMatch(s) then
      ' Convert manually (avoid overflow issues)
      neg = false : if Left(s,1) = "-" then neg = true : s = Mid(s,2)
      n = 0 : for i = 1 to Len(s) : ch = Asc(Mid(s,i,1)) - 48 : n = n*10 + ch : end for
      if neg then n = 0 - n
    else
      return x
    end if
  else
    return "" + x
  end if

  if n < 0 then n = n + 4294967296
  s = StrI(n)
  while Len(s) > 0 and Left(s,1) = " "
    s = Mid(s,2)
  end while
  return s
end function
function u32str(x as dynamic) as string
  t = type(x)
  if t = "Integer" or t = "roInt" or t = "LongInteger" then
    n = x
    if n < 0 then n = n + 4294967296
    s = StrI(n)
    while Len(s) > 0 and Left(s,1) = " "
      s = Mid(s,2)
    end while
    return s
  else if t = "roString" or t = "String" then
    return x
  end if
  return "" + x
end function

sub go()
  url = m.top.url
  if url = invalid or url = "" then
    m.top.error = "No URL configured"
    m.top.status = "error"
    return
  end if

  ut = CreateObject("roUrlTransfer")
  ut.SetCertificatesFile("")
  ut.InitClientCertificates()
  ut.SetUrl(url)
  ut.SetRequest("GET")
  rsp = ut.GetToString()
  if rsp = invalid or Len(rsp) = 0 then
    m.top.error = "Empty response"
    m.top.status = "error"
    return
  end if

  data = ParseJson(rsp)
  if data = invalid then
    m.top.error = "Invalid JSON"
    m.top.status = "error"
    return
  end if

  cats = [] : ids = []

  if type(data) = "roArray" then
    for each it in data
      if it <> invalid and type(it) = "roAssociativeArray" then
        nm = "" : if it.Lookup("category_name") <> invalid then nm = "" + it.category_name
        cid = "" : if it.Lookup("category_id") <> invalid then cid = u32str_any(it.category_id)
        if cid = "" and it.Lookup("category_id_str") <> invalid then cid = "" + it.category_id_str
        if nm <> "" and cid <> "" then
          cats.push(nm)
          ids.push(cid)
        end if
      end if
    end for
  end if

  if cats.count() = 0 then
    m.top.error = "Invalid JSON shape"
    m.top.status = "error"
    return
  end if

  m.top.titles = cats
  m.top.ids = ids
  m.top.status = "ok"
end sub
