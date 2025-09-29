sub init()
print ">>> MainScene.init (custom labels + animated focusbar)"
  m.focusbar = m.top.findNode("focusbar")
  m.labels = [ m.top.findNode("lbl0"), m.top.findNode("lbl1"), m.top.findNode("lbl2") ]
  m.titles = ["Live TV","Movies","Series"]
  m.selectedIndex = 0

  ' Animation setup (omit easingFunction to avoid firmware warning)
  m.anim = createObject("roSGNode", "Animation")
  m.anim.duration = 0.12
  m.anim.repeat = false
  m.moveInterp = createObject("roSGNode", "Vector2DFieldInterpolator")
  m.moveInterp.fieldToInterp = "focusbar.translation"
  m.moveInterp.key = [0.0, 1.0]
  m.anim.appendChild(m.moveInterp)
  m.top.appendChild(m.anim)

  setFocusbarToIndex(m.selectedIndex, false)
  updateLabelStyles()
  m.top.setFocus(true)

  
  
  
  
  ' nudge Categories/Channels list focusbars to the right
  nudgeListFocusbars(20)
' nudge selection bar a bit to the right
' Style the new first-screen title label
  atm = m.top.findNode("appTitleMain")
  if atm <> invalid then
    f = CreateObject("roSGNode","Font")
    f.uri = "pkg:/fonts/DejaVuSans-Bold.ttf"
    f.size = 48
    atm.font = f
  end if
' Apply bundled TTF font to the title
  hh = m.top.findNode("hello")
  if hh <> invalid then
    f = CreateObject("roSGNode","Font")
    f.uri = "pkg:/fonts/DejaVuSans-Bold.ttf"
    f.size = 48
    hh.font = f
  end if
vid__ = m.top.findNode("previewVideo")
  if vid__ <> invalid then
    vid__.unobserveField("state")
    vid__.observeField("state", "onPreviewState")
  end if

  ' watchdog timer for preview playback
  m.prevWatch = createObject("roSGNode", "Timer")
  m.prevWatch.duration = 3.0
  m.prevWatch.repeat = false
  m.prevWatch.observeField("fire", "onPreviewWatchdog")
  m.top.appendChild(m.prevWatch)
end sub

sub setFocusbarToIndex(idx as integer, doAnimate as boolean)
  baseY = 120 : rowStep = 60
  x = 52 : yTarget = baseY + idx * rowStep 

  if doAnimate then
    cur = m.focusbar.translation
    if cur = invalid then cur = [x, yTarget]
    m.moveInterp.keyValue = [ cur, [x, yTarget] ]
    m.anim.control = "start"
  else
    m.focusbar.translation = [x, yTarget]
  end if
  print ">>> focusbar target y="; yTarget; " (index="; idx; ", animate="; doAnimate; ")"
end sub

sub updateLabelStyles()
  for i = 0 to m.labels.count()-1
    lbl = m.labels[i]
    if i = m.selectedIndex then
      lbl.color = "0xFFFFFFFF"
    else
      lbl.color = "0xCCCCCCFF"
    end if
  end for
end sub

