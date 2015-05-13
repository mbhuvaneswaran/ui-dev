
page_offset = (selector, recursive=true) ->
  dom_page_offset = (node) ->
    pos =
      left: node?.offsetLeft or 0
      top:  node?.offsetTop  or 0

    if node?.parentElement and recursive
      parent_pos = dom_page_offset node.parentElement
      pos.left += parent_pos.left
      pos.top  += parent_pos.top

    pos

  if typeof selector is 'string'
    dom_page_offset elem(selector)[0]
  else if selector.length
    dom_page_offset selector[0]
  else
    dom_page_offset selector
