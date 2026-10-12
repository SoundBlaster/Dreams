// Deterministic animation/event checks. This is not a browser-rendering test.
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import vm from 'node:vm';

const html = readFileSync(process.argv[2], 'utf8');
const script = html.match(/<script>([\s\S]*?)<\/script>/)[1];
let paints = 0, nextFrame = 1;
const frames = new Map(), elements = new Map(), documentEvents = new Map();
const context2d = Object.fromEntries(['clearRect','save','scale','translate','restore','beginPath','lineTo','moveTo','closePath'].map(k=>[k,()=>{}]));
context2d.fill = () => paints++;
function element(id) {
    if (!elements.has(id)) elements.set(id, {
        value: id === 'width' ? '8' : id === 'progress' ? '1000' : 'authored',
        checked: false, textContent: '', innerHTML: '', children: [], events: new Map(), attributes: {},
        setAttribute(k,v) { this.attributes[k]=v; },
        replaceChildren() { this.children=[]; },
        append(child) { this.children.push(child); },
        addEventListener(k,fn) { this.events.set(k,fn); },
        getContext() { return context2d; },
    });
    return elements.get(id);
}
const document = {
    hidden: false, getElementById: element,
    createElement: () => ({setAttribute(k,v){this[k]=v;}}),
    addEventListener: (k,fn) => documentEvents.set(k,fn),
};
const sandbox = vm.createContext({document,performance:{now:()=>0},
    requestAnimationFrame: fn => {const id=nextFrame++;frames.set(id,fn);return id;},
    cancelAnimationFrame: id => frames.delete(id),
});
vm.runInContext(script,sandbox);
assert.equal(JSON.stringify(sandbox.hull([[0,0],[2,0],[1,1],[1,0],[0,0]])),
    JSON.stringify([[0,0],[2,0],[1,1]]));
assert.equal(sandbox.hull([[0,0],[0,0],[1,0]]).length,2);
// A linear ramp must keep moving through its interior control point.
const ramp = [[0,0],[.4,.4],[1,1]];
for (let i=0;i<=100;i++) assert.ok(Math.abs(sandbox.interpolate(ramp,i/100)-i/100)<1e-12);
if(process.argv[3]) {
    for(const {knots,samples} of JSON.parse(readFileSync(process.argv[3],'utf8'))) {
        for(const [s,expected] of samples) assert.ok(Math.abs(sandbox.interpolate(knots,s)-expected)<1e-12);
    }
    console.log('PASS: Python export / JavaScript preview pressure parity');
}
assert.equal(element('alphabet').children.length,46);
assert.equal(element('title').textContent,'オ');
assert.ok(paints>0);
element('play').onclick();
assert.equal(+element('progress').value,0); // synchronous clear before RAF, even in a background tab
function frame(time) {const jobs=[...frames.values()];frames.clear();for(const job of jobs)job(time);}
paints=0;frame(1050);
assert.ok(Math.abs(+element('progress').value-500)<1e-9);
assert.ok(paints>0);
frame(2100);
assert.equal(+element('progress').value,1000);
assert.equal(frames.size,0);
assert.equal(element('play').textContent,'▶ Написать');
element('profile').value='tome';element('profile').events.get('change')();
assert.ok(element('pressure').innerHTML.includes('polyline'));
element('mirror').checked=true;element('mirror').events.get('input')();
assert.ok(element('skeleton').innerHTML.includes('translate(109 0) scale(-1 1)'));
element('play').onclick();
document.hidden=true;documentEvents.get('visibilitychange')();
assert.equal(frames.size,0);
document.hidden=false;
element('alphabet').children[11].onclick(); // シ
assert.equal(element('title').textContent,'シ');
assert.equal(element('profile').value,'authored');
element('strokes').children[2].onclick();
assert.ok(element('strokeInfo').textContent.startsWith('Штрих 3'));
assert.ok(element('normalSVG').href.endsWith('uni30B7.svg'));
console.log('PASS: catalogue initialization, timed writing, completion, profile change, reflection, visibility stop, glyph/stroke selection');