function onKeyEvent(key as String, press as Boolean) as Boolean
  if not press then return false

  print ">>> key: "; key; " | sel="; m.selectedIndex
  chv = m.top.findNode("chanview")
  if chv <> invalid and chv.hasFocus() then
    if key = "left" then
      cv = m.top.findNode("catview")
      if cv <> invalid then
        chv.setFocus(false)
        cv.visible = true
        cv.setFocus(true)
      end if
      fr = m.top.findNode("chanSelFrame")
      if fr <> invalid then fr.visible = false
      return true
    end if
    if key = "OK" then
      print ">>> MainScene: OK on channel idx="; chv.selIndex; ", id="; chv.currentId
      if chv.currentId = invalid or chv.currentId = "" then
        idx = chv.selIndex : if idx = invalid then idx = 0
        ids = chv.ids : if ids = invalid then ids = []
        if idx >= 0 and idx < ids.count() then
          sid = asString(ids[idx])
          chv.currentId = sid
          print ">>> MainScene: derived id from ids["; idx; "] -> "; sid
        else
          print ">>> MainScene: no id derivable (ids Len="; ids.count(); ", idx="; idx; ")"
        end if
      end if
      onChannelSelectionChanged()
      return true
    else
      return false  ' let ChannelsView handle navigation keys
    end if
  end if
  cv = m.top.findNode("catview")
  if cv <> invalid and cv.visible = true then
    if key = "OK" then
      idx = 0
      if cv.selIndex <> invalid then idx = cv.selIndex
      name = ""
      titles = cv.titles
      if titles <> invalid and idx >= 0 and idx < titles.count() then name = titles[idx]
      cid = invalid
      if m.catIds <> invalid and idx >= 0 and idx < m.catIds.count() then cid = m.catIds[idx]
      print ">>> MainScene: OK on category idx="; idx; ", name="; name
      showChannels(cid, name)
      return true
    else
      return false  ' let CategoriesView handle nav keys
    end if
  end if
  if key = "OK" then
    cv = m.top.findNode("catview")
    if cv <> invalid and cv.visible = true then
      idx = 0
      if cv.selIndex <> invalid then idx = cv.selIndex
      name = ""
      titles = cv.titles
      if titles <> invalid and idx >= 0 and idx < titles.count() then name = titles[idx]
      cid = invalid
      if m.catIds <> invalid and idx >= 0 and idx < m.catIds.count() then cid = m.catIds[idx]
      print ">>> MainScene: OK on category idx="; idx; ", name="; name
      showChannels(cid, name)
      return true
    end if
  end if

  if key = "down" then
    if m.selectedIndex < m.labels.count()-1 then
      m.selectedIndex = m.selectedIndex + 1
    else
      m.selectedIndex = 0
    end if
    setFocusbarToIndex(m.selectedIndex, true)
    PlayPreview()
      updateLabelStyles()
    return true
  else if key = "up" then
    if m.selectedIndex > 0 then
      m.selectedIndex = m.selectedIndex - 1
    else
      m.selectedIndex = m.labels.count()-1
    end if
    setFocusbarToIndex(m.selectedIndex, true)
    updateLabelStyles()
    return true
  else if key = "left" then
    cv = m.top.findNode("catview")
    if cv <> invalid and cv.visible = true then
      onCategoryChosen()
      chv = m.top.findNode("chanview")
      if chv <> invalid then
        chv.visible = true
        chv.setFocus(true)
      end if
      fr = m.top.findNode("chanSelFrame")
      if fr <> invalid then fr.visible = true
      return true
    end if
  end if
  if key = "back" then
    chv = m.top.findNode("chanview")
    if chv <> invalid and chv.hasFocus() then
    if key = "left" then
      cv = m.top.findNode("catview")
      if cv <> invalid then
        chv.setFocus(false)
        cv.visible = true
        cv.setFocus(true)
      end if
      fr = m.top.findNode("chanSelFrame")
      if fr <> invalid then fr.visible = false
      return true
    end if
      chv.visible = false
      m.top.findNode("catview").setFocus(true)
      return true
    end if
    cv = m.top.findNode("catview")
    if cv <> invalid and cv.visible = true then
      cv.setFocus(false)
      cv.visible = false
      mm = m.top.findNode("mainmenu")
      mm.visible = true
      m.top.setFocus(true)
      updateLabelStyles()
      return true
    end if
    return false
  else if key = "right" then
    cv = m.top.findNode("catview")
    chv = m.top.findNode("chanview")
    if cv <> invalid and cv.visible = true and chv <> invalid then
      cv.setFocus(false)
      chv.visible = true
      chv.setFocus(true)
      fr = m.top.findNode("chanSelFrame")
      if fr <> invalid then fr.visible = true
      return true
    end if
  else if key = "OK" then
    print ">>> OK on "; m.selectedIndex; " -> "; m.titles[m.selectedIndex]
    if m.titles[m.selectedIndex] = "Live TV" then
      showCategories()
      return true
    end if
    return true
  end if

  return false
end function

sub showCategories()
  mm = m.top.findNode("mainmenu")
  cv = m.top.findNode("catview")
  mm.visible = false : cv.visible = true : cv.setFocus(true)
  cv.unobserveField("selected") : cv.observeField("selected", "onCategoryChosen")
  print ">>> MainScene: observing CategoriesView.selected"
  cfg = loadConfig()
  url = invalid : if cfg <> invalid then url = cfg.categories_url
  print ">>> LiveTV: fetching categories from ", url
  fetch = m.top.findNode("fetchCats")
  fetch.unobserveField("status")
  fetch.observeField("status", "onCatsStatus")
  fetch.control = "STOP"
  fetch.status = "" : fetch.error = ""
  fetch.titles = [] : fetch.ids = [] : fetch.directUrls = []
  fetch.url = url
  fetch.control = "RUN"
