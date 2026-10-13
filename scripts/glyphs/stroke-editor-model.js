/* Parametric centerlines and width envelopes; shared by browser and Node checks. */
(function (root) {
  'use strict';
  const clamp = (v, a, b) => Math.max(a, Math.min(b, v));
  const mix = (a, b, t) => a.map((v, i) => v + (b[i] - v) * t);
  const distance = (a, b) => Math.hypot(a[0] - b[0], a[1] - b[1]);
  const copy = value => JSON.parse(JSON.stringify(value));
  function point(segment, t) {
    if (segment.kind === 'line') return mix(segment.start, segment.end, t);
    // The middle handle lies ON the curve at t=.5, not off-curve like a Bezier control.
    const control = segment.mid.map((v, i) => 2 * v - (segment.start[i] + segment.end[i]) / 2);
    return mix(mix(segment.start, control, t), mix(control, segment.end, t), t);
  }
  function samples(stroke) {
    const raw = [stroke.segments[0].start];
    for (const segment of stroke.segments) {
      for (let i = 1; i <= 48; i++) {
        const p = point(segment, i / 48);
        if (distance(p, raw.at(-1)) > 1e-7) raw.push(p);
      }
    }
    if (raw.length < 2) return [];
    const lengths = [0];
    for (let i = 1; i < raw.length; i++) lengths.push(lengths.at(-1) + distance(raw[i], raw[i - 1]));
    const total = lengths.at(-1), result = [];
    // Uniform physical spacing: width peak is a fraction of ARC LENGTH.
    const count = Math.min(1600, Math.max(2, Math.ceil(total / .4)));
    let j = 0;
    for (let i = 0; i <= count; i++) {
      const d = total * i / count;
      while (j + 1 < raw.length - 1 && lengths[j + 1] < d) j++;
      result.push([...mix(raw[j], raw[j + 1], (d - lengths[j]) / (lengths[j + 1] - lengths[j])), i / count]);
    }
    return result;
  }
  function widthAt(stroke, s) {
    const peak = stroke.peak;
    const a = stroke.startCap === 'sharp' ? 0 : stroke.startWidth;
    const b = stroke.endCap === 'sharp' ? 0 : stroke.endWidth;
    const smooth = t => t * t * (3 - 2 * t);
    return s <= peak ? a + (stroke.width - a) * smooth(s / peak)
      : stroke.width + (b - stroke.width) * smooth((s - peak) / (1 - peak));
  }
  function hull(points) {
    const sorted = [...new Map(points.map(p => [p.join(','), p])).values()].sort((a,b) => a[0]-b[0] || a[1]-b[1]);
    if (sorted.length < 3) return sorted;
    function half(points) {
      const out = [];
      for (const p of points) {
        while (out.length > 1) {
          const a=out.at(-2), b=out.at(-1);
          if ((b[0]-a[0])*(p[1]-a[1])-(b[1]-a[1])*(p[0]-a[0]) > 0) break;
          out.pop();
        }
        out.push(p);
      }
      return out.slice(0,-1);
    }
    return [...half(sorted), ...half([...sorted].reverse())];
  }
  const number = v => Number(v.toFixed(4));
  function outline(stroke, widthStretch=1) {
    const pts = samples(stroke), polygons = [];
    // Explicit joins sweep each section independently, retaining global arc-length pressure.
    let groups=[pts];
    if(stroke.join && stroke.join!=='legacy') {
      groups=stroke.segments.map(segment=>samples({segments:[segment]})).filter(group=>group.length>1);
      const lengths=groups.map(group=>group.slice(1).reduce((sum,p,i)=>sum+distance(p,group[i]),0)),total=lengths.reduce((a,b)=>a+b,0);
      let offset=0;
      groups=groups.map((group,i)=>{const result=group.map(p=>[p[0],p[1],(offset+p[2]*lengths[i])/total]);offset+=lengths[i];return result;});
    }
    for(const group of groups) {
    let previous = [];
    for (let i=0; i<group.length; i++) {
      const a = group[Math.max(0,i-1)], b = group[Math.min(group.length-1,i+1)];
      // Build normals in displayed coordinates, then map back into the glyph group.
      const dx=(b[0]-a[0])*widthStretch, dy=b[1]-a[1], norm=Math.hypot(dx,dy)||1;
      const nx=-dy/norm/widthStretch, ny=dx/norm;
      const [x,y,s] = group[i], r = widthAt(stroke,s)/2;
      const current = [[x+nx*r,y+ny*r],[x-nx*r,y-ny*r]];
      const polygon = hull([...previous,...current]);
      if (polygon.length >= 3) polygons.push(polygon);
      previous = current;
    }
    }
    if(groups.length>1)for(let i=1;i<groups.length;i++) {
      const before=groups[i-1],after=groups[i],p=after[0],r=widthAt(stroke,p[2])/2;
      const tangent=(a,b)=>{const dx=(b[0]-a[0])*widthStretch,dy=b[1]-a[1],l=Math.hypot(dx,dy);return l>1e-9?[dx/l,dy/l]:null;};
      const u=tangent(before.at(-2),before.at(-1)),v=tangent(after[0],after[1]);if(!u||!v||!r)continue;
      const cross=u[0]*v[1]-u[1]*v[0];if(Math.abs(cross)<1e-7)continue;
      const sign=cross>0?-1:1,local=q=>[p[0]+q[0]/widthStretch,p[1]+q[1]];
      const a=[-u[1]*r*sign,u[0]*r*sign],b=[-v[1]*r*sign,v[0]*r*sign];
      if(stroke.join==='round') {
        polygons.push(hull(Array.from({length:48},(_,j)=>local([Math.cos(j*Math.PI/24)*r,Math.sin(j*Math.PI/24)*r]))));
      } else {
        const wedge=[[p[0],p[1]],local(a)];
        if(stroke.join==='miter') {
          const t=((b[0]-a[0])*v[1]-(b[1]-a[1])*v[0])/cross,tip=[a[0]+t*u[0],a[1]+t*u[1]];
          // Limit acute spikes to four half-widths, falling back to bevel.
          if(Math.hypot(...tip)<=r*4)wedge.push(local(tip));
        }
        wedge.push(local(b));polygons.push(hull(wedge));
      }
    }
    // Shallow half-ellipses soften each terminal independently. Their depth is
    // 35% of the local half-width, so the tip stays gently rounded, not bulbous.
    for (const end of [false, true]) {
      if (stroke[end ? 'endCap' : 'startCap'] !== 'round' || pts.length < 2) continue;
      const p = end ? pts.at(-1) : pts[0], inside = end ? pts.at(-2) : pts[1];
      const length = Math.hypot((p[0]-inside[0])*widthStretch,p[1]-inside[1]), r = widthAt(stroke, end ? 1 : 0) / 2;
      if (!length || !r) continue;
      const tx = (p[0] - inside[0])*widthStretch / length, ty = (p[1] - inside[1]) / length;
      const cap = [];
      for (let i = 0; i <= 16; i++) {
        const angle = -Math.PI / 2 + Math.PI * i / 16;
        const along = Math.cos(angle) * r * .35, across = Math.sin(angle) * r;
        cap.push([p[0] + (tx * along - ty * across)/widthStretch, p[1] + ty * along + tx * across]);
      }
      polygons.push(hull(cap));
    }
    // Consistently wound overlapping sweep cells: intersections add ink, never XOR.
    const offset=stroke.offset||[0,0];
    return polygons.map(p => 'M'+p.map(v=>v.map((n,i)=>number(n+offset[i])).join(' ')).join('L')+'Z').join('');
  }
  function centerPath(stroke) {
    if(stroke.offset)stroke={...stroke,segments:stroke.segments.map(s=>({...s,...Object.fromEntries(['start','mid','end'].map(k=>[k,s[k].map((n,i)=>n+stroke.offset[i])]))}))};
    let d = 'M'+stroke.segments[0].start.join(' ');
    for (const s of stroke.segments) {
      if (s.kind === 'line') d += 'L'+s.end.join(' ');
      else {
        const c = s.mid.map((v,i)=>2*v-(s.start[i]+s.end[i])/2);
        d += 'Q'+c.join(' ')+' '+s.end.join(' ');
      }
    }
    return d;
  }
  function setPoint(stroke, index, key, p) {
    p = p.map(v=>number(clamp(v,0,109)));
    stroke.segments[index][key] = p;
    if (key === 'mid') stroke.segments[index].kind = 'arc';
    if (key === 'start' && index) stroke.segments[index-1].end = [...p];
    if (key === 'end' && index+1 < stroke.segments.length) stroke.segments[index+1].start = [...p];
    for (const s of stroke.segments) if (s.kind === 'line') s.mid = mix(s.start,s.end,.5);
  }
  function insertSegment(stroke,index,side) {
    if(!['before','after'].includes(side)||!Number.isInteger(index)||!stroke.segments[index])throw new Error('Выбери участок штриха');
    if(stroke.segments.length>=32)throw new Error('Максимум 32 участка');
    const before=side==='before', neighborIndex=before?index-1:index+1;
    const neighbor=stroke.segments[neighborIndex];
    if(neighbor) {
      // Exact subdivision keeps the existing curve and joins in place.
      const half=point(neighbor,.5);
      const first={kind:neighbor.kind,start:[...neighbor.start],mid:point(neighbor,.25),end:[...half]};
      const second={kind:neighbor.kind,start:[...half],mid:point(neighbor,.75),end:[...neighbor.end]};
      stroke.segments.splice(neighborIndex,1,first,second);
      return before?index:index+1;
    }
    const part=stroke.segments[index],anchor=before?part.start:part.end;
    const inside=point(part,before?.01:.99);
    let dx=anchor[0]-inside[0],dy=anchor[1]-inside[1],length=Math.hypot(dx,dy);
    if(length<1e-8){dx=before?part.start[0]-part.end[0]:part.end[0]-part.start[0];dy=before?part.start[1]-part.end[1]:part.end[1]-part.start[1];length=Math.hypot(dx,dy);}
    let outside=anchor.map((v,i)=>number(clamp(v+12*(i?dy:dx)/(length||1),0,109)));
    if(distance(anchor,outside)<.1)outside=mix(anchor,[54.5,54.5],.2).map(number);
    const start=before?outside:[...anchor],end=before?[...anchor]:outside;
    const insertion=before?index:index+1;
    stroke.segments.splice(insertion,0,{kind:'line',start,mid:mix(start,end,.5),end});
    return insertion;
  }
  function validate(project) {
    const fail = message => {throw new Error(message);};
    if (!project || project.schema !== 'dreams.stroke-editor/v1') fail('Неподдерживаемый формат проекта');
    if (!Array.isArray(project.glyphs) || !project.glyphs.length || project.glyphs.length > 256) fail('Нужно от 1 до 256 знаков');
    if (typeof project.attribution !== 'string' || project.attribution.length > 4000) fail('Нет сведений об источнике');
    const components=project.components===undefined?[]:project.components;
    if(!Array.isArray(components)||components.length>256||new Set(components.map(c=>c?.id)).size!==components.length)fail('Неверная библиотека компонентов');
    for(const c of components) {
      if(!c||typeof c.id!=='string'||!/^[a-zA-Z0-9_-]{1,80}$/.test(c.id)||typeof c.name!=='string'||!c.name.trim()||c.name.length>120||!c.stroke||c.stroke.componentId!==undefined||c.stroke.offset!==undefined)fail('Неверный компонент');
      validate({schema:project.schema,attribution:project.attribution,glyphs:[{character:'X',stretch:1,mirror:false,strokes:[c.stroke]}]});
    }
    const ids = new Set();
    const finite = (v,a,b) => typeof v==='number' && Number.isFinite(v) && v>=a && v<=b;
    for (const g of project.glyphs) {
      if (typeof g.character !== 'string' || [...g.character].length !== 1 || /[\u0000-\u001f\u007f]/.test(g.character) || ids.has(g.character)) fail('Знаки должны быть уникальными одиночными символами');
      ids.add(g.character);
      if(g.preserveWidth!==undefined && typeof g.preserveWidth!=='boolean')fail('Неверный режим толщины');
      if(g.placement!==undefined && (!g.placement || !finite(g.placement.scale,.05,20) || !finite(g.placement.x,-2000,2000) || !finite(g.placement.y,-2000,2000)))fail('Неверное размещение знака');
      if (!finite(g.stretch,.5,1.2) || typeof g.mirror !== 'boolean') fail('Неверные пропорции знака');
      if (!Array.isArray(g.strokes) || !g.strokes.length || g.strokes.length>24) fail('Нужно от 1 до 24 штрихов');
      for (const st of g.strokes) {
        if(!st||typeof st!=='object')fail('Неверный штрих');
        if(st.offset!==undefined&&(!Array.isArray(st.offset)||st.offset.length!==2||!st.offset.every(v=>finite(v,-2000,2000))))fail('Неверное положение штриха');
        if(st.componentId!==undefined){if(typeof st.componentId!=='string'||!components.some(c=>c.id===st.componentId)||st.segments!==undefined)fail('Неверная ссылка на компонент');continue;}
        if(st.join!==undefined&&!['legacy','miter','bevel','round'].includes(st.join))fail('Неверное соединение участков');
        if (!finite(st.width,.5,16) || !finite(st.startWidth,0,st.width) || !finite(st.endWidth,0,st.width) || !finite(st.peak,.05,.95)) fail('Неверный профиль толщины');
        if (!['sharp','flat','round'].includes(st.startCap) || !['sharp','flat','round'].includes(st.endCap)) fail('Неверное окончание');
        if (!Array.isArray(st.segments) || !st.segments.length || st.segments.length>32) fail('Нужно от 1 до 32 участков');
        for (let i=0;i<st.segments.length;i++) {
          const seg=st.segments[i];
          if (!['line','arc'].includes(seg.kind)) fail('Неизвестный вид участка');
          for (const k of ['start','mid','end']) if (!Array.isArray(seg[k]) || seg[k].length!==2 || !seg[k].every(v=>finite(v,0,109))) fail('Координаты должны лежать в 0…109');
          if (i && distance(st.segments[i-1].end,seg.start)>1e-4) fail('Разрыв между участками штриха');
        }
        if (!samples(st).length) fail('Штрих имеет нулевую длину');
      }
    }
    return project;
  }
  function transform(glyph) {
    const p=glyph.placement;
    return (p?`translate(${p.x} ${p.y}) scale(${p.scale}) `:'')+`translate(54.5 0) scale(${glyph.stretch*(glyph.mirror?-1:1)} 1) translate(-54.5 0)`;
  }
  const exportCell={width:956,height:1024,x:96.5,y:74,scaleX:7,scaleY:8};
  function metricGuides(metrics) {
    const c=exportCell,toY=value=>(metrics.ascent-value-c.y)/c.scaleY;
    return {baseline:toY(0),cap:toY(metrics.capHeight),xHeight:toY(metrics.xHeight),
      ascent:toY(metrics.ascent),descent:toY(-metrics.descent),
      left:-c.x/c.scaleX,right:(metrics.advance-c.x)/c.scaleX,
      lineHeight:metrics.ascent+metrics.descent+(metrics.lineGap||0)};
  }
  function glyphBounds(glyph,paths=glyph.strokes.map(s=>outline(s,glyph.preserveWidth?glyph.stretch:1))) {
    const p=glyph.placement||{scale:1,x:0,y:0},xs=[],ys=[];
    for(const path of paths) {
      const values=(path.match(/-?\d+(?:\.\d+)?/g)||[]).map(Number);
      for(let i=0;i<values.length;i+=2){xs.push((54.5+(values[i]-54.5)*glyph.stretch*(glyph.mirror?-1:1))*p.scale+p.x);ys.push(values[i+1]*p.scale+p.y);}
    }
    const left=Math.min(...xs),top=Math.min(...ys),right=Math.max(...xs),bottom=Math.max(...ys);
    return {left,top,right,bottom,width:right-left,height:bottom-top};
  }
  function fitGlyph(glyph,metrics) {
    const bounds=glyphBounds(glyph),guides=metricGuides(metrics),p=glyph.placement||{scale:1,x:0,y:0};
    if(bounds.height<1e-6)throw new Error('Контур слишком мал для вписывания');
    const factor=(guides.baseline-guides.cap)/bounds.height;
    const placement={scale:p.scale*factor,x:54.5-((bounds.left+bounds.right)/2-p.x)*factor,y:guides.cap-(bounds.top-p.y)*factor};
    if(placement.scale<.05||placement.scale>20||Math.abs(placement.x)>2000||Math.abs(placement.y)>2000)throw new Error('Масштаб вписывания вне допустимого диапазона');
    // Avoid accumulating floating-point drift when the button is pressed again.
    if(Math.abs(factor-1)>1e-10||Math.abs((bounds.left+bounds.right)/2-54.5)>1e-10||Math.abs(bounds.top-guides.cap)>1e-10)glyph.placement=placement;
  }
  function strokeShape(project,instance) {
    if(!instance.componentId)return instance;
    const component=project.components?.find(c=>c.id===instance.componentId);
    if(!component)throw new Error('Компонент не найден');return component.stroke;
  }
  function resolveGlyph(project,glyph) {
    return {...glyph,strokes:glyph.strokes.map(st=>st.componentId?{...strokeShape(project,st),...(st.offset?{offset:st.offset}:{})}:st)};
  }
  function svg(glyph, attribution, project) {
    if(project)glyph=resolveGlyph(project,glyph);
    const escape = text => text.replaceAll('&','&amp;').replaceAll('<','&lt;').replaceAll('>','&gt;');
    // Same cell metrics as the existing katakana export. Guides are excluded from glyph reads.
    return `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ${exportCell.width} ${exportCell.height}" width="${exportCell.width}" height="${exportCell.height}"><title>${escape(glyph.character)}</title><metadata>${escape(attribution)}</metadata><g id="glyph" fill="black" fill-rule="nonzero" transform="translate(${exportCell.x} ${exportCell.y}) scale(${exportCell.scaleX} ${exportCell.scaleY})"><g transform="${transform(glyph)}">${glyph.strokes.map(s=>`<path d="${outline(s,glyph.preserveWidth?glyph.stretch:1)}"/>`).join('')}</g></g></svg>`;
  }
  const api = {point,samples,widthAt,outline,centerPath,setPoint,insertSegment,validate,transform,metricGuides,glyphBounds,fitGlyph,strokeShape,resolveGlyph,svg,copy,mix};
  if (typeof module !== 'undefined' && module.exports) module.exports = api;
  else root.StrokeEditorModel = api;
})(globalThis);
