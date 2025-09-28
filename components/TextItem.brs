sub init()
  ' no-op
end sub

sub onContent()
  c = m.top.itemContent
  if c <> invalid then
    txt = ""
    if c.title <> invalid then txt = c.title
    if c.text  <> invalid then txt = c.text
    m.top.findNode("label").text = txt
  end if
end sub
