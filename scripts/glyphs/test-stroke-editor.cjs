// Geometry/data checks; actual browser interaction is checked separately through CUA.
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const M = require('./stroke-editor-model.js');
const seed = M.validate(JSON.parse(fs.readFileSync(process.argv[2], 'utf8')));
assert.equal(seed.glyphs.length,46);
let checks=0;
function check(name,fn){fn();checks++;console.log('PASS:',name);}
const base = {segments:[{kind:'line',start:[10,20],mid:[45,20],end:[80,20]}],width:10,peak:.3,startWidth:4,endWidth:6,startCap:'flat',endCap:'flat'};
check('explicit joins distinguish sharp, bevel and round corners while preserving legacy outlines',()=>{
  const stroke={...base,width:10,startWidth:10,endWidth:10,segments:[{kind:'line',start:[20,20],mid:[40,20],end:[60,20]},{kind:'line',start:[60,20],mid:[60,40],end:[60,60]}]};
  const contains=(d,x,y)=>d.match(/M[^Z]+Z/g).some(poly=>{
    const points=poly.slice(1,-1).split('L').map(p=>p.split(' ').map(Number));let inside=false;
    for(let i=0,j=points.length-1;i<points.length;j=i++) {const a=points[i],b=points[j];if((a[1]>y)!==(b[1]>y)&&x<(b[0]-a[0])*(y-a[1])/(b[1]-a[1])+a[0])inside=!inside;}
    return inside;
  });
  assert.equal(M.outline(stroke),M.outline({...stroke,join:'legacy'}));
  const miter=M.outline({...stroke,join:'miter'}),bevel=M.outline({...stroke,join:'bevel'}),round=M.outline({...stroke,join:'round'});
  assert.equal(contains(miter,64,16),true);assert.equal(contains(bevel,64,16),false);assert.equal(contains(round,64,16),false);
  assert.equal(contains(round,63,17),true);assert.equal(contains(bevel,63,17),false);
  for(const join of ['miter','bevel','round'])for(const stretch of [.5,1,1.2]){
    const g=M.copy(seed.glyphs[0]);g.strokes=[{...stroke,join}];g.stretch=stretch;g.preserveWidth=true;
    M.validate({...seed,glyphs:[g]});assert.ok(!/NaN|Infinity/.test(M.svg(g,seed.attribution)));
  }
  const reversed={...stroke,segments:stroke.segments.toReversed().map(s=>({...s,start:s.end,end:s.start}))};
  assert.equal(contains(M.outline({...reversed,join:'miter'}),64,16),true);
  assert.equal(contains(M.outline({...reversed,join:'bevel'}),64,16),false);
  assert.equal(contains(M.outline({...reversed,join:'round'}),63,17),true);
  const invalid=M.copy(seed);invalid.glyphs[0].strokes[0].join='invalid';assert.throws(()=>M.validate(invalid));
});
check('middle handle is on curve; straight lines ignore off-axis middle handles',()=>{
  const part={kind:'arc',start:[10,20],mid:[40,75],end:[85,25]};
  assert.deepEqual(M.point(part,0),part.start);assert.deepEqual(M.point(part,.5),part.mid);assert.deepEqual(M.point(part,1),part.end);
  part.kind='line';assert.deepEqual(M.point(part,.5),[47.5,22.5]);
});
check('exact continuous width maximum and independent sharp/blunt terminals',()=>{
  assert.equal(M.widthAt(base,0),4);assert.equal(M.widthAt(base,1),6);assert.equal(M.widthAt(base,.3),10);
  for(let i=0;i<=1000;i++)assert.ok(M.widthAt(base,i/1000)<=10);
  assert.ok(Math.abs(M.widthAt(base,.3-1e-6)-M.widthAt(base,.3+1e-6))<1e-8);
  const sharp={...base,startCap:'sharp',endCap:'sharp'};
  assert.equal(M.widthAt(sharp,0),0);assert.equal(M.widthAt(sharp,1),0);assert.notEqual(M.outline(sharp),M.outline(base));
});
check('peak follows physical arc length, not section index',()=>{
  const s=M.copy(base);s.segments=[{kind:'line',start:[0,20],mid:[5,20],end:[10,20]},{kind:'line',start:[10,20],mid:[50,20],end:[90,20]}];
  const p=M.samples(s).reduce((a,b)=>Math.abs(b[2]-.3)<Math.abs(a[2]-.3)?b:a);
  assert.ok(Math.abs(p[0]-27)<.5);
});
check('rounded terminals extend gently along the tangent with consistent winding',()=>{
  const polygons = stroke => M.outline(stroke).match(/M[^Z]+Z/g).map(d=>
    d.slice(1,-1).split('L').map(p=>p.split(' ').map(Number)));
  const bounds = stroke => {
    const points=polygons(stroke).flat();
    return [Math.min(...points.map(p=>p[0])),Math.max(...points.map(p=>p[0]))];
  };
  assert.deepEqual(bounds(base),[10,80]);
  assert.deepEqual(bounds({...base,startCap:'round'}),[9.3,80]);
  assert.deepEqual(bounds({...base,endCap:'round'}),[10,81.05]);
  const rounded={...base,startCap:'round',endCap:'round'};
  assert.equal(M.widthAt(rounded,0),4);assert.equal(M.widthAt(rounded,1),6);
  for(const p of polygons(rounded)) {
    const area=p.reduce((sum,a,i)=>{const b=p[(i+1)%p.length];return sum+a[0]*b[1]-a[1]*b[0];},0);
    assert.ok(area>0,'cap and sweep must add ink rather than cut a hole');
  }
  const vertical=M.copy(rounded);
  vertical.segments=[{kind:'line',start:[20,10],mid:[20,45],end:[20,80]}];
  const ys=polygons(vertical).flat().map(p=>p[1]);
  assert.equal(Math.min(...ys),9.3);assert.equal(Math.max(...ys),81.05);
  assert.equal(M.outline({...rounded,startWidth:0,endWidth:0}),M.outline({...base,startWidth:0,endWidth:0}));
  const project=M.copy(seed);project.glyphs[0].strokes=[rounded];
  assert.deepEqual(M.validate(JSON.parse(JSON.stringify(project))),project);
  assert.ok(M.svg(project.glyphs[0],project.attribution).includes(M.outline(rounded)));
  project.glyphs[0].strokes[0].endCap='unknown';assert.throws(()=>M.validate(project));
});
check('optional proportion changes retain displayed stroke thickness in every direction',()=>{
  for(const stretch of [.5,.59,1,1.2])for(const end of [[70,20],[10,80],[70,80]]) {
    const stroke={...base,width:13,startWidth:13,endWidth:13,segments:[{kind:'line',start:[10,20],mid:[40,50],end}]};
    const points=M.outline(stroke,stretch).match(/M[^Z]+Z/g).flatMap(d=>d.slice(1,-1).split('L').map(p=>p.split(' ').map(Number)));
    const dx=(end[0]-10)*stretch,dy=end[1]-20,norm=Math.hypot(dx,dy);
    const projections=points.map(([x,y])=>-dy/norm*x*stretch+dx/norm*y);
    assert.ok(Math.abs(Math.max(...projections)-Math.min(...projections)-13)<.0003);
    if(stretch===1)assert.equal(M.outline(stroke,stretch),M.outline(stroke));
  }
  const glyph={...M.copy(seed.glyphs[4]),stretch:.59,preserveWidth:true};
  assert.ok(M.svg(glyph,seed.attribution).includes(M.outline(glyph.strokes[0],.59)));
  const project=M.copy(seed);project.glyphs[4]=glyph;
  assert.equal(M.validate(JSON.parse(JSON.stringify(project))).glyphs[4].preserveWidth,true);
  glyph.preserveWidth='yes';assert.throws(()=>M.validate(project));
});
check('shared endpoints remain connected when either section moves',()=>{
  const s=M.copy(base);s.segments.push({kind:'line',start:[80,20],mid:[80,40],end:[80,60]});
  M.setPoint(s,0,'end',[70,30]);assert.deepEqual(s.segments[1].start,[70,30]);
  M.setPoint(s,1,'start',[60,40]);assert.deepEqual(s.segments[0].end,[60,40]);assert.deepEqual(s.segments[0].mid,[35,30]);
});
check('insert before/after the selection preserves interior curves and extends boundary joins',()=>{
  const segments=[{kind:'line',start:[10,20],mid:[25,20],end:[40,20]},
    {kind:'arc',start:[40,20],mid:[65,45],end:[80,70]},
    {kind:'line',start:[80,70],mid:[90,70],end:[100,70]}];
  for(const [index,side,neighborIndex,newIndex] of [[0,'after',1,1],[2,'before',1,2]]) {
    const stroke={...M.copy(base),segments:M.copy(segments)};
    assert.equal(M.insertSegment(stroke,index,side),newIndex);assert.equal(stroke.segments.length,4);
    for(let i=0;i<=20;i++) {
      const t=i/20,split=t<=.5?stroke.segments[neighborIndex]:stroke.segments[neighborIndex+1];
      const actual=M.point(split,t<=.5?t*2:(t-.5)*2),expected=M.point(segments[neighborIndex],t);
      assert.ok(Math.hypot(...actual.map((v,j)=>v-expected[j]))<1e-10);
    }
    for(let i=1;i<stroke.segments.length;i++)assert.deepEqual(stroke.segments[i-1].end,stroke.segments[i].start);
  }
  for(const side of ['before','after']) {
    const stroke={...M.copy(base),segments:[M.copy(segments[0])]};
    const inserted=M.insertSegment(stroke,0,side);assert.equal(inserted,side==='before'?0:1);
    assert.deepEqual(stroke.segments[0].end,stroke.segments[1].start);
    assert.ok(M.samples(stroke).length>0);
    const project=M.copy(seed);project.glyphs[0].strokes=[stroke];M.validate(project);
  }
  const boundary={...M.copy(base),segments:[{kind:'line',start:[10,0],mid:[5,0],end:[0,0]}]};
  M.insertSegment(boundary,0,'after');assert.notDeepEqual(boundary.segments[1].start,boundary.segments[1].end);
  const full={...M.copy(base),segments:Array.from({length:32},()=>M.copy(segments[0]))};
  assert.throws(()=>M.insertSegment(full,0,'after'));assert.equal(full.segments.length,32);
});
check('reject NaN, broken joins, duplicate signs, oversized and zero-length strokes',()=>{
  const p=M.copy(seed);p.glyphs[0].strokes[0].width=NaN;assert.throws(()=>M.validate(p));
  const joined=M.copy(seed);joined.glyphs[4].strokes[0].segments[1].start=[0,0];assert.throws(()=>M.validate(joined));
  const dup=M.copy(seed);dup.glyphs.push(dup.glyphs[0]);assert.throws(()=>M.validate(dup));
  assert.throws(()=>M.validate({...seed,glyphs:Array(257).fill(seed.glyphs[0])}));
  const zero=M.copy(seed);zero.glyphs[0].strokes[0].segments=[{kind:'line',start:[1,1],mid:[1,1],end:[1,1]}];assert.throws(()=>M.validate(zero));
});
check('lossless JSON round trip and finite SVG output for the full alphabet',()=>{
  assert.deepEqual(M.validate(JSON.parse(JSON.stringify(seed))),seed);
  for(const g of seed.glyphs){const svg=M.svg(g,seed.attribution);assert.ok(svg.includes('id="glyph"'));assert.ok(!/NaN|Infinity/.test(svg));}
});
check('mirror and proportions affect SVG output',()=>{
  const g=M.copy(seed.glyphs[4]);const normal=M.svg(g,seed.attribution);
  g.mirror=true;assert.notEqual(M.svg(g,seed.attribution),normal);assert.ok(M.transform(g).includes('scale(-0.85 1)'));
  g.stretch=.65;assert.ok(M.transform(g).includes('scale(-0.65 1)'));
});
check('font metric guides use the same coordinate mapping as exported SVG',()=>{
  const metrics={ascent:900,descent:124,advance:956,capHeight:780,xHeight:560};
  const g=M.metricGuides(metrics);
  assert.equal(g.baseline,103.25);assert.equal(g.cap,5.75);assert.equal(g.xHeight,33.25);
  assert.equal(g.ascent,-9.25);assert.equal(g.descent,118.75);assert.equal(g.lineHeight,1024);
  assert.equal(96.5+7*g.left,0);assert.equal(96.5+7*g.right,956);
  assert.equal(74+8*g.baseline,900);assert.equal(74+8*g.cap,120);
  assert.equal(M.metricGuides({...metrics,lineGap:30}).lineHeight,1054);
});
check('fit glyph uniformly aligns ink bounds with cap height and baseline without changing strokes',()=>{
  const metrics={ascent:900,descent:124,advance:956,capHeight:780,xHeight:560},guides=M.metricGuides(metrics);
  for(const original of seed.glyphs)for(const mirror of [false,true])for(const preserveWidth of [false,true]) {
    const glyph={...M.copy(original),mirror,preserveWidth},strokes=M.copy(glyph.strokes),before=M.glyphBounds(glyph);
    M.fitGlyph(glyph,metrics);const bounds=M.glyphBounds(glyph);
    assert.ok(Math.abs(bounds.top-guides.cap)<1e-8);assert.ok(Math.abs(bounds.bottom-guides.baseline)<1e-8);
    assert.ok(Math.abs((bounds.left+bounds.right)/2-54.5)<1e-8);
    assert.ok(Math.abs(bounds.width/before.width-bounds.height/before.height)<1e-8);
    assert.deepEqual(glyph.strokes,strokes);
    const fitted=JSON.stringify(glyph);M.fitGlyph(glyph,metrics);assert.equal(JSON.stringify(glyph),fitted);
    const project=M.copy(seed);project.glyphs=[glyph];M.validate(project);
    assert.ok(M.svg(glyph,seed.attribution).includes(`scale(${glyph.placement.scale})`));
  }
  const invalid=M.copy(seed);invalid.glyphs[0].placement={scale:NaN,x:0,y:0};assert.throws(()=>M.validate(invalid));
});
check('Latin/Cyrillic custom signs and XML-special characters',()=>{
  const p=M.copy(seed);for(const character of ['R','Ж','<'])p.glyphs.push({character,stretch:.85,mirror:false,strokes:[M.copy(base)]});
  M.validate(p);assert.ok(M.svg(p.glyphs.at(-1),'A&B').includes('<title>&lt;</title>'));
});
if(process.argv[3]){
  fs.mkdirSync(process.argv[3],{recursive:true});
  for(const g of seed.glyphs)for(const mirror of [false,true]){
    const name=g.character.codePointAt(0).toString(16)+(mirror?'-mirror':'');
    fs.writeFileSync(path.join(process.argv[3],name+'.svg'),M.svg({...g,mirror},seed.attribution));
  }
}
console.log(`${checks} geometry/data checks passed`);
