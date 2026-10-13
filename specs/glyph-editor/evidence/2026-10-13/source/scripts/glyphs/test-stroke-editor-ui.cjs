// Event/state regression tests using a small DOM double; not native pointer verification.
const assert=require('node:assert/strict'), fs=require('node:fs'), vm=require('node:vm');
const M=require('./stroke-editor-model.js');
const seed=JSON.parse(fs.readFileSync(process.argv[2],'utf8'));
const elements=new Map(), storage=new Map();
function element(id=''){
  if(id && elements.has(id))return elements.get(id);
  const e={id,value:'',checked:true,dataset:{},children:[],events:{},textContent:'',innerHTML:'',
    classList:{toggle(){}},setAttribute(k,v){this[k]=v;},replaceChildren(){this.children=[];},
    append(child){this.children.push(child);if(child.id)elements.set(child.id,child);},
    addEventListener(k,fn){this.events[k]=fn;},setPointerCapture(){},
    click(){this.onclick?.();},showModal(){this.open=true;},close(){this.open=false;},
    getScreenCTM(){return {inverse(){return {apply:(x,y)=>[54.5+(x-54.5)/-.85,y]};}};},
  };
  if(id)elements.set(id,e);return e;
}
const sandbox=vm.createContext({fontMetrics:{upm:1024,advance:956,ascent:900,descent:124,capHeight:780,xHeight:560},seed,M:undefined,globalThis:null,document:{getElementById:element,createElement:()=>element(),addEventListener(){}},
  localStorage:{getItem:k=>storage.get(k),setItem:(k,v)=>storage.set(k,v)},window:{addEventListener(){}},
  Blob,URL:{createObjectURL:()=>'',revokeObjectURL(){}},setTimeout:()=>{},
  DOMPoint:class{constructor(x,y){this.x=x;this.y=y;}matrixTransform(m){const [x,y]=m.apply(this.x,this.y);return {x,y};}},
});
// Use the real browser model entry point, avoiding a mock of geometry itself.
vm.runInContext(fs.readFileSync('scripts/glyphs/stroke-editor-model.js','utf8').replace('globalThis);','this);'),sandbox);
sandbox.globalThis=sandbox;
vm.runInContext(fs.readFileSync('scripts/glyphs/stroke-editor.js','utf8'),sandbox);
const state=()=>JSON.parse(vm.runInContext('JSON.stringify(project)',sandbox));
assert.equal(element('alphabet').children.length,46);
assert.equal(element('stage').viewBox,'-49 -18 210 153');
assert.ok(element('stage').innerHTML.includes('Baseline 0'));
assert.ok(element('stage').innerHTML.includes('Line height 1024'));
const metricProject=state();element('guideBaseline').checked=false;element('guideBaseline').onchange();
assert.ok(!element('stage').innerHTML.includes('Baseline 0'));
element('guideBaseline').checked=true;element('guideBaseline').onchange();
element('metricGuides').checked=false;element('metricGuides').onchange();
assert.equal(element('stage').viewBox,'-8 -8 125 125');assert.deepEqual(state(),metricProject);
element('showRulers').checked=false;element('showRulers').onchange();assert.equal(element('stage').viewBox,'0 0 109 109');
element('showRulers').checked=true;element('showRulers').onchange();
element('metricGuides').checked=true;element('metricGuides').onchange();

// Visible hierarchy selects actual stroke/section, including non-first strokes.
const layers=element('strokeLayers');assert.equal(layers.children.length,state().glyphs[4].strokes.length);
layers.children[1].children[1].children[0].children[0].onclick();
assert.equal(vm.runInContext('strokeIndex',sandbox),1);assert.equal(vm.runInContext('segmentIndex',sandbox),0);
element('strokeLayers').children[0].children[0].onclick();
const beforeMove=state();element('glyphX').value='12.5';element('glyphX').onchange();
element('glyphY').value='-8';element('glyphY').onchange();
assert.deepEqual(state().glyphs[4].placement,{scale:1,x:12.5,y:-8});
assert.deepEqual(state().glyphs[4].strokes,beforeMove.glyphs[4].strokes);
element('undo').onclick();element('undo').onclick();assert.deepEqual(state(),beforeMove);
element('moveGlyph').onclick();const moveStage=element('stage');
moveStage.events.pointerdown({target:{dataset:{}},clientX:50,clientY:50,pointerId:12,preventDefault(){}});
moveStage.events.pointermove({clientX:50,clientY:60,pointerId:12});moveStage.events.pointerup({pointerId:12});
assert.equal(state().glyphs[4].placement.y,10);assert.deepEqual(state().glyphs[4].strokes,beforeMove.glyphs[4].strokes);
element('undo').onclick();assert.deepEqual(state(),beforeMove);element('editPoints').onclick();
element('glyphX').value='3000';element('glyphX').onchange();assert.deepEqual(state(),beforeMove);
element('moveGlyph').onclick();
moveStage.events.pointerdown({target:{dataset:{}},clientX:50,clientY:50,pointerId:13,preventDefault(){}});
moveStage.events.pointermove({clientX:55,clientY:70,pointerId:13,shiftKey:true});
assert.equal(state().glyphs[4].placement.x,0);assert.equal(state().glyphs[4].placement.y,20);
moveStage.events.pointercancel({type:'pointercancel',pointerId:13});assert.deepEqual(state(),beforeMove);
element('editPoints').onclick();
console.log('PASS: layer hierarchy selection and whole-glyph movement preserve strokes and support Undo');

