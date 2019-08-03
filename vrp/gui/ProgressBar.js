let anchors = {
  center: [],
  minimap: [],
  botright: []
};
const baseWidth = 1920;
const baseHeight = 1080;
let ratio;

function setStyles([anchor_name, anchor_index, anchor]){
  switch (anchor_name) {
    case "minimap":
      let width = Math.round(cfg.anchor_minimap_width*ratio.width/anchor.length); //divide horizontal map space by number of pbars
      let barWidth = anchor_index > 0 ? width - Math.round(2*ratio.width) : width;

      //set size
      this.div.style.width = this.div_label.style.width = `${barWidth}px`;
      this.div_inner.style.height = this.div.style.height = this.div_label.style.height = `${Math.round(9*ratio.height)}px`;
      this.div_label.style.lineHeight = this.div_label.style.height;

      //set label font size
      this.div_label.style.fontSize = "0.8em";

      //set position
      this.div.style.left = `${Math.round(cfg.anchor_minimap_left*ratio.width)+anchor_index*barWidth}px`;
      this.div.style.top = `${Math.round(document.body.offsetHeight-cfg.anchor_minimap_bottom*ratio.height)}px`;

      this.div.style.borderBottom = `${Math.round(5*ratio.height)}px solid rgba(0,0,0,0.6)`;
      if (anchor_index > 0)
        this.div.style.borderLeft = `${Math.round(4*ratio.width)}px solid rgba(0,0,0,0.6)`;
      break;
    case "botright":
      //set size
      this.div.style.width = this.div_label.style.width = `${Math.round(200*ratio.width)}px`;
      this.div_inner.style.height = this.div.style.height = this.div_label.style.height = `${Math.round(20*ratio.height)}px`;
      this.div_label.style.lineHeight = this.div_label.style.height;

      //set label font size
      this.div_label.style.fontSize = "1em";

      //set position
      this.div.style.left = `${document.body.offsetWidth-this.div.offsetWidth-Math.round(100*ratio.width)}px`;
      this.div.style.top = `${document.body.offsetHeight-Math.round(120*ratio.height)-anchor_index*Math.round(22*ratio.height)}px`;
      break;
    case "center":
      //set size
      this.div.style.width = this.div_label.style.width = `${500*ratio.width}px`;
      this.div_inner.style.height = this.div.style.height = this.div_label.style.height = `${20*ratio.height}px`;
      this.div_label.style.lineHeight = this.div_label.style.height;

      //set label font size
      this.div_label.style.fontSize = "1em";

      //set position
      this.div.style.left = `${Math.round(document.body.offsetWidth/2-this.div.offsetWidth/2)}px`;
      this.div.style.top = `${Math.round(document.body.offsetHeight-Math.round(80*ratio.height)-anchor_index*Math.round(22*ratio.height))}px`;
      break;
  }
}

class ProgressBar{
  constructor(data){
    this.data = data;
    this.value = data.value;
    this.disp_value = data.value;

    this.div = document.createElement("div");
    this.div.classList.add("progressbar");

    this.div_label = document.createElement("div");
    this.div_label.classList.add("label");
    this.div.appendChild(this.div_label);

    this.setText(data.text);

    this.div_inner = document.createElement("div");
    this.div_inner.classList.add("inner");
    this.div.appendChild(this.div_inner);

    this.div_inner.style.zIndex = 1;
    this.div_label.style.zIndex = 2;

    this.div.style.backgroundColor = `rgba(${data.r},${data.g},${data.b},0.3)`;
    this.div_inner.style.backgroundColor = `rgba(${data.r},${data.g},${data.b},0.7)`;
    
    ratio = {
      height: document.body.clientHeight/baseHeight,
      width: document.body.clientWidth/baseWidth,
    }
  }

  setValue(val){
    this.value = val;
  }

  setText(text){
    this.div_label.innerHTML = text;
  }

  frame(){
    //update display in function of pbar anchor
    let anchor_name = this.data.anchor;
    let anchor = anchors[this.data.anchor];
    if (anchor) {
      let anchor_index = anchor.indexOf(this);
      if (anchor.includes(this)) {
        setStyles.call(this, [anchor_name, anchor_index, anchor]);
      }
    }

    //smooth display value
    this.disp_value += (this.value - this.disp_value)*0.2;

    //update inner bar
    this.div_inner.style.width = `${Math.round(this.div.offsetWidth*this.disp_value)}px`;
  }

  addDom(){
    document.body.appendChild(this.div);

    //add to anchor
    let anchor = anchors[this.data.anchor];
    if(anchor)
      anchor.push(this);
  }

  removeDom(){
    document.body.removeChild(this.div);

    //remove from anchors
    let anchor = anchors[this.data.anchor];
    if (anchor) {
      let i = anchor.indexOf(this);
      if (i > -1) {
        anchor.splice(i,1);
      }
    }
  }
}

// PROGRESS BAR DYNAMIC CLASS

defineDynamicClass("dprogressbar", (el) => {
  let value = parseFloat(el.dataset.value); //value: 0 -> 1
  let color = el.dataset.color; //color: css color
  let bgcolor = el.dataset.bgcolor; //bgcolor: css color
  let content = el.innerHTML;
  el.innerHTML = "";

  let inner = document.createElement("div");
  inner.classList.add("inner");
  el.appendChild(inner);

  let label = document.createElement("div");
  label.classList.add("label");
  label.innerHTML = content;
  el.appendChild(label);

  el.style.backgroundColor = bgcolor;
  inner.style.backgroundColor = color;

  //set label font size
  label.style.fontSize = "1em";

  inner.style.width = `${Math.round(value*100)}%`;
})