end sub


function loadConfig() as object
  cf = ReadAsciiFile("pkg:/config.json")
  if cf = invalid then return invalid
  cfg = ParseJson(cf)
  return cfg
end function


sub onCatsStatus()
  fetch = m.top.findNode("fetchCats")
  cv = m.top.findNode("catview")
  if fetch.status = "ok" then
    cv.titles = fetch.titles
    m.catIds = fetch.ids

    m.catMapIndex = {} : m.catMapTitle = {}
    if fetch.titles <> invalid and fetch.ids <> invalid then
      for i = 0 to fetch.titles.count()-1
        if i < fetch.ids.count() then
          m.catMapIndex[toStr(i)] = toStr(fetch.ids[i])
          m.catMapTitle[fetch.titles[i]] = toStr(fetch.ids[i])
        end if
      end for
    end if
    print ">>> LiveTV: categories loaded: "; fetch.titles.count(); " items"
  else if fetch.status = "error" then
    print ">>> LiveTV: fetch error -> "; fetch.error
    ' Provide a small fallback list so UI still works
    cv.titles = ["All","News","Sports","Movies"]
  end if
end sub

sub onCategoryChosen()
  print ">>> onCategoryChosen: fired"
  cv = m.top.findNode("catview")
  sel = cv.selected
  if sel = invalid then return
  idx = sel.index : name = sel.text
  ' Find category id if available
  cid = invalid
  if m.catIds <> invalid and idx >= 0 and idx < m.catIds.count() then
    cid = m.catIds[idx]
  end if
  showChannels(cid, name)
end sub


function ToStr(x as dynamic) as string
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


function ToU32Str(x as dynamic) as string
  ' normalize number/string to unsigned 32-bit string
  t = type(x)
  if t = "Integer" or t = "roInt" or t = "LongInteger" then
    n = x
  else if t = "roString" or t = "String" then
    s = x
    while Len(s) > 0 and Left(s,1) = " "
      s = Mid(s,2)
    end while
    neg = false : if Len(s) > 0 and Left(s,1) = "-" then neg = true : s = Mid(s,2)
    n = 0 : for i = 1 to Len(s) : ch = Asc(Mid(s,i,1)) - 48 : n = n*10 + ch : end for
    if neg then n = 0 - n
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

sub showChannels(categoryId as dynamic, label as dynamic)
  chv = m.top.findNode("chanview")
  chv.visible = true
  chv.setFocus(true)
  ' Build URL
  cfg = loadConfig()
  base = invalid : if cfg <> invalid then base = cfg.base_url else base = "http://192.168.0.35/player_api.php"
  url = base + "?action=get_live_streams"
  if categoryId <> invalid then
  catParam = ToU32Str(categoryId)
' log once for debugging
print ">>> showChannels: category_id = "; toStr(categoryId)

  url = url + "&category_id=" + toStr(categoryId)
end if
  print ">>> Channels: fetching from [ " + url + " ]"
  fetch = m.top.findNode("fetchCh")
  fetch.unobserveField("status")
  fetch.observeField("status", "onChStatus")
  fetch.control = "STOP"
  fetch.status = "" : fetch.error = ""
  fetch.titles = [] : fetch.ids = [] : fetch.directUrls = []
  fetch.url = url
  fetch.control = "RUN"
end sub

sub onChStatus()
  fetch = m.top.findNode("fetchCh")
  chv = m.top.findNode("chanview")
  if fetch.status = "ok" then
    chv.titles = fetch.titles
    chv.ids = fetch.ids
    if fetch.directUrls <> invalid then chv.directUrls = fetch.directUrls else chv.directUrls = []
    print ">>> Channels loaded: "; fetch.titles.count(); " items"
  else
    print ">>> Channels fetch error -> "; fetch.error
    chv.titles = ["(no channels)"]
  end if
end sub

