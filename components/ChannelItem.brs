sub init()
  print ">>> ChannelItem.init"
  m.art = m.top.findNode("art")
  m.label = m.top.findNode("label")
end sub

sub onContent()
  c = m.top.itemContent
  print ">>> ChannelItem.onContent() called. has content? "; (c <> invalid)
  if c <> invalid
    uri = invalid
    if c.poster      <> invalid then uri = c.poster
    if c.HDPosterUrl <> invalid then uri = c.HDPosterUrl
    if uri <> invalid then
      print ">>> ChannelItem: setting poster uri = "; uri
      m.art.uri = uri
    else
      print ">>> ChannelItem: no poster uri provided"
    end if
    if c.title <> invalid then m.label.text = c.title
  end if
end sub