const guideProject=state(),guideSVG=M.svg(state().glyphs[4],seed.attribution);
element('guideAddH').onclick();element('userGuidePosition').value='20';element('userGuidePosition').onchange();
element('guideAddV').onclick();element('userGuidePosition').value='80';element('userGuidePosition').onchange();
const guideState=()=>JSON.parse(vm.runInContext('JSON.stringify(userGuides)',sandbox));
assert.deepEqual(guideState(),[{axis:'h',position:20},{axis:'v',position:80}]);
element('guidePresetName').value='Test grid';element('guidePresetSave').onclick();
element('userGuidePosition').value='50';element('userGuidePosition').onchange();
element('guidePresetApply').onclick();assert.deepEqual(guideState(),[{axis:'h',position:20},{axis:'v',position:80}]);
element('guidePresetSave').onclick();assert.equal(vm.runInContext('guidePresets.length',sandbox),1,'duplicate names are refused');
element('userGuidePosition').value='NaN';element('userGuidePosition').onchange();assert.equal(guideState()[0].position,20);
const guideStage=element('stage');guideStage.events.pointerdown({target:{dataset:{userGuide:'0'}},pointerId:20,preventDefault(){}});
guideStage.events.pointermove({clientX:20,clientY:35,pointerId:20});guideStage.events.pointerup({pointerId:20});
assert.equal(guideState()[0].position,35);
assert.equal(JSON.parse(storage.get('dreams.stroke-editor.v1.user-guides')).lines[0].position,35);
guideStage.events.pointerdown({target:{dataset:{ruler:'y'}},clientX:0,clientY:45,pointerId:21,preventDefault(){}});
assert.equal(guideState().length,3);guideStage.events.pointercancel({type:'pointercancel',pointerId:21});assert.equal(guideState().length,2);
element('alphabet').children[1].onclick();assert.equal(guideState()[0].position,35);element('alphabet').children[4].onclick();
assert.deepEqual(state(),guideProject);assert.equal(M.svg(state().glyphs[4],seed.attribution),guideSVG);
element('guidePresetList').value='';vm.runInContext('userGuides=[];guidePresets=[];loadUserGuides();renderUserGuides();',sandbox);assert.equal(guideState()[0].position,35);assert.equal(element('guidePresetList').value,'0');
assert.throws(()=>vm.runInContext("validateGuideState({schema:'dreams.guides/v1',visible:true,lines:[{axis:'h',position:NaN}],presets:[]})",sandbox));
element('guidePresetRemove').onclick();assert.equal(vm.runInContext('guidePresets.length',sandbox),0);
element('guideRemove').onclick();element('guideRemove').onclick();assert.equal(guideState().length,0);
console.log('PASS: rulers, editable guides, independent named presets, persistence, cancellation and glyph isolation');