function manualReplace(hay as string, needle as string, with as string) as string
  if hay = invalid or needle = invalid then return hay
  p = Instr(1, hay, needle)
  if p <= 0 then return hay
  leftPart = ""
  if p > 1 then leftPart = Left(hay, p-1)
  rightStart = p + Len(needle)
  rightPart = ""
  if rightStart <= Len(hay) then rightPart = Mid(hay, rightStart)
  return leftPart + with + rightPart
end function

function asString(x as dynamic) as string
  t = type(x)
  if t = "roString" or t = "String" then return x
  if t = "Integer" or t = "roInt" then
    s = StrI(x)
  else
    s = "" + x
  end if
  while Len(s) > 0 and Left(s,1) = " "
    s = Mid(s,2)
  end while
  return s
end function

sub onChannelSelectionChanged()
  chv = m.top.findNode("chanview")
  vid = m.top.findNode("previewVideo")
  if chv = invalid or vid = invalid then return

  sid = chv.currentId
  surl = chv.currentUrl

  if (surl = invalid or surl = "") then
    si = invalid
    if chv.selIndex <> invalid then si = chv.selIndex
    if si = invalid and chv.selectedIndex <> invalid then si = chv.selectedIndex
    if si <> invalid and chv.directUrls <> invalid and si >= 0 and si < chv.directUrls.count() then
      surl = chv.directUrls[si]
    end if
  end if

  if surl = invalid or surl = "" then
    vid.visible = false
    return
  end if

  base = stripExt(surl)
  base = rstripSlash(base)

  m.previewAttempts = []

  ' as-is
  if LCase(Right(surl,5)) = ".m3u8" then
    m.previewAttempts.push({ url: surl, fmt: "hls" })
  else if LCase(Right(surl,3)) = ".ts" then
    m.previewAttempts.push({ url: surl, fmt: "mp2t" })
  else
    m.previewAttempts.push({ url: surl, fmt: "mp2t" })
  end if

  ' xtream-style live paths derived from base credentials
  x = makeXtreamLive(surl)
  if x <> invalid then
    m.previewAttempts.push({ url: x.hls, fmt: "hls" })
    m.previewAttempts.push({ url: x.ts, fmt: "mp2t" })
  end if

  ' generic guesses
  m.previewAttempts.push({ url: base + ".m3u8", fmt: "hls" })
  m.previewAttempts.push({ url: base + ".ts", fmt: "mp2t" })
  m.previewAttempts.push({ url: base + "/index.m3u8", fmt: "hls" })
  m.previewAttempts.push({ url: base + "/playlist.m3u8", fmt: "hls" })
  m.previewAttempts.push({ url: base + "/stream.m3u8", fmt: "hls" })

  m.previewAttemptIndex = 0
  m.previewWatchdogTicks = 0
  tryNextPreviewAttempt()
  ' update now playing if already playing
  vid = m.top.findNode("previewVideo") : lbl = m.top.findNode("nowPlayingLabel") : chv = m.top.findNode("chanview")
  if vid <> invalid and lbl <> invalid and chv <> invalid and LCase(vid.state) = "playing" then
    tarr = chv.titles : if tarr = invalid then tarr = []
    si = chv.selIndex : if si = invalid then si = 0
    tt = "" : if si >= 0 and si < tarr.count() then tt = tarr[si]
    lbl.text = tt : lbl.visible = true
  end if
end sub





function buildStreamUrl(streamId as dynamic) as string
  ' Prefer template in config
  cfg = loadConfig()
  if cfg <> invalid and cfg.stream_url_template <> invalid then
    tmpl = cfg.stream_url_template
    s = asString(streamId)
    ' Left-trim in case of StrI padding
    while Len(s) > 0 and Left(s,1) = " "
      s = Mid(s,2)
    end while
    return manualReplace(tmpl, "{id}", s)
  end if
  ' Fallback to base_url?action=stream&stream_id={id}
  base = invalid : if cfg <> invalid then base = cfg.base_url else base = "http://192.168.0.35/player_api.php"
  s = asString(streamId) : while Len(s) > 0 and Left(s,1) = " " : s = Mid(s,2) : end while
  return base + "?action=stream&stream_id=" + s
end function

