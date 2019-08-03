 //progress bar ticks (25fps)
const frameTimeout = 1/25.0*1000;

window.addEventListener("load",function(){
  //init dynamic menu
  var dynamic_menu = new Menu();
  var wprompt = new WPrompt();
  var requestmgr = new RequestManager();
  var announcemgr = new AnnounceManager();
  var radio_display = new RadioDisplay();
  var aengine = new AudioEngine();

  requestmgr.onResponse = function(id,ok){ $.post("http://vrp/request",JSON.stringify({act: "response", id: id, ok: ok})); }
  wprompt.onClose = function(){ $.post("http://vrp/prompt",JSON.stringify({act: "close", result: wprompt.result})); }
  dynamic_menu.onValid = function(option,mod){ $.post("http://vrp/menu",JSON.stringify({act: "valid", option: option, mod: mod})); }
  var select_event = false;
  dynamic_menu.onSelect = function(option){ 
    if(select_event){
      $.post("http://vrp/menu",JSON.stringify({act: "select", option: option}));
    }
  }

  //init
  $.post("http://vrp/init",""); 

  let pbars = {}
  var divs = {}

  function tickBar(force){
    let t = setTimeout(() => {
      clearTimeout(t);
      for(let k in pbars){
        pbars[k].frame();
      }
      tickBar();
    }, force ? 0 : frameTimeout);
  }
  tickBar(true);

  //MESSAGES
  window.addEventListener("message",function(evt){ //lua actions
    var data = evt.data;

    if(data.act == "cfg"){
      cfg = data.cfg;
    }
    else if(data.act == "set_visible"){
      if(data.flag)
        $(document.body).show();
      else
        $(document.body).hide();
    }
    else if(data.act == "open_menu"){ //OPEN DYNAMIC MENU
      select_event = data.menudata.select_event;
      dynamic_menu.open(data.menudata);
    }
    else if(data.act == "close_menu"){ //CLOSE MENU
      dynamic_menu.close();
    }
    else if(data.act == "set_menu_select_event"){
      select_event = data.select_event;
    }
    else if(data.act == "update_menu_option"){
      dynamic_menu.updateOption(data.index, data.title, data.description);
    }
    // PROGRESS BAR
    else if(data.act == "set_pbar"){
      let pbar = pbars[data.pbar.name];
      if(pbar)
        pbar.removeDom();

      pbars[data.pbar.name] = new ProgressBar(data.pbar);
      pbars[data.pbar.name].addDom();
    }
    else if(data.act == "set_pbar_val"){
      let pbar = pbars[data.name];
      if(pbar)
        pbar.setValue(data.value);
    }
    else if(data.act == "set_pbar_text"){
      let pbar = pbars[data.name];
      if(pbar)
        pbar.setText(data.text);
    }
    else if(data.act == "remove_pbar"){
      let pbar = pbars[data.name]
      if(pbar){
        pbar.removeDom();
        delete pbars[data.name];
      }
    }
    // PROMPT 
    else if(data.act == "prompt"){
      wprompt.open(data.title,data.text);
    }
    // REQUEST
    else if(data.act == "request"){
      requestmgr.addRequest(data.id,data.text,data.time);
    }
    // ANNOUNCE
    else if(data.act == "announce"){
      announcemgr.addAnnounce(data.background,data.content);
    }
    // DIV
    else if(data.act == "set_div"){
      var div = divs[data.name];
      if(div)
        div.removeDom();

      divs[data.name] = new Div(data)
      divs[data.name].addDom();
    }
    else if(data.act == "set_div_css"){
      var div = divs[data.name];
      if(div)
        div.setCss(data.css);
    }
    else if(data.act == "set_div_content"){
      var div = divs[data.name];
      if(div)
        div.setContent(data.content);
    }
    else if(data.act == "div_execjs"){
      var div = divs[data.name];
      if(div)
        div.executeJS(data.js);
    }
    else if(data.act == "remove_div"){
      var div = divs[data.name];
      if(div)
        div.removeDom();

      delete divs[data.name];
    }
    // AUDIO
    else if(data.act == "play_audio_source")
      aengine.playAudioSource(data);
    else if(data.act == "set_audio_source")
      aengine.setAudioSource(data);
    else if(data.act == "remove_audio_source")
      aengine.removeAudioSource(data);
    else if(data.act == "audio_listener")
      aengine.setListenerData(data);
    //VoIP
    else if(data.act == "configure_voip")
      aengine.configureVoIP(data);
    else if(data.act == "connect_voice")
      aengine.connectVoice(data);
    else if(data.act == "disconnect_voice")
      aengine.disconnectVoice(data);
    else if(data.act == "set_voice_state")
      aengine.setVoiceState(data);
    else if(data.act == "configure_voice")
      aengine.configureVoice(data);
    else if(data.act == "set_voice_indicator")
      aengine.setVoiceIndicator(data);
    else if(data.act == "set_player_positions")
      aengine.setPlayerPositions(data);
    // Radio
    else if(data.act == "set_radio_player_speaking_state")
      radio_display.setPlayerSpeakingState(data);
    // CONTROLS
    else if(data.act == "event"){ //EVENTS
      if(data.event == "UP"){
        if(!wprompt.opened)
          dynamic_menu.moveUp();
      }
      else if(data.event == "DOWN"){
        if(!wprompt.opened)
          dynamic_menu.moveDown();
      }
      else if(data.event == "LEFT"){
        if(!wprompt.opened)
          dynamic_menu.valid(-1);
      }
      else if(data.event == "RIGHT"){
        if(!wprompt.opened)
          dynamic_menu.valid(1);
      }
      else if(data.event == "SELECT"){
        if(!wprompt.opened)
          dynamic_menu.valid(0);
      }
      else if(data.event == "CANCEL"){
        if(wprompt.opened)
          wprompt.close();
      }
      else if(data.event == "F5"){
        requestmgr.respond(true);
      }
      else if(data.event == "F6"){
        requestmgr.respond(false);
      }
    }
  });
});
