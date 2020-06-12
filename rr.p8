pico-8 cartridge // http://www.pico-8.com
version 27
__lua__
local save_seed
local handl=0.03
local r16=12
local gameover=false
local r8=12
local explode=false
local gates={}
local score=0
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

function irnd16()
	local t=flr(r16)^^flr(r16>>14)^^flr(r16>>13)^^flr(r16>>11)^^1
	r16=(r16>>1)&0x7fff
	r16|=(t<<15)
	return r16&0xffff
end
function rnd16()
	local t=flr(r16>>15)^^flr(r16>>13)^^flr(r16>>12)^^flr(r16>>10)^^1
	r16=(r16<<1)&0xffff
	r16|=(t&1)
	return r16&0xffff
end

function irnd8()
	local t=flr(r8>>6)^^flr(r8>>5)^^flr(r8>>4)^^r8
	r8=(r8>>1)&0xff
	r8=r8|((t&1)<<7)
	return r8
end
function rnd8()
	local t=flr(r8>>7)^^flr(r8>>5)^^flr(r8>>4)^^flr(r8>>3)
	r8=(r8<<1)&0xff
	r8|=(t&1)
	return r8
end

function rnd16p(v)
	local s=r16
	r16=v
	irnd16()
	r16=s
end

function rnd1()
	lfsr^^=lfsr>>7
	lfsr^^=lfsr<<9
	lfsr^^=lfsr>>13
	return lfsr
end
function rnd2()
	lfsr^^=lfsr<<7
	lfsr^^=lfsr>>9
	lfsr^^=lfsr<<8
	return lfsr
end
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
	score=0
	gameover=false
	theend=false
	target=0
	mklevel(16,16,2000,seed)
	ship={dshot=0,f=1,x=64,y=-110,g=0,v=0,h=0,t=0,tx=0}
//	ship.y=128*15*8+16
//	ship.y=128*7*8-230
	yy,cam_y=ship.y,ship.y
	cam()
	cam_y=yy
	mksnap(1)
	started=true