sub onPreviewState()
  vid = m.top.findNode("previewVideo")
  if vid = invalid then return
  st = vid.state
  if st = invalid then return

  lbl = m.top.findNode("nowPlayingLabel")

  if lcase(st) = "playing" then
    chv = m.top.findNode("chanview")
    if chv <> invalid and lbl <> invalid then
      tarr = chv.titles : if tarr = invalid then tarr = []
      si = chv.selIndex : if si = invalid then si = 0
      tt = "" : if si >= 0 and si < tarr.count() then tt = tarr[si]
      lbl.text = tt
      lbl.visible = true
    end if
    fr = m.top.findNode("chanSelFrame")
    if fr <> invalid then fr.visible = true
  else if lcase(st) = "stopped" or lcase(st) = "error" or lcase(st) = "finished" then
    if lbl <> invalid then lbl.visible = false
  end if

  if lcase(st) = "error" then
    if m.previewAttempts <> invalid then
      m.previewAttemptIndex = m.previewAttemptIndex + 1
      tryNextPreviewAttempt()
    end if
    return
  end if
end sub






sub startPreviewAttempts(sid as dynamic)
  m.previewAttempts = []
  id = asString(sid)
  ' 1) TS /live/{id}.ts (mp2t)
  url1 = manualReplace("http://192.168.0.35/live/{id}.ts", "{id}", id)
  m.previewAttempts.push({ url: url1, fmt: "mp2t" })
  ' 2) TS /live/{id} (mp2t fallback)
  url2 = manualReplace("http://192.168.0.35/live/{id}", "{id}", id)
  m.previewAttempts.push({ url: url2, fmt: "mp2t" })
  m.previewAttemptIndex = 0
  tryNextPreviewAttempt()
end sub

function preflightPlayable(u as string, fmt as string) as boolean
  if u = invalid or u = "" then return false
  ut = CreateObject("roUrlTransfer")
  if ut = invalid then return true  ' cannot preflight here; allow attempt to proceed
  if ut.SetCertificatesFile <> invalid then ut.SetCertificatesFile("common:/certs/ca-bundle.crt")
  if ut.InitClientCertificates <> invalid then ut.InitClientCertificates()
  if ut.SetUrl <> invalid then ut.SetUrl(u)
  if ut.SetRequest <> invalid then ut.SetRequest("HEAD")
  if ut.setPort <> invalid then ut.setPort(CreateObject("roMessagePort"))
  if ut.setCertificatesDepth <> invalid then ut.setCertificatesDepth(3)
  if ut.enablePeerVerification <> invalid then ut.enablePeerVerification(true)
  if ut.RetainBodyOnError <> invalid then ut.RetainBodyOnError(true)
  if ut.SetMinimumTransferRate <> invalid then ut.SetMinimumTransferRate(1, 3)
  ok = false
  if ut.AsyncGetToString <> invalid then ok = ut.AsyncGetToString()

  t0 = createObject("roTimespan") : t0.mark()
  mp = invalid : if ut.getPort <> invalid then mp = ut.getPort()
  if mp <> invalid then
    while true
      msg = wait(300, mp)
      if type(msg) = "roUrlEvent" then exit while
      if t0.totalMilliseconds() > 3000 then exit while
    end while
  end if

  code = 0 : if ut.GetResponseCode <> invalid then code = ut.GetResponseCode()
  ctype = invalid : if ut.GetResponseHeader <> invalid then ctype = ut.GetResponseHeader("Content-Type")
  if code >= 300 and code < 400 and ut.GetResponseHeader <> invalid then
    loc = ut.GetResponseHeader("Location")
    if loc <> invalid and loc <> "" then
      ut2 = CreateObject("roUrlTransfer")
      if ut2 <> invalid then
        if ut2.SetCertificatesFile <> invalid then ut2.SetCertificatesFile("common:/certs/ca-bundle.crt")
        if ut2.InitClientCertificates <> invalid then ut2.InitClientCertificates()
        if ut2.SetUrl <> invalid then ut2.SetUrl(loc)
        if ut2.SetRequest <> invalid then ut2.SetRequest("HEAD")
        if ut2.setPort <> invalid then ut2.setPort(CreateObject("roMessagePort"))
        if ut2.enablePeerVerification <> invalid then ut2.enablePeerVerification(true)
        if ut2.AsyncGetToString <> invalid then ut2.AsyncGetToString()
        msg2 = wait(2000, ut2.getPort())
        if ut2.GetResponseCode <> invalid then code = ut2.GetResponseCode()
        if ut2.GetResponseHeader <> invalid then ctype = ut2.GetResponseHeader("Content-Type")
        u = loc
      end if
    end if
  end if

  if code < 200 or code >= 300 then return false
  if fmt <> invalid and LCase(fmt) = "hls" then
    if ctype <> invalid and Instr(1, LCase(ctype), "mpegurl") > 0 then return true
    if ctype = invalid or ctype = "" then return true
    return false
  else
    if ctype <> invalid and (Instr(1, LCase(ctype), "video/mp2t") > 0 or Instr(1, LCase(ctype), "video/") > 0) then return true
    if ctype = invalid or ctype = "" then return true
    return false
  end if
