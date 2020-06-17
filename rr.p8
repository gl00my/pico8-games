pico-8 cartridge // http://www.pico-8.com
version 27
__lua__
--reverse raid
--ny hugeping
local exp={}
local parts={}
local las={}
local last_gate=15
local lvl_h=3000

function ship_crash()
	ship.crash=ship.h
	if ship.h>0 then
		ship.crash+=0.1
	elseif ship.h<0 then
		ship.crash-=0.1
	end
end
function zap(v)
	v.f=nil
	v.d=nil
end
function oini(v,f,d)
		v.f=f
		v.d=d
end
local save_seed
local hiscore=0
local max_gw=0
local handl=0.03
local frict=0.9
local frictv=0.99
local gravity=0.01
local fuelr=0.0006
local r16=12
local gameover=false
local r8=12
local explode=false
local gates={}
local theend=false
local yy=-120
local cam_y=-200
local tm=0
local lives=5
local title=true

local pals={
0b1111111111111011.1,
0b1111111011111011.1,
0b1101111001111011.1,
0b0101111001011011.1,
0b0101101001011010.1,
0b0101100001010010.1,
0b0101000001010000.1,
0b0001000001000000.1,
0b0000000001000000.1,
0b0000000000000000.1,
}
--[[
function irnd16()
	local t=flr(r16)^^flr(r16>>14)^^flr(r16>>13)^^flr(r16>>11)^^1
	r16=(r16>>1)&0x7fff
	r16|=(t<<15)
	return r16&0xffff
end
--]]
function rnd16()
	local t=flr(r16>>15)^^flr(r16>>13)^^flr(r16>>12)^^flr(r16>>10)^^1
	r16=(r16<<1)&0xffff
	r16|=(t&1)
	return r16&0xffff
end
--[[
function irnd8()
	local t=flr(r8>>6)^^flr(r8>>5)^^flr(r8>>4)^^r8
	r8=(r8>>1)&0xff
	r8=r8|((t&1)<<7)
	return r8
end
--]]
function rnd8()
	local t=flr(r8>>7)^^flr(r8>>5)^^flr(r8>>4)^^flr(r8>>3)
	r8=(r8<<1)&0xff
	r8|=(t&1)
	return r8
end
--[[
function rnd16p(v)
	local s=r16
	r16=v
	irnd16()
	r16=s
end
--]]
local lvl={}

function lnorm(cur,prev)
	if not prev then
		return
	end
	if prev.l<cur.l then
		cur.lspr=3 -- \
	elseif prev.l>cur.l then
		cur.lspr=4 -- /
		if prev.lspr==1 then
			prev.lspr=4 -- /
		end
	end
	if prev.lspr==3 and cur.lspr==4 then
		prev.lspr=2 -- >
	end
	if prev.lspr==4 and cur.l>=prev.l then
		prev.lspr=5 -- <
	end
end

function rnorm(cur,prev)
	if not prev then
		return
	end
	local ncur={l=cur.r,lspr=cur.rspr}
	local nprev={l=prev.r,lspr=prev.rspr}
	lnorm(ncur,nprev)
	cur.rspr=ncur.lspr
	prev.rspr=nprev.lspr
end
local started=false
function restart(seed)
	exp={}
	parts={}
	las={}

	gameover=false
	theend=false
	target=0
	mklevel(16,16,lvl_h,seed)
	ship={score=0,dshot=0,f=1,x=64,y=-110,g=0,v=0,h=0,t=0,tx=0}
	yy,cam_y=ship.y,ship.y
	cam()
	cam_y=yy
	mksnap(0)
	started=true
end
function _init()
	music(0,2000)
	if cartdata("hgpgrevraid") then
		max_gw=dget(0) or 0
//		max_gw=last_gate
		hiscore=dget(1) or 0
		save_seed=dget(2)
		if (save_seed==0)save_seed=false 
	end
	fadeout(function()
		restart(save_seed)
	end)
//	ship.y=1920*8
//	restart()
end

function new(v)
	local pos=v.c%(14-(v.r+v.l+(v.land or 0)))
	for i=1,#v.spr do
		if v.spr[i]==0 then
			pos-=1
			if pos<=0 and i>1 and v.spr[i+1]==0 and v.spr[i-1]==0 then
				v.pos=(i-1)*8
				return true
			end
		end
	end
end

function d_mine(v)
	local x,y=tos(v.pos,v.yy)
	spr(32+tm\16%2,x-4,y-4,1,1,v.dir>0)
end
function lasd()
	for l in all(las) do
		local x,y=tos(l.x,l.y)
		if l.dy~=0 then
			spr(36+tm\8%2,x-4,y-4)
		else
			spr(34+tm\8%2,x-4,y-4)
		end
	end
end
function lasm()
	local nlas={}
	for l in all(las) do
		l.x+=l.dx
		l.y+=l.dy
		local _,y=tos(l.x,l.y)
		if y>128+16 or y<-16 then
			l.v.shot=false
		elseif not mmcol(l.x,l.y) then
			add(nlas,l)
		elseif fget(mmcol(l.x,l.y),0) then
			add(nlas,l)
		else
			l.v.shot=false
			sfx(6)
			expa(l.x,l.y,4,l.v)
		end
	end
	las=nlas
end

function ecol(x,y,w,h,v)
	if v and v.nc then return end
	for e in all(exp) do
		local d=((x-e.x)^2+(y-e.y)^2)^0.5
		if v!=e.v and e.r>0 and d<e.cr+(w+h)/2 then
			return true
		end
	end	
end
function expd()
	for e in all(exp) do
		local x,y=tos(e.x,e.y)
		if e.r>0 then
			circfill(x,y,e.cr,15)
		else
			circfill(x,y,-e.r,15)
			circfill(x+1,y,e.cr,0)
		end
	end
end

local smk={}
function smkm()
	local nsmk={}
	for s in all(smk) do
		s.cr+=0.2
		s.y-=rnd(1)
		if s.cr<s.r then
			add(nsmk,s)
		end
	end
	smk=nsmk
end

function smkd()
	for s in all(smk) do
		local x,y=tos(s.x,s.y)
		fillp(0b1010010110100101.1)
		circfill(x,y,s.cr,5)
		fillp()
	end
end

function smka(x,y,r)
	add(smk,{x=x,y=y,cr=0,r=r})
end

function maxexp()
	local me=-1
	for e in all(exp) do
		if (e.r>0 and e.y+e.r>me) me=e.y+e.r
	end
	if (me<0) return false
	return me\8
end

function expm()
	local nexp={}
	for e in all(exp) do
		if e.r>0 then
			e.cr+=1
			if e.cr>=e.r then
				e.r=-e.r
				e.cr=0
			end
			add(nexp,e)
		else
			e.cr+=1
			if e.cr<=-e.r then
				add(nexp,e)
			end
		end
	end
	exp=nexp
end

function expa(x,y,r,v)
	add(exp,{x=x,y=y,r=r,cr=0,v=v})
end

function lshot(v,x,y,dx)
	v.shot=true
	add(las,{x=x+2*dx,v=v,y=y,dx=dx,dy=0})
end
function lshoty(v,x,y,dy)
	v.shot=true
	add(las,{x=x,v=v,y=y+dy*4,dy=dy,dx=0})
end

function lcol(x,y,w,h,v)
	for l in all(las) do
		if l.v~=v and l.x>=x-w and l.x-1<x+w and
			l.y>=y-h and l.y<y+h then
			del(las,l)
			l.v.shot=false
			return true
		end
	end
end

function pcol(x,y,w,h,v)
	for l in all(parts) do
		if l.x>=x-w and l.x<x+w and
			l.y>=y-h and l.y<y+h then
			del(parts,l)
			return true
		end
	end
end

function hit(x,y,xx,yy,ww,hh,dx,dy)
	dx=dx or 0
	dy=dy or 0
	if x>=xx+dx-ww and x<xx+dx+ww and
		y>=yy+dy-hh and y<yy+dy+hh then
		return true
	end
end

function scorea(d)
	local os=ship.score
	ship.score+=d or 5
	if ship.score\100~=os\100 then
		lives+=1
		sfx(5)
	end
	if ship.score>=hiscore then
		if os<hiscore then
			sfx(8)
		end
		hiscore=ship.score
		dset(1,hiscore)
	end
end

function f_hit(v,dx,dy)
	dx=dx or 0
	dy=dy or 0
	if hit(v.pos+dx,v.yy+dy,ship.x,ship.y,8,4) then
		zap(v)
		sfx(2)
		scorea(v.score)
		expa(v.pos,v.yy,8,v)
		ship_crash()
	end
end