end
function _init()
	fadeout(function()
		restart()
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
local las={}

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
		if y>128+16 or y<0 and l.dy!=0 then
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

local exp={}
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
		if l.v~=v and l.x>=x-w and l.x<x+w and
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
	local os=score
	score+=d or 5
	if score\100~=os\100 then
		lives+=1
		sfx(5)
	end
end

function f_hit(v,dx,dy)
	dx=dx or 0
	dy=dy or 0
	if hit(v.pos+dx,v.yy+dy,ship.x,ship.y,8,4) then
		v.f=nil
		v.d=nil
		sfx(2)
		scorea(v.score)
		expa(v.pos,v.yy,8,v)
		ship.crash=true
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
		v.pos=x
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
			v.delay=100
			sfx(7)
		end
	end
	
	f_hit(v)
	f_lcol(v,4,4,0,0,6)
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
		v.f=f_gaub
		v.d=d_gaub
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
		v.f=f_mine
		v.d=d_mine
	end
end

function f_lcol(v,w,h,dx,dy,rr)
	if lcol(v.pos+(dx or 0),v.yy+(dy or 0),w,h,v)
		or pcol(v.pos+(dx or 0),v.yy+(dy or 0),w,h)
		or ecol(v.pos+(dx or 0),v.yy+(dy or 0),w,h,v)
		then
		v.f=nil
		v.d=nil
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
	if not ship.crash and hit(v.pos,v.yy-4,ship.x,
		ship.y,8,4) or hit(v.pos,v.yy+4,ship.x,
		ship.y,8,4) then
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
	ship.gw=g
	snap={}
	for k,v in pairs(ship) do
		snap[k]=v
	end
//	printh("mksnap "..tostr(g))
end

function restore()
	ship={}
	mklevel(16,16,2000,save_seed)
	for k,v in pairs(snap) do
		ship[k]=v
	end
	ship.v=0
	ship.h=0
	ship.f=1
	target=0
	local g=gates[ship.gw]
	if ship.gw~=1 then
		ship.y=g.y*8+12
	else
		ship.y=-64
	end
	for i=g.l+1,14-g.r do
		g.spr[i+1]=0
	end
	if ship.gw>1 then
			lvl[g.y].f=nil
			lvl[g.y].d=nil
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
	if v.tm>120 then
		v.laser=true
		if v.tm>240 then
			v.laser=false
			v.tm=0
		end
	end
	f_lcol(v,4,4,4,4)
	f_hit(v,4,4)
	if v.laser then
		sfx(4)
		if mm(v.stop,v.yy)==0 then
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
			ship.crash=true
		end
	end
end

function d_laser(v)
	local x,y=tos(v.pos,v.yy)
	spr(48+tm\8%2,x,y,1,1,v.dir<0)
	if v.laser then
		if v.dir<0 then
			x-=1
		end
		line(x+4,y+3+tm%2,v.stop,y+3+tm%2,(tm\4%2==1) and 12 or 7)
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
	v.d=d_laser
	v.f=f_laser
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
	v.d=d_tank
	v.f=f_tank
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
	v.d=d_rock
	v.f=f_rock
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
			v.f=f_fuel
			v.d=d_fuel
		end
	end
end

function mklevel(w,h,hh,seed)
	save_seed=seed
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
		
		if dist>128 and gate_nr<14 then
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
				if y>=hh-128 then
//					printh(gate_nr)
					t=5
				end
			end
		end
		add(lvl,cur)
	end
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
		--		cur.f=f_item
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
		if v.t~=0 then
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
	lvl[hh-1].f=nil
	lvl[hh-1].d=nil
	lvl[hh-2].f=nil
	lvl[hh-2].d=nil
	n_laser(lvl[hh-3])
	n_laser(lvl[hh-4])
	local l=lvl[hh+8]
	l.spr[11]=97
	for i=12,16 do
		l.spr[i]=98
	end
//printh(#gates)
end

function cam()
	local d=abs(cam_y-yy)
	if yy~=cam_y then
		if d>1 then d=1 end
		if cam_y>yy then
			yy+=d
		else
			yy-=d
		end
		if yy<-120 then yy=-120 end
	end
	local v=cos(0.25+ship.v*0.25)
	if not ship.explode then
		if ship.crash then
			cam_y=(ship.y-48)
		else
			cam_y=(ship.y-48)-v*32
		end
	end
end
function clip(v,m,x)
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
		ship.crash=true
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
	if theend !=true and theend>128 then
		yy+=1
		cam_y=yy
		ship.y-=1
	else
		cam_y=ship.y-100+4*sin(ship.v)
		yy=cam_y
	end
	if theend==true then theend=0 end
	theend+=1
end

function shipm()
	if gameover and (btnp(4) or btnp(5)) then
		fadeout(function()
			lives=5
			restart()
			title=true
		end)
		return
	end
	if theend then
		endm()
		return
	end
	if title then
		if btn(0) and btn(1) then
			restart(flr(rnd(16384)))
			title=false
			ship.v,ship.h=0,0
		elseif btnp(4) or btnp(5) then
			title=false
			ship.v=0
			ship.h=0
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
	if type(ship.crash)=='number' then
		x=x+ship.crash 
	end
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
		ship.h-=handl
		ship.tx=-1
		ship.f-=0.0005
	elseif not both and btn(1) and ship.f>0 and not ship.crash then
		ship.h+=handl
		ship.tx=1
		ship.f-=0.0005
	else
		ship.h*=0.90
		ship.tx=0
	end
	if ship.dshot==0 and not ship.crash and btnp(4) then
		sfx(0)
		lshoty(ship,ship.x+1,ship.y-3,3)
		ship.dshot=20
	end
	if not ship.crash and ship.dshot>0 then ship.dshot-=1 end
	ship.h=clip(ship.h,-1,1)
	if (btn(2) or btn(5) or both) and ship.f>0 and not ship.crash then
		ship.v-=handl
		ship.t=true
		ship.f-=0.0005
	else
		ship.t=false
		ship.v*=0.99
	end
	if ship.t then
		sfx(1)
	end
	if ship.f<0 then ship.f=0 end
	if not ship.crash and ship.y<0 then
		if x<8 then ship.tx=1 ship.h+=0.2 end
		if x>=120 then ship.tx=-1 ship.h-=0.2 end
		if y<-128 then ship.t=false ship.v=0 end
	end
	if not ship.t then
		ship.v+=0.01
	end
	ship.v+=0.01
	ship.v=clip(ship.v,-1,1)
	shipcol()
	if lcol(ship.x,ship.y,8,4) or
		ecol(ship.x,ship.y,8,4,ship) then
		expa(ship.x,ship.y,8,ship)
		sfx(2)
		ship.crash=true
		ship.crash=ship.h
	end
end

function _update60()
	tm+=1
	if not started then
		return
	end
	for y=1,18 do
		local v=lvl[y+yy\8]
		if v.f then
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
parts={}

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
	print("score "..score,0,0,15)
	for i=1,lives do
		if i>10 then
			break
		end
		print("♥",128-i*6,123,8)
	end
	if save_seed then
		print("seed "..save_seed,0,123,7)
	end
//	print(tostr(yy\8),0,0,7)
end

function endd()
	pal(14,0)
	starsd()
	if theend>200 then
		pal()
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
		end
		pal(14,0)
//		spr(68,100,(y-24)*0.7,2,2)
		spr(68,100,40,2,2)
		pal(15,0)
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
		print("⬅️+➡️ random raid",x+34,y,13)
		print("v1.0",112,122,15)
		print("hugeping presents",32,0)
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
d0000000d00000000000000000000000000000000000000077ffff6677ffff66000760000007600075757570575757570d0000000d0000000000000000000000
d0000000d0000000ccccccccccccccccccccccccccccccccee888888ee888888000760000007600002332200023322000dd000000dd000000008800000099000
df880000dfee0000d8d1d1d1d1d9d1d1d1d1dad1d1d1d1dbee888888ee888888033333300333333043b7fff043b7fff07a6666e8766666e80008800000099000
df880000dfee0000ccccccccccccccccccccccccccccccccee888888ee888888057575700757575043bb340043bb3400addddde87adddde8000dd000000dd000
d0000000d00000001111111111111111111111111111111177ffff6677ffff66749949955994994702332200023322000550000005500000000dd000000dd000
d0000000d00000000000000000000000000000000000000077ffff6677ffff66599499477499499575757570575757570500000005000000000dd000000dd000
0000000000000000000000000000000000000000000000000cccccc00999999007575750057575707575757057575757000000000000000000cccc0000cccc00
00000000000000000000000011111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00100000000110000000000011111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01110000001110000000000011111111000001111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000
111110000011110000001000f1f1f1f1000016d1d110000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1111110001111100000111001f1f1f1f00016df61de1000000000000000000000000000000000000000000000000000000000000000000000000000000000000
111111100111111000111110ffffffff0016dff6d1de100000000000000000000000000000000000000000000000000000000000000000000000000000000000
111111111111111001111111f1f1f1f1001d6f66dd11e00000000000000000000000000000000000000000000000000000000000000000000000000000000000
111111111111111111111111ffffffff0016df6dd1de100000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000001d66dddd11e00000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000010000100000001000000011ddddd11e100000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000001110011101000111000000011d1d11e1000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0001000000011111111111101111100000001e1e1e10000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00111000001111111111111111111100000001e1e100000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01111100011111111111111111111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
11111110111111111111111111111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
11111111111111111111111111111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888eeeeee888888888888888888888888888888888888888888888888888888888888888888888888ff8ff8888228822888222822888888822888888228888
8888ee888ee88888888888888888888888888888888888888888888888888888888888888888888888ff888ff888222222888222822888882282888888222888
888eee8e8ee88888e88888888888888888888888888888888888888888888888888888888888888888ff888ff888282282888222888888228882888888288888
888eee8e8ee8888eee8888888888888888888888888888888888888888888888888888888888888888ff888ff888222222888888222888228882888822288888
888eee8e8ee88888e88888888888888888888888888888888888888888888888888888888888888888ff888ff888822228888228222888882282888222288888
888eee888ee888888888888888888888888888888888888888888888888888888888888888888888888ff8ff8888828828888228222888888822888222888888
888eeeeeeee888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
1e111e1e1e1e1e1111e111e11e1e1e1e111116161111161116161616161617111616111711111111111111111111111111111111111111111111111111111111
1ee11e1e1e1e1e1111e111e11e1e1e1e111116161111161116661616166117111616111711111111111111111111111111111111111111111111111111111111
1e111e1e1e1e1e1111e111e11e1e1e1e111116161111161616161616161617111666111711111111111111111111111111111111111111111111111111111111
1e1111ee1e1e11ee11e11eee1ee11e1e111116661666166616161166166611711161117111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
12111e1111ee11ee1eee1e111111161611111616111116661166116611711616111116661166116611111c1c1111161611111616161611111c1c117111111111
12111e111e1e1e111e1e1e111111161611111616177711611616161117111616111116161616161111111c1c1111161611111616161611111c1c111711111111
12111e111e1e1e111eee1e111111116111111666111111611616166617111616111116661616166617771ccc1111161611111666166617771ccc111711111111
12111e111e1e1e111e1e1e11111116161171111617771161161611161711166611111611161611161111111c117116661111111611161111111c111711111111
12111eee1ee111ee1e1e1eee111116161711166611111161166116611171116111711611166116611111111c171111611171166616661111111c117111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
121111bb1bbb1bbb11711ccc1c111111117116161111116616661666166611111eee1ee11ee111111ccc111111ee1eee11111cc1117111111616111116161171
12111b111b1b1b1b17111c111c111171171116161111161111611611161611111e1e1e1e1e1e11111c1c11111e1e1e1e111111c1111711111616111116161117
12111bbb1bbb1bb117111ccc1ccc1777171116161111166611611661166611111eee1e1e1e1e11111c1c11111e1e1ee1111111c1111711111161111116661117
1211111b1b111b1b1711111c1c1c1171171116661111111611611611161111111e1e1e1e1e1e11111c1c11111e1e1e1e111111c1111711711616117111161117
12111bb11b111b1b11711ccc1ccc1111117111611171166111611666161111111e1e1e1e1eee11111ccc11111ee11e1e11111ccc117117111616171116661171
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1eee1ee11ee111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1e111e1e1e1e11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1ee11e1e1e1e11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1e111e1e1e1e11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1eee1e1e1eee11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1eee1e1e1ee111ee1eee1eee11ee1ee1111116661111166616661661161611711616117111111111111111111111111111111111111111111111111111111111
1e111e1e1e1e1e1111e111e11e1e1e1e111116111111116116161616161617111616111711111111111111111111111111111111111111111111111111111111
1ee11e1e1e1e1e1111e111e11e1e1e1e111116611111116116661616166117111616111711111111111111111111111111111111111111111111111111111111
1e111e1e1e1e1e1111e111e11e1e1e1e111116111111116116161616161617111666111711111111111111111111111111111111111111111111111111111111
1e1111ee1e1e11ee11e11eee1ee11e1e111116111666116116161616161611711161117111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
12111e1111ee11ee1eee1e111111161611111616111116661166116611111616111116611666166617171ccc11111cc111111111111111111111111111111111
12111e111e1e1e111e1e1e111111161617771616111116161616161111711616111116161161161611711c1c111111c111111111111111111111111111111111
12111e111e1e1e111eee1e111111116111111616111116661616166617771616111116161161166117771c1c111111c111111111111111111111111111111111
12111e111e1e1e111e1e1e111111161617771666111116111616111611711666111116161161161611711c1c111111c111111111111111111111111111111111
12111eee1ee111ee1e1e1eee1111161611111161117116111661166111111161117116661666161617171ccc11c11ccc11111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
12111eee1eee1111166616661166116616111171161611111616111116611666166617171c1c11111616111116161616117111111eee1e1e1eee1ee111111111
121111e11e111111166616661611161616111711161611711616111116161161161611711c1c111116161111161616161117111111e11e1e1e111e1e11111111
121111e11ee11111161616161611161616111711116117771616111116161161166117771ccc111116161111166616661117111111e11eee1ee11e1e11111111
121111e11e11111116161616161116161611171116161171166611111616116116161171111c117116661111111611161117111111e11e1e1e111e1e11111111
12111eee1e11111116161616116616611666117116161111116111711666166616161717111c171111611171166616661171111111e11e1e1eee1e1e11111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
12111211161611111666116611661111161611111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
12111211161611111616161616111777161611111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
12111211161611111666161616661111116111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
12111211166611111611161611161777161611111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
12111211116111711611166116611111161611111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
121112111eee1eee11111666166617171ccc111111111cc111111eee1e1e1eee1ee1111111111111111111111111111111111111111111111111111111111111
1211121111e11e1111111161166611171c1c1777177711c1111111e11e1e1e111e1e111111111111111111111111111111111111111111111111111111111111
1211121111e11ee111111161161611711ccc1111111111c1111111e11eee1ee11e1e111111111111111111111111111111111111111111111111111111111111
1211121111e11e1111111161161617111c1c1777177711c1111111e11e1e1e111e1e111111111111111111111111111111111111111111111111111111111111
121112111eee1e1111111161161617171ccc111111111ccc111111e11e1e1eee1e1e111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
12111211121116161111116616661666166611111ee111ee1eee1111161611111166166616661666111111111111111111111111111111111111111111111111
12111211121116161111161111611611161617771e1e1e1e11e11111161611111611116116111616111111111111111111111111111111111111111111111111
12111211121116161111166611611661166611111e1e1e1e11e11111161611111666116116611666111111111111111111111111111111111111111111111111
12111211121116661111111611611611161117771e1e1e1e11e11111166611111116116116111611111111111111111111111111111111111111111111111111
12111211121111611171166111611666161111111e1e1ee111e11111116111711661171116661611111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111177111111111111111111111111111111111111111111111111111111111
121112111eee1ee11ee1111111111111111111111111111111111111111111111111177711111111111111111111111111111111111111111111111111111111
121112111e111e1e1e1e111111111111111111111111111111111111111111111111177771111111111111111111111111111111111111111111111111111111
121112111ee11e1e1e1e111111111111111111111111111111111111111111111111177111111111111111111111111111111111111111111111111111111111
121112111e111e1e1e1e111111111111111111111111111111111111111111111111111711111111111111111111111111111111111111111111111111111111
121112111eee1e1e1eee111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
12111eee1ee11ee11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
12111e111e1e1e1e1111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
12111ee11e1e1e1e1111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
12111e111e1e1e1e1111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
12111eee1e1e1eee1111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
12111eee1eee11111ee111ee1eee1111116616161666166611111166166616661166161611111eee1ee11ee111111ee111ee1eee111116161111116616161166
121111e11e1111111e1e1e1e11e11111161116161161161611111611161616161611161611111e1e1e1e1e1e11111e1e1e1e11e1111116161111161116161616
121111e11ee111111e1e1e1e11e11111166616661161166611111611166116661666166611111eee1e1e1e1e11111e1e1e1e11e1111116161111166616661616
121111e11e1111111e1e1e1e11e11111111616161161161111111611161616161116161611111e1e1e1e1e1e11111e1e1e1e11e1111116661111111616161616
12111eee1e1111111e1e1ee111e11111166116161666161111711166161616161661161611111e1e1e1e1eee11111e1e1ee111e1111111611171166116161661
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
12111211161111661616116616661171161611111616111116661166116611111ccc1717161611111661166616661111161611111616161611111cc111111ccc
1211121116111611161616161161171116161111161611111616161616111171111c11711616111116161161161611111616111116161616111111c11111111c
121112111611166616661616116117111616111116161111166616161666177711cc17771616111116161161166111111616111116661666177711c111111ccc
1211121116111116161616161161171116661171166611111611161611161171111c11711666111116161161161611711666111111161116111111c111711c11
12111211166616611616166111611171116117111161117116111661166111111ccc1717116111711666166616161711116111711666166611111ccc17111ccc
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
12111eee1ee11ee11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
12111e111e1e1e1e1111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
12111ee11e1e1e1e1111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
12111e111e1e1e1e1111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
12111eee1e1e1eee1111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
12111666111116161666166611711616117111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
12111611111116161161116117111616111711111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
12111661111116661161116117111616111711111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
12111611111116161161116117111666111711111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
12111611166616161666116111711161117111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
12111666111116111166116616111171161611111c1c11111c1c11111ccc11111ccc11111c1c1171111111111111111111111111111111111111111111111111
12111611111116111611161616111711161611111c1c11111c1c11111c1c11111c1c11111c1c1117111111111111111111111111111111111111111111111111
12111661111116111611161616111711161611111ccc11111ccc11111c1c11111c1c11111ccc1117111111111111111111111111111111111111111111111111
1211161111111611161116161611171116661171111c1171111c11711c1c11711c1c1171111c1117111111111111111111111111111111111111111111111111
1211161116661666116616611666117111611711111c1711111c17111ccc17111ccc1711111c1171111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1eee1ee11ee111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1e111e1e1e1e11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1ee11e1e1e1e11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1e111e1e1e1e11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1eee1e1e1eee11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
82888222822882228888822282288222888282288228822282228888888888888888888888888888888882228282822282228882822282288222822288866688
82888828828282888888888288288282882888288828828288828888888888888888888888888888888882888282888282828828828288288282888288888888
82888828828282288888882288288222882888288828822288228888888888888888888888888888888882228222822282828828822288288222822288822288
82888828828282888888888288288882882888288828888288828888888888888888888888888888888888828882828882828828828288288882828888888888
82228222828282228888822282228882828882228222888282228888888888888888888888888888888882228882822282228288822282228882822288822288
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888

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
6060606043434343434343434360606043434343434343434343434343434343000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
000100003b550335502c550295502655024550225501f5501c55019550175501655013550115500f5500c55008550065500755005550015500055000550026000260002600016000160001600006000060000600
0006000009620096003f6000160002600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000300003f670346702e6702967026670246702567025670256702767025670216701e6701a66014650116500d6400b6400764006630046200361002610006100260001600006000560004600036000160000600
000800002d050380501d0501a050220502d050350503e0500e0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000100002925027250262502425023250212501f2501d2501b250192501625015250122500f2500c2500b2500a250072500425001250002500025000000000000000000000000000000000000000000000000000
00100000270502e05033050350503a0503f0503f05000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000100003f6503665032650306502d6502b6502a6502865025650236501d65019650146500f650086500365001650006500065000000000000000000000000000000000000000000000000000000000000000000
000100003b55036550315502d5502855023550205501e55019550165501455011550105500f5500d5500a55008550075500555000000000000000000000000000000000000000000000000000000000000000000
