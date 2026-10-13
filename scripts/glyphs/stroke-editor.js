/* Browser interaction. Geometry and exported outlines live in stroke-editor-model.js. */
'use strict';
const M = globalThis.StrokeEditorModel;
const el = id => document.getElementById(id);
const STORAGE = 'dreams.stroke-editor.v1';
let project = M.copy(seed), selected = 4, strokeIndex = 0, segmentIndex = 0;
let history = [], future = [], rangeBefore = null, drag = null;
let segmentInsertPreview = null, moveGlyphMode = false, layerSignature = '';
let references = [], referenceSelected = -1, referenceDrag = null;
const REFERENCE_STORAGE = STORAGE+'.references';
const GUIDE_STORAGE=STORAGE+'.user-guides';
let userGuides=[],guidePresets=[],userGuideSelected=-1,guideDrag=null;
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
function selectLayer(stroke,segment=0) {
  finishRange();strokeIndex=stroke;segmentIndex=segment;segmentInsertPreview=null;renderControls();paint();
  el('strokeLayers').children[stroke]?.children[1]?.children[segment]?.children[0]?.focus?.();
}
function renderLayers() {
  const signature=JSON.stringify([selected,strokeIndex,segmentIndex,currentGlyph().strokes.map(s=>s.segments.map(p=>p.kind))]);
  if(signature===layerSignature)return;layerSignature=signature;
  const list=el('strokeLayers');list.replaceChildren();
  currentGlyph().strokes.forEach((stroke,i)=>{
    const row=document.createElement('li'),button=document.createElement('button'),children=document.createElement('ul');
    button.textContent=`Штрих ${i+1} · ${stroke.segments.length} уч.`;
    button.setAttribute('aria-label',`Выбрать штрих ${i+1}`);button.setAttribute('aria-pressed',String(i===strokeIndex));
    button.onclick=()=>selectLayer(i);row.append(button);
    stroke.segments.forEach((segment,j)=>{
      const item=document.createElement('li'),part=document.createElement('button');
      part.className='section-row';part.textContent=`${segment.kind==='line'?'╱':'⌒'} Участок ${j+1} · ${segment.kind==='line'?'прямая':'дуга'}`;
      part.setAttribute('aria-label',`Штрих ${i+1}, участок ${j+1}`);part.setAttribute('aria-pressed',String(i===strokeIndex&&j===segmentIndex));
      part.onclick=()=>selectLayer(i,j);item.append(part);children.append(item);
    });row.append(children);list.append(row);
  });
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
  renderLayers();
  el('glyphX').value=(g.placement?.x||0).toFixed(2);el('glyphY').value=(g.placement?.y||0).toFixed(2);
  el('editPoints').setAttribute('aria-pressed',String(!moveGlyphMode));el('moveGlyph').setAttribute('aria-pressed',String(moveGlyphMode));
  el('startWidth').max=el('endWidth').max=s.width;
  for(const id of ['width','startWidth','endWidth']){el(id).value=s[id];el(id+'Value').textContent=s[id].toFixed(1);}
  el('peak').value=Math.round(s.peak*100);el('peakValue').textContent=Math.round(s.peak*100)+'%';
  el('stretch').value=Math.round(g.stretch*100);el('stretchValue').textContent=Math.round(g.stretch*100)+'%';
  el('placementStatus').textContent=g.placement?`Масштаб всего глифа: ${(g.placement.scale*100).toFixed(1)}% · включая толщину`:'';
  el('resetPlacement').disabled=!g.placement;
  el('strokeJoin').value=s.join||'legacy';
  el('mirror').checked=g.mirror;el('preserveWidth').checked=!!g.preserveWidth;
  for(const k of ['start','end']){el(k+'Cap').value=s[k+'Cap'];el(k+'Width').disabled=s[k+'Cap']==='sharp';}
  for(const kind of ['line','arc'])el(kind).setAttribute('aria-pressed',String(part.kind===kind));
  for(const k of ['start','mid','end'])for(let axis=0;axis<2;axis++) {
    el(k+axis).value=part[k][axis].toFixed(2);
    el(k+axis).disabled=part.kind==='line' && k==='mid';
  }
  el('removeStroke').disabled=g.strokes.length===1;el('addStroke').disabled=g.strokes.length>=24;
  for(const id of ['addSegmentBefore','addSegmentAfter'])el(id).disabled=s.segments.length>=32;
  el('removeSegment').disabled=s.segments.length===1;
  el('undo').disabled=!history.length;el('redo').disabled=!future.length;
  el('resetGlyph').disabled=!seed.glyphs.some(g=>g.character===currentGlyph().character);
}
function paintMetricGuides(g,paths) {
  const enabled=el('metricGuides').checked;
  el('stage').setAttribute('viewBox',enabled?'-49 -18 210 153':el('showRulers').checked?'-8 -8 125 125':'0 0 109 109');
  el('metricsLegend').textContent=enabled?`Метрики экспорта · UPM ${fontMetrics.upm} · line height ${M.metricGuides(fontMetrics).lineHeight} · пунктирная рамка: bounding box контура. X-height — ориентир для латиницы.`:'';
  if(!enabled)return '';
  const m=M.metricGuides(fontMetrics),lines=[
    [m.ascent,'Ascent',fontMetrics.ascent,'#7a899c','guideLimits'],
    [m.cap,'Cap / body',fontMetrics.capHeight,'#528267','guideCap'],
    [m.xHeight,'Meanline',fontMetrics.xHeight,'#8f83a2','guideMeanline'],
    [m.baseline,'Baseline',0,'#b46e35','guideBaseline'],
    [m.descent,'Descent',-fontMetrics.descent,'#7a899c','guideLimits']].filter(line=>el(line[4]).checked);
  const bounds=M.glyphBounds(g,paths),x=bounds.left,y=bounds.top,width=bounds.width,height=bounds.height;
  return `<g pointer-events="none" font-family="system-ui" font-size="3" fill="#647468"><defs><marker id="metricArrow" viewBox="0 0 10 10" refX="5" refY="5" markerWidth="4" markerHeight="4" orient="auto-start-reverse"><path d="M0 0L10 5L0 10Z" fill="#7a899c"/></marker></defs><rect x="${m.left}" y="${m.ascent}" width="${m.right-m.left}" height="${m.descent-m.ascent}" fill="none" stroke="#a8b2ad" stroke-width=".2"/>${lines.map(([y,label,value,color])=>`<path d="M${m.left} ${y}H${m.right}" stroke="${color}" stroke-width="${label==='Baseline'?.45:.25}" stroke-dasharray="${label==='Meanline'?'1 1':''}"/><text x="-47" y="${y-1}" fill="${color}">${label} ${value}</text>`).join('')}<circle cx="${m.left}" cy="${m.baseline}" r=".8" fill="#b46e35"/>${el('guideBounds').checked?`<rect x="${x}" y="${y}" width="${width}" height="${height}" fill="none" stroke="#857b44" stroke-width=".25" stroke-dasharray="1 1"/>`: ''}${el('guideCell').checked?`<path d="M${m.right+4} ${m.ascent}V${m.descent}" stroke="#7a899c" stroke-width=".3" marker-start="url(#metricArrow)" marker-end="url(#metricArrow)"/><text transform="translate(${m.right+8} ${(m.ascent+m.descent)/2}) rotate(90)" text-anchor="middle">Line height ${m.lineHeight}</text><path d="M${m.left} ${m.descent+6}H${m.right}" stroke="#7a899c" stroke-width=".3" marker-start="url(#metricArrow)" marker-end="url(#metricArrow)"/><text x="${(m.left+m.right)/2}" y="${m.descent+10}" text-anchor="middle">Advance ${fontMetrics.advance} · leading ${fontMetrics.lineGap||0}</text>`:''}</g>`;
}
function paint() {
  const g=currentGlyph(), s=currentStroke(), part=currentSegment();
  const paths=g.strokes.map(st=>M.outline(st,g.preserveWidth?g.stretch:1));
  const ink=paths.map(d=>`<path d="${d}"/>`).join('');
  const guides=g.strokes.map((st,i)=>`<path d="${M.centerPath(st)}" fill="none" stroke="${i===strokeIndex?'#ce8231':'#8faaa1'}" stroke-width="${i===strokeIndex?.55:.25}" stroke-dasharray="${i===strokeIndex?'':'1 1'}" data-stroke="${i}"/>`).join('');
  const handles=['start','mid','end'].map((key,i)=>{
    const [x,y]=part[key], colors=['#267955','#cb8731','#79529f'];
    if(key==='mid' && part.kind==='line')return '';
    return `<circle cx="${x}" cy="${y}" r="1.8" fill="${colors[i]}" data-key="${key}"/>`;
  }).join('');
  const join=segmentInsertPreview ? part[segmentInsertPreview==='before'?'start':'end'] : null;
  const insertionHint=join?`<circle cx="${join[0]}" cy="${join[1]}" r="3" fill="none" stroke="#b17f24" stroke-width=".65" pointer-events="none"/>`:'';
  const allPoints=s.segments.map((seg,i)=>`<circle cx="${seg.start[0]}" cy="${seg.start[1]}" r=".8" fill="#afc0b3" data-segment="${i}"/>`).join('');
  el('stage').innerHTML=`<defs><pattern id="grid" width="10.9" height="10.9" patternUnits="userSpaceOnUse"><path d="M10.9 0H0V10.9" fill="none" stroke="#dae0d3" stroke-width=".16"/></pattern></defs><rect width="109" height="109" fill="url(#grid)"/><path d="M54.5 0V109M0 54.5H109" stroke="#b9caba" stroke-width=".25"/>${referenceMarkup()}${userGuideMarkup(true)}<g id="geometry" transform="${M.transform(g)}"><g fill="#173b2e" fill-rule="nonzero">${ink}</g><g class="guides">${guides}${allPoints}${handles}</g>${insertionHint}</g>${referenceFrame()}${paintMetricGuides(g,paths)}${rulerMarkup()}${userGuideMarkup(false)}`;
  el('stage').classList.toggle('hide-handles',!el('handles').checked||moveGlyphMode);
  el('stage').classList.toggle('move-glyph',moveGlyphMode);
  el('sizes').innerHTML=[20,26,32,48].map(size=>`<div class="sample"><svg width="${size}" height="${size}" viewBox="0 0 109 109" aria-label="${size} пикселей"><g fill="#41d88a" transform="${M.transform(g)}">${ink}</g></svg><span>${size}px</span></div>`).join('');
  const points=Array.from({length:101},(_,i)=>`${10+i*2.4},${55-M.widthAt(s,i/100)/16*45}`).join(' ');
  el('widthGraph').innerHTML=`<path d="M10 10V55H250" fill="none" stroke="#c0cab8"/><polyline points="${points}" stroke="#277758" stroke-width="2" fill="none"/><circle cx="${10+s.peak*240}" cy="${55-s.width/16*45}" r="3" fill="#cb8731"/>`;
}
function render(){renderUserGuides();renderReferences();el('credit').textContent=project.attribution;renderAlphabet();renderControls();paint();}
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
el('preserveWidth').onchange=()=>{const value=el('preserveWidth').checked;edit(()=>{currentGlyph().preserveWidth=value;});};
el('strokeJoin').onchange=()=>{const join=el('strokeJoin').value;edit(()=>{if(join==='legacy')delete currentStroke().join;else currentStroke().join=join;});};
el('fitGlyph').onclick=()=>edit(()=>M.fitGlyph(currentGlyph(),fontMetrics));
el('resetPlacement').onclick=()=>edit(()=>{delete currentGlyph().placement;});
el('handles').onchange=paint;
el('showRulers').onchange=()=>{paint();storeUserGuides();};
for(const id of ['metricGuides','guideBaseline','guideCap','guideMeanline','guideLimits','guideBounds','guideCell'])el(id).onchange=()=>{paint();try{localStorage.setItem(STORAGE+'.'+id,String(el(id).checked));}catch{}};
for(const [id,mode] of [['editPoints',false],['moveGlyph',true]])el(id).onclick=()=>{finishRange();moveGlyphMode=mode;renderControls();paint();};
for(const [id,axis] of [['glyphX','x'],['glyphY','y']])el(id).onchange=()=>{
  const value=Number(el(id).value),empty=el(id).value==='';
  edit(()=>{if(empty||!Number.isFinite(value))throw new Error('Введи числовой сдвиг');
    const g=currentGlyph();g.placement={scale:1,x:0,y:0,...g.placement,[axis]:value};});
};
for(const kind of ['line','arc'])el(kind).onclick=()=>edit(()=>{
  const part=currentSegment();part.kind=kind;
  if(kind==='line')part.mid=M.mix(part.start,part.end,.5);
});
for(const [id,side] of [['addSegmentBefore','before'],['addSegmentAfter','after']]) {
  const button=el(id);
  button.onclick=()=>edit(()=>{segmentInsertPreview=null;segmentIndex=M.insertSegment(currentStroke(),segmentIndex,side);});
  button.onmouseenter=button.onfocus=()=>{if(!button.disabled){segmentInsertPreview=side;paint();}};
  button.onmouseleave=button.onblur=()=>{segmentInsertPreview=null;paint();};
}
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

