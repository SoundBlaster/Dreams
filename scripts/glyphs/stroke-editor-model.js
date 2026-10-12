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
    let previous = [];
    for (let i=0; i<pts.length; i++) {
      const a = pts[Math.max(0,i-1)], b = pts[Math.min(pts.length-1,i+1)];
      // Build normals in displayed coordinates, then map back into the glyph group.
      const dx=(b[0]-a[0])*widthStretch, dy=b[1]-a[1], norm=Math.hypot(dx,dy)||1;
      const nx=-dy/norm/widthStretch, ny=dx/norm;
      const [x,y,s] = pts[i], r = widthAt(stroke,s)/2;
      const current = [[x+nx*r,y+ny*r],[x-nx*r,y-ny*r]];
      const polygon = hull([...previous,...current]);
      if (polygon.length >= 3) polygons.push(polygon);
      previous = current;
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
    return polygons.map(p => 'M'+p.map(v=>v.map(number).join(' ')).join('L')+'Z').join('');
  }
  function centerPath(stroke) {
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
    const ids = new Set();
    const finite = (v,a,b) => typeof v==='number' && Number.isFinite(v) && v>=a && v<=b;
    for (const g of project.glyphs) {
      if (typeof g.character !== 'string' || [...g.character].length !== 1 || /[\u0000-\u001f\u007f]/.test(g.character) || ids.has(g.character)) fail('Знаки должны быть уникальными одиночными символами');
      ids.add(g.character);
      if(g.preserveWidth!==undefined && typeof g.preserveWidth!=='boolean')fail('Неверный режим толщины');
      if (!finite(g.stretch,.5,1.2) || typeof g.mirror !== 'boolean') fail('Неверные пропорции знака');
      if (!Array.isArray(g.strokes) || !g.strokes.length || g.strokes.length>24) fail('Нужно от 1 до 24 штрихов');
      for (const st of g.strokes) {
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
    return `translate(54.5 0) scale(${glyph.stretch*(glyph.mirror?-1:1)} 1) translate(-54.5 0)`;
  }
  const exportCell={width:956,height:1024,x:96.5,y:74,scaleX:7,scaleY:8};
  function metricGuides(metrics) {
    const c=exportCell,toY=value=>(metrics.ascent-value-c.y)/c.scaleY;
    return {baseline:toY(0),cap:toY(metrics.capHeight),xHeight:toY(metrics.xHeight),
      ascent:toY(metrics.ascent),descent:toY(-metrics.descent),
      left:-c.x/c.scaleX,right:(metrics.advance-c.x)/c.scaleX,
      lineHeight:metrics.ascent+metrics.descent+(metrics.lineGap||0)};
  }
  function svg(glyph, attribution) {
    const escape = text => text.replaceAll('&','&amp;').replaceAll('<','&lt;').replaceAll('>','&gt;');
    // Same cell metrics as the existing katakana export. Guides are excluded from glyph reads.
    return `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ${exportCell.width} ${exportCell.height}" width="${exportCell.width}" height="${exportCell.height}"><title>${escape(glyph.character)}</title><metadata>${escape(attribution)}</metadata><g id="glyph" fill="black" fill-rule="nonzero" transform="translate(${exportCell.x} ${exportCell.y}) scale(${exportCell.scaleX} ${exportCell.scaleY})"><g transform="${transform(glyph)}">${glyph.strokes.map(s=>`<path d="${outline(s,glyph.preserveWidth?glyph.stretch:1)}"/>`).join('')}</g></g></svg>`;
  }
  const api = {point,samples,widthAt,outline,centerPath,setPoint,insertSegment,validate,transform,metricGuides,svg,copy,mix};
  if (typeof module !== 'undefined' && module.exports) module.exports = api;
  else root.StrokeEditorModel = api;
})(globalThis);