function f_gaub(v)
	local x=v.pos+v.dir*0.1
	if mmcol(x+v.dir*4,v.yy) then
		v.dir=-v.dir
	else
		if tm%8==1 then
			v.step=not v.step
		end
		if mmcol(x,v.yy+4) then
			v.pos=x
		end
	end
	if not ship.crash and v.yy>ship.y and not v.shot then
		lshoty(v,v.pos+1,v.yy-2,-1)
		sfx(7)
	end
	f_hit(v)
	f_lcol(v,4,4,0,0,4)
end

function d_gaub(v)
	local x,y=tos(v.pos-4,v.yy-4)
	spr(56+(v.step and 0 or 1),x,y)
end

function f_tank(v)
	if not v.started then
		if abs(ship.y-v.yy)<v.dist then
			v.started=true
		end
		return
	end
	if v.delay>0 then
		v.delay-=1
	end
	local x=v.pos+v.dir*0.1
	if x<0 or x>128 or mmcol(x+v.dir*4,v.yy) then
		v.pos=x
		if tm%8==1 then
			v.step=not v.step
		end
	else
		if not ship.crash and not v.shot and v.delay<=0 then
			lshot(v,v.pos+4*v.dir,v.yy,v.dir)
			v.delay=120
			sfx(7)
		end
	end
	if v.pos>-8 and v.pos<132 then
		f_hit(v)
		f_lcol(v,4,4,0,0,6)
	end
end

function d_tank(v)
	local x,y=tos(v.pos-4,v.yy-4)
	spr(58+(v.step and 1 or 0),x,y,1,1,v.dir<0)
end

function f_mine(v)
	v.m+=0.01
	local xx=v.pos
	if v.started then
		if agate(v,3) then
			xx+=v.dir*0.3
		end
	else
		if abs(ship.y-v.yy)>8 then
			v.started=abs(ship.y-v.yy)<v.dist
		end
	end
	if mmcol(xx+v.dir*4,v.yy) then
		v.dir=-v.dir
	else
		v.pos=xx
	end
	v.yy=v.y*8+4+sin(v.m)*4,1
	if v.started and not v.shot and not ship.crash and ship.y>v.yy-16 and ship.y<v.yy+16 then
		if sgn(ship.x-v.pos)==sgn(v.dir) then
			if agate(v,7) then
				sfx(7)
				lshot(v,v.pos,v.yy,
				(ship.x<v.pos) and -1 or 1)
			end
		end
	end
	f_hit(v)
	f_lcol(v,4,4,0,0,4)
end

function agate(v,n)
	return v.y\128>=n
end

function n_gaub(v)
	if not agate(v,5) then return end
	if not v then return end
	if new(v) then
		v.nam="gaub"
		v.score=3
		v.yy=v.y*8+6
		v.pos+=4
		v.dir=(v.c%2==1) and -1 or 1
		oini(v,f_gaub,d_gaub)
	end
end
function n_mine(v)
	if not agate(v,2) then return end
	if v.y<16 then return end
	if new(v) then
		v.nam="mine"
		v.score=2
		v.m=0
		v.started=false
		v.dist=(v.c%15)*8
		v.pos+=4
		v.yy=v.y*8+4
		v.dir=(v.c%2==1) and 1 or -1
		oini(v,f_mine,d_mine)
	end
end

function f_lcol(v,w,h,dx,dy,rr)
	if lcol(v.pos+(dx or 0),v.yy+(dy or 0),w,h,v)
		or pcol(v.pos+(dx or 0),v.yy+(dy or 0),w,h)
		or ecol(v.pos+(dx or 0),v.yy+(dy or 0),w,h,v)
		then
		zap(v)
		sfx(2)
		expa(v.pos,v.yy,rr or h,v)
		scorea(v.score)
	end
end

function d_fuel(v)
	local x,y=tos(v.pos,v.yy)
	spr(38+tm\8%2,x-4,y-8,1,2)
end

function f_fuel(v)
	f_lcol(v,4,8)
	local n=lvl[v.y+2]
	if v.f and n and n.laser then
		local x,e=n.pos+4,n.stop
		if x>e then
			x,e=e,x
		end
		if v.pos>=x and v.pos<=e then 
			zap(v)
			expa(v.pos,v.yy,8)
		end
	end
	if not ship.crash and (hit(v.pos,v.yy-4,ship.x,
		ship.y,8,4) or hit(v.pos,v.yy+4,ship.x,
		ship.y,8,4)) then
		ship.f+=0.01
		if ship.f>1 then ship.f=1 end
		if ship.f<1 then
			if tm%8==1 then
				sfx(3)
			end
		end
	end
end

local snap={}

function mksnap(g)
	if ship.crash then
		return
	end
	if g>max_gw then
		max_gw=g
		dset(0,g)
	end
	ship.gw=g
	snap={}
	for k,v in pairs(ship) do
		snap[k]=v
	end
//	printh("mksnap "..tostr(g))
end
function rgate(g,set)
	for i=g.l+1,14-g.r do
		g.spr[i+1]=set and 50 or 0
		if (set) add(g.brk,i+1)
	end
	g.f=set and f_gate
	g.d=set and d_gate

	if g.y>0 then
		n_gaub(lvl[g.y])
		if not set then
			zap(lvl[g.y])
		end
	end
end
function restore(gw)
	ship={}
	if not gw then
		mklevel(16,16,lvl_h,save_seed)
	else
		for g in all(gates) do
			rgate(g,true)
		end
	end
	for k,v in pairs(snap) do
		ship[k]=v
	end
	if (gw)ship.gw=gw
	ship.v=0
	ship.h=0
	ship.f=1
	target=0
	local g=gates[ship.gw]
	if ship.gw>1 then
		ship.y=g.y*8-- -12
	elseif ship.gw==1 then
		ship.y=-64
	elseif ship.gw==0 then
		ship.y=-110
	end
	if g and ship.gw>=g.nr then
		rgate(g)
	end
	ship.x=64
	ship.shot=false
	camera()
	yy,cam_y=ship.y,ship.y
	cam()
	cam_y=yy
end

function f_bgun(v)
//	if not ship.crash then
//		lshoty(v,v.pos+1,v.yy-2,-1)
//	end
end

function f_brk(v,k)
	local s=v.spr[k]
	if s==0 then
		del(v.brk,k)
		return
	end
	local tv={nam="brk",
		pos=k*8-4,
		yy=v.y*8+4}
	tv.d=true
	tv.nc=(s==112)
	tv.score=(s==112)and 5 or 1;
	f_lcol(tv,4,4,0,0,6)
	if not tv.d then
		v.spr[k]=0
		del(v.brk,k)
		if s==112 then
			if (not explode)explode=10
			target+=1
		elseif v.gate then
			if (not explode)explode=10
			mksnap(v.nr)
		end
	end
	if s==62 and tv.d then
		return f_bgun(tv)
	end
end
--[[
function f_item(v)
	local tv={pos=4,yy=v.y*8+4}
	for k,p in ipairs(lvl[v.y+1].spr) do
			if fget(p,0) then
				tv.d=true
				f_lcol(tv,4,4,0,0,6)
				if not tv.d then
					v.spr[k]=0
					if v.gate then
						if (not explode)explode=8
						mksnap(v.nr)
					end
				end
			end
			tv.pos+=8
	end
end
--]]
function f_laser(v)
	if not v.tm then
		v.tm=0
	end
	v.tm+=1
	if v.tm>v.tmmax\2 then
		v.laser=true
		if v.tm>v.tmmax then
			v.laser=false
			v.tm=0
		end
	end
	f_lcol(v,4,4,4,4)
	f_hit(v,4,4)
	if v.laser then
		sfx(4)
		if mm(v.stop+v.dir*4,v.yy)==0 then
			n_laser(v)
		end
		local x,e=v.pos+4,v.stop
		if v.pos>v.stop then
			x,e=e,x
		end
		if ship.x>x and ship.x<e and
			ship.y-4<v.yy+3 and ship.y+4>v.yy+3 then
			if not ship.crash then
				sfx(2)
				expa(ship.x,ship.y,8,ship)
			end
			ship_crash()
		end
	end
end

function d_laser(v)
	local x,y=tos(v.pos,v.yy)
	spr(48+tm\8%2,x,y,1,1,v.dir<0)
	if v.laser then
		if v.dir<0 then
			x-=7
		end
		line(x+7,y+3+tm%2,v.stop,y+3+tm%2,(tm\4%2==1) and 12 or 7)
		if tm%7==1 then
			sparka(v.stop,v.yy+3)
		end
	end
end

