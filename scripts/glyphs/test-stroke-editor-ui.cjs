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
const sandbox=vm.createContext({seed,M:undefined,globalThis:null,document:{getElementById:element,createElement:()=>element(),addEventListener(){}},
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
element('width').value='9';element('width').oninput();element('width').onchange();
assert.equal(state().glyphs[4].strokes[0].width,9);
element('undo').onclick();assert.equal(state().glyphs[4].strokes[0].width,7.5);
element('redo').onclick();assert.equal(state().glyphs[4].strokes[0].width,9);
element('mirror').checked=true;element('mirror').onchange();
const stage=element('stage');stage.events.pointerdown({target:{dataset:{key:'start'}},pointerId:7,preventDefault(){}});
stage.events.pointermove({clientX:40,clientY:34,pointerId:7});stage.events.pointerup({pointerId:7});
assert.deepEqual(state().glyphs[4].strokes[0].segments[0].start,[71.5588,34]);
element('undo').onclick();assert.equal(state().glyphs[4].strokes[0].segments[0].start[0],18);
const count=state().glyphs[4].strokes[0].segments.length;
element('addSegment').onclick();assert.equal(state().glyphs[4].strokes[0].segments.length,count+1);
element('removeSegment').onclick();assert.equal(state().glyphs[4].strokes[0].segments.length,count);
const previous=state();
element('pasteText').value='{}';element('applyPaste').onclick();assert.deepEqual(state(),previous);assert.ok(element('pasteError').textContent);
const custom=M.copy(seed);custom.attribution='Custom fixture';custom.glyphs=[custom.glyphs[0]];
element('pasteText').value=JSON.stringify(custom);element('applyPaste').onclick();assert.equal(state().glyphs.length,1);
assert.equal(element('credit').textContent,'Custom fixture');
element('undo').onclick();assert.equal(state().glyphs.length,46);assert.equal(element('credit').textContent,seed.attribution);
assert.equal(JSON.parse(storage.get('dreams.stroke-editor.v1')).glyphs.length,46);
console.log('PASS: edits, undo/redo, mirrored pointer coordinates, sections, validation, import rollback, attribution and autosave');
