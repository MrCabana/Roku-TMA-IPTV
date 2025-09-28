sub init()
  m.top.functionName = "go"
end sub

function toStr(x as dynamic) as string
  t = type(x)
  if t = "roString" or t = "String" then return x
  if t = "Integer" or t = "roInt" or t = "LongInteger" then
    s = StrI(x)
    while Len(s) > 0 and Left(s,1) = " "
      s = Mid(s,2)
    end while
    return s
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

  titles = []
  ids = []
  directs = []

  if type(data) = "roArray" then
    for each it in data
      if it <> invalid and type(it) = "roAssociativeArray" then
        name = "" : if it.Lookup("name") <> invalid then name = toStr(it.name)
        sid  = "" : if it.Lookup("stream_id") <> invalid then sid  = toStr(it.stream_id)
        dsrc = "" : if it.Lookup("direct_source") <> invalid then dsrc = toStr(it.direct_source)

        if sid <> "" then
          ids.push(sid)
          titles.push(name)
          directs.push(dsrc)
        end if
      end if
    end for
  end if

  if titles.count() = 0 then
    m.top.error = "No channels"
    m.top.status = "error"
    return
  end if

  m.top.titles = titles
  m.top.ids = ids
  m.top.directUrls = directs
  m.top.status = "ok"
end sub