end function

sub tryNextPreviewAttempt()

  if m.previewAttemptIndex >= m.previewAttempts.count() then
    return
  end if

  att = m.previewAttempts[m.previewAttemptIndex]
  vid = m.top.findNode("previewVideo")
  if vid = invalid then return

  ' tiny log: attempt # and host
  p = Instr(1, att.url, "://")
  h = ""
  if p > 0 then
    p2 = Instr(p+3, att.url, "/")
    if p2 > 0 then h = Mid(att.url, p+3, p2 - (p+3))
  end if
  print ">>> Attempt #"; (m.previewAttemptIndex + 1); " host="; h

  ' quick preflight to avoid long buffering on blocked/invalid URLs

  cn = createObject("roSGNode", "ContentNode")
  cn.url = att.url
  if att.fmt <> invalid and lcase(att.fmt) = "hls" then
      cn.streamformat = "hls"
  end if

  vid.visible = true
  vid.control = "stop"
  vid.content = cn
  vid.control = "play"

  if m.prevWatch <> invalid then
    m.prevWatch.control = "stop"
    m.prevWatch.control = "start"
  end if

end sub







sub onPreviewWatchdog()
  vid = m.top.findNode("previewVideo")
  if vid = invalid then return
  st = vid.state
  if st = "playing" then
    print ">>> Preview watchdog: already playing"
    return
  end if

  if st = "stopped" or st = "finished" or st = "error" then
    print ">>> Preview watchdog: state="; st; " advancing to next attempt"
    if m.previewAttempts <> invalid then
      m.previewAttemptIndex = m.previewAttemptIndex + 1
      tryNextPreviewAttempt()
    end if
  else
    print ">>> Preview watchdog: still "; st; ", giving it more time"
    t = m.top.findNode("previewTimer")
    if t <> invalid then
      t.duration = 5.0
      t.control = "start"
    end if
  end if
end sub



function guessFormatFromUrl(u as string) as string
  if u = invalid or u = "" then return "mp2t"
  lu = LCase(u)
  if Right(lu, 5) = ".m3u8" then return "hls"
  if Right(lu, 3) = ".ts" then return "mp2t"
  if Instr(1, lu, "m3u8") > 0 then return "hls"
  return "mp2t"
end function

sub startPreviewAttemptsDirect(sid as dynamic, direct as string)
    m.previewAttempts = []

    ' figure base direct
    if direct = invalid or direct = "" then
        cv = m.top.findNode("chanview")
        if cv <> invalid and cv.currentUrl <> invalid and cv.currentUrl <> "" then
            direct = cv.currentUrl
        end if
    end if
    if direct = invalid or direct = "" then
        if sid <> invalid and sid <> "" then
            direct = "http://192.168.0.35/live/" + sid.toStr() + ".ts"
        end if
    end if
    if direct = invalid or direct = "" then return

    ' normalize to base without ext
    base = stripExt(direct)

    ' Attempt #1: HLS directly
    m.previewAttempts.push({ url: base + ".m3u8", fmt: "hls" })

    ' Attempt #2: TS directly
    m.previewAttempts.push({ url: base + ".ts", fmt: "mp2t" })

    m.previewAttemptIndex = 0
    m.previewWatchdogTicks = 0
    tryNextPreviewAttempt()
end sub





function replaceAll(s as string, find as string, repl as string) as string
  if s = invalid then return ""
  res = s : p = Instr(1, res, find)
  while p > 0
    Left = Left(res, p - 1)
    Right = Mid(res, p + Len(find))
    res = Left + repl + Right
    p = Instr(p + Len(repl), res, find)
  end while
  return res
end function