const beforeFit=state();element('fitGlyph').onclick();
assert.ok(state().glyphs[4].placement);assert.equal(element('resetPlacement').disabled,false);
assert.ok(JSON.parse(storage.get('dreams.stroke-editor.v1')).glyphs[4].placement);
element('undo').onclick();assert.deepEqual(state(),beforeFit);
element('redo').onclick();assert.ok(state().glyphs[4].placement);
element('resetPlacement').onclick();assert.equal(state().glyphs[4].placement,undefined);
element('undo').onclick();assert.ok(state().glyphs[4].placement);
element('undo').onclick();assert.deepEqual(state(),beforeFit);
element('width').value='9';element('width').oninput();element('width').onchange();
assert.equal(state().glyphs[4].strokes[0].width,9);
element('undo').onclick();assert.equal(state().glyphs[4].strokes[0].width,7.5);
element('redo').onclick();assert.equal(state().glyphs[4].strokes[0].width,9);
element('preserveWidth').checked=true;element('preserveWidth').onchange();
assert.equal(state().glyphs[4].preserveWidth,true);
assert.equal(JSON.parse(storage.get('dreams.stroke-editor.v1')).glyphs[4].preserveWidth,true);
element('undo').onclick();assert.equal(state().glyphs[4].preserveWidth,undefined);
const beforeJoin=state();element('strokeJoin').value='miter';element('strokeJoin').onchange();
assert.equal(state().glyphs[4].strokes[0].join,'miter');
assert.equal(JSON.parse(storage.get('dreams.stroke-editor.v1')).glyphs[4].strokes[0].join,'miter');
element('undo').onclick();assert.deepEqual(state(),beforeJoin);
const componentBefore=state();element('makeComponent').onclick();
let component=state().components[0];assert.equal(state().glyphs[4].strokes[0].componentId,component.id);
assert.equal(element('width').disabled,true);assert.equal(element('start0').disabled,true);
element('undo').onclick();
element('copyStroke').onclick();element('alphabet').children[0].onclick();element('pasteLinkedStroke').onclick();
component=state().components[0];
assert.equal(state().glyphs[4].strokes[0].componentId,component.id,'linked paste converts the unchanged source');
const linkedIndex=state().glyphs[0].strokes.length-1;assert.equal(state().glyphs[0].strokes[linkedIndex].componentId,component.id);
element('pasteLinkedStroke').onclick();assert.equal(state().components.length,1);assert.equal(state().glyphs[0].strokes.at(-1).componentId,component.id);element('undo').onclick();
element('strokeX').value='12';element('strokeX').onchange();assert.deepEqual(state().glyphs[0].strokes[linkedIndex].offset,[12,0]);
assert.deepEqual(state().glyphs[4].strokes[0].offset,[0,0]);
const frozen=state();element('width').value='11';element('width').oninput();assert.deepEqual(state(),frozen);
element('editComponent').onclick();element('width').value='11';element('width').oninput();element('width').onchange();
assert.equal(state().components[0].stroke.width,11);
assert.equal(M.resolveGlyph(state(),state().glyphs[4]).strokes[0].width,11);
assert.equal(M.resolveGlyph(state(),state().glyphs[0]).strokes[linkedIndex].width,11);
assert.deepEqual(state().glyphs[0].strokes[linkedIndex].offset,[12,0]);
element('undo').onclick();assert.equal(state().components[0].stroke.width,component.stroke.width);assert.equal(element('width').disabled,true);
element('detachComponent').onclick();assert.equal(state().glyphs[0].strokes[linkedIndex].componentId,undefined);assert.deepEqual(state().glyphs[0].strokes[linkedIndex].offset,[12,0]);
element('copyStroke').onclick();element('pasteStroke').onclick();const copied=state().glyphs[0].strokes.at(-1);assert.equal(copied.componentId,undefined);
const beforeTrace=state();element('traceEnabled').checked=true;element('traceEnabled').onchange();
assert.ok(element('stage').innerHTML.includes('id="glyphTrace"'));assert.deepEqual(state(),beforeTrace);
element('traceOpacity').value='40';element('traceOpacity').oninput();assert.ok(element('stage').innerHTML.includes('opacity="0.4"'));
element('traceEnabled').checked=false;element('traceEnabled').onchange();
// Return to the exact pre-component project, leaving the clipboard as a plain snapshot.
while(JSON.stringify(state())!==JSON.stringify(componentBefore)){assert.ok(element('undo').disabled===false);element('undo').onclick();}
element('alphabet').children[4].onclick();
console.log('PASS: copied strokes, frozen components, shared edits, independent positions, detaching, Undo and tracing');
const originalCap=state().glyphs[4].strokes[0].endCap;
element('endCap').value='round';element('endCap').onchange();
assert.equal(state().glyphs[4].strokes[0].endCap,'round');
assert.equal(element('endWidth').disabled,false);
assert.equal(JSON.parse(storage.get('dreams.stroke-editor.v1')).glyphs[4].strokes[0].endCap,'round');
element('undo').onclick();assert.equal(state().glyphs[4].strokes[0].endCap,originalCap);
element('redo').onclick();assert.equal(state().glyphs[4].strokes[0].endCap,'round');
element('undo').onclick();
element('mirror').checked=true;element('mirror').onchange();
const stage=element('stage');stage.events.pointerdown({target:{dataset:{key:'start'}},pointerId:7,preventDefault(){}});
stage.events.pointermove({clientX:40,clientY:34,pointerId:7});stage.events.pointerup({pointerId:7});
assert.deepEqual(state().glyphs[4].strokes[0].segments[0].start,[71.5588,34]);
element('undo').onclick();assert.equal(state().glyphs[4].strokes[0].segments[0].start[0],18);
const snapBefore=state(), snapSegment=snapBefore.glyphs[4].strokes[0].segments[0];
stage.events.pointerdown({target:{dataset:{key:'end'}},pointerId:8,preventDefault(){}});
stage.events.pointermove({clientX:40,clientY:snapSegment.start[1]+1,pointerId:8,shiftKey:true});stage.events.pointerup({pointerId:8});
assert.equal(state().glyphs[4].strokes[0].segments[0].end[1],snapSegment.start[1]);
element('undo').onclick();assert.deepEqual(state(),snapBefore);
stage.events.pointerdown({target:{dataset:{key:'start'}},pointerId:9,preventDefault(){}});
// Mirrored 85% glyph: screen x that maps to the opposite endpoint's x.
const screenX=54.5+(snapSegment.end[0]-54.5)*-.85;
stage.events.pointermove({clientX:screenX,clientY:90,pointerId:9,shiftKey:true});stage.events.pointerup({pointerId:9});
assert.equal(state().glyphs[4].strokes[0].segments[0].start[0],snapSegment.end[0]);
element('undo').onclick();assert.deepEqual(state(),snapBefore);
const count=state().glyphs[4].strokes[0].segments.length;
element('addSegmentAfter').onclick();assert.equal(state().glyphs[4].strokes[0].segments.length,count+1);
element('removeSegment').onclick();assert.equal(state().glyphs[4].strokes[0].segments.length,count);
element('strokeLayers').children[0].children[1].children[0].children[0].onclick();
const beforeInsertion=state();
element('addSegmentBefore').onfocus();assert.ok(element('stage').innerHTML.includes('stroke="#b17f24"'));
element('addSegmentBefore').onclick();assert.equal(vm.runInContext('segmentIndex',sandbox),0);
assert.equal(state().glyphs[4].strokes[0].segments.length,count+1);
element('undo').onclick();assert.deepEqual(state(),beforeInsertion);
element('addSegmentAfter').onclick();assert.equal(vm.runInContext('segmentIndex',sandbox),1);
element('undo').onclick();assert.deepEqual(state(),beforeInsertion);
const previous=state();
element('pasteText').value='{}';element('applyPaste').onclick();assert.deepEqual(state(),previous);assert.ok(element('pasteError').textContent);
const custom=M.copy(seed);custom.attribution='Custom fixture';custom.glyphs=[custom.glyphs[0]];
element('pasteText').value=JSON.stringify(custom);element('applyPaste').onclick();assert.equal(state().glyphs.length,1);
assert.equal(element('credit').textContent,'Custom fixture');
element('undo').onclick();assert.equal(state().glyphs.length,46);assert.equal(element('credit').textContent,seed.attribution);
assert.equal(JSON.parse(storage.get('dreams.stroke-editor.v1')).glyphs.length,46);
console.log('PASS: edits, undo/redo, mirrored pointer coordinates, sections, validation, import rollback, attribution and autosave');
const nameInput=element('checkpointName');nameInput.maxLength=120;
nameInput.setSelectionRange=(start,end)=>{nameInput.selectionStart=start;nameInput.selectionEnd=end;};
let tabPrevented=false;
const tab=extra=>{tabPrevented=false;nameInput.events.keydown({key:'Tab',preventDefault(){tabPrevented=true;},...extra});};
nameInput.value='мягкий хвост';tab();assert.equal(nameInput.value,'オ · мягкий хвост');assert.equal(tabPrevented,true);
assert.equal(nameInput.selectionStart,nameInput.value.length);
tab();assert.equal(tabPrevented,false,'second Tab retains focus navigation');
nameInput.value='';tab({shiftKey:true});assert.equal(nameInput.value,'');assert.equal(tabPrevented,false);
tab();assert.equal(nameInput.value,'オ · ');
element('alphabet').children[0].onclick();nameInput.value='вариант';tab();assert.equal(nameInput.value,'ア · вариант');
nameInput.value='x'.repeat(120);tab();assert.equal(nameInput.value.length,120);assert.equal(tabPrevented,false);
element('alphabet').children[4].onclick();
console.log('PASS: checkpoint name Tab inserts the selected glyph once and preserves keyboard navigation');
const ref={character:'オ',name:'Frame',src:'data:image/png;base64,AAAA',x:10,y:20,width:40,height:60,opacity:.6,flipX:false,flipY:false,locked:false,ratio:true};
sandbox.ref=ref;vm.runInContext('references=[{...ref}];referenceSelected=0;renderReferences();paint();',sandbox);
const refs=()=>JSON.parse(vm.runInContext('JSON.stringify(references)',sandbox));
element('referenceWidth').value='80';element('referenceWidth').onchange();assert.equal(refs()[0].height,120);
element('referenceRatio').checked=false;element('referenceRatio').onchange();
element('referenceHeight').value='30';element('referenceHeight').onchange();assert.equal(refs()[0].width,80);
element('referenceFlipX').onclick();element('referenceFlipY').onclick();assert.equal(refs()[0].flipX,true);assert.equal(refs()[0].flipY,true);
assert.ok(element('stage').innerHTML.includes('scale(-1 -1)'));
element('referenceLock').checked=true;element('referenceLock').onchange();assert.equal(element('referenceWidth').disabled,true);
element('referenceFlipX').onclick();assert.equal(refs()[0].flipX,true,'locked reference cannot flip');
element('referenceOpacity').value='25';element('referenceOpacity').oninput();element('referenceOpacity').onchange();assert.equal(refs()[0].opacity,.25);
assert.equal(JSON.parse(storage.get('dreams.stroke-editor.v1.references')).images[0].opacity,.25);
assert.equal(state().references,undefined,'reference images never enter the glyph project');
assert.throws(()=>vm.runInContext("validateReferences({schema:'dreams.references/v1',images:[{...ref,src:'javascript:alert(1)'}]})",sandbox));
const resize=(corner,dx,dy,uniform)=>JSON.parse(vm.runInContext(`JSON.stringify(resizeReference(ref,'${corner}',${dx},${dy},${uniform}))`,sandbox));
assert.deepEqual(resize('se',20,0,false),{width:60,height:60,x:10,y:20});
assert.deepEqual(resize('nw',-20,0,true),{width:60,height:90,x:-10,y:-10});
assert.equal(resize('se',-100,-100,true).width,1);
element('alphabet').children[0].onclick();assert.equal(element('referenceList').children.length,0);
element('alphabet').children[4].onclick();assert.equal(element('referenceList').children.length,1);
element('referenceRemove').onclick();assert.equal(refs().length,0);
console.log('PASS: reference transforms, proportional resizing, locks, per-glyph storage and safe image validation');

