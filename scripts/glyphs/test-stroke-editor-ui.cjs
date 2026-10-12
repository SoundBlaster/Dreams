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
assert.equal(element('stage').viewBox,'0 0 109 109');assert.deepEqual(state(),metricProject);
element('metricGuides').checked=true;element('metricGuides').onchange();

element('width').value='9';element('width').oninput();element('width').onchange();
assert.equal(state().glyphs[4].strokes[0].width,9);
element('undo').onclick();assert.equal(state().glyphs[4].strokes[0].width,7.5);
element('redo').onclick();assert.equal(state().glyphs[4].strokes[0].width,9);
element('preserveWidth').checked=true;element('preserveWidth').onchange();
assert.equal(state().glyphs[4].preserveWidth,true);
assert.equal(JSON.parse(storage.get('dreams.stroke-editor.v1')).glyphs[4].preserveWidth,true);
element('undo').onclick();assert.equal(state().glyphs[4].preserveWidth,undefined);
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
const count=state().glyphs[4].strokes[0].segments.length;
element('addSegmentAfter').onclick();assert.equal(state().glyphs[4].strokes[0].segments.length,count+1);
element('removeSegment').onclick();assert.equal(state().glyphs[4].strokes[0].segments.length,count);
element('segment').value='0';element('segment').onchange();
const beforeInsertion=state();
element('addSegmentBefore').onfocus();assert.ok(element('stage').innerHTML.includes('stroke="#b17f24"'));
element('addSegmentBefore').onclick();assert.equal(element('segment').value,0);
assert.equal(state().glyphs[4].strokes[0].segments.length,count+1);
element('undo').onclick();assert.deepEqual(state(),beforeInsertion);
element('addSegmentAfter').onclick();assert.equal(element('segment').value,1);
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
