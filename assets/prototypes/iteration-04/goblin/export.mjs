// Offline export/preview only. Never loaded by Godot. Requires sharp.
import fs from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { createRequire } from 'node:module';
const require = createRequire(import.meta.url);
const sharp = require(process.env.GAUNTLANDS_SHARP || 'sharp');
const root = path.dirname(fileURLToPath(import.meta.url));
const repo = path.resolve(root, '../../../..');
const out = path.join(root, 'east');
await fs.mkdir(out, {recursive:true});
const source = await sharp(path.join(root, 'source/generated-atlas.png')).ensureAlpha().resize(384,256,{kernel:'nearest'}).raw().toBuffer();
// One common 1:4 sampling grid; binary alpha keeps pixel edges crisp.
for(let i=0;i<source.length;i+=4){source[i+3]=source[i+3]>=128?255:0;if(!source[i+3])source.fill(0,i,i+3);}
const rows = ['idle','walk','attack','hurt','death'];
const anchor=[40,72], size=96;
const all=[], exportNotes=[];
for(let row=0;row<5;row++){
  const y0=Math.round(row*256/5),y1=Math.round((row+1)*256/5);
  const boundaries=row===4?[0,68,125,186,250,318,384]:[0,64,128,192,256,320,384];
  for(let col=0;col<6;col++){
    const x0=boundaries[col],x1=boundaries[col+1];
    let pts=[];
    for(let y=y0;y<y1;y++)for(let x=x0;x<x1;x++)if(source[(y*384+x)*4+3])pts.push([x,y]);
    const minX=Math.min(...pts.map(p=>p[0])),maxX=Math.max(...pts.map(p=>p[0]));
    const minY=Math.min(...pts.map(p=>p[1])),maxY=Math.max(...pts.map(p=>p[1]));
    const boots=pts.filter(p=>p[1]>=maxY-1);
    let groundX=Math.round((Math.min(...boots.map(p=>p[0]))+Math.max(...boots.map(p=>p[0])))/2);
    // Falling poses retain a rear-foot pivot while the torso falls forward.
    if(row===4 && col>=2)groundX=[0,0,138,201,262,330][col];
    const frame=Buffer.alloc(size*size*4);
    for(const [x,y] of pts){
      const dx=x-groundX+anchor[0],dy=y-maxY+anchor[1]-1;
      if(dx<2||dx>=size-2||dy<2||dy>=size-2)throw Error('Clipped pose '+rows[row]+' '+col);
      source.copy(frame,(dy*size+dx)*4,(y*384+x)*4,(y*384+x)*4+4);
    }
    const name=`${rows[row]}_${String(col).padStart(3,'0')}.png`;
    const png=await sharp(frame,{raw:{width:size,height:size,channels:4}}).png().toBuffer();
    await fs.writeFile(path.join(out,name),png);
    all.push({clip:rows[row],index:col,name,png});
    exportNotes.push({file:'east/'+name,source_bounds:[x0*4,y0*4,(x1-x0)*4,(y1-y0)*4],sampled_ground_anchor:[groundX,maxY+1],bounds:[minX,minY,maxX,maxY]});
  }
}
const clips={
 idle:{loop:true,durations_ms:Array(6).fill(200),note:'Cosmetic 1.2-second breathing loop; existing idle has no gameplay duration.'},
 walk:{loop:true,durations_ms:Array(6).fill(4000/54),note:'Six samples over existing 4/9-second walk cycle. Existing movement remains 54 world px/s.'},
 attack:{loop:false,durations_ms:[250,250,70,70,330,330],phases:[{name:'windup',start_ms:0,end_ms:500},{name:'contact',start_ms:500,end_ms:640},{name:'recovery',start_ms:640,end_ms:1300}],note:'Existing goblin timings, not player timings. Preview replay is a review control only.'},
 hurt:{loop:false,durations_ms:Array(6).fill(160/6),note:'Cosmetic 0.16-second reaction only; does not add a stun or cancel an attack.'},
 death:{loop:false,durations_ms:[100,100,100,100,100,220],hold_last:true,note:'720ms offline presentation study only. Gameplay death/collision removal/loot remains immediate; no new corpse/respawn timer is proposed.'}
};
for(const [clip,def] of Object.entries(clips))def.frames=all.filter(f=>f.clip===clip).map(f=>'east/'+f.name);
const manifest={status:'Milestone A prototype; awaiting user visual approval; no integration',direction:'east (fixed right-facing three-quarter view)',canvas_px:[size,size],ground_pivot_px:anchor,scale:'1 native image pixel = 1 world pixel in the 640px viewport; enlargement uses nearest neighbour',format:'RGBA PNG; binary alpha; identical canvas; no per-frame scaling',source:'source/generated-atlas.png',source_size_px:[1536,1024],sampling:'One shared 1:4 nearest-neighbour grid, transparent threshold 128; translation only for foot alignment; no anatomy redrawing or interpolation',clips,exports:exportNotes};
await fs.writeFile(path.join(root,'manifest.json'),JSON.stringify(manifest,null,2)+'\n');
const dataURI=b=>'data:image/png;base64,'+b.toString('base64');
const texts=[];const overlays=[];
texts.push('<rect width="1240" height="1200" fill="#12171b"/>','<text x="32" y="40" fill="#e8dfca" font-size="25">GAUNTLANDS / GOBLIN MOTION STUDY</text>','<text x="32" y="68" fill="#aab3b5" font-size="14">Milestone A · east only · 96 × 96 RGBA · 2× nearest-neighbour · pivot (40, 72)</text>');
const captions={idle:['breath 1','breath 2','breath 3','breath 4','breath 5','breath 6'],walk:['step 1','step 2','step 3','step 4','step 5','step 6'],attack:['WINDUP · 250ms','WINDUP · 250ms','CONTACT · 70ms','CONTACT · 70ms','RECOVER · 330ms','RECOVER · 330ms'],hurt:['recoil 1','recoil 2','recoil 3','settle 1','settle 2','guard'],death:['buckle','crouch','fall','impact','settle','hold final']};
for(let r=0;r<5;r++){
 const y=110+r*214;
 texts.push(`<text x="32" y="${y}" fill="#c6b887" font-size="16">${rows[r].toUpperCase()}</text>`);
 for(let c=0;c<6;c++){
  const x=24+c*200,fy=y+8;
  texts.push(`<rect x="${x}" y="${fy}" width="192" height="158" rx="5" fill="#252c32"/><path d="M${x+8} ${fy+110}h176" stroke="#506054" stroke-dasharray="3 4"/><text x="${x+8}" y="${fy+181}" fill="#aeb8bb" font-size="12">${captions[rows[r]][c]}</text>`);
  const f=all[r*6+c];
  // Top of 96px canvas is intentionally cropped from review panels only.
  overlays.push({input:await sharp(f.png).resize(192,192,{kernel:'nearest'}).extract({left:0,top:34,width:192,height:158}).toBuffer(),left:x,top:fy});
 }
}
await sharp(Buffer.from(`<svg xmlns="http://www.w3.org/2000/svg" width="1240" height="1200"><g font-family="Arial">${texts.join('')}</g></svg>`)).composite(overlays).png().toFile(path.join(root,'contact-sheet.png'));
const room=await fs.readFile(path.join(repo,'assets/room.png'));
const old=await sharp(path.join(repo,'assets/goblin.png')).extract({left:0,top:96,width:48,height:48}).png().toBuffer();
const reference=await fs.readFile(path.join(repo,'assets/concepts/wide_dark_pixel_art_game_asset_sheet_illustration.png'));
const frameData=Object.fromEntries(all.map(f=>['east/'+f.name,dataURI(f.png)]));
const comparisonSvg=`<svg xmlns="http://www.w3.org/2000/svg" width="1280" height="800"><rect width="1280" height="800" fill="#12171b"/><g font-family="Arial" fill="#e8dfca"><text x="24" y="36" font-size="22">APPROVED REFERENCE / PROTOTYPE AT GAMEPLAY SCALE</text><text x="24" y="74" font-size="15">Reference: original goblin sheet</text><text x="664" y="74" font-size="15">Unchanged room.png · original actor left / prototype right</text><text x="664" y="510" font-size="15">Prototype guard and sword contact · 3× inspection</text><text x="24" y="778" font-size="14">Offline comparison only. No assets are connected to the game. Visual approval pending.</text></g></svg>`;
const roomComparison=await sharp(room).composite([{input:old,left:176,top:222},{input:all[0].png,left:360,top:192}]).png().toBuffer();
await sharp(Buffer.from(comparisonSvg)).composite([
 {input:await sharp(reference).resize(608,405).toBuffer(),left:24,top:90},
 {input:roomComparison,left:640,top:90},
 {input:await sharp(all[0].png).resize(288,288,{kernel:'nearest'}).toBuffer(),left:660,top:464},
 {input:await sharp(all[14].png).resize(288,288,{kernel:'nearest'}).toBuffer(),left:968,top:464}
]).png().toFile(path.join(root,'reference-comparison.png'));
const html=`<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Gauntlands — Goblin Milestone A</title>
<style>*{box-sizing:border-box}body{margin:0;background:#11161a;color:#e5e0d3;font:15px system-ui,sans-serif}main{max-width:1200px;margin:auto;padding:28px}h1{font-size:28px;margin:0 0 7px}p{color:#aab4b7;line-height:1.6}header{border-bottom:1px solid #394147;margin-bottom:22px;padding-bottom:16px}.badge{color:#d2bf83;font-size:12px;letter-spacing:2px}button,select,input{background:#273139;color:#eee6d3;border:1px solid #4b5961;border-radius:5px;padding:8px;margin:4px 4px 4px 0}button{cursor:pointer}button:hover{background:#3e4d55}.controls{display:flex;flex-wrap:wrap;align-items:center;gap:4px}.views{display:grid;grid-template-columns:416px 1fr;gap:20px;margin:20px 0}.panel{background:#1a2228;border:1px solid #343f46;border-radius:10px;padding:16px}.zoom{width:384px;height:384px;background:repeating-conic-gradient(#252e35 0% 25%,#303940 0% 50%) 0/24px 24px;image-rendering:pixelated}canvas{max-width:100%;image-rendering:pixelated}.room{width:640px;height:384px;max-width:none}h2{font-size:15px;margin:0 0 12px}#status{font-variant-numeric:tabular-nums;color:#d2bf83;min-height:26px}#timeline{width:100%;margin:12px 0}.sheet{width:100%;display:block;border-radius:8px}.legend{font-size:12px}.phase{display:flex;height:8px;margin-top:12px;border-radius:4px;overflow:hidden}.phase span:nth-child(1){background:#b79b54;flex:500}.phase span:nth-child(2){background:#c76955;flex:140}.phase span:nth-child(3){background:#668a91;flex:660}details{margin-top:20px}summary{cursor:pointer;padding:12px 0}label{font-size:13px}a{color:#c5b884}@media(max-width:900px){.views{grid-template-columns:1fr}.zoom{width:384px;height:384px}}</style>
<main><header><div class="badge">ITERATION 04 · MILESTONE A · VISUAL APPROVAL PENDING</div><h1>Goblin motion study</h1><p>One east-facing goblin. Transparent, aligned frames. Review the face, equipment, planted feet and sword phases before approving further art.</p></header>
<div class="controls"><label>Clip <select id="clip"><option value="idle">Idle</option><option value="walk">Walk</option><option value="attack">Sword attack</option><option value="hurt">Hurt</option><option value="death">Death</option></select></label><button id="play">Pause</button><button id="restart">Replay</button><button id="step">Next frame</button><label>Speed <select id="speed"><option value="1">1× timing</option><option value="0.25">¼× inspection</option><option value="0.5">½×</option></select></label><label><input id="anchor" type="checkbox" checked>Show ground anchor</label></div>
<div class="views"><section class="panel"><h2>Enlarged pixel inspection</h2><canvas id="zoom" class="zoom" width="384" height="384"></canvas><div id="status"></div><input id="timeline" aria-label="Animation timeline" type="range" min="0" max="1200" step="1" value="0"><div class="phase"><span></span><span></span><span></span></div><p class="legend">Sword: windup 500ms · contact 140ms · recovery 660ms. Single actions hold their final pose; use Replay.</p></section><section class="panel"><h2>Actual 1× scale on the existing dungeon artwork</h2><canvas id="room" class="room" width="640" height="384"></canvas><p class="legend">Original goblin on the left; prototype on the right. One canvas pixel equals one world pixel. The enlarged panel uses nearest-neighbour sampling. This is an offline art mockup, not a running game.</p></section></div>
<details open><summary>All frames and phase boundaries</summary><img class="sheet" src="contact-sheet.png" alt="Labelled animation contact sheet"></details><details><summary>Approved reference and scale comparison</summary><img class="sheet" src="reference-comparison.png" alt="Reference comparison"><img class="sheet" src="${dataURI(reference)}" alt="Full approved goblin concept sheet"></details><p class="legend"><a href="manifest.json">Frame and timing manifest</a> · <a href="README.md">Provenance and review notes</a> · No gameplay integration. Death duration is a visual study only; gameplay death remains immediate.</p></main>
<script>const clips=${JSON.stringify(clips)},urls=${JSON.stringify(frameData)};const imgs={};function load(src){return new Promise(resolve=>{let im=new Image;im.onload=()=>resolve(im);im.src=src})}let roomImage,oldImage;let active='idle',time=0,playing=true,speed=1,last=0;const $=id=>document.getElementById(id);const zoom=$('zoom').getContext('2d'),room=$('room').getContext('2d');function duration(){return clips[active].durations_ms.reduce((a,b)=>a+b,0)}function current(){let t=time,def=clips[active];for(let i=0;i<def.frames.length;i++){if(t<def.durations_ms[i])return i;t-=def.durations_ms[i]}return def.frames.length-1}function draw(){let def=clips[active],i=current(),im=imgs[def.frames[i]];zoom.imageSmoothingEnabled=false;room.imageSmoothingEnabled=false;zoom.clearRect(0,0,384,384);zoom.drawImage(im,0,0,384,384);room.clearRect(0,0,640,384);room.drawImage(roomImage,0,0);room.drawImage(oldImage,176,222);room.drawImage(im,360,192);if($('anchor').checked){for(const [ctx,x,y,s] of [[zoom,40*4,72*4,1],[room,400,264,1]]){ctx.strokeStyle='#7dcbb4';ctx.lineWidth=1;ctx.beginPath();ctx.moveTo(x-6,y+.5);ctx.lineTo(x+6,y+.5);ctx.moveTo(x+.5,y-4);ctx.lineTo(x+.5,y+4);ctx.stroke()}}let phase=active==='attack'?(time<500?'WINDUP':time<640?'CONTACT':'RECOVERY'):active.toUpperCase();$('status').textContent=phase+' · frame '+String(i).padStart(3,'0')+' · '+Math.round(time)+' / '+Math.round(duration())+' ms';$('timeline').value=time}function switchClip(){active=$('clip').value;time=0;$('timeline').max=duration();playing=true;$('play').textContent='Pause';draw()}$('clip').onchange=switchClip;$('play').onclick=()=>{playing=!playing;$('play').textContent=playing?'Pause':'Play'};$('restart').onclick=()=>{time=0;playing=true;$('play').textContent='Pause'};$('step').onclick=()=>{playing=false;$('play').textContent='Play';let i=(current()+1)%clips[active].frames.length;time=clips[active].durations_ms.slice(0,i).reduce((a,b)=>a+b,0)+.001;draw()};$('speed').onchange=()=>speed=+$('speed').value;$('timeline').oninput=()=>{time=+$('timeline').value;playing=false;$('play').textContent='Play';draw()};$('anchor').onchange=draw;function tick(now){if(playing){time+=Math.min(now-last,100)*speed;const total=duration();if(time>=total){if(clips[active].loop)time%=total;else{time=total;playing=false;$('play').textContent='Play'}}}last=now;draw();requestAnimationFrame(tick)};(async()=>{await Promise.all(Object.entries(urls).map(async([k,v])=>imgs[k]=await load(v)));roomImage=await load('${dataURI(room)}');oldImage=await load('${dataURI(old)}');switchClip();requestAnimationFrame(tick);window.previewReady=true})();</script></html>`;
await fs.writeFile(path.join(root,'preview.html'),html);
// Convenient looping review movie. Precise millisecond playback is in the HTML.
const movie=[],delays=[];
for(const clip of rows){
  const repeats=clip==='walk'?3:1;
  for(let repeat=0;repeat<repeats;repeat++)for(let i=0;i<6;i++){
    const f=all.find(f=>f.clip===clip&&f.index===i);
    let label=clip.toUpperCase();
    if(clip==='attack')label+=' / '+(i<2?'WINDUP':i<4?'CONTACT':'RECOVERY');
    const heading=Buffer.from(`<svg xmlns="http://www.w3.org/2000/svg" width="1024" height="448"><rect width="1024" height="448" fill="#151c22"/><g font-family="Arial" fill="#ddd5c1"><text x="16" y="28" font-size="18">GOBLIN / ${label}</text><text x="16" y="52" font-size="12">Existing room · original left / prototype right · 1×</text><text x="656" y="52" font-size="12">4× nearest-neighbour inspection</text></g></svg>`);
    movie.push(await sharp(heading).composite([{input:room,left:0,top:64},{input:old,left:176,top:286},{input:f.png,left:360,top:256},{input:await sharp(f.png).resize(384,384,{kernel:'nearest'}).toBuffer(),left:640,top:64}]).png().toBuffer());
    delays.push(Math.round(clips[clip].durations_ms[i])+(clip==='death'&&i===5?1200:0));
  }
}
await sharp(movie,{join:{animated:true}}).gif({delay:delays,loop:0,effort:7}).toFile(path.join(root,'animation-preview.gif'));
console.log(JSON.stringify({frames:all.length,canvas:[96,96],pivot:anchor,alpha:[0,255],clips:Object.keys(clips),exports:'east/',preview:'preview.html'},null,2));
