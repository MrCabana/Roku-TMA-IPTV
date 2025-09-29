function asString(x as dynamic) as string
  t = type(x)
  if t = "roString" or t = "String" then return x
  if t = "Integer" or t = "roInt" then
    s = StrI(x)
  else
    ' last resort: concatenate to coerce
    s = "" + x
  end if
  ' left-trim any leading spaces from StrI
  while Len(s) > 0 and Left(s,1) = " "
    s = Mid(s,2)
  end while
  return s
end function

sub init()
  m.focusbar = m.top.findNode("focusbar")
  m.listContainer = m.top.findNode("listContainer")
  m.labels = []
  m.selectedIndex = 0

  m.baseX = 388
  m.baseY = 120
  m.rowStep = 64
  m.visibleRows = 9
  m.textNudge = 2
  m.topIndex = 0

  for i = 0 to m.visibleRows - 1
    lbl = createObject("roSGNode", "Label")
    lbl.width = 600 : lbl.height = 52
    lbl.vertAlign = "center"
    lbl.translation = [ m.baseX, m.baseY + i*m.rowStep + m.textNudge ]
    lbl.text = ""
    lbl.color = "0xCCCCCCFF"
    m.labels.push(lbl)
    m.listContainer.appendChild(lbl)
  end for

  m.anim = createObject("roSGNode", "Animation")
  m.anim.duration = 0.12
  m.moveInterp = createObject("roSGNode", "Vector2DFieldInterpolator")
  m.moveInterp.fieldToInterp = "focusbar.translation"
  m.moveInterp.key = [0.0, 1.0]
  m.anim.appendChild(m.moveInterp)
  m.top.appendChild(m.anim)
end sub

sub onTitles()
  m.selectedIndex = 0
  m.topIndex = 0
  m.top.selIndex = 0
  updateCurrentId()
  renderWindow()
  updateFocus(false)
end sub

sub updateCurrentId()
  ids = m.top.ids : if ids = invalid then ids = []
  if m.selectedIndex >= 0 and m.selectedIndex < ids.count() then
    m.top.currentId = asString(ids[m.selectedIndex])
  else
    m.top.currentId = ""
  end if
end sub

sub renderWindow()
  titles = m.top.titles : if titles = invalid then titles = []
  for i = 0 to m.visibleRows - 1
    idx = m.topIndex + i
    lbl = m.labels[i]
    if idx >= 0 and idx < titles.count() then
      lbl.visible = true
      lbl.text = titles[idx]
      if idx = m.selectedIndex then
        lbl.color = "0xFFFFFFFF"
      else
        lbl.color = "0xCCCCCCFF"
      end if
    else
      lbl.visible = false
      lbl.text = ""
    end if
  end for
end sub

sub ensureVisible()
  if m.selectedIndex < m.topIndex then
    m.topIndex = m.selectedIndex
    renderWindow()
  else if m.selectedIndex >= m.topIndex + m.visibleRows then
    m.topIndex = m.selectedIndex - (m.visibleRows - 1)
    renderWindow()
  end if
end sub

sub updateFocus(doAnimate as boolean)
  rowInWindow = m.selectedIndex - m.topIndex
  if rowInWindow < 0 then rowInWindow = 0
  if rowInWindow > m.visibleRows-1 then rowInWindow = m.visibleRows-1
  yTarget = m.baseY + rowInWindow * m.rowStep
  x = 360
  if doAnimate then
    cur = m.focusbar.translation
    if cur = invalid then cur = [x, yTarget]
    m.moveInterp.keyValue = [ cur, [x, yTarget] ]
    m.anim.control = "start"
  else
    m.focusbar.translation = [x, yTarget]
  end if
end sub

function onKeyEvent(key as String, press as Boolean) as Boolean
  if not press then return false
  titles = m.top.titles : if titles = invalid then titles = []

  if key = "down" then
    if titles.count() = 0 then return true
    if m.selectedIndex < titles.count()-1 then
      m.selectedIndex = m.selectedIndex + 1
    else
      m.selectedIndex = 0
      m.topIndex = 0
    end if
    m.top.selIndex = m.selectedIndex
    updateCurrentId()
    ensureVisible() : renderWindow() : updateFocus(true)
    return true

  else if key = "up" then
    if titles.count() = 0 then return true
    if m.selectedIndex > 0 then
      m.selectedIndex = m.selectedIndex - 1
    else
      m.selectedIndex = titles.count()-1
      m.topIndex = m.selectedIndex - (m.visibleRows - 1)
      if m.topIndex < 0 then m.topIndex = 0
    end if
    m.top.selIndex = m.selectedIndex
    updateCurrentId()
    ensureVisible() : renderWindow() : updateFocus(true)
    return true

  else if key = "OK" then
    return false  ' bubble to parent (MainScene handles preview)
  else if key = "back" then
    return false
  end if

  return false
end function

sub bumpPlayPulse()
  p = m.top.playPulse
  if p = invalid then p = 0
  m.top.playPulse = p + 1
end sub


sub updateCurrentSelection()
  idx = m.selectedIndex
  ids = m.top.ids : if ids = invalid then ids = []
  urls = m.top.directUrls : if urls = invalid then urls = []
  if idx >= 0 and idx < ids.count() then
    m.top.currentId = asString(ids[idx])
  else
    m.top.currentId = ""
  end if
  if idx >= 0 and idx < urls.count() then
    m.top.currentUrl = urls[idx]
  else
    m.top.currentUrl = ""
  end if
  updateSelFrame()
  updateSelFrame()
  updateSelFrame()
end sub
' move selection frame to match selected index
sub updateSelFrame()
  fr = m.top.findNode("chanSelFrame")
  rl = m.rowlist
  if fr = invalid or rl = invalid then return
  ' base top-left matches RowList translation minus 2px margin
  base = rl.translation
  y = base[1] + (m.selectedIndex * 40) - 2
  x = base[0] - 2
  fr.translation = [x, y]
  fr.visible = true
end sub



sub onFocusChanged()
  fr = m.top.findNode("chanSelFrame")
  if fr = invalid then return
  if m.top.hasFocus() then
    updateSelFrame()
    fr.visible = true
  else
    fr.visible = false
  end if
end sub