function selectedReference() {return references[referenceSelected];}
function validateReferences(data) {
  if(!data||data.schema!=='dreams.references/v1'||!Array.isArray(data.images)||data.images.length>24)throw new Error('Неверный файл референсов (максимум 24 изображения).');
  for(const r of data.images) {
    if(!r||typeof r.character!=='string'||[...r.character].length!==1||typeof r.name!=='string'||r.name.length>200||
      typeof r.src!=='string'||!/^data:image\/(png|jpeg|webp);base64,[A-Za-z0-9+/=]+$/.test(r.src)||
      !['x','y','width','height','opacity'].every(k=>Number.isFinite(r[k]))||
      Math.abs(r.x)>1000||Math.abs(r.y)>1000||r.width<1||r.width>1000||r.height<1||r.height>1000||r.opacity<0||r.opacity>1||
      !['flipX','flipY','locked','ratio'].every(k=>typeof r[k]==='boolean'))throw new Error('Повреждённые параметры изображения.');
  }
  return data.images;
}
function storeReferences() {
  try{localStorage.setItem(REFERENCE_STORAGE,JSON.stringify({schema:'dreams.references/v1',images:references}));el('referenceStatus').textContent='Референсы сохранены в браузере. Для переносимой копии сохрани референсы JSON.';}
  catch{el('referenceStatus').textContent='Не хватает места в браузере. Сохрани референсы JSON, чтобы не потерять изображения.';}
}
function validateGuideState(value) {
  const lines=items=>Array.isArray(items)&&items.length<=64&&items.every(g=>g&&['h','v'].includes(g.axis)&&typeof g.position==='number'&&Number.isFinite(g.position)&&g.position>=0&&g.position<=109);
  if(!value||value.schema!=='dreams.guides/v1'||typeof value.visible!=='boolean'||!lines(value.lines)||!Array.isArray(value.presets)||value.presets.length>32||!value.presets.every(p=>p&&typeof p.name==='string'&&p.name.trim()&&p.name.length<=80&&lines(p.lines))||new Set(value.presets.map(p=>p.name)).size!==value.presets.length)throw new Error('Некорректные пресеты направляющих');
  return value;
}
function storeUserGuides() {
  try{localStorage.setItem(GUIDE_STORAGE,JSON.stringify({schema:'dreams.guides/v1',visible:el('showRulers').checked,lines:userGuides,presets:guidePresets}));}
  catch{el('userGuideStatus').textContent='Браузер не сохранил направляющие: недостаточно места.';}
}
function loadUserGuides() {
  try{const raw=localStorage.getItem(GUIDE_STORAGE);if(raw){const saved=validateGuideState(JSON.parse(raw));userGuides=saved.lines;guidePresets=saved.presets;el('showRulers').checked=saved.visible;userGuideSelected=userGuides.length?0:-1;}}
  catch{el('userGuideStatus').textContent='Сохранённые направляющие не прочитаны. Старая копия не перезаписана.';}
}
function renderUserGuides() {
  const list=el('userGuideList'),preset=el('guidePresetList'),previous=preset.value;list.replaceChildren();preset.replaceChildren();
  userGuides.forEach((g,i)=>{const option=document.createElement('option');option.value=i;option.textContent=`${g.axis==='h'?'Горизонталь Y':'Вертикаль X'} · ${g.position.toFixed(1)}`;list.append(option);});list.value=userGuideSelected;
  const selected=userGuides[userGuideSelected];el('userGuidePosition').value=selected?selected.position.toFixed(2):'';
  for(const id of ['userGuidePosition','guideRemove','userGuideList'])el(id).disabled=!selected;
  guidePresets.forEach((p,i)=>{const option=document.createElement('option');option.value=i;option.textContent=p.name;preset.append(option);});
  preset.value=previous!==''&&guidePresets[Number(previous)]?previous:guidePresets.length?'0':'';
  for(const id of ['guidePresetApply','guidePresetRemove','guidePresetList'])el(id).disabled=!guidePresets.length;
  el('guideAddH').disabled=el('guideAddV').disabled=userGuides.length>=64;
}
function rulerMarkup() {
  if(!el('showRulers').checked)return '';
  const ticks=Array.from({length:22},(_,i)=>i*5).concat(109);
  return `<g font-family="system-ui" font-size="2" fill="#63766b"><rect x="0" y="-6" width="109" height="6" fill="#e5e9df" data-ruler="x" style="cursor:crosshair"/><rect x="-6" y="0" width="6" height="109" fill="#e5e9df" data-ruler="y" style="cursor:crosshair"/><g pointer-events="none">${ticks.map(n=>`<path d="M${n} 0v-${n%10===0?2:1}M0 ${n}h-${n%10===0?2:1}" stroke="#89998c" stroke-width=".15"/>${n%10===0?`<text x="${n+.5}" y="-3">${n}</text><text x="-5.7" y="${n+2.5}">${n}</text>`:''}`).join('')}</g></g>`;
}
function userGuideMarkup(hits) {
  if(!el('showRulers').checked)return '';
  return userGuides.map((g,i)=>{
    const p=g.position,d=g.axis==='h'?`M0 ${p}H109`:`M${p} 0V109`;
    if(hits)return `<path d="${d}" fill="none" stroke="transparent" stroke-width="2" data-user-guide="${i}" style="cursor:${g.axis==='h'?'ns':'ew'}-resize"/>`;
    const marker=g.axis==='h'?`-5,${p-1.5} 0,${p} -5,${p+1.5}`:`${p-1.5},-5 ${p},0 ${p+1.5},-5`;
    return `<path d="${d}" fill="none" stroke="${i===userGuideSelected?'#b758a1':'#9676af'}" stroke-width=".22" stroke-dasharray="1 1" pointer-events="none"/><polygon points="${marker}" fill="${i===userGuideSelected?'#b758a1':'#9676af'}" data-user-guide="${i}" style="cursor:${g.axis==='h'?'ns':'ew'}-resize"/>`;
  }).join('');
}
function addUserGuide(axis,position=54.5) {
  if(userGuides.length>=64)return false;
  userGuides.push({axis,position:Math.max(0,Math.min(109,position))});userGuideSelected=userGuides.length-1;el('showRulers').checked=true;return true;
}
for(const [id,axis] of [['guideAddH','h'],['guideAddV','v']])el(id).onclick=()=>{addUserGuide(axis);storeUserGuides();renderUserGuides();paint();};
el('userGuideList').onchange=()=>{userGuideSelected=Number(el('userGuideList').value);renderUserGuides();paint();};
el('userGuidePosition').onchange=()=>{
  const input=el('userGuidePosition'),value=Number(input.value),g=userGuides[userGuideSelected];
  if(!g||input.value===''||!Number.isFinite(value)||value<0||value>109){el('userGuideStatus').textContent='Координата должна лежать в 0–109.';renderUserGuides();return;}
  g.position=value;storeUserGuides();renderUserGuides();paint();
};
el('guideRemove').onclick=()=>{if(userGuideSelected<0)return;userGuides.splice(userGuideSelected,1);userGuideSelected=Math.min(userGuideSelected,userGuides.length-1);storeUserGuides();renderUserGuides();paint();};
el('guidePresetSave').onclick=()=>{
  const name=el('guidePresetName').value.trim();
  if(!name||name.length>80||guidePresets.length>=32||guidePresets.some(p=>p.name===name)){el('userGuideStatus').textContent='Укажи уникальное имя пресета (до 80 символов, до 32 пресетов).';return;}
  guidePresets.push({name,lines:M.copy(userGuides)});storeUserGuides();renderUserGuides();el('guidePresetList').value=guidePresets.length-1;el('userGuideStatus').textContent=`Пресет «${name}» сохранён в браузере.`;
};
el('guidePresetApply').onclick=()=>{const p=guidePresets[Number(el('guidePresetList').value)];if(!p)return;userGuides=M.copy(p.lines);userGuideSelected=userGuides.length?0:-1;el('showRulers').checked=true;storeUserGuides();renderUserGuides();paint();};
el('guidePresetRemove').onclick=()=>{const i=Number(el('guidePresetList').value);if(!guidePresets[i])return;guidePresets.splice(i,1);storeUserGuides();renderUserGuides();};
function beginGuideDrag(event) {
  const data=event.target.dataset;if(data.userGuide===undefined&&data.ruler===undefined)return false;
  const before=M.copy(userGuides),selectedBefore=userGuideSelected;
  if(data.ruler!==undefined){const p=referencePoint(event);if(!addUserGuide(data.ruler==='x'?'v':'h',p[data.ruler==='x'?0:1]))return true;}
  else userGuideSelected=Number(data.userGuide);
  if(!userGuides[userGuideSelected])return true;
  guideDrag={pointer:event.pointerId,before,selectedBefore};el('stage').setPointerCapture(event.pointerId);event.preventDefault();renderUserGuides();paint();return true;
}
function loadReferences() {
  try{const saved=localStorage.getItem(REFERENCE_STORAGE);if(saved)references=validateReferences(JSON.parse(saved));}
  catch{el('referenceStatus').textContent='Сохранённые референсы не прочитаны; исходная копия в браузере сохранена.';}
}
function renderReferences() {
  const visible=references.map((r,i)=>[r,i]).filter(([r])=>r.character===currentGlyph().character);
  if(!visible.some(([,i])=>i===referenceSelected))referenceSelected=visible[0]?.[1]??-1;
  const list=el('referenceList');list.replaceChildren();
  for(const [r,i] of visible){const o=document.createElement('option');o.value=i;o.textContent=r.name;list.append(o);}
  list.value=referenceSelected;
  const r=selectedReference();
  for(const id of ['referenceList','referenceRemove','referenceX','referenceY','referenceWidth','referenceHeight','referenceRatio','referenceLock','referenceFlipX','referenceFlipY','referenceOpacity'])el(id).disabled=!r;
  if(!r)return;
  for(const [id,key] of [['referenceX','x'],['referenceY','y'],['referenceWidth','width'],['referenceHeight','height']]){el(id).value=+r[key].toFixed(2);el(id).disabled=r.locked;}
  el('referenceRatio').checked=r.ratio;el('referenceLock').checked=r.locked;el('referenceOpacity').value=Math.round(r.opacity*100);
  el('referenceFlipX').disabled=el('referenceFlipY').disabled=r.locked;
}
function referenceMarkup() {
  return references.map((r,i)=>r.character!==currentGlyph().character?'':`<image href="${r.src}" width="${r.width}" height="${r.height}" preserveAspectRatio="none" opacity="${r.opacity}" transform="translate(${r.x+(r.flipX?r.width:0)} ${r.y+(r.flipY?r.height:0)}) scale(${r.flipX?-1:1} ${r.flipY?-1:1})" data-reference="${i}" style="cursor:${r.locked?'default':'move'};pointer-events:${r.locked?'none':'all'}"/>`).join('');
}
function referenceFrame() {
  const r=selectedReference();if(!r||r.locked)return '';
  return `<g fill="#fffdf6" stroke="#b17f24" stroke-width=".3"><rect x="${r.x}" y="${r.y}" width="${r.width}" height="${r.height}" fill="none" stroke-dasharray="1 1" pointer-events="none"/>${['nw','ne','sw','se'].map(c=>`<rect x="${r.x+(c[1]==='e'?r.width:0)-1}" y="${r.y+(c[0]==='s'?r.height:0)-1}" width="2" height="2" data-reference="${referenceSelected}" data-corner="${c}" style="cursor:${c==='nw'||c==='se'?'nwse':'nesw'}-resize"/>`).join('')}</g>`;
}
function referencePoint(event) {
  const p=new DOMPoint(event.clientX,event.clientY).matrixTransform(el('stage').getScreenCTM().inverse());return [p.x,p.y];
}
function beginReferenceDrag(event) {
  if(event.target.dataset.reference===undefined)return false;
  referenceSelected=Number(event.target.dataset.reference);const r=selectedReference();if(!r||r.locked)return true;
  finishRange();referenceDrag={pointer:event.pointerId,start:referencePoint(event),before:{...r},corner:event.target.dataset.corner};
  el('stage').setPointerCapture(event.pointerId);event.preventDefault();renderReferences();paint();return true;
}
function resizeReference(before,corner,dx,dy,uniform) {
  const east=corner[1]==='e',south=corner[0]==='s';
  let w=Math.max(1,Math.min(1000,before.width+(east?dx:-dx))), h=Math.max(1,Math.min(1000,before.height+(south?dy:-dy)));
  if(uniform){const scale=Math.abs(w/before.width-1)>Math.abs(h/before.height-1)?w/before.width:h/before.height;
    const bounded=Math.max(1/Math.min(before.width,before.height),Math.min(1000/Math.max(before.width,before.height),scale));w=before.width*bounded;h=before.height*bounded;}
  return {width:w,height:h,x:east?before.x:before.x+before.width-w,y:south?before.y:before.y+before.height-h};
}
function moveReferenceDrag(event) {
  if(!referenceDrag||referenceDrag.pointer!==event.pointerId)return false;
  const d=referenceDrag,r=selectedReference(),p=referencePoint(event),dx=p[0]-d.start[0],dy=p[1]-d.start[1];
  if(d.corner){Object.assign(r,resizeReference(d.before,d.corner,dx,dy,r.ratio||event.shiftKey));r.x=Math.max(-1000,Math.min(1000,r.x));r.y=Math.max(-1000,Math.min(1000,r.y));}
  else {r.x=Math.max(-1000,Math.min(1000,d.before.x+dx));r.y=Math.max(-1000,Math.min(1000,d.before.y+dy));}
  renderReferences();paint();return true;
}
function referenceChange(fn) {const r=selectedReference();if(!r)return;fn(r);renderReferences();paint();storeReferences();}
el('referenceList').onchange=()=>{referenceSelected=Number(el('referenceList').value);renderReferences();paint();};
el('referenceRemove').onclick=()=>{if(referenceSelected<0)return;references.splice(referenceSelected,1);referenceSelected=-1;renderReferences();paint();storeReferences();};
for(const [id,key] of [['referenceX','x'],['referenceY','y'],['referenceWidth','width'],['referenceHeight','height']])el(id).onchange=()=>{
  const value=Number(el(id).value),r=selectedReference();if(!r||r.locked)return;
  if(el(id).value===''||!Number.isFinite(value)||Math.abs(value)>1000||(['width','height'].includes(key)&&value<1)){renderReferences();return;}
  referenceChange(r=>{if(r.ratio&&['width','height'].includes(key)){const other=key==='width'?'height':'width',next=r[other]*value/r[key];if(next<1||next>1000)return;r[other]=next;}r[key]=value;});
};
for(const [id,key] of [['referenceRatio','ratio'],['referenceLock','locked']])el(id).onchange=()=>referenceChange(r=>{r[key]=el(id).checked;});
for(const axis of ['X','Y'])el('referenceFlip'+axis).onclick=()=>referenceChange(r=>{if(!r.locked)r['flip'+axis]=!r['flip'+axis];});
el('referenceOpacity').oninput=()=>{const r=selectedReference();if(r){r.opacity=Number(el('referenceOpacity').value)/100;paint();}};
el('referenceOpacity').onchange=storeReferences;
el('referenceAdd').onclick=()=>el('referenceFile').click();
el('referenceFile').onchange=async()=>{
  const character=currentGlyph().character;
  try{for(const file of el('referenceFile').files){
    if(references.length>=24)throw new Error('Максимум 24 изображения в рабочем пространстве.');
    if(!['image/png','image/jpeg','image/webp'].includes(file.type)||file.size>20_000_000)throw new Error('Нужен PNG, JPEG или WebP до 20 МБ.');
    const url=URL.createObjectURL(file);
    try{const image=new Image();image.src=url;await image.decode();
      const scale=Math.min(1,1024/Math.max(image.naturalWidth,image.naturalHeight)),canvas=document.createElement('canvas');
      canvas.width=Math.max(1,Math.round(image.naturalWidth*scale));canvas.height=Math.max(1,Math.round(image.naturalHeight*scale));canvas.getContext('2d').drawImage(image,0,0,canvas.width,canvas.height);
      const src=canvas.toDataURL(file.type==='image/png'?'image/png':'image/jpeg',.85);
      const size=Math.min(80/canvas.width,80/canvas.height);
      const r={character,name:file.name.slice(0,200),src,x:(109-canvas.width*size)/2,y:(109-canvas.height*size)/2,width:canvas.width*size,height:canvas.height*size,flipX:false,flipY:false,opacity:.6,locked:false,ratio:true};
      validateReferences({schema:'dreams.references/v1',images:[r]});references.push(r);referenceSelected=references.length-1;
    }finally{URL.revokeObjectURL(url);}
  }renderReferences();paint();storeReferences();}
  catch(error){renderReferences();paint();storeReferences();el('referenceStatus').textContent=error.message;}
  finally{el('referenceFile').value='';}
};
el('referenceExport').onclick=()=>download('dreams-references.json',JSON.stringify({schema:'dreams.references/v1',images:references},null,2),'application/json');
el('referenceImport').onclick=()=>el('referenceJSON').click();
el('referenceJSON').onchange=async()=>{
  try{const file=el('referenceJSON').files[0];if(!file)return;if(file.size>20_000_000)throw new Error('JSON больше 20 МБ.');
    const images=validateReferences(JSON.parse(await file.text()));references=images;referenceSelected=-1;renderReferences();paint();storeReferences();}
  catch(error){el('referenceStatus').textContent=error.message;}finally{el('referenceJSON').value='';}
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
  if(event.button!==undefined && event.button!==0)return;
  if(beginGuideDrag(event))return;
  if(moveGlyphMode) {
    finishRange();drag={key:'glyph',before:snapshot(),pointer:event.pointerId,start:referencePoint(event),placement:{scale:1,x:0,y:0,...currentGlyph().placement}};
    el('stage').setPointerCapture(event.pointerId);event.preventDefault();return;
  }
  if(beginReferenceDrag(event))return;
  const key=event.target.dataset.key;
  if(!key) {
    if(event.target.dataset.segment!==undefined){segmentIndex=Number(event.target.dataset.segment);renderControls();paint();}
    else if(event.target.dataset.stroke!==undefined){strokeIndex=Number(event.target.dataset.stroke);segmentIndex=0;renderControls();paint();}
    return;
  }
  finishRange();drag={key,before:snapshot(),pointer:event.pointerId,anchor:[...currentSegment()[key==='start'?'end':key==='end'?'start':'mid']]};el('stage').setPointerCapture(event.pointerId);event.preventDefault();
});
el('stage').addEventListener('pointermove',event=>{
  if(guideDrag&&guideDrag.pointer===event.pointerId){const g=userGuides[userGuideSelected],p=referencePoint(event);g.position=Number(Math.max(0,Math.min(109,p[g.axis==='v'?0:1])).toFixed(2));renderUserGuides();paint();return;}
  if(moveReferenceDrag(event))return;
  if(!drag || event.pointerId!==drag.pointer)return;
  if(drag.key==='glyph') {
    const p=referencePoint(event);let dx=p[0]-drag.start[0],dy=p[1]-drag.start[1];
    if(event.shiftKey){if(Math.abs(dx)>=Math.abs(dy))dy=0;else dx=0;}
    currentGlyph().placement={...drag.placement,x:Math.max(-2000,Math.min(2000,drag.placement.x+dx)),y:Math.max(-2000,Math.min(2000,drag.placement.y+dy))};
    renderControls();paint();return;
  }
  const p=new DOMPoint(event.clientX,event.clientY).matrixTransform(el('geometry').getScreenCTM().inverse());
  let position=[p.x,p.y];
  if(event.shiftKey) {
    const a=drag.anchor,g=currentGlyph(),dx=Math.abs((p.x-a[0])*g.stretch),dy=Math.abs(p.y-a[1]);
    position=dx>=dy?[p.x,a[1]]:[a[0],p.y];
  }
  M.setPoint(currentStroke(),segmentIndex,drag.key,position);renderControls();paint();
});
function endDrag(event) {
  if(guideDrag&&guideDrag.pointer===event.pointerId){if(event.type==='pointercancel'){userGuides=guideDrag.before;userGuideSelected=guideDrag.selectedBefore;}guideDrag=null;storeUserGuides();renderUserGuides();paint();return;}
  if(referenceDrag && event.pointerId===referenceDrag.pointer){referenceDrag=null;storeReferences();return;}
  if(!drag || event.pointerId!==drag.pointer)return;
  const before=drag.before, cancelled=event.type==='pointercancel'&&drag.key==='glyph';drag=null;
  if(cancelled){restore(before);return;}
  try{M.validate(project);remember(before);renderControls();}
  catch(error){restore(before);status(error.message,true);}
}
el('stage').addEventListener('pointerup',endDrag);el('stage').addEventListener('pointercancel',endDrag);
document.addEventListener('keydown',event=>{
  if((event.metaKey||event.ctrlKey)&&event.key.toLowerCase()==='z'&&!['INPUT','SELECT','TEXTAREA'].includes(event.target.tagName)){
    event.preventDefault();el(event.shiftKey?'redo':'undo').click();
  }
});
window.addEventListener('pagehide',()=>{finishRange();if(drag)store();if(referenceDrag)storeReferences();if(guideDrag)storeUserGuides();});
try {const saved=localStorage.getItem(STORAGE);if(saved){project=M.validate(JSON.parse(saved));checkpointParent=localStorage.getItem(STORAGE+'.parent') || null;selected=Math.min(4,project.glyphs.length-1);status('Восстановлены сохранённые правки');}}
catch {status('Сохранённый проект не прочитан. Исходные знаки загружены; старая копия не перезаписана.',true);}
el('credit').textContent=project.attribution;
try{for(const id of ['metricGuides','guideBaseline','guideCap','guideMeanline','guideLimits','guideBounds','guideCell']){const saved=localStorage.getItem(STORAGE+'.'+id);if(saved!==null&&saved!==undefined)el(id).checked=saved==='true';}}catch{}
loadUserGuides();loadReferences();M.validate(project);render();
