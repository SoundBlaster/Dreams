/* Browser interaction. Geometry and exported outlines live in stroke-editor-model.js. */
'use strict';
const M = globalThis.StrokeEditorModel;
const el = id => document.getElementById(id);
const STORAGE = 'dreams.stroke-editor.v1';
let project = M.copy(seed), selected = 4, strokeIndex = 0, segmentIndex = 0;
let history = [], future = [], rangeBefore = null, drag = null;
let checkpointParent = null, checkpointHead = null, checkpointBusy = false, checkpointAvailable = false;
const currentGlyph = () => project.glyphs[selected];
const currentStroke = () => currentGlyph().strokes[strokeIndex];
const currentSegment = () => currentStroke().segments[segmentIndex];
function status(message, error=false) {el('status').textContent=message;el('status').dataset.error=String(error);}
function snapshot() {return JSON.stringify({project,selected,strokeIndex,segmentIndex,checkpointParent});}
function store() {
  try {localStorage.setItem(STORAGE,JSON.stringify(project));localStorage.setItem(STORAGE+'.parent',checkpointParent || '');status('Сохранено в браузере · JSON сохраняет переносимую копию');}
  catch {status('Браузер не сохранил правки. Скачай JSON, чтобы их не потерять.',true);}
}
function remember(before) {
  if (before===snapshot()) return;
  history.push(before);if(history.length>40)history.shift();future=[];store();
  el('undo').disabled=!history.length;el('redo').disabled=true;
}
function edit(fn) {
  finishRange();const before=snapshot();
  try {fn();M.validate(project);remember(before);render();}
  catch(error) {restore(before);status(error.message,true);}
}
function restore(saved) {
  const state=JSON.parse(saved);project=state.project;selected=state.selected;
  strokeIndex=state.strokeIndex;segmentIndex=state.segmentIndex;render();
  checkpointParent=state.checkpointParent ?? null;
}
function finishRange() {if(rangeBefore){const before=rangeBefore;rangeBefore=null;remember(before);}}
function options(id,count,prefix,selectedValue) {
  const select=el(id);select.replaceChildren();
  for(let i=0;i<count;i++){const o=document.createElement('option');o.value=i;o.textContent=`${prefix} ${i+1}`;select.append(o);}
  select.value=selectedValue;
}
function renderAlphabet() {
  el('alphabet').replaceChildren();
  project.glyphs.forEach((glyph,index)=>{
    const button=document.createElement('button');button.textContent=glyph.character;
    button.setAttribute('aria-pressed',String(index===selected));
    button.setAttribute('aria-label',`Знак ${glyph.character}`);
    button.onclick=()=>{finishRange();selected=index;strokeIndex=segmentIndex=0;render();};
    el('alphabet').append(button);
  });
}
function renderControls() {
  const g=currentGlyph(), s=currentStroke(), part=currentSegment();
  el('glyphTitle').textContent=g.character;
  el('selection').textContent=`Штрих ${strokeIndex+1} / ${g.strokes.length} · участок ${segmentIndex+1} / ${s.segments.length}`;
  options('stroke',g.strokes.length,'Штрих',strokeIndex);options('segment',s.segments.length,'Участок',segmentIndex);
  for(const id of ['width','startWidth','endWidth']){el(id).value=s[id];el(id+'Value').textContent=s[id].toFixed(1);}
  el('startWidth').max=el('endWidth').max=s.width;
  el('peak').value=Math.round(s.peak*100);el('peakValue').textContent=Math.round(s.peak*100)+'%';
  el('stretch').value=Math.round(g.stretch*100);el('stretchValue').textContent=Math.round(g.stretch*100)+'%';
  el('mirror').checked=g.mirror;
  for(const k of ['start','end']){el(k+'Cap').value=s[k+'Cap'];el(k+'Width').disabled=s[k+'Cap']==='sharp';}
  for(const kind of ['line','arc'])el(kind).setAttribute('aria-pressed',String(part.kind===kind));
  for(const k of ['start','mid','end'])for(let axis=0;axis<2;axis++) {
    el(k+axis).value=part[k][axis].toFixed(2);
    el(k+axis).disabled=part.kind==='line' && k==='mid';
  }
  el('removeStroke').disabled=g.strokes.length===1;el('addStroke').disabled=g.strokes.length>=24;
  el('addSegment').disabled=s.segments.length>=32;
  el('removeSegment').disabled=s.segments.length===1;
  el('undo').disabled=!history.length;el('redo').disabled=!future.length;
  el('resetGlyph').disabled=!seed.glyphs.some(g=>g.character===currentGlyph().character);
}
function paint() {
  const g=currentGlyph(), s=currentStroke(), part=currentSegment();
  const paths=g.strokes.map(st=>M.outline(st));
  const ink=paths.map(d=>`<path d="${d}"/>`).join('');
  const guides=g.strokes.map((st,i)=>`<path d="${M.centerPath(st)}" fill="none" stroke="${i===strokeIndex?'#ce8231':'#8faaa1'}" stroke-width="${i===strokeIndex?.55:.25}" stroke-dasharray="${i===strokeIndex?'':'1 1'}" data-stroke="${i}"/>`).join('');
  const handles=['start','mid','end'].map((key,i)=>{
    const [x,y]=part[key], colors=['#267955','#cb8731','#79529f'];
    if(key==='mid' && part.kind==='line')return '';
    return `<circle cx="${x}" cy="${y}" r="1.8" fill="${colors[i]}" data-key="${key}"/>`;
  }).join('');
  const allPoints=s.segments.map((seg,i)=>`<circle cx="${seg.start[0]}" cy="${seg.start[1]}" r=".8" fill="#afc0b3" data-segment="${i}"/>`).join('');
  el('stage').innerHTML=`<defs><pattern id="grid" width="10.9" height="10.9" patternUnits="userSpaceOnUse"><path d="M10.9 0H0V10.9" fill="none" stroke="#dae0d3" stroke-width=".16"/></pattern></defs><rect width="109" height="109" fill="url(#grid)"/><path d="M54.5 0V109M0 54.5H109" stroke="#b9caba" stroke-width=".25"/><g id="geometry" transform="${M.transform(g)}"><g fill="#173b2e" fill-rule="nonzero">${ink}</g><g class="guides">${guides}${allPoints}${handles}</g></g>`;
  el('stage').classList.toggle('hide-handles',!el('handles').checked);
  el('sizes').innerHTML=[20,26,32,48].map(size=>`<div class="sample"><svg width="${size}" height="${size}" viewBox="0 0 109 109" aria-label="${size} пикселей"><g fill="#41d88a" transform="${M.transform(g)}">${ink}</g></svg><span>${size}px</span></div>`).join('');
  const points=Array.from({length:101},(_,i)=>`${10+i*2.4},${55-M.widthAt(s,i/100)/16*45}`).join(' ');
  el('widthGraph').innerHTML=`<path d="M10 10V55H250" fill="none" stroke="#c0cab8"/><polyline points="${points}" stroke="#277758" stroke-width="2" fill="none"/><circle cx="${10+s.peak*240}" cy="${55-s.width/16*45}" r="3" fill="#cb8731"/>`;
}
function render(){el('credit').textContent=project.attribution;renderAlphabet();renderControls();paint();}
function blankStroke() {return {segments:[{kind:'line',start:[35,30],mid:[50,50],end:[65,70]}],width:7.5,peak:.5,startWidth:5,endWidth:5,startCap:'flat',endCap:'flat'};}
function download(name,data,type) {
  const url=URL.createObjectURL(new Blob([data],{type}));
  const a=document.createElement('a');a.href=url;a.download=name;a.click();setTimeout(()=>URL.revokeObjectURL(url),1000);
}
for(const [key,label] of [['start','Начало'],['mid','Середина'],['end','Конец']]) {
  for(let axis=0;axis<2;axis++) {
    const wrapper=document.createElement('label');wrapper.textContent=`${label} ${axis?'Y':'X'}`;
    const input=document.createElement('input');input.type='number';input.min=0;input.max=109;input.step=.1;input.id=key+axis;
    input.setAttribute('aria-label',`${label} ${axis?'Y':'X'}`);
    input.onchange=()=>edit(()=>{
      const value=Number(input.value);
      if(!Number.isFinite(value) || input.value==='')throw new Error('Введи числовую координату');
      const p=[...currentSegment()[key]];p[axis]=value;M.setPoint(currentStroke(),segmentIndex,key,p);
    });wrapper.append(input);el('coordinates').append(wrapper);
  }
}
for(const id of ['width','peak','startWidth','endWidth','stretch']) {
  el(id).oninput=()=>{
    if(!rangeBefore)rangeBefore=snapshot();
    const s=currentStroke(), value=Number(el(id).value);
    if(id==='stretch')currentGlyph().stretch=value/100;
    else s[id]=id==='peak'?value/100:value;
    s.startWidth=Math.min(s.startWidth,s.width);s.endWidth=Math.min(s.endWidth,s.width);
    renderControls();paint();
  };
  el(id).onchange=finishRange;
}
for(const id of ['startCap','endCap'])el(id).onchange=()=>{const value=el(id).value;edit(()=>{currentStroke()[id]=value;});};
el('mirror').onchange=()=>{const value=el('mirror').checked;edit(()=>{currentGlyph().mirror=value;});};
el('handles').onchange=paint;
el('stroke').onchange=()=>{finishRange();strokeIndex=Number(el('stroke').value);segmentIndex=0;render();};
el('segment').onchange=()=>{finishRange();segmentIndex=Number(el('segment').value);render();};
for(const kind of ['line','arc'])el(kind).onclick=()=>edit(()=>{
  const part=currentSegment();part.kind=kind;
  if(kind==='line')part.mid=M.mix(part.start,part.end,.5);
});
el('addSegment').onclick=()=>edit(()=>{
  const s=currentStroke(), start=[...s.segments.at(-1).end];
  const end=[Math.min(100,start[0]+12),Math.min(100,start[1]+12)];
  if(M.mix(start,end,.5).every((v,i)=>v===start[i]))end[0]=Math.max(0,start[0]-12);
  s.segments.push({kind:'line',start,mid:M.mix(start,end,.5),end});segmentIndex=s.segments.length-1;
});
el('addStroke').onclick=()=>edit(()=>{currentGlyph().strokes.push(blankStroke());strokeIndex=currentGlyph().strokes.length-1;segmentIndex=0;});
el('removeSegment').onclick=()=>edit(()=>{
  const s=currentStroke();if(s.segments.length===1)return;
  s.segments.splice(segmentIndex,1);
  if(segmentIndex>0 && segmentIndex<s.segments.length)M.setPoint(s,segmentIndex,'start',s.segments[segmentIndex-1].end);
  segmentIndex=Math.min(segmentIndex,s.segments.length-1);
});
el('removeStroke').onclick=()=>edit(()=>{if(currentGlyph().strokes.length>1)currentGlyph().strokes.splice(strokeIndex,1);strokeIndex=segmentIndex=0;});
el('resetGlyph').onclick=()=>edit(()=>{project.glyphs[selected]=M.copy(seed.glyphs.find(g=>g.character===currentGlyph().character));strokeIndex=segmentIndex=0;});
el('addGlyph').onclick=()=>edit(()=>{
  const character=el('newCharacter').value.trim();
  if([...character].length!==1)throw new Error('Введи один символ');
  if(project.glyphs.some(g=>g.character===character))throw new Error('Этот знак уже есть в списке');
  project.glyphs.push({character,stretch:.85,mirror:false,strokes:[blankStroke()]});
  selected=project.glyphs.length-1;strokeIndex=segmentIndex=0;el('newCharacter').value='';
});
el('undo').onclick=()=>{finishRange();if(!history.length)return;future.push(snapshot());restore(history.pop());store();};
el('redo').onclick=()=>{finishRange();if(!future.length)return;history.push(snapshot());restore(future.pop());store();};
el('save').onclick=()=>{finishRange();download('dreams-strokes.json',JSON.stringify(project,null,2),'application/json');status('JSON подготовлен к скачиванию');};
el('export').onclick=()=>{finishRange();download(`uni${currentGlyph().character.codePointAt(0).toString(16).toUpperCase()}.svg`,M.svg(currentGlyph(),project.attribution),'image/svg+xml');status('SVG текущего знака подготовлен к скачиванию');};
el('import').onclick=()=>el('projectFile').click();
function loadProject(text) {
  if(text.length>2_000_000)throw new Error('JSON больше 2 МБ');
  const loaded=M.validate(JSON.parse(text));
  edit(()=>{project=loaded;selected=strokeIndex=segmentIndex=0;checkpointParent=null;});
  el('credit').textContent=project.attribution;
}
el('pasteProject').onclick=()=>{el('pasteError').textContent='';el('pasteDialog').showModal();};
el('cancelPaste').onclick=()=>el('pasteDialog').close();
el('applyPaste').onclick=()=>{
  try{loadProject(el('pasteText').value);el('pasteDialog').close();}
  catch(error){el('pasteError').textContent=error.message;}
};
el('projectFile').onchange=async()=>{
  const file=el('projectFile').files[0];if(!file)return;
  try {
    if(file.size>2_000_000)throw new Error('JSON больше 2 МБ');
    loadProject(await file.text());
  } catch(error){status('Не удалось открыть: '+error.message,true);}
  finally{el('projectFile').value='';}
};
async function checkpointRequest(path, options) {
  const response=await fetch(path,options);
  if(!response.ok){
    let message='База недоступна. Запусти make glyph-editor вместо обычного HTTP-сервера.';
    try {message=(await response.json()).error || message;} catch {}
    throw new Error(message);
  }
  return response.json();
}
async function refreshCheckpoints() {
  const data=await checkpointRequest('/api/checkpoints');
  checkpointAvailable=true;
  checkpointHead=data.head;
  if(checkpointParent && !data.checkpoints.some(record=>record.id===checkpointParent))checkpointParent=null;
  const list=el('checkpointList'), selectedID=list.value;
  list.replaceChildren();
  for(const record of [...data.checkpoints].reverse()) {
    const option=document.createElement('option');option.value=record.id;
    const changed=record.changedGlyphs.length>8 ? `${record.changedGlyphs.length} знаков`
      : record.changedGlyphs.length ? record.changedGlyphs.join(' ') : 'без изменения глифов';
    option.textContent=`${record.label} · ${new Date(record.createdAt).toLocaleString()} · ${changed}`;
    list.append(option);
  }
  if(data.checkpoints.some(record=>record.id===selectedID))list.value=selectedID;
  el('checkpointSave').disabled=false;
  el('checkpointRestore').disabled=!data.checkpoints.length;
  el('checkpointStatus').textContent=`На диске: ${data.checkpoints.length} checkpoints. Восстановление не удаляет историю.`;
}
async function checkpointAction(action) {
  if(checkpointBusy)return;
  checkpointBusy=true;
  for(const id of ['checkpointSave','checkpointRestore','checkpointRefresh'])el(id).disabled=true;
  try {await action();}
  catch(error){el('checkpointStatus').textContent=error.message;}
  finally {
    checkpointBusy=false;el('checkpointRefresh').disabled=false;
    el('checkpointSave').disabled=!checkpointAvailable;
    el('checkpointRestore').disabled=!el('checkpointList').children.length;
  }
}
el('checkpointName').addEventListener('keydown',event=>{
  if(event.key!=='Tab'||event.shiftKey||event.metaKey||event.ctrlKey||event.altKey||event.isComposing)return;
  const input=el('checkpointName'), character=currentGlyph().character;
  if(input.value.includes(character))return;
  const value=`${character} · ${input.value.trimStart()}`;
  if(value.length>input.maxLength)return;
  event.preventDefault();input.value=value;input.setSelectionRange(value.length,value.length);
});
el('checkpointRefresh').onclick=()=>checkpointAction(refreshCheckpoints);
el('checkpointSave').onclick=()=>checkpointAction(async()=>{
  finishRange();
  const label=el('checkpointName').value.trim();
  if(!label)throw new Error('Дай checkpoint короткое название.');
  const record=await checkpointRequest('/api/checkpoints',{method:'POST',headers:{'Content-Type':'application/json'},
    body:JSON.stringify({project,label,expectedHead:checkpointHead,parent:checkpointParent})});
  checkpointParent=record.id;
  store();
  await refreshCheckpoints();
  el('checkpointList').value=record.id;
  el('checkpointStatus').textContent=`Checkpoint «${record.label}» сохранён на диске. Для истории в Git закоммить stroke-library.`;
});
el('checkpointRestore').onclick=()=>checkpointAction(async()=>{
  const id=el('checkpointList').value;
  const loaded=M.validate(await checkpointRequest('/api/checkpoints/'+encodeURIComponent(id)));
  edit(()=>{project=loaded;selected=Math.min(selected,project.glyphs.length-1);strokeIndex=segmentIndex=0;checkpointParent=id;});
  el('checkpointStatus').textContent='Версия восстановлена в редакторе. Undo возвращает предыдущую форму; база не изменена.';
});
if(typeof fetch==='function')el('checkpointRefresh').onclick();
el('stage').addEventListener('pointerdown',event=>{
  const key=event.target.dataset.key;
  if(!key) {
    if(event.target.dataset.segment!==undefined){segmentIndex=Number(event.target.dataset.segment);renderControls();paint();}
    else if(event.target.dataset.stroke!==undefined){strokeIndex=Number(event.target.dataset.stroke);segmentIndex=0;renderControls();paint();}
    return;
  }
  finishRange();drag={key,before:snapshot(),pointer:event.pointerId};el('stage').setPointerCapture(event.pointerId);event.preventDefault();
});
el('stage').addEventListener('pointermove',event=>{
  if(!drag || event.pointerId!==drag.pointer)return;
  const p=new DOMPoint(event.clientX,event.clientY).matrixTransform(el('geometry').getScreenCTM().inverse());
  M.setPoint(currentStroke(),segmentIndex,drag.key,[p.x,p.y]);renderControls();paint();
});
function endDrag(event) {
  if(!drag || event.pointerId!==drag.pointer)return;
  const before=drag.before;drag=null;
  try{M.validate(project);remember(before);renderControls();}
  catch(error){restore(before);status(error.message,true);}
}
el('stage').addEventListener('pointerup',endDrag);el('stage').addEventListener('pointercancel',endDrag);
document.addEventListener('keydown',event=>{
  if((event.metaKey||event.ctrlKey)&&event.key.toLowerCase()==='z'&&!['INPUT','SELECT','TEXTAREA'].includes(event.target.tagName)){
    event.preventDefault();el(event.shiftKey?'redo':'undo').click();
  }
});
window.addEventListener('pagehide',()=>{finishRange();if(drag)store();});
try {const saved=localStorage.getItem(STORAGE);if(saved){project=M.validate(JSON.parse(saved));checkpointParent=localStorage.getItem(STORAGE+'.parent') || null;selected=Math.min(4,project.glyphs.length-1);status('Восстановлены сохранённые правки');}}
catch {status('Сохранённый проект не прочитан. Исходные знаки загружены; старая копия не перезаписана.',true);}
el('credit').textContent=project.attribution;
M.validate(project);render();
