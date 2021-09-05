local list_url = 'https://raw.githubusercontent.com/socantre/temp/main/master_list.json'

---

function onClick_toggleUi()
  if UI.getAttribute('load_ui', 'active') == 'false' then
    UI.show('load_ui')
  else
    UI.hide('load_ui')
  end
end

function onClick_refreshList()
  WebRequest.get(list_url, completed_list_update)
end

function onClick_select(player, url)
  WebRequest.get(url, complete_obj_download)
end

function onClick_load()
  UI.show('progress_display')
  UI.hide('load_button')
end

function onClick_cancel()
  UI.show('load_button')
  UI.hide('progress_display')
end

---

function find_tag_with_id(ui, id)
  for i,obj in ipairs(ui) do
    if obj.attributes and obj.attributes.id and obj.attributes.id == id then
      return obj
    end
    if obj.children then
      local result = find_tag_with_id(obj.children, id)
      if result then return result end
    end
  end
  return nil
end

function update_list(objects)
  local ui = UI.getXmlTable()
  local update_height = find_tag_with_id(ui, 'ui_update_height')
  local update_children = find_tag_with_id(update_height.children, 'ui_update_point')

  update_children.children = {}

  for i,v in ipairs(objects) do
    table.insert(update_children.children,
      {
        tag = 'Text',
        value = v.name,
        attributes = { onClick = 'onClick_select('..v.url..')' }
      }
    )
  end

  update_height.attributes.height = #(update_children.children) * 24
  UI.setXmlTable(ui)
end

function complete_obj_download(request)
  assert(request.is_done)
  if request.is_error then
    print('error: ' .. request.error)
  else
    spawnObjectJSON({json = request.text})
    print('Object loaded.')
  end
end

function completed_list_update(request)
  assert(request.is_done)
  if request.is_error then
    print('error: ' .. request.error)
  else
    local json_response = JSON.decode(request.text)
    if not json_response.objects then
      print('error: missing objects')
    else
      update_list(json_response.objects)
      print('Loadable Items list udpated.')
    end
  end
  current_request = nil
end

---

function onLoad()
  addHotkey("Farmer", setFarmer2, false)
end


function setFarmer2(playerColor, hoverObject, c, d, e, f)
  if hoverObject then
    local p = hoverObject.getPosition()
    hoverObject.setPositionSmooth({p.x, p.y + 1, p.z}, false, true)
    hoverObject.setRotationSmooth({90,0,0}, false, true)
  end
end