function b64url(s as string) as string
  ba = CreateObject("roByteArray")
  ba.FromAsciiString(s)
  enc = ba.ToBase64String()
  enc = replaceAll(enc, "+", "-")
  enc = replaceAll(enc, "/", "_")
  while Len(enc) > 0 and Right(enc, 1) = "="
    enc = Left(enc, Len(enc)-1)
  end while
  return enc
end function



function ensureLive(u as string) as string
  if u = invalid or u = "" then return ""
  hostSep = Instr(1, u, "://")
  if hostSep = 0 then return u
  pathStart = Instr(hostSep + 3, u, "/")
  if pathStart = 0 then return u
  baseHost = Left(u, pathStart)       ' includes trailing /
  basePath = Mid(u, pathStart + 1)    ' no leading /
  if Instr(1, LCase("/" + basePath), "/live/") > 0 then
    return baseHost + basePath
  else
    return baseHost + "live/" + basePath
  end if
end function



function stripQuery(u as string) as string
    if u = invalid then return ""
    parts = u.Split("?")
    if parts = invalid or parts.count() = 0 then return u
    return parts[0]
end function




function makeXtreamLive(u as string) as object
  ' Returns {hls: string, ts: string} or invalid if not xtream-like
  if u = invalid or u = "" then return invalid
  ' Expect ...://host[:port]/USER/PASS/ID[...]
  re = CreateObject("roRegex", "^https?://[^/]+/([^/]+)/([^/]+)/([0-9]+)", "i")
  m = re.Match(u)
  if m = invalid or m.Count() < 4 then return invalid
  usr = m[1] : pwd = m[2] : sid = m[3]
  ' Extract scheme://host[:port]
  p = Instr(1, u, "://")
  if p = 0 then return invalid
  p2 = Instr(p+3, u, "/")
  if p2 = 0 then return invalid
  base = Left(u, p2) ' includes trailing /
  res = { hls: base + "live/" + usr + "/" + pwd + "/" + sid + ".m3u8", ts: base + "live/" + usr + "/" + pwd + "/" + sid + ".ts" }
  return res
end function
function rstripSlash(u as string) as string
  if u = invalid then return ""
  while Len(u) > 0 and Right(u,1) = "/"
    u = Left(u, Len(u)-1)
  end while
  return u
end function
function stripExt(u as string) as string
    base = stripQuery(u)
    re1 = createObject("roRegex", "\.m3u8$", "i")
    re2 = createObject("roRegex", "\.ts$", "i")
    s = re1.Replace(base, "")
    s = re2.Replace(s, "")
    return s
end function


function buildProxyBundle(direct as string) as dynamic
    base = stripExt(direct)
    ts = base + ".ts"
    hls = base + ".m3u8"
    return { ts: ts, hls: hls }
end function




sub PlayPreview()
    chv = m.top.findNode("chanview")
    vid = m.top.findNode("previewVideo")
    if chv = invalid or vid = invalid then return

    sid = chv.currentId
    surl = chv.currentUrl
    di = []
    if chv.directUrls <> invalid then di = chv.directUrls

    si = chv.selectedIndex
    if si = invalid and chv.selIndex <> invalid then si = chv.selIndex
    if si = invalid then si = -1
    if si >= 0 and di <> invalid and si < di.count() and di[si] <> "" then
        surl = di[si]
    end if

    base = "http://192.168.0.35"
    if (surl = invalid or surl = "") and sid <> invalid and sid <> "" then
        surl = base + "/live/" + sid.toStr() + ".ts"
    end if

    if surl = invalid or surl = "" then return

    ' reset and play
    vid.control = "stop"
    vid.content = { url: surl }
    vid.control = "play"
end sub







sub nudgeListFocusbars(offsetX as integer)
  cv = m.top.findNode("catview")
  if cv <> invalid then
    fb = cv.findNode("focusbar")
    if fb <> invalid and fb.translation <> invalid then
      t = fb.translation
      if t.count() >= 2 then
        fb.translation = [ t[0] + offsetX, t[1] ]
      end if
    end if
  end if

  ch = m.top.findNode("chanview")
  if ch <> invalid then
    fb2 = ch.findNode("focusbar")
    if fb2 <> invalid and fb2.translation <> invalid then
      t2 = fb2.translation
      if t2.count() >= 2 then
        fb2.translation = [ t2[0] + offsetX, t2[1] ]
      end if
    end if
  end if
end sub