function n_laser(v)
	local p={}
	for i=1,#v.spr do
		local s=v.spr[i]
		if s==17 or s==1 then
			add(p,{s,(i-1)*8})
		end
	end
	p=p[v.c%#p+1]
	if not p then return end
	if p[1]==17 then
		v.pos=p[2]-8
		v.dir=-1
	elseif p[1]==1 then
		v.pos=p[2]+8
		v.dir=1
	end
	local x=v.pos
	v.yy=v.y*8
	while true do
		x+=v.dir
		if mmcol(x,v.yy+4) or x>128 or x<0 then
			v.stop=x-v.dir
			break
		end
	end
	v.nam="laser"
	v.score=3
	oini(v,f_laser,d_laser)
	v.tmmax=240 -- s+v.c%128
end

function n_tank(v)
	if not agate(v,9) then return end
	v.nam="tank"
	v.score=4
	v.delay=0
	v.dist=(v.c%15)*8
	if v.c%2==1 then
		v.dir=1
		v.pos=-8
	else
		v.dir=-1
		v.pos=136
	end
	v.yy=v.y*8+4
	oini(v,f_tank,d_tank)
end

function n_rock(v)
	if not agate(v,12) then return end
	v.nam="rocket"
	v.score=3
	v.dist=(v.c%15)*8
	if v.c%2==1 then
		v.dir=1
		v.pos=-8
	else
		v.dir=-1
		v.pos=136
	end
	v.yy=v.y*8+4
	oini(v,f_rock,d_rock)
end

function f_rock(v)
	if not v.started then
		if abs(ship.y-v.yy)<v.dist then
			v.started=true
		end
		return
	end
	v.pos=v.pos+v.dir*1
	if v.pos>256 then v.pos=-7 end
	if v.pos<-128 then v.pos=136 end
	if v.pos>-8 and v.pos<132 then
		f_hit(v)
		f_lcol(v,4,2,0,0,6)
	end
end

function d_rock(v)
	local x,y=tos(v.pos-4,v.yy-4)
	spr(60+tm\4%2,x,y,1,1,v.dir<0)
	if v.dir>0 then
		spr(29+tm\4%2,x-8,y,1,1,true)
	else
		spr(29+tm\4%2,x+8,y,1,1)
	end
end

function n_fuel(v)
	if v.y<32 then return end
	if new(v) then
		v.pos+=4
		v.nam="fuel"
		v.score=10
		v.yy=v.y*8+8
		if mm(v.pos,v.yy)==0 and
			mm(v.pos,v.yy+8)==0 then
			oini(v,f_fuel,d_fuel)
		end
	end
end

function mklevel(w,h,hh,seed)
	save_seed=seed
	dset(2,save_seed)
	seed=seed or 12
	r16,r8=seed,seed
	lvl={}
	local l,r=4,12
	local t=1
	local cland=0
	local land=0
	local dist=0
	local gate_nr=0
	gates={}
	for y=1,hh do
		dist+=1
		if t~=5 and t~=0 then
		
		if dist>128 and gate_nr<last_gate-1 then
			t=0
			cland=0
		elseif y%h==0 and t~=5 then
			t=rnd8()%3+1
			cland=0
		end
		end
		local pl,pr,pland=l,r,land
		local c=abs(rnd16())
		local cl=(c>>4)&0xf
		local cr=c&0xf
		local l1,r1
		if t==0 then
			cl=0
			cl=4+cl
			cr=w-1-cl
		elseif t==1 then
			cl%=6
			cr=w-1-cl
		elseif t==2 then
			cl=cl-cr
			cr=cl+cr
		elseif t==3 then
			cland=(cr+cl)%4+1
			cl%=3
			cr%=3
			cr=w-1-cr
		elseif t==5 then
			cl=0
			cr=w-1
		end
		local free=r-l-1
		if cland>pland and free>9 then
			land+=1
		elseif cland<pland or free<=7 then
			land-=1
		end
		if cland>0 and land==0 then
			land=1
		end
		if cl>pl then
			l+=1
		elseif cl<pl then
			l-=1
		end
		if cr<pr then
			r-=1
		elseif cr>pr then
			r+=1
		end
		if(l<=0)l=0
		if(r>=w-1)r=w-1
		while abs(r-l)<4 do
			l-=1
			r+=1
			if(l<=0)l=0
			if(r>=w-1)r=w-1
		end
		local cur={t=t,l=l,r=w-r-1,c=c}
		if y==1 then cur.gate=true end
		if land>0 then
//			cur.lx=(w-(cur.l-1+cur.r))\2
			cur.lx=cur.l+ceil((free)/2) --todo
			cur.land=land
		end
//		printh(tostr(l)..tostr(" ")..tostr(r))
		if l>=4 and r<=11 and free>3 
			and t==0 then
			if dist>128+7 then
				dist=-6
				cur.gate=true
				gate_nr+=1
//				printh("start"..gate_nr)
			end
//			printh("dist"..dist.." "..y)
			if dist==0 then
//				printh(gate_nr.." "..y)
				t=1
				if gate_nr>=last_gate-1 then
					t=5
				end
			end
		end
		add(lvl,cur)
		if t==5 and dist>32 then
			hh=y
			break
		end
	end
//	printh("hh="..hh)

	local prev
	for y=1,#lvl do
		local cur=lvl[y]
		cur.lspr,cur.rspr=1,1
		lnorm(cur,prev)
		rnorm(cur,prev)
		cur.spr={}
		prev=cur
	end
-- tiles
	prev=false
	for y=1,#lvl do
		local cur=lvl[y]
		for x=1,w do
			if x-1<cur.l or x>w-cur.r then 
				cur.spr[x]=7
			elseif x-1==cur.l then
				cur.spr[x]=cur.lspr
			elseif x==w-cur.r then
				cur.spr[x]=cur.rspr+16
			else
				cur.spr[x]=0
			end
		end

		if cur.land then
			local xc=cur.lx-cur.land\2
			local xe=xc+cur.land-1
			local pxc,pxe
			cur.xc,cur.xe=xc,xe
			if prev and prev.land then
				pxc,pxe=prev.xc,prev.xe
				while pxe>xe+1 do
					xe+=1
					cur.land+=1
				end
				while pxc<xc-1 do
					xc-=1
					cur.land+=1
				end
				while pxe<xe-1 do
					xe-=1
					cur.land-=1
				end
				while pxc>xc+1 do
					xc+=1
					cur.land-=1
				end
				cur.xc,cur.xe=xc,xe
			end

			for i=cur.xc,cur.xe do
				local pp=prev.spr[i+1]
				if cur.xc==cur.xe then
					cur.spr[i+1]=8
				elseif i==cur.xc then
					cur.spr[i+1]=17
				elseif i==cur.xe then
					cur.spr[i+1]=1
				else
					cur.spr[i+1]=7
				end
			end

			local pc,pe,px,cc,ce,pa,pb

			if prev then
				pc=prev.spr[xc+1]
				pe=prev.spr[xe+1]
				pa=prev.spr[xc]
				pb=prev.spr[xe+2]
				if prev.land then
					px=prev.spr[prev.xc+1]
				end
			end

			if cur.land==1 then
				if pc==0 then
					if px==6 then
						prev.spr[prev.xc+1]=23
					elseif px~=nil then
						prev.spr[prev.xc+1]=22
					end
					cur.spr[xc+1]=6
				end
			end

			cc=cur.spr[xc+1]
			ce=cur.spr[xe+1]

			if pc==0 and cc==17 then
				cur.spr[xc+1]=19
			end
			if pa==19 then
				prev.spr[xc]=18
			end
			if pa==17 and prev.land~=1 then
				prev.spr[xc]=20
			end

			if pe==0 and ce==1 then
				cur.spr[xe+1]=3
			end
			if pb==3 then
				prev.spr[xe+2]=2
			end
--			printh(tostr(y).." "..tostr(cur.land).." "..tostr(pa).." "..tostr(pb))
			if pb==1 and prev.land~=1 then
				prev.spr[xe+2]=4
			end
		elseif prev and prev.land then
			if prev.land>1 then
				cur.spr[prev.xc+1]=22
				if prev.spr[prev.xe+1]==3 then
					prev.spr[prev.xe+1]=2
				else
					prev.spr[prev.xe+1]=4
				end
			else
				if prev.spr[prev.xc+1]==6 then
					prev.spr[prev.xc+1]=23
				else
					prev.spr[prev.xc+1]=22
				end
			end
		end
		if cur.gate then
			for i=cur.l+1,14-cur.r do
				cur.spr[i+1]=50
		--		curoitem
			end
			add(gates,cur)
			cur.nr=#gates
		end
		prev=cur
	end
	lvl[1].spr[lvl[1].l+1]=1
	lvl[1].spr[16-lvl[1].r]=17
	for y=1,#lvl do
		local v=lvl[y]
		v.y=y-1
		v.brk={}
		for k,c in ipairs(v.spr) do
			if fget(c,0) then
				add(v.brk,k)
			end
		end
		if v.gate and y>1 then
			n_gaub(lvl[y-1])
		end
		if v.t~=0 and not v.gate then
			local r=(v.c>>7)&0xff
			if r%16==1 then
				n_mine(v)
			elseif r%22==7 then
				n_fuel(v)
			elseif r%4==1 then
				n_laser(v)
			elseif r%17==1 then
				n_tank(v)
			elseif r%15==1 then
				n_rock(v)
			end
		end
	end
	for y=-16,0 do
		lvl[y]={spr={},l=0,r=0}
		for x=1,16 do
			lvl[y].spr[x]=0
		end
	end

	lvl[hh].spr[12]=62
	lvl[hh].spr[5]=62
	add(lvl[hh].brk,12)
	add(lvl[hh].brk,5)

	for y=hh+1,hh+24 do
		local l={spr={},l=0,r=0,y=y-1,brk={}}
		lvl[y]=l
		for x=1,16 do
			if y<hh+8 then
				if x==5 and y<hh+5 then l.spr[x]=5
				elseif x==12 then l.spr[x]=21
				elseif y>hh+4 and x<=5 then
					l.spr[x]=0
					if x==5 then
						l.spr[x]=114
						add(l.brk,x)
					end
				else
					l.spr[x]=7
				end
			elseif y==hh+8 and
				x<12 then
				l.spr[x]=24
			else
				l.spr[x]=7
			end
			if x>5 and x<12 and y<hh+8 then
				l.spr[x]=112
				add(l.brk,x)
			elseif x>1 and x<16 and y==hh+1 then
				l.spr[x]=24
				l.spr[5]=1
				l.spr[12]=17
			end
		end
	end
	zap(lvl[hh-1])
	zap(lvl[hh-2])
	n_laser(lvl[hh-3])
	n_laser(lvl[hh-4])
	local l=lvl[hh+8]
	l.spr[11]=97
	for i=12,16 do
		l.spr[i]=98
	end
//printh(#gates)
end
local thrust=0
function cam()
	local d=abs(cam_y-yy)
	local v=cos(0.25+ship.v*0.25)
	if ship.t then
		if(thrust<0)thrust=0
		thrust+=1
	else
		if(thrust>0)thrust=0
		thrust-=1
	end
	if yy~=cam_y then
		if d>1 then
			if abs(thrust)<30 then
				d=clamp(d/8,0,1)
			else
				d=1
			end
		end
		if cam_y>yy then
			yy+=d
		else
			yy-=d
		end
		if yy<-120 then yy=-120 end
	end
	if not ship.explode then
		if ship.crash then
			cam_y=(ship.y-48)
		else
			cam_y=(ship.y-48)-v*32
		end
	end
end
function clamp(v,m,x)
	if (v<m)v=m
	if (v>x)v=x
	return v
end

function mm(x,y)
	if x<0 or x>=128 or y<0 then
		return
	end
	local v=lvl[y\8+1]
	if not v then return end
	return v.spr[x\8+1]
end

function mmcol(x,y)
	local c=mm(x,y)
	if not c or c==0 then return end
	local cc=sget((c%16)*8+x%8,c\16*8+y%8)
	if cc==0 then
		return
	end
	return c
end

function shipcol()
	local x,y=ship.x,ship.y
	local c=mmcol(x,y) or
		mmcol(x+7,y) or
		mmcol(x-6,y) or
 	mmcol(x+7,y+3) or
		mmcol(x-6,y+3) or
		mmcol(x,y+3) or
		mmcol(x,y-3)
	if c and not ship.crash then
		sfx(2)
		expa(ship.x,ship.y,8,ship)
		ship_crash()
	end
end

function f_end()
	theend=0
	ship.h=rnd(1)
	ship.v=rnd(1)
	ship.y=110
end

function endm()
	ship.x=64+cos(ship.h)*4
	ship.h+=rnd(0.01)
	ship.v+=rnd(0.005)
	if theend!=true and theend>128 then
		yy+=1
		cam_y=yy
		ship.y-=1
		if theend==129 then
			sfx(11)
		end
	else
		cam_y=ship.y-100+4*sin(ship.v)
		yy=cam_y
		ship.t=true
		ship.tx=0
		sfx(1)
	end
	if theend==true then theend=0 end
	if (theend<500)theend+=1
end

function shipm()
	if (gameover or (theend and theend>200)) and (btnp(4) or btnp(5)) then
		fadeout(function()
			if not theend then
				music(0,2000)
			end
			lives=5
			restart(save_seed)
			title=true
		end)
		return
	end
	if theend then
		endm()
		return
	end
	if title and not fade then
		if btnp(0) then
			ship.gw-=1
			if ship.gw<0 then
				ship.gw=0
			else
				restore(ship.gw)
				mksnap(ship.gw)
				sfx(9)
			end
		elseif btnp(1) then
			ship.gw+=1
			if ship.gw>max_gw then
				ship.gw=max_gw
			else
				restore(ship.gw)
				mksnap(ship.gw)
				sfx(9)
			end
		elseif btnp(2) and save_seed then
			sfx(10)
			fadeout(restart)
		elseif btnp(3) then
			sfx(10)
			fadeout(function()
					restart(flr(rnd(16384)))
			end)
		elseif btnp(4) or btnp(5) then
			title=false
			ship.v=0
			ship.h=0
			music(-1,2000)
--[[ --hack
			fadeout(function()
				f_end()
				theend=0
			end)
--]]
		else
			ship.y-=sin(ship.v)*rnd(0.2)
			ship.x-=cos(ship.h)*rnd(0.1)
			ship.v+=rnd(0.02)
			ship.h+=rnd(0.02)
		end
		return
	end
	local y,x=ship.y,ship.x
	y+=cos(0.25-ship.v*0.25)
	x+=cos(0.25-ship.h*0.25)
	if (ship.crash) x=x+ship.crash 
	if not ship.crash then
		if x<0 and y>0 and target>0 then
			-- ending
			fadeout(f_end)
			ship.x-=0.5
			return
		end
		ship.x,ship.y=x,y
	else
		if not mmcol(x+6,y+2) and
			not mmcol(x-5,y+2) and
			not mmcol(x,y+2) then
			ship.x,ship.y=x,y
			if tm%10==1 and not ship.explode then
				smka(ship.x+rnd(8)-4,ship.y+rnd(8)-4,8)
			end
		else
			if not ship.explode then
				sfx(2)
				expa(ship.x,ship.y,8,ship)
				ship.explode=15
				explode=15
				partsa(ship.x,ship.y)
			end
		end
	end
	local both=btn(0) and btn(1)
	if not both and btn(0) and ship.f>0 and not ship.crash then
		if (ship.h>0)ship.h*=frict
		ship.h-=handl
		ship.tx=-1
		ship.f-=fuelr
	elseif not both and btn(1) and ship.f>0 and not ship.crash then
		if (ship.h<0)ship.h*=frict
		ship.h+=handl
		ship.tx=1
		ship.f-=fuelr
	else
		ship.h*=frict
		ship.tx=0
	end
	if ship.f<0.25 and tm%60==1 and not ship.crash then
		sfx(23)
	end
	if ship.dshot==0 and not ship.crash and btnp(4) then
		sfx(0)
		lshoty(ship,ship.x+1,ship.y-3,3)
		ship.dshot=20
	end
	if not ship.crash and ship.dshot>0 then ship.dshot-=1 end
	ship.h=clamp(ship.h,-1,1)
	if (btn(2) or btn(5) or both) and ship.f>0 and not ship.crash then
		ship.v-=handl
		ship.t=true
		ship.f-=fuelr
	else
		ship.t=false
		ship.v*=frictv
	end
	if ship.t or ship.tx!=0 then
		sfx(1)
	end
	if ship.f<0 then ship.f=0 end
	if not ship.crash and ship.y<0 then
		if x<8 then ship.tx=1 ship.h+=0.2 end
		if x>=120 then ship.tx=-1 ship.h-=0.2 end
		if y<-128 then ship.t=false ship.v=0 end
	end
	if not ship.t then
		ship.v+=gravity
	end
	ship.v+=gravity
	ship.v=clamp(ship.v,-1,1)
	shipcol()
	if lcol(ship.x,ship.y,8,4) or
		ecol(ship.x,ship.y,8,4,ship) then
		expa(ship.x,ship.y,8,ship)
		sfx(2)
		ship_crash()
	end
end

function _update60()
	tm+=1
	if not started then
		return
	end
	if theend then
		shipm()
		cam()
		return
	end
	local me=(maxexp() or yy\8)
	me=max(18,me-yy\8+1)
	for y=1,me do
		local v=lvl[y+yy\8]
		if v.f and not title then
			v:f()
		end
		for b in all(v.brk) do
			f_brk(v,b)
		end
	end
	lasm()
	expm()
	shipm()
	smkm()
	partsm()
	cam()
end
function tos(x,y)
	return x,y-yy
end

function partsm()
	local np={}
	for p in all(parts) do
		local vx,vy=cos(p.dir),sin(p.dir)
		local dy=vy+p.t*0.03
		local dx=vx
		if p.vx then
			dx*=p.vx
		end

		if mmcol(p.x+dx,p.y+dy) then
			if p.spark then
				if mmcol(p.x+dx,p.y) then
					vx=-vx
					p.dir=atan2(vx,vy)
				elseif mmcol(p.x,p.y+dy) then
					vy=-vy
					p.t=1
					p.dir=atan2(vx,vy)
				else
					p.l=1000
				end
			else
					sfx(6)
					expa(p.x,p.y,rnd(3)+3,p)
					p.l=1000
			end
		else
			p.x+=dx
			p.y+=dy
		end
		p.t+=1
		p.l+=1
		local x,y=tos(p.x,p.y)
		if p.l<300 and x>-8 and x<132 and y>-8 and y<132 then
			add(np,p)
		end
	end
	parts=np
end

function trnd(n)
	return flr(rnd(n))+1
end

function sparka(x,y)
	local col={8,9,10,12}
--	for i=1,rnd(6)+6 do
		add(parts,{spark=true,
		v=1,vx=0.95,x=x,
		y=y,dir=rnd(1),
		l=290,t=0,
		color=col[trnd(#col)]})
--	end
end

function partsa(x,y)
	local p={13,14,15,31,47,41,42}
	for i=1,rnd(6)+6 do
		add(parts,{v=1,
		hi=flr(rnd(2))==1,
		vi=flr(rnd(2))==1,
		x=x,y=y,dir=rnd(1),l=0,t=0,
		spr=p[(i-1)%#p+1]})
	end
end

function partsd()
	for p in all(parts) do
		if p.spark then
			local x,y=tos(p.x,p.y)
			pset(x,y,p.color)
		else
			local x,y=tos(p.x-4,p.y-4)
			spr(p.spr,x,y,1,1,p.hi,p.vi)
		end
	end
end

function shipd()
	local x,y=tos(ship.x,ship.y)
	local s=9
	local d1,d2=0,0
	if ship.explode then
		return
	end
	if type(ship.crash)=='number' then
		if ship.crash>0 then
			spr(11,x-8,y-4,2,1,true)
		elseif ship.crash<0 then
			spr(11,x-8,y-4,2,1)
		else
			spr(9,x-8,y-4,2,1)
		end
	elseif ship.tx<0 then
		d2=1
		spr(11,x-8,y-4,2,1)
	elseif ship.tx>0 then
		spr(11,x-7,y-4,2,1,true)
		d1=1
	else
		spr(9,x-8,y-4,2,1)
	end
	if ship.t then
		spr(25+(tm\5%3),x-9,y+4-d1)
		spr(25+((tm\5+1)%3),x+2,y+4-d2)
	end
	if ship.tx<0 then
		spr(29+(tm\5%2),x+7,y-2)
	end
	if ship.tx>0 then
		spr(29+(tm\5%2),x-14,y-2,1,1,true)
	end
end
function anim(c)
	local a={
		[50]={50,51,52,53};
		[62]={62,63};
		[112]={112,113},
	}
	if a[c] then
		c=a[c][tm\10%#a[c]+1]
	end
	return c
end
local fade=false
local fade_nr=0

function fadeout(cb)
	if fade then return end
	fade=1
	fade_nr=1
	fade_cb=cb
end
function fading()
	if fade then
		if fade>#pals or fade==0 then
			fade=false
			if(fade_cb)fade_cb()
			fade_cb=nil
			if fade_nr>0 then
				fillp()
				rectfill(0,0,127,127,0x00)
				fade=#pals
				fade_nr=-1
			end
		else
			fillp(pals[fade])
			rectfill(0,0,127,127,0x00)
			fillp()
		end
		if (tm%5==1)fade+=fade_nr
	end
end

function hud()
	if title then
		return
	end
	if gameover then
		print("game over",48,60,tm\4%2==1 and 8 or 15)
	end
	spr(43,64-12,0,3,1)
	print("gate "..ship.gw,100,0,7)
	local fx=ceil(20*ship.f)
	line(64-11+fx,1,64-11+fx,3,10)
	if hiscore>ship.score then
		print("score "..ship.score,0,0,7)
	else
		print("score "..ship.score,0,0,tm\5%2==1 and 15 or 7)
	end
	for i=1,lives do
		if i>10 then
			break
		end
		print("♥",128-i*6,123,8)
	end
//	print(tostr(yy\8),0,0,7)
end

function endd()
	pal(14,0)
	starsd()
	if theend>200 then
		if theend==201 then
			music(0,2000)
		end
		pal()
		local x,y=0,42
		print("the end",x+50,y,12)
		y+=10
		local pcnt=flr(target/42*100)
		x+=16
		print("you are the brave hero!",x,y,8)
		y+=6
		print("you destroyed "..pcnt.."% of data.",x,y,7)
		y+=6
		print("evil kylix is defeated!",x,y)
		y+=10
		print("thank you, pilot!",x,y)
		local sc="score "..ship.score
		print(sc,64-(#sc\2)*4,0,tm\5%2==1 and 7 or 15)
		fading()
		return
	end
	local off=tm*2%8

	if theend>100 then
		off=(theend-100)*2
	end

	for y=-1,16 do
			for x=1,16 do
					spr(16,(x-1)*8,off+(y-1)*8)
			end
	end

	if theend>100 then
		map(16,0,0,-8*10+off,16,8)
		if off<200 then
			for i=1,3 do
				spr(115,(i+4)*8-off\7,-16+off)
				spr(115,(i+7)*8+off\7,-16+off)
			end
		end
	end

	local s=16
	for y=-1,16 do
			for x=1,16 do
					if x<5 or x>12 then
						s=7
					elseif x==5 then
						s=1
					elseif x==12 then
						s=17
					else
						s=0
					end
					if s!=0 then
						spr(s,(x-1)*8,off+(y-1)*8)
					end
			end
	end
	shipd()
//	cam()
	pal()
	fading()
end

function starsd()
		if not stars then
			stars={}
			local col={
				1,8,13,15,12,
			}
			for i=1,30 do
				add(stars,
					{x=rnd(128),
					y=rnd(128),
					c=col[trnd(#col)]})
			end
		end
		for s in all(stars) do
			pset(s.x,s.y,s.c)
			if (theend and theend>180)s.y+=(s.c/8)
			if s.y>128 then
				s.x=rnd(128)
				s.y=-rnd(16)
			end
		end
		pal(14,0)
//		spr(68,100,(y-24)*0.7,2,2)
		if not theend then
			spr(68,100,40,2,2)
		end
		pal(15,0)
end
function paint(xoff,yoff,y,col)
	if y<0 then return end
	for x=0,6*8 do
		local yy=70\16*8+y%16
		local xx=70%16*8
		local c=sget(xx+x,yy)
		if c!=0 and c!=14 then
			pset(xoff+x,yoff+y,col)
		end
	end
end

function _draw()
	if not started then 
		fading()
		return 
	end
	cls(0)
	if theend then
		endd()
		return
	end
	if explode then
			if explode>0 then
				camera(rnd(4)-2,rnd(4)-2)
			end
			explode-=1
			if explode==0 then
				camera()
			end
			if explode<-15 then
				explode=false
			end
	end
	if ship.explode then
		ship.explode-=1
		if ship.explode<-128 then
			if lives>1 then
				fadeout(function()
					lives-=1
					restore()
				end)
			else
				lives=0
				gameover=true
			end
		end
	end
	if -yy<=128 then
		starsd()
		local _,y=tos(0,-4)
		pal(15,0)
		map(0,0,0,y-60,16,8)
		for x=0,15 do
			if x<=lvl[1].l or 
				x>=15-lvl[1].r then
				spr(96,x*8,y-4)
			end
		end
		pal()
	end

	pal(15,0)
	for y=1,17 do
			for x=1,16 do
				if y+yy\8>0 then
					local plx=1.2
					if yy<0 then plx=1 end
					spr(16,(x-1)*8,(y-1)*8-yy/plx%8)
				end
			end
	end
	pal()
	for y=1,17 do
		local v=lvl[y+yy\8]

		for x=1,#v.spr do
			if v.spr[x]!=0 then
				local s=anim(v.spr[x])
				pal(15,0)
				spr(s,(x-1)*8,(y-1)*8-yy%8)
				pal(15)
			end
		end
--		spr(v.lspr,v.l*8,(y-1)*8-yy%8)
--		spr(v.rspr+16,(15-v.r)*8,(y-1)*8-yy%8)
	end
	for y=-1,17 do
		local v=lvl[y+yy\8]
		if v and v.d then
			v:d()
		end
	end
	shipd()
	lasd()
	partsd()
	expd()
	smkd()
	hud()
	if title then
		pal(14,0)
		spr(70,44,24,6,2)
		pal()
		local p=tm\8%24
		if p<16 then
			paint(44,24,p-1,12)
			paint(44,24,p,12)
		end
		print("BY hUGEPING",43,42,1)
		local x,y=0,60
		print("pilot! this is the planet",x+12,y,6)
		y+=6
		print("of evil boltzmann brain kylix!",x+5,y)
		y+=6
		print("destroy the main data center!",x+7,y,8)
		y+=6
		print("it is behind 15 gates.",x+24,y,8)
		y+=6
		print("good luck!",x+48,y,9)
		y+=12
		print("🅾️/z start",x+48,y,tm\4%2==1 and 15 or 8)
		y+=6
		y+=2
		if max_gw>0 then
			print("gate ⬅️"..ship.gw.."➡️",x+48,y,15)
		end
		y+=8
		if save_seed then
			print("⬆️ reset-next ⬇️",x+34,y,13)
		else
			print("⬇️ random world",x+36,y,13)
		end
		print("v1.2",112,122,15)
//		print("hugeping presents",32,0)
		if hiscore>0 then
			local h="hi score "..hiscore
			local x=64-#h*2
			print("hi score "..hiscore,x,0,tm\5%2==1 and 13 or 2)
		end
	end
	if save_seed then
		print("seed "..save_seed,0,122,7)
	end
	fading()
end
__gfx__
000000001111111dd0000000d00000001111111d1111111d00000000111111111111111d00000000d000000000000000d0000000001000000000000000000000
00000000111f11111d0000001d0000001f1111d01111f1d000000000111111f1d1f1111100000000d000000000000000d000000001dd00000000ffd00007d000
007007001111111d1110000011d0000011111d00111111d00000000011f111111111111d000000d666d00000000000d666ddd00000dd100000061c60000fd000
000770001f11111111d00000f11d00001111d00011111d00000000001f111111d111f111000dddfcccfddd000000ddfcccf11ddd000d10000061cc6000011000
000770001111111d11d000001111d000111d000011111d00000dd000111111111111111d0ddd11f111f11ddd0ddd11f111f00110000dd1000066cc0000ddd100
007007001111f1111110000011111d0011d000001f1111d000d11d0011f11111d1111111001100f676f00110001100f676f00df00000d100000fd00000000d00
000000001111111d1d000000111f11d01d000000111111d00d1111d011111f11111f111d00fd000606000df000fd000606000d700000d0000000000000000000
0000000011111111d00000001111111dd00000001111f11dd111f11d11111111d1111111007d000000000d70007d000000000000000000000000000000000000
ffffffffd11111110000000d0000000dd1111111d1111111d111111d00dd11000dddddd0000aa000000aa000000aa000000aa000000000000000000000000000
ffffffff11111111000000d1000000d10d111f110d1f11110d1f11d00d1111d0d111111d00008000000090000000900000008000000000000000000000000000
ffffffffd11f11110000011100000d1100d111110d11111100d11d0011111f1011111111000000000000800000000000000e0000000000000000000000011000
fffff1ff1111111100000d110000d111000d111100d11111000dd000d111111d1f11111f00008000000800000008000000080000a080000098000000000f6100
ffffffffd111111100000d11000d11110000d11100d111f10000000011f11111111111110000000000000000000080000000000098000000a0080000000ff100
fff1ffff11111f110000011100d111f100000d110d1111110000000011111f11111111110000000000000000000000000000000000000000000000000000f100
ffffffffd1111111000000d10d11f111000000d10d11f11100000000011111d011111f1100000000000000000000000000000000000000000000000000000000
ffffffff11f111110000000dd11111110000000dd1111111000000000011dd001111111100000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000cccccc0099999900000000000000000000000000000000000000000000000000000000000000000
0005550000055500000000000000000000090000000c000077ffff6677ffff660000000000000000000000001811111111191111111113100005550000011000
0022222000222220000000000000000000090000000c000077ffff6677ffff6600000000000000d000d666d01888888999999999333333100022222000cd1000
00d8555000d95550099999900777777000090000000c0000ee888888ee88888800000000000dddf000fcccf018111111111911111111131000d8555000cdd100
00333330003b3330000000000000000000090000000c0000ee888888ee888888000000000ddd11f000f111f000000000000000000000000000333330000dd100
0005550000055500000000000000000000090000000c0000ee888888ee88888800000000001100f000f676f000000000000000000000000000055500000dd100
0000000000000000000000000000000000090000000c000077ffff6677ffff66000000000000000000060600000000000000000000000000000000000000d000
00000000000000000000000000000000000000000000000077ffff6677ffff660000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000077ffff6677ffff66000e8000000e8000757575705757575700000000000000000000000000000000
1d0000001d0000000000000000000000000000000000000077ffff6677ffff66000760000007600075757570575757570d0000000d0000000000000000000000
1d0000001d000000ccccccccccccccccccccccccccccccccee888888ee888888000760000007600002332200023322000dd000000dd000000008800000099000
1d1ff8801d1ffee0d8d1d1d1d1d9d1d1d1d1dad1d1d1d1dbee888888ee888888033333300333333043b7fff043b7fff07a6666e8766666e80008800000099000
1d1ff8801d1ffee0ccccccccccccccccccccccccccccccccee888888ee888888057575700757575043bb340043bb3400addddde87adddde8000dd000000dd000
1d0000001d0000001111111111111111111111111111111177ffff6677ffff66749949955994994702332200023322000550000005500000000dd000000dd000
1d0000001d0000000000000000000000000000000000000077ffff6677ffff66599499477499499575757570575757570500000005000000000dd000000dd000
0000000000000000000000000000000000000000000000000cccccc00999999007575750057575707575757057575757000000000000000000cccc0000cccc00
000000000000000000000000111111110000000000000000eeeeeeeeeeeeeee0eeeeeeeeeeeeeeeeeeeeeeeeeee0000000000000000000000000000000000000
001000000001100000000000111111110000000000000000eddddeedddddede0ededddddeddddeeedddeeddddde0000000000000000000000000000000000000
011100000011100000000000111111110000011111000000edeeededeeeeede0ededeeeeedeeededeeededeeeee0000000000000000000000000000000000000
111110000011110000001000f1f1f1f1000016d1d1100000edeeededeeeeedeeededeeeeedeeededeeeeedeeee00000000000000000000000000000000000000
1111110001111100000111001f1f1f1f00016df61de10000eddddeeddddeeededeeddddeeddddeeedddeedddde00000000000000000000000000000000000000
111111100111111000111110ffffffff0016dff6d1de1000edeeededeeeeeededeedeeeeedeeedeeeeededeeee00000000000000000000000000000000000000
111111111111111001111111f1f1f1f1001d6f66dd11e000ede0ededeeeeeededeedeeeeede0ededeeededeeeee0000000000000000000000000000000000000
111111111111111111111111ffffffff0016df6dd1de1000ede0ededddddeeedeeedddddede0edeedddeeddddde0000000000000000000000000000000000000
00000000000000000000000000000000001d66dddd11e000eee0eeeeeeeee0eee0eeeeeeeee0eee0eeeeeeeeeee0000000000000000000000000000000000000
000000000000010000100000001000000011ddddd11e100000000000000eeeee000eeee000ee00eeee0000000000000000000000000000000000000000000000
0000000000001110011101000111000000011d1d11e100000000000000e8888e00e8888e0e88ee8888e000000000000000000000000000000000000000000000
0001000000011111111111101111100000001e1e1e100000000000000e88ee880e88ee88ee88ee88e88e00000000000000000000000000000000000000000000
00111000001111111111111111111100000001e1e1000000000000000e88ee880e88ee88ee88ee88e88e00000000000000000000000000000000000000000000
01111100011111111111111111111110000000000000000000000000e888888ee8888888e88ee88ee88e00000000000000000000000000000000000000000000
11111110111111111111111111111111000000000000000000000000e88ee888e88eee88e88ee88ee88e00000000000000000000000000000000000000000000
1111111111111111111111111111111100000000000000000000000e888eee88e88e0e88e88ee88888e000000000000000000000000000000000000000000000
111111110daaaad01111111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
11111111d116d11d111111f100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
111111111116d11111f1111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
f1f1f1f11f16d11f1f11111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1f1f1f1f1116d1111111111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ffffffff1116dddddddddddd00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
f1f1f1f1111666666666666600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
fddddddf111111111111111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6d6d6d6d6d6d6d6d00dd0d0001010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
d1111111d111111100d0dd001c1c1c1c000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
618dbdc161ed3d2100dd0d00dddddddd000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
d1111111d111111100d0dd001d1d1d1d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
61dedcd161d8d5d100dd0d00d1d1d1d1000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
d1111111d111111100d0dd00dddddddd000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
615d5de1618dbda100dd0d001c1c1c1c000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
d1111111d111111100d0dd0001010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__label__
17710770077177707771000077017770000100000001000000010000000100000001000000010000000100000001000000010770777177707771101177117701
711171d07070707070000000070070000000000000000000000018111a11111911111111131000000000000000000000000070007070070070d1111117011711
77717d007070770077000000070077700000000000000000000018888a899999999933333310000000000000000000000000700077700700770d111117111711
11717d007070707070000000070000700000000000000000000018111a1111191111111113100000000000000000000000007070707007007000d11117111711
771117707700707077700000777077700000000000000000000000000000000000000000000000000000000000000000000077707070070077700d1177717771
111111d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000d111111011
1111011d000001000000010000000100000001000000010000000100000001000000010000000100000001000000010000000100000001000000010d11111111
11111111d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000d1111111
111111011d010000000100000001000000010000000100000001000000010000000100000001000000010000000100000001000000010000000100000d101111
1101111111d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000d111111
10111111011d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000d11111
111111111111d000000000000000000000000000000000000000000000000000000dd00000000000000000000000000000000000000000000000000000d11101
1101111111111d0000000000000000000000000000000000000000000000000000d11d000000000000000000000000000000000000000000000000000d111111
11111011111011d00000000000000000000000000000000000000000000000000d1111d00000000000000000000000000000000000000000000000000d110111
111111111111111d000001000000010000000100000001000000010000000100d111011d000001000000010000000100000001000000010000000100d1111111
1111111111111111d00000000000000000000000000000000000000000000000d1111111d0000000000000000000000000000000000000000000000d11111111
11111101111111011d0100000001000000010000000100000001000000010000111111111d01000000010000000100000001000000010000000100d111111101
110111111101111111d000000000000000000000000000000000000000000000d1101111111000000000000000000000000000000000000000000d1111011111
1011111110111111011d000000000000000000000000000000000000000000001111111111d00000000000000000000000000000000000000000d11110111111
11111111111111111111d0000000000000000000000000000000000000000000d111111111d0000000000000000000000000000000000000000d111111111111
110111111101111111111d00000000000000000000000000000000000000000011111011111000000000000000000000000000000000000000d1110111011111
1111101111111011111011d00000000000000000000000000000000000000000d11111111d000000000000000000000000000000000000000d11011111111011
11111111111111111111111d000001000000010000000100000001000000010011011111d000010000000100000001000000015550000100d111111111111111
11111111111111111111111d000000000000000000000000000000000000000d1111111d000000000000000000000000000002222200000d1111111111111111
1111110111111101101111d000010000000100000001000000010000000100d1101111d000010000000100000001000000010d95550100d11111110111111101
110111111101111111111d000000000000000000000000000000000000000d1111111d00000000000000000000000000000003b333000d111101111111011111
10111111101111111111d000000000000000000000000000000000000000d1111111d000000000000000000000000000000000555000d1111011111110111111
1111111111111111111d000000000000000000000000000000000000000d1111111d000000000000000000000000000000000000000d11111111111111111111
110111111101111111d000000000000000000000000000000000000000d1110111d000000000000000000000000000000000000000d111011101111111011111
11111011111110111d000000000000000000000000000000000000000d1101111d000000000000000000000000000000000000000d1101111111101111111011
1111111111111111d000010000000100000001000000010000000100d1111111d000010000000100000001000000010000000100d11111111111111111111111
111111111111111d000000000000000000000000000000000000000d1111111d0000000000000000000000000000000000000000d11111111111111111111111
11111101111101d000010000000100000001000000010000000100d11110111100010000000100000001000000010000000100000d1110111111110111111101
11011111111111d00000000000000000000000000000000000000d111111111d000000000000000000000000000000000000000000d111111101111111011111
1011111111111d00000000000000000000000000000000000000d111101111110000000000000000000000000000000000000000000d11111011111110111111
1111111111111d0000000000000000000000000000000000000d11111111111d00000000000000000000000000000000000000000000d1111111111111111111
11011111101111d00000000000000000000000000000000000d1110111110111000000000000000000000000000000000000000000000d111101111111011111
11111011111111d0000000000000000000000000000000000d1101111111111d0000000000000000000000000000000000000000000000d11111101111111011
111111111111011d00000100000001000000010000000100d11111111111111100000100000001000000010000000100000001000000010d1111111111111111
111111111111111d0000000000000000000000000000000d1111111111111111d00000000000000000000000000000000000000000000000d111111111111111
1111110111101111000100000001000000010000000100d111111101111111011d01000000010000000100000001000000010000000100000d11101111111101
110111111111111d00000000000000000000000000000111110111111101111111d00000000000000000000000000000000000000000000000d1111111011111
101111111011111100000000000000000000000000000d111011111110111111011d00000000000000000000000000000000000000000000000d111110111111
111111111111111d00000000000000000000000000000d1111111111111111111111d00000000000000000000000000000000000000000000000d11111111111
110111111111011100000000000000000000000000000111110111111101111111111d00000000000000000000000000000000000000000000000d1111011111
111110111111111d000000000000000000000000000000d11111101111111011111011d00000000000000000000000000000000000000000000000d111111011
11111111111111110000010000000100000001000000010d11111111111111111111111d00000100000001000000010000000100000001000000010d11111111
1111111111111111d0000000000000000000000000000000d11111111111111111111111d00000000000000000000000000000000000000000000000d1111111
11111101111111011d0100000001000000010000000100001111111111111101111111011d01000000010000000100000001000000010000000100000d101111
110111111101111111100000000000000000d00000000000d110111111011111110111111110000000000000000000000000000000000000000000000d111111
101111111011111111d00000000000000000d0000000000011111111101111111011111111d00000000000000000000000000000000000000000000000d11111
111111111111111111d000000000000000d666d000000000d1111111111111111111111111d00000000000000000000000000000000000000000000000d11101
1101111111011111111000000000000dddfcccfddd0000001111101111011111110111111110000000000000000000000000000000000000000000000d111111
11111011111110111d00000000000ddd11f111f11ddd0000d111111111111011111110111d00000000000000000000000000000000000000000000000d110111
1111111111111111d00001000000011100f676f001100100110111111111111111111111d00001000000010000000100000001000000010000000100d1111111
111111111111111d00000000000000fd000606000df00000d1111111111111111111111d00000000000000000000000000000000000000000000075757575111
11111101111101d0000100000001007d000100000d71000011111111111111011110111100010000000100000001000000010000000100000001075757575101
11011111111111d000000000000000aa000000000aa00000d1101111110111111111111d00000000000000000000000000000000000000000000011223321111
1011111111111d0000000000000000090000000000900000111111111011111110111111000000999999000000000000000000000000000000000dfff7b34111
1111111111111d0000000000000000080000000000000000d1111111111111111111111d000000000000000000000000000000000000000000000d143bb34111
11011111101111d00000000000000080000000000800000011111011110111111111011100000000000000000000000000000000000000000000011223321111
11111011111111d000000000000000000000000000800000d1111111111110111111111d00000000000000000000000000000000000000000000075757575011
111111111111011d0000010000000100000001000000010011011111111111111111111100000100000001000000010000000100000001000000075757575111
1111111111111111d0000000000000000000000000000000d11111111111111111111111d00000000000000000000000000000000000000000000000d1111111
11111101111111011d0100000001000000010000000100001111111111111101111111011d01000000010000000100000001000000010000000100000d101111
110111111101111111100000000000000000000000000000d110111111011111110111111110000000000000000000000000000000000000000000000d111111
101111111011111111d0000000000000000000000000000011111111101111111011111111d00000000000000000000000000000000000000000000000d11111
111111111111111111d00000000000000000000000000000d1111111111111111111111111d00000000000000000000000000000000000000000000000d11101
1101111111011111111000000000000000000000000000001111101111011111110111111110000000000000000000000000000000000000000000000d111111
11111011111110111d000000000000000000000000000000d111111111111011111110111d00000000000000000000000000000000000000000000000d110111
1111111111111111d0000100000001000000010000000100110111111111111111111111d00001000000010000000100000001000000010000000100d1111111
111111111111111d00000000000000000000000000000000d1111111111111111111111d000000000000000000000000000000000000000000000000d1111111
11111101101111d0000100000001000000010000000100001111111111111101101111d000010000000100000001000000010000000100000001000011111111
1101111111111d0000000000000000000000000000000000d11011111101111111111d00000000000000000000000000000000000000000000000000d1101111
101111111111d0000000000000000000000000000000000011111111101111111111d00000000000000000000000000000000000000000000000000011111111
11111111111d000000000000000000000000000000000000d111111111111111111d0000000000000000000000000000000000000000000000000000d1111111
1101111111d0000000000000000000000000000000000000111110111101111111d0000000000000000000000000000000000000000000000000000011111011
111110111d00000000000000000000000000000000000000d1111111111110111d000000000000000000000000000000000000000000000000000000d1111111
11111111d0000100000001000000010000000100000001001101111111111111d000010000000100000001000000010000000100000001000000010011011111
1111111d0000000000000000000000000000000000000000d11111111111111d00000000000000000000000000000000000000000000000000000000d1111111
111101d000010000000100000001000000010000000100000d111011111011111d01000000010000000100000001000000010000000100000001000011111111
111111d0000000000000000000000000000000000000000000d111111111111d1d000000000000000000000000000000000000000000000000000000d1101111
11111d000000000000000000000000000000000000000000000d1111101111111d1ff88000000000000000000000000000000000000000000000800011111111
11111d0000000000000000000000000000000000000000000000d1111111111d1d1ff88cccccccccccccccccccccccccccccccccccccccccccccccccd1111111
101111d0000000000000000000000000000000000000000000000d11111101111d00000000000000000000000000000000000000000000000000000011111011
111111d00000000000000000000000000000000000000000000000d11111111d1d000000000000000000000000000000000000000000000000000000d1111111
1111011d00000100000001000000010000000100000001000000010d111111110000010000000100000001000000010000000100000001000000010011011111
11111111d00000000000000000000000000000000000000000000000d1111111d0000000000000000000000000000000000000000000000000000000d1111111
111111011d0100000001000000010000000100000001000000010000111111111d01000000010000000100000001000000010000000100000001000011111111
11011111111000000000000000000000000000000000000000000000d110111111100000000000000000000000000000000000000000000000000000d1101111
1011111111d0000000000000000000000000000000000000000000001111111111d0000000000000000000000000000000000000000000000000000011111111
1111111111d000000000000000000000000000000000000000000000d111111111d00000000000000000000000000000000000000000000000000000d1111111
11011111111000000000000000000000000000000000000000000000111110111110000000000000000000000000000000000000000000000000000011111011
111110111d0000000000000000000000000000000000000000000000d11111111d000000000000000000000000000000000000000000000000000000d1111111
11111111d0000100000001000000010000000100000001000000010011011111d000010000000100000001000000010000000100000001000000010011011111
1111111d00000000000000000000000000000000000000000000000d1111111d00000000000000000000000000000000000000000000000000000000d1111111
111101d00001000000010000000100000001000000010000000100d1111011110001000000010000000100000001000000010000000100000001000011111111
111111d00000000000000000000000000000000000000000000001111111111d00000000000000000000000000000000000000000000000000000000d1101111
11111d00000000000000000000000000000000000000000000000d11101111110000000000000000000000000000000000000000000000000000000011111111
11111d00000000000000000000000000000000000000000000000d111111111d00000000000000000000000000000000000000000000000000000000d1111111
101111d0000000000000000000000000000000000000000000000111111101110000000000000000000000000000000000000000000000000000000011111011
111111d00000000000000000000000000000000000000000000000d11111111d00000000000000000000000000000000000000000000000000000000d1111111
1111011d00000100000001000000010000000100000001000000010d111111110000010000000100000001000000010000000100000001000000010011011111
1111111d000000000000000000000000000000000000000000000000d111111d00000000000000000000000000000000000000000000000000000000d1111111
111011110001000000010000000100000001000000010000000100000d1011d00001000000010000000100000001000000010000000100000001000011111111
1111111d00000000000000000000000000000000000000000000000000d11d0000000000000000000000000000000000000000000000000000000000d1101111
10111111000000000000000000000000000000000000000000000000000dd0000000000000000000000000000000000000000000000000000000000011111111
1111111d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000d1111111
11110111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011111011
1111111d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000d1111111
11111111000001000000010000000100000001000000010000000100000001000000010000000100000001000000010000000100000001000000010011011111
1111111d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000d1111111
11101111000100000001000000010000000100000001000000010000000100000001000000010000000100000001000000010000000100000001000011111111
1111111d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000d1101111
10111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011111111
1111111d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000d1111111
11110111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011111011
1111111d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000d1111111
11111111000001000000010000000100000001000000010000000100000001000000010000000100000001000000010000000100000001000000010011011111
11111111d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000d11111111
111111011d010000000100000001000000010000000100000001000000010000000100000001000000010000000100000001000000010000000100d111111101
11011111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011111011111
1011111111d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000d1110111111
1111111111d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000088088088088088188188188
11011111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000088888088888088888088888
111110111d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000088888088888088888188888
11111111d00001000000010000000100000001000000010000000100000001000000010000000100000001000000010000000100008881008880018881118881
1111111d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000008000008000008d1111811

__gff__
0000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000010101010000000000000000010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001010101000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5050514041424142515253415042415152405050410000000000004250515253000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4343434343434343434343434343434343434343434343434343434343434343000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
000100003b550335502c550295502655024550225501f5501c55019550175501655013550115500f5500c55008550065500755005550015500055000550026000260002600016000160001600006000060000600
000600000063700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000300003f670346702e6702967026670246702567025670256702767025670216701e6701a66014650116500d6400b6400764006630046200361002610006100260001600006000560004600036000160000600
000800002d050380501d0501a050220502d050350503e0500e0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000100002923027230262302423023230212301f2301d2301b230192301623015230122300f2300c2300b2300a230072400424001240002400024000000000000000000000000000000000000000000000000000
00100000270502e05033050350503a0503f0503f05000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000100003f6503665032650306502d6502b6502a6502865025650236501d65019650146500f650086500365001650006500065000000000000000000000000000000000000000000000000000000000000000000
000100003b55036550315502d5502855023550205501e55019550165501455011550105500f5500d5500a55008550075500555000000000000000000000000000000000000000000000000000000000000000000
00070000057500f750137501b75022750277502e750357503a7503f7503a750377503c7503a7503c7503a7503c7503a7503c7503a750377503975037750337502b7502e75029750247501d750187501375007750
000800002105028050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000500000057000570015700157002560025500355005550055500655007550095500a5500c5500d5500d5500f55011550135501455017550185501a5501c5501f55023550255502a5502c550305503555039550
00050000046500565005650066500765008650086500b6500b6500c6500d6500d6500e6500e6500f65010650116501365015650176501a6501c6501d6501f6502265024650286502b65030650356503c6503f650
011000001a5511a5521a5001a5521a5511a5001a5521a5521a5001d5521c552185521a5521a5521a5001a5521a5521a5001a5521a5521a5001d5521c552155521855118552185001855218552185001855218552
01100000185521d5521c552155521855118552185001855218552185001c5521c5521c5001d5521d5521a4001a4001a4001a4001a4001a4001a4001a4001a4001a4001a4001a4001a4001a4001a4001a30000000
011000001f5511f5521f5521f5521f5521f5521f5521f5521f5521d5521c552185521a5521a5521a5521a5521a5521a5521a5521a5521a5521d5521c552155521d5511d5521d5521d5521d5521d5521d5521d552
01100000185521d5521c552155521855118552185521855218552185511d5521d5521d5001f5521f5521f50000000000000000000000000000000000000000000000000000000000000000000000000000000000
000800000c5000c5000c5000c5000c5000c5000c5000c5000c5000c5000c5000c5000c5000c5000c500000000000000000000000c00300000000001800329000000001860300000000000c003000000000018003
011000000c07328000000001800300000000001865300000000001830300000000000c07300000000001800329000000001865300000000001835300000000000c05329000000001800300000000001867300000
01100000000001830300000000000c073000000000018003290000000018653000000000018353000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000002903528035260352803529035280352903528035260352803529035280352903528035260352803529035280352903528035260352803529035280352803526035240352603528035260352803526035
011000002803526035240352603528035260352803526035240352603528035260352803526035240352603500000000000000000000000000000000000000000000000000000000000000000000000000000000
011000000e5520e552115521055211552105520e5520e5520e5560e5520e5520e5550e5020e5520e552115521055211552105520e5520e5520e5520e5520e5520c5510c5520c5520c5520c5520c5520c5520c552
010800000c5520c5520c5520c5520c5520c5520c5520c5520c5520c5520c5520c5520c5520c5520c5520c55211000100000e0000c0000e0000e5000e5000e5000c5000c5000c5000c5000c5000c5000c5000c500
0010000029750007000070000700217002570026700357002f70024700207002f7003070005400024000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
01 4c0c514c
00 100d5244
00 4c0c1144
00 100d1244
00 410e1144
00 100f1244
00 4c0c114c
00 100d1244
00 150c1113
00 160d1214
00 150c1113
00 160d1214
00 410e1144
00 100f1244
00 150c1113
02 160d1214