(async()=>{
  let head=null, records=[], savedProject;
  sandbox.fetch=async(url,options)=>{
    if(options?.method==='POST'){
      const body=JSON.parse(options.body);
      if(body.expectedHead!==head)return {ok:false,json:async()=>({error:'Conflict'})};
      savedProject=M.copy(body.project);head='checkpoint-1';
      const record={id:head,label:body.label,createdAt:new Date().toISOString(),changedGlyphs:['オ']};
      records.push(record);return {ok:true,json:async()=>record};
    }
    return {ok:true,json:async()=>url==='/api/checkpoints'?{head,checkpoints:records}:M.copy(savedProject)};
  };
  await element('checkpointRefresh').onclick();
  assert.equal(element('checkpointSave').disabled,false,'empty database accepts its first checkpoint');
  assert.equal(element('checkpointRestore').disabled,true);
  element('checkpointName').value='Round オ';await element('checkpointSave').onclick();
  const before=state();
  assert.equal(records.length,1);assert.equal(element('checkpointRestore').disabled,false);
  assert.equal(storage.get('dreams.stroke-editor.v1.parent'),'checkpoint-1');
  element('width').value='12';element('width').oninput();element('width').onchange();
  const edited=state();assert.notDeepEqual(edited,before);
  await element('checkpointRestore').onclick();assert.deepEqual(state(),before);
  element('undo').onclick();assert.deepEqual(state(),edited,'restore can be undone');
  sandbox.fetch=async()=>({ok:false,json:async()=>({error:'Disk full'})});
  const unchanged=state();await element('checkpointSave').onclick();
  assert.deepEqual(state(),unchanged);assert.equal(element('checkpointStatus').textContent,'Disk full');
  console.log('PASS: empty library, checkpoint save/restore/undo and server failure preserve editable state');
})().catch(error=>{console.error(error);process.exitCode=1;});
