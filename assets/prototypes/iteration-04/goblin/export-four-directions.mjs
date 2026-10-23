// Offline Milestone B asset export and review only. Never loaded by Godot.
import fs from 'node:fs/promises';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
import {createRequire} from 'node:module';
const require=createRequire(import.meta.url);
const sharp=require(process.env.GAUNTLANDS_SHARP||'sharp');
const root=path.dirname(fileURLToPath(import.meta.url)),repo=path.resolve(root,'../../../..');
const review=path.join(root,'four-direction');
await fs.mkdir(review,{recursive:true});
const directions=['south','west','north','east'],clips=['idle','walk','attack','hurt','death'];
const original=JSON.parse(await fs.readFile(path.join(root,'manifest.json'),'utf8'));
const timing=structuredClone(original.clips);
for(const t of Object.values(timing))delete t.frames;
const atlas={},exportNotes=[];
const hurtPixels=await sharp(path.join(root,'source/milestone-b-north-hurt.png')).ensureAlpha().resize(171,114,{kernel:'nearest'}).raw().toBuffer();
for(let p=0;p<hurtPixels.length;p+=4){hurtPixels[p+3]=hurtPixels[p+3]>=128?255:0;if(!hurtPixels[p+3])hurtPixels.fill(0,p,p+3);}
for(const direction of directions){
  atlas[direction]={};
  if(direction!=='east'){
    const sourcePath=path.join(root,`source/milestone-b-${direction}.png`);
    const meta=await sharp(sourcePath).metadata();
    if(meta.width!==1536||meta.height!==1024)throw Error('Unexpected source dimensions: '+direction);
    const pixels=await sharp(sourcePath).ensureAlpha().resize(384,256,{kernel:'nearest'}).raw().toBuffer();
    for(let p=0;p<pixels.length;p+=4){pixels[p+3]=pixels[p+3]>=128?255:0;if(!pixels[p+3])pixels.fill(0,p,p+3);}
    const rowOccupancy=Array(256).fill(0);
    for(let y=0;y<256;y++)for(let x=0;x<384;x++)if(pixels[(y*384+x)*4+3])rowOccupancy[y]++;
    const rowBounds=[0];
    for(let r=1;r<5;r++){
      const target=Math.round(r*256/5);let best=target,score=Infinity;
      for(let y=target-8;y<=target+8;y++){const s=rowOccupancy[y]*100+Math.abs(y-target);if(s<score){best=y;score=s;}}
      rowBounds.push(best);
    }
    rowBounds.push(256);
    await fs.mkdir(path.join(root,direction),{recursive:true});
    for(let r=0;r<5;r++){
      const y0=rowBounds[r],y1=rowBounds[r+1];
      // Prefer empty source gutters near each nominal cell boundary.
      const occupancy=Array(384).fill(0);
      for(let y=y0;y<y1;y++)for(let x=0;x<384;x++)if(pixels[(y*384+x)*4+3])occupancy[x]++;
      const bounds=[0];
      for(let c=1;c<6;c++){
        let best=c*64,score=Infinity;
        for(let x=c*64-12;x<=c*64+12;x++){
          const s=(occupancy[x-1]+occupancy[x]+occupancy[x+1])*100+Math.abs(x-c*64);
          if(s<score){best=x;score=s;}
        }
        bounds.push(best);
      }
      bounds.push(384);
      for(let c=0;c<6;c++){
        const correctedHurt=direction==='north'&&r===3;
        const framePixels=correctedHurt?hurtPixels:pixels,imageWidth=correctedHurt?171:384;
        const fx0=correctedHurt?(c%3)*57:bounds[c],fx1=correctedHurt?fx0+57:bounds[c+1];
        let fy0=correctedHurt?Math.floor(c/3)*57:y0,fy1=correctedHurt?fy0+57:y1;
        // This raised blade crosses the nominal row gutter; keep it with attack.
        if(direction==='north'&&c===1){if(r===1)fy1=101;if(r===2)fy0=101;}
        let pts=[];
        for(let y=fy0;y<fy1;y++)for(let x=fx0;x<fx1;x++)if(framePixels[(y*imageWidth+x)*4+3])pts.push([x,y]);
        if(!pts.length)throw Error(`Empty frame ${direction}/${clips[r]}_${c}`);
        const minX=Math.min(...pts.map(p=>p[0])),maxX=Math.max(...pts.map(p=>p[0]));
        const minY=Math.min(...pts.map(p=>p[1])),maxY=Math.max(...pts.map(p=>p[1]));
        const ground=pts.filter(p=>p[1]>=maxY-1);
        let pivotX=Math.round((Math.min(...ground.map(p=>p[0]))+Math.max(...ground.map(p=>p[0])))/2);
        if(direction==='west'&&r===4&&c>=2)pivotX=Math.round(minX+(maxX-minX)*.75);
        const feetMidpoint=pivotX;
        // A wide stance may straddle the ground anchor. Retain the complete sword.
        pivotX=Math.max(maxX-53,Math.min(pivotX,minX+38));
        if(Math.abs(pivotX-feetMidpoint)>8)throw Error(`Excessive alignment shift ${direction}/${clips[r]}_${c}`);
        const frame=Buffer.alloc(96*96*4);
        for(const [x,y] of pts){
          const dx=x-pivotX+40,dy=y-maxY+71;
          if(dx<2||dx>=94||dy<2||dy>=94)throw Error(`Clipped output ${direction}/${clips[r]}_${c}`);
          framePixels.copy(frame,(dy*96+dx)*4,(y*imageWidth+x)*4,(y*imageWidth+x)*4+4);
        }
        const name=`${clips[r]}_${String(c).padStart(3,'0')}.png`;
        await sharp(frame,{raw:{width:96,height:96,channels:4}}).png().toFile(path.join(root,direction,name));
        const factor=correctedHurt?1536/171:4;
        exportNotes.push({file:`${direction}/${name}`,source:`source/milestone-b-${direction}${correctedHurt?'-hurt':''}.png`,source_bounds:[fx0*factor,fy0*factor,(fx1-fx0)*factor,(fy1-fy0)*factor],sampled_ground_anchor:[pivotX,maxY+1],ground_anchor_adjustment_px:pivotX-feetMidpoint,sampled_bounds:[minX,minY,maxX,maxY]});
      }
    }
  }
  for(const clip of clips){atlas[direction][clip]=[];for(let i=0;i<6;i++)atlas[direction][clip].push(await fs.readFile(path.join(root,direction,`${clip}_${String(i).padStart(3,'0')}.png`)));}
}
const manifest={status:'Milestone B four-direction review; awaiting user approval; no integration',milestone_a:'Approved by user after walk revision at b87e979d62abe5a547ee56ae9f1bcc11ac152aab; east PNGs unchanged',canvas_px:[96,96],ground_pivot_px:[40,72],format:'RGBA PNG, binary alpha, nearest-neighbour; no per-pose scaling',direction_selection:{source:'scripts/actor.gd update_art, unchanged',rule:'abs(x)>abs(y): east if x>0 else west; otherwise north if y<0 else south; diagonal ties use vertical direction',vectors:{south:[0,1],west:[-1,0],north:[0,-1],east:[1,0]}},timing,frames:Object.fromEntries(directions.map(d=>[d,Object.fromEntries(clips.map(c=>[c,Array.from({length:6},(_,i)=>`../${d}/${c}_${String(i).padStart(3,'0')}.png`)]))])),exports:exportNotes};
await fs.writeFile(path.join(review,'manifest.json'),JSON.stringify(manifest,null,2)+'\n');
const uri=b=>'data:image/png;base64,'+b.toString('base64');
for(const direction of directions){
  const labels=[],layers=[];
  labels.push('<rect width="1240" height="1200" fill="#12171b"/>',`<text x="24" y="36" fill="#e8dfca" font-size="25">GOBLIN / ${direction.toUpperCase()} / MILESTONE B</text>`,'<text x="24" y="65" fill="#aab3b5" font-size="14">96×96 RGBA · pivot (40,72) · 2× nearest neighbour · visual review pending</text>');
  for(let r=0;r<5;r++){
    const y=110+r*214;
    labels.push(`<text x="24" y="${y}" fill="#c6b887" font-size="16">${clips[r].toUpperCase()}</text>`);
    for(let c=0;c<6;c++){
      const x=24+c*200,top=y+8;
      const caption=clips[r]==='attack'?(c<2?'WINDUP':c<4?'CONTACT':'RECOVERY'):(clips[r]==='walk'?['contact A','passing A','push A','contact B','passing B','push B'][c]:String(c).padStart(3,'0'));
      labels.push(`<rect x="${x}" y="${top}" width="192" height="158" rx="5" fill="#252c32"/><path d="M${x+8} ${top+110}h176" stroke="#506054" stroke-dasharray="3 4"/><text x="${x+8}" y="${top+181}" fill="#aeb8bb" font-size="12">${caption}</text>`);
      layers.push({input:await sharp(atlas[direction][clips[r]][c]).resize(192,192,{kernel:'nearest'}).extract({left:0,top:34,width:192,height:158}).toBuffer(),left:x,top});
    }
  }
  await sharp(Buffer.from(`<svg xmlns="http://www.w3.org/2000/svg" width="1240" height="1200"><g font-family="Arial">${labels.join('')}</g></svg>`)).composite(layers).png().toFile(path.join(review,`contact-${direction}.png`));
}
const room=await fs.readFile(path.join(repo,'assets/room.png'));
const urls=Object.fromEntries(directions.map(d=>[d,Object.fromEntries(clips.map(c=>[c,atlas[d][c].map(uri)]))]));
const html=`<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Gauntlands — Four-direction goblin</title>
<style>*{box-sizing:border-box}body{margin:0;background:#11161a;color:#e5e0d3;font:15px system-ui,sans-serif}main{max-width:1440px;margin:auto;padding:24px}h1{margin:6px 0;font-size:28px}h2{font-size:16px}p{color:#acb8bb;line-height:1.6}.badge{font-size:12px;color:#cfbd82;letter-spacing:2px}button,select,input{background:#273139;color:#eee6d3;border:1px solid #4b5961;border-radius:5px;padding:8px;margin:4px}button,summary{cursor:pointer}.controls{display:flex;flex-wrap:wrap;align-items:center}.views{display:grid;grid-template-columns:repeat(auto-fit,minmax(320px,1fr));gap:12px;margin-top:18px}.panel{background:#1a2228;border:1px solid #354047;border-radius:8px;padding:12px;overflow:auto}canvas{image-rendering:pixelated}.sprite{width:288px;height:288px;background:repeating-conic-gradient(#252e35 0% 25%,#303940 0% 50%) 0/24px 24px}.world{display:flex;flex-wrap:wrap;gap:24px;margin-top:20px}.world canvas{width:640px;height:384px}.note{max-width:480px}.timeline{width:100%;margin:16px 0}#status{color:#d2bf83;font-variant-numeric:tabular-nums}details{margin:18px 0}details img{width:100%;max-width:1240px}.legend{font-size:12px}a{color:#c9bb86}</style>
<main><div class="badge">ITERATION 04 · MILESTONE B · VISUAL APPROVAL PENDING</div><h1>Four-direction goblin</h1><p>South, west, north and the approved east. All views share the same animation phase, scale and ground anchor.</p><div class="controls"><label>Clip <select id="clip"><option>idle</option><option selected>walk</option><option>attack</option><option>hurt</option><option>death</option></select></label><button id="play">Pause</button><button id="restart">Replay</button><button id="step">Next frame</button><label>Speed <select id="speed"><option value="1">1×</option><option value="0.25">¼×</option><option value="0.5">½×</option></select></label><label><input id="anchor" type="checkbox" checked>Ground guides</label><label><input id="travel" type="checkbox" checked>Walking travel</label></div><div id="status"></div><input class="timeline" id="timeline" aria-label="Animation timeline" type="range" value="0" min="0" max="445" step="1"><div class="views">${directions.map(d=>`<section class="panel"><h2>${d.toUpperCase()}${d==='east'?' · APPROVED BASELINE':''}</h2><canvas class="sprite" id="${d}" width="288" height="288"></canvas></section>`).join('')}</div><div class="world"><section class="panel"><h2>Actual 1× world scale / direction changes</h2><canvas id="world" width="640" height="384"></canvas></section><section class="note"><h2>Dungeon-facing preview</h2><label>Direction <select id="direction"><option value="cycle">Cycle directions</option>${directions.map(d=>`<option>${d}</option>`).join('')}</select></label><p>Walking travel follows each facing vector at 54px/s. The preview resets its short travel path; this is an offline art comparison.</p><p>Review head/body scale, foot placement, equipment handedness and directional transitions. East frames are unchanged.</p><p class="legend">Sword: windup 0–500ms · contact 500–640ms · recovery 640–1300ms. Hurt 160ms. Death is a 720ms visual study; gameplay death remains immediate. No game integration.</p></section></div>${directions.map(d=>`<details><summary>${d.toUpperCase()} — all frames</summary><img src="contact-${d}.png" alt="${d} contact sheet"></details>`).join('')}<p class="legend"><a href="manifest.json">Frame/timing manifest</a> · <a href="README.md">Provenance and review notes</a></p></main>
<script>const urls=${JSON.stringify(urls)},timing=${JSON.stringify(timing)},directions=${JSON.stringify(directions)};let images={},background;let clip='walk',time=0,totalClock=0,playing=true,speed=1,last=0;const $=id=>document.getElementById(id);const vectors={south:[0,1],west:[-1,0],north:[0,-1],east:[1,0]};function load(src){return new Promise(r=>{let im=new Image;im.onload=()=>r(im);im.src=src})}function duration(){return timing[clip].durations_ms.reduce((a,b)=>a+b,0)}function current(){let t=time;for(let i=0;i<6;i++){if(t<timing[clip].durations_ms[i])return i;t-=timing[clip].durations_ms[i]}return 5}function draw(){let i=current();for(const d of directions){const ctx=$(d).getContext('2d');ctx.imageSmoothingEnabled=false;ctx.clearRect(0,0,288,288);ctx.drawImage(images[d][clip][i],0,0,288,288);if($('anchor').checked){ctx.strokeStyle='#73b5a0';ctx.beginPath();ctx.moveTo(110,216.5);ctx.lineTo(130,216.5);ctx.moveTo(120.5,210);ctx.lineTo(120.5,222);ctx.stroke()}}const ctx=$('world').getContext('2d');ctx.imageSmoothingEnabled=false;ctx.drawImage(background,0,0);const choice=$('direction').value;const d=choice==='cycle'?directions[Math.floor(totalClock/1200)%4]:choice;const offset=clip==='walk'&&$('travel').checked?(totalClock*.054)%76:0;const [vx,vy]=vectors[d];const x=320+vx*offset,y=240+vy*offset;ctx.drawImage(images[d][clip][i],x-40,y-72);ctx.fillStyle='#ddd5c1';ctx.font='12px system-ui';ctx.fillText(d.toUpperCase(),24,24);let phase=clip==='attack'?(time<500?'WINDUP':time<640?'CONTACT':'RECOVERY'):clip.toUpperCase();$('status').textContent=phase+' · frame '+String(i).padStart(3,'0')+' · '+Math.round(time)+' / '+Math.round(duration())+' ms';$('timeline').value=time}function selectClip(){clip=$('clip').value;time=0;totalClock=0;playing=true;$('play').textContent='Pause';$('timeline').max=duration();draw()}$('clip').onchange=selectClip;$('play').onclick=()=>{playing=!playing;$('play').textContent=playing?'Pause':'Play'};$('restart').onclick=()=>{time=0;totalClock=0;playing=true;$('play').textContent='Pause'};$('step').onclick=()=>{playing=false;$('play').textContent='Play';const next=(current()+1)%6;time=timing[clip].durations_ms.slice(0,next).reduce((a,b)=>a+b,0)+.001;draw()};$('speed').onchange=()=>speed=+$('speed').value;$('timeline').oninput=()=>{time=+$('timeline').value;playing=false;$('play').textContent='Play';draw()};for(const id of ['anchor','travel','direction'])$(id).onchange=draw;function tick(now){if(playing){const dt=Math.min(now-last,100)*speed;time+=dt;totalClock+=dt;if(time>=duration()){if(timing[clip].loop)time%=duration();else{time=duration();playing=false;$('play').textContent='Play'}}}last=now;draw();requestAnimationFrame(tick)};(async()=>{await Promise.all(directions.map(async d=>{images[d]={};await Promise.all(Object.keys(urls[d]).map(async c=>images[d][c]=await Promise.all(urls[d][c].map(load))))}));background=await load('${uri(room)}');selectClip();window.previewReady=true;requestAnimationFrame(tick)})();</script></html>`;
await fs.writeFile(path.join(review,'preview.html'),html);
const movie=[],delays=[];
for(const clip of clips)for(let repeat=0;repeat<(clip==='walk'?3:1);repeat++)for(let i=0;i<6;i++){
  const label=clip==='attack'?(i<2?'WINDUP':i<4?'CONTACT':'RECOVERY'):clip.toUpperCase();
  const bg=Buffer.from(`<svg xmlns="http://www.w3.org/2000/svg" width="768" height="260"><rect width="768" height="260" fill="#1a2228"/><g font-family="Arial" fill="#e8dfca"><text x="16" y="24" font-size="18">GOBLIN / ${label} / FOUR DIRECTIONS</text>${directions.map((d,j)=>`<text x="${j*192+12}" y="54" font-size="13">${d.toUpperCase()}</text>`).join('')}</g></svg>`);
  movie.push(await sharp(bg).composite(await Promise.all(directions.map(async(d,j)=>({input:await sharp(atlas[d][clip][i]).resize(192,192,{kernel:'nearest'}).toBuffer(),left:j*192,top:64})))).png().toBuffer());
  delays.push(Math.round(timing[clip].durations_ms[i])+(clip==='death'&&i===5?1200:0));
}
await sharp(movie,{join:{animated:true}}).gif({delay:delays,loop:0,effort:7}).toFile(path.join(review,'animation-preview.gif'));
console.log(JSON.stringify({directions,frames:120,newFrames:90,preservedEastFrames:30,canvas:[96,96],pivot:[40,72],preview:'four-direction/preview.html'},null,2));
