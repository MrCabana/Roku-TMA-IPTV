sub init()
  m.focusbar = m.top.findNode("focusbar")
  m.listContainer = m.top.findNode("listContainer")
  m.labels = []
  m.selectedIndex = 0

  

  ' Enlarge the top "TMA IPTV" header in CategoriesView using bundled TTF
  hd = m.top.findNode("header")
  if hd <> invalid then
    f = CreateObject("roSGNode","Font")
    f.uri = "pkg:/fonts/DejaVuSans-Bold.ttf"
    f.size = 48
    hd.font = f
  end if
' Layout constants
  m.baseX = 80
  m.baseY = 120          ' first row Y (below header)
  m.rowStep = 64
  m.textNudge = 2         ' 48px height + 12px gap
  m.visibleRows = 9      ' rows visible without overlapping header
  m.topIndex = 0         ' first visible item index

  ' Create fixed pool of label nodes = visibleRows
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

  ' Animation for focus bar (no easingFunction to avoid warnings)
  m.anim = createObject("roSGNode", "Animation")
  m.anim.duration = 0.12
  m.moveInterp = createObject("roSGNode", "Vector2DFieldInterpolator")
  m.moveInterp.fieldToInterp = "focusbar.translation"
  m.moveInterp.key = [0.0, 1.0]
  m.anim.appendChild(m.moveInterp)
  m.top.appendChild(m.anim)

  m.top.setFocus(true)
end sub

sub onTitles()
  m.selectedIndex = 0
  m.topIndex = 0
  renderWindow()
  updateFocus(true)
end sub

sub renderWindow()
  titles = m.top.titles
  if titles = invalid then titles = []

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
  ' Adjust topIndex so selectedIndex is within the window
  if m.selectedIndex < m.topIndex then
    m.topIndex = m.selectedIndex
    renderWindow()
  else if m.selectedIndex >= m.topIndex + m.visibleRows then
    m.topIndex = m.selectedIndex - (m.visibleRows - 1)
    renderWindow()
  end if
end sub

sub updateFocus(doAnimate as boolean)
  ' Focus bar moves within the fixed window; rows themselves never move
  rowInWindow = m.selectedIndex - m.topIndex
  if rowInWindow < 0 then rowInWindow = 0
  if rowInWindow > m.visibleRows-1 then rowInWindow = m.visibleRows-1
  yTarget = m.baseY + rowInWindow * m.rowStep
  x = 52
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
  titles = m.top.titles
  if titles = invalid or titles.count() = 0 then return false

  if key = "down" then
    if m.selectedIndex < titles.count()-1 then
      m.selectedIndex = m.selectedIndex + 1
      m.top.selIndex = m.selectedIndex
    else
      m.selectedIndex = 0
      m.topIndex = 0
      m.top.selIndex = m.selectedIndex
    end if
    ensureVisible()
    renderWindow()
    updateFocus(true)
    return true
  else if key = "up" then
    if m.selectedIndex > 0 then
      m.selectedIndex = m.selectedIndex - 1
      m.top.selIndex = m.selectedIndex
    else
      ' wrap to last safely
      titles = m.top.titles
      if titles = invalid then titles = []
      if titles.count() > 0 then
        m.selectedIndex = titles.count() - 1
      else
        m.selectedIndex = 0
      end if
      m.topIndex = m.selectedIndex - (m.visibleRows - 1)
      if m.topIndex < 0 then m.topIndex = 0
    end if
    ensureVisible()
    renderWindow()
    updateFocus(true)
    return true
  else if key = "OK" or key = "right" or key = "left" then
  if press and m.top.onSelect <> invalid and m.top.onSelect.callback <> invalid then
    m.top.onSelect.callback(m.selectedIndex, titles[m.selectedIndex])
    return true
  end if
  return false

  else if key = "back" then
    return false
  end if

  return false
end function
