sub main()
  print ">>> main(): start"
  screen = CreateObject("roSGScreen")
  port = CreateObject("roMessagePort")
  screen.setMessagePort(port)

  screen.Show()
  print ">>> main(): screen shown (pre)"

  scene = screen.CreateScene("MainScene")
  scene.setFocus(true)
  print ">>> main(): scene created & focus set"

  while true
    msg = wait(0, port)
    if type(msg) = "roSGScreenEvent" and msg.isScreenClosed() then
      print ">>> main(): screen closed"
      return
    end if
  end while
end sub
