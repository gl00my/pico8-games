pico-8 cartridge // http://www.pico-8.com
version 27
__lua__
-- aeroplane adventure
-- by hugeping
tm=0
pspr={
	{64,8,10,1-1/8},--\\
	{13,10,9,1-1/16},--\
	{1,9,9,0},-->
	{3,9,9,1/16},--/
	{5,9,9,1/8},--//

	{7,9,9,0},
	{9,9,9,0},
	{11,9,9,0},
}

turnl={6,7,8,-7,-6,-3}
turnr={-6,-7,-8,7,6,3}
turn={}
tturn={1,0.8,0.5,0.8,1,1}

function alim(p,m)
	if p>0 then
		if (abs(p)>m) return m
	else
		if (abs(p)>m) return -m
	end
	return p
end

function axnorm(x)
	if (x<0) x+=768*8
	if (x>=768*8) x=x%(768*8)
	return x
end

function xnorm(d)
	if (d>=384*8) d-=768*8
	if (d<=-384*8) d+=768*8
	return d
end

function cam(p)
	local d=xnorm(sx-rsx)
	d=alim(d,2)
	sx-=d
	if ending then
		rsx=0
		return
	end
	if p.dir>0 then
		rsx=p.x+32
	else
		rsx=p.x-32
	end
end

function mksafe()
	if safe and abs(xnorm(plane.x-safe.x)) < 64 then
		return
	end
	safe={}
	for k,v in pairs(plane) do
		safe[k]=v
	end
	safe.f=1
end

function restore()
	plane={}
	for k,v in pairs(safe) do
		plane[k]=v
	end
	sx=plane.x
end

function plu(p)
	if title or gameover then
		return
	end
	if p.restore and tm%10==0 then
		p.restore-=1
		if (p.restore==0 and planes>0) restore()
		if p.restore==0 and planes==0 then
			gameover=1
			music(0)
		end
	end
	p.x=xnorm(p.x)
	rsx,sx=xnorm(rsx),xnorm(sx)

	local d=plane.dir>0 and 1 or -1

	if p.crash and not p.stp then
		if (p.smoke and (tm%15==0)) smk(p.x,p.y)

		if p.t>0 then p.t-=0.01 end
		local c=mm(p.x\8,(p.y)\8)
		if c==0 or fget(c,0) then
			p.y+=0
		else
			if not fget(c,2) then
				mkexp(p.x,p.y)
			else
				p.y+=2
				p.sink=1
				sfx(4)
			end
			planes-=1
			p.stp=true
			p.smoke=false
			p.restore=4
		end
	end
	if p.sink then
		p.y=p.y+0.1
		if p.sink>6 then
			p.sink=false
		end
	end
	local o=pspr[abs(p.dir)]
	local a=o[4]
	if (d<0) a=0.5-a
	local t=p.t^0.5
	if (abs(p.dir)==1) t=1
	if (abs(p.dir)==2 and t<0.5) t=0.5
	if p.turn then
		t*=tturn[p.turn]
	end
	if p.f<=0 then
		p.t=p.t-0.01
		if (p.t<0)p.t=0
	else
		p.f-=p.t*0.001
		if (p.f<0)p.f=0
	end
	local dx=1*cos(a)*(t)
	local dy=1*sin(a)*(t)+(1-t)
	local colx=ceil(p.x+dx)
	local coly=ceil(p.y+dy)
	local colc=collision(colx,coly)
	local oland=p.land
	if (not p.turn) p.land=false
	if not p.stp and not p.land
	and colc then
		if fget(colc,1) and abs(p.dir)>2 and abs(p.dir)<5 then
			-- p.y=coly\8*8-1
			p.dir=d>0 and 4 or -4
			p.land=true
			p.repair=not fget(colc,3)
			p.smoke=false
			p.crash=false
			if (not oland) sfx(3)
		else
			p.crash=1
			p.dir=1
			if (d<0) p.dir=-1
			p.turn=false
		end
	end

	if not p.stp then
		p.x+=dx
		if (not p.land) p.y+=dy
	end
	if p.turn and tm%8==0 then
		if p.turn==1 and abs(p.dir)!=3 then
			if (abs(p.dir)<=2) d=-d
			p.dir-=d
		else
			p.turn+=1
			if p.turn>#turn then
				p.turn=false
			else
				p.dir=turn[p.turn]
			end
		end
	end
	if (p.repair and p.t==0 and not p.crash) then
		if p.land then
			if (p.x<128 and p.x>-128 and friends>0) then
				ending=1
				friends=0
				frnds={}
				music(1)
				frnd(p.x\8+1,6)
			elseif ending then
				ending+=1
				if ending == 30 then
					frnd(p.x\8+1,6)
				end
				if #frnds == 0 and ending>=160 then
					mset(5,6,213)
					if (tm%20==0) smk(5*8+10,64+6*8,-0.3)
				end
			else
				mksafe()
			end
		end
		p.f+=0.005
		if (p.f>1) p.f=1
	end
	if tm%3==0 and
		not p.land and
		not p.turn and
		(t<0.3 or p.y<8) and
 	abs(plane.dir)>1 then
		plane.dir-=d
	end
	if (p.crash or ending) return
	if not p.turn and
		((btn(0) and p.dir>0) or
			(btn(1) and p.dir<0)) then
			turn=d>0 and turnl or turnr
			p.turn=1
	end
	if p.f>0 then
		if btn(4) or (btn(1) and d>0) or
		(btn(0) and d<0) then
			p.t+=0.02
		elseif btn(5) then
			p.t-=0.02
		end
	end
	if (p.t>1) p.t=1
	if (p.t<0) p.t=0
	if not p.land and
	tm%3==0 and not p.turn then
		if btn(2) and
	 	abs(p.dir)<5 and p.y>=8 then
   if (t>=0.3 or abs(p.dir)<2) p.dir+=d
		elseif btn(3) and
 		abs(p.dir)>1 then
			p.dir-=d
		end
	end
end

function pld(p)
	local fl=false
	local n=abs(p.dir)
	if (p.dir<0) fl=true
	local s=pspr[n]
	local w=flr(tm/(4-p.t^0.5*3)%2)
	if (p.crash) w=0
	if(w==1 and p.t>0.01)sfx(0)
	local x=s[2]
	if (fl) x=16-x
	spr(s[1]+w*32,
	    tos(p.x-x),
	    p.y-s[3],
	    2,2,fl)
end

function cld(r,x,y)
	local r1,r2=r,r
	local c={x=x,y=y,{0,0,r,0}}
	local x2=0
	x,y=0,0
	for i=1,rnd(2)+2 do
		x+=r1
		x2-=r2
		if i==1 then
			r1=r1*(0.8+rnd(0.2))
			r2=r2*(0.8+rnd(0.2))
		else
			r1=r1*(0.5+rnd(0.5))
			r2=r2*(0.5+rnd(0.5))
		end
		add(c,{x,y,r1,rnd(1)})
		add(c,{x2,y,r2,rnd(1)})
	end
	c.d=(flr(rnd(2)) == 1) and 1 or -1
	c.f=(flr(rnd(3)) == 1) and true or false
	if (c.f and c.y<r)c.y=r+8
	if c.f and abs(xnorm(c.x-plane.x)) < 128 then
		c.f=false
	end
	return c
end

function tos(x)
	return xnorm(64-(sx-x))
end

function flash(x,y,l)
	if l<=0 then
		return
	end
	l-=1
	local c=mm(x\8,y\8)
	if c!=0 or y>128 then
		return
	end
	local dy=16+rnd(16)
	local dx=rnd(32)-16
	if hitbox(plane.x,plane.y,
		  x-16,y,32,32) then
		dx=plane.x-x
		dy=plane.y-y
		l=0
		if not plane.land then
			plane.crash=1
			plane.smoke=true
		end
	elseif hitbox(plane.x,plane.y,x,y,dx,dy) then
		if not plane.land then
			plane.crash=1
			plane.smoke=true
		end
	end

	fillp(0xffff)
	line(tos(x),y,tos(x+dx),y+dy,0x77)
	flash(x+dx,y+dy,l)
end

function cldd(c)
	local x=tos(c.x)
	if x<-64 or x>192 then
		return
	end
	fillp(0b0101101001011010.1)
	if c.flash then
		if (c.flash==1)sfx(5)
		c.flash+=1
		local cl=c[flr(rnd(#c))+1]
		flash(c.x+cl[1],c.y+cl[2],#cl)
		if (c.flash>4) c.flash=false

	end

	for v in all(c) do
		circfill(x+v[1],
			 c.y+v[2]+sin(v[4])*v[3]\8,
			 v[3],c.flash and 0xff or c.f and 0xc5 or 0xc7)
	end
end

function cldm(c)
	local seen
	c.x+=c.d*rnd(0.5)
	c.x=xnorm(c.x)
	for v in all(c) do
		v[4]+=rnd(0.01)
	end
	if c.f and not c.flash
	and tm%30==0 and rnd(100)<30 then
		c.flash=1
	end
	return seen
end

exp={}
smks={}

function smkd(v)
	local x=tos(v.x)
	if x<-16 or x>132 then
		return
	end
	if (v.r>2) circ(x-4,v.y,v.r-1,0)
end

function bird(x,y)
	return {s=rnd(0.8)+0.4,spr=66,x=x,y=y,d=rnd(1),f=flr(rnd(2))}
end

function bal(x,y)
	return {x=x,y=y,a=rnd(1)}
end
function bald(v)
	local x=tos(v.x)
	if x<-16 or x>132 then
		return
	end
	spr(207,x+4,v.y-8,1,2)
end

function birdd(v)
	local x=tos(v.x)
	if x<-16 or x>132 then
		return
	end
	spr(v.spr+16*flr(tm/4%2),tos(v.x-4),v.y-4)
end

frnds={}

function frnd(x,y)
	add(frnds,{x=x*8-3,y=64+y*8+5,step=1})
end

function frndm(v)
	local a={212,228,244,228}
	local b={244,229,244,245}

	if tos(v.x)<-16 or
 	tos(v.x)>140 then
		return true
	end
	if ending or (plane.land and
		      abs(xnorm(v.x-plane.x))<64) then
		if (tm%2!=0) return true
		if not ending and abs(xnorm(v.x-plane.x))<=2 then
			friends+=1
			sfx(6)
			return false
		end
		v.spr=b[v.step]
		local dx=xnorm(v.x-plane.x)>0 and -1 or 1
		if (ending) dx=1
		v.x+=dx
		if (ending and v.x>40) return
			v.step+=1
		if (v.step>4) v.step=1
		return true
	end

	if (tm%5==0) v.step+=1
	if (v.step>4) v.step=1
	v.spr=a[v.step]
	return true
end

function frndd(v)
	local x=tos(v.x)
	if x>140 or x<-16 then
		return
	end
	spr(v.spr,x-4,v.y-4)
end

crashes={}

function start()
	if (not ending) music(1)
	for v in all(crashes) do
		mm(v[2],v[3],v[1])
	end
	crashes={}
	plane={x=-18,
	       y=120,dir=4,
	       t=0,f=1,true,land=true,turn=false}
	planes=5
	friends=0
	tm=0
	sun=24
	sx,sy=plane.x,64
	rsx,rsy=sx,64

	clds={}
	birds={}
	frnds={}
	bals={}

	mksafe()
	frnd(126+256,6)
	for i=1,7 do
		add(bals,bal(3*i*128+64,rnd(64)))
		add(bals,bal(-4*i*128-64,rnd(64)))
	end
	for i=1,32 do
		add(clds,cld(rnd(10)+8,
			     rnd(6144)-3072,rnd(64)))
	end
	for i=1,32 do --60
		add(birds,bird(rnd(6144)-3072,
			       rnd(64)))
	end
end

frames=0
function movie(x,y)
	clip(x,y,48,48)
	rectfill(x,y,x+48,y+48,0x11)

	for i=0,5 do
		spr(89,x+i*8,y+32)
		spr(89,x+i*8,y+40)
	end
	for i=1,5 do
		spr(227,x+i*8,y+40)
	end
	spr(211,x,y+40)
	local a={244,245,244,229}
	spr(a[(frames%4)+1],x+54-frames,y+38)
	frames+=1
	if (frames==40) then
		frames-=1
	end
	clip()
end


function _init()
	title=true
	start()
	-- movie(40,40)
end

function hitbox(x,y,xx,yy,ww,hh)
	if x>1536 then
		x-=1536
		xx-=1536
	elseif x<-1536 then
		x+=1536
		xx+=1536
	end
	if x>=xx and y>=yy
	and x<xx+ww and y<yy+hh then
	 	return true
	end
end

function hit(x,y,xx,yy,ww,hh)
	if x>1536 then
		x-=1536
		xx-=1536
	elseif x<-1536 then
		x+=1536
		xx+=1536
	end
	if x>xx-ww and y>yy-hh
	and x<xx+ww and y<yy+hh then
	 	return true
	end
end

function smk(x,y,d)
	add(smks,{x=x,y=y,r=2,d=d})
end

function smkm(v)
	v.r+=0.1
	if (v.d) v.y+=v.d
	if (v.r<6) return true
end

function balm(v)
	if v.crash then
		v.y+=v.crash
		v.crash+=0.01
		if mm(v.x\8,(v.y+3)\8)!=0 or v.y>128 then
			mkexp(v.x,v.y)
			return false
		end
		return true
	end
	if tm%1==0 then
		v.a=alim(v.a+rnd(0.1)-0.05,1)
	end
	local dx=cos(v.a)*rnd(0.7)
	local dy=sin(v.a)*rnd(0.7)
	if v.y+dy<=0 or mm((v.x+dx)\8,(v.y+6+dy)\8)!=0 or v.y>128 then
		v.a=rnd(1)
	else
		v.x+=dx
		v.y+=dy
	end

	if not plane.land and hitbox(plane.x,plane.y,
				     v.x-4,v.y-9,10,16) then
		plane.crash=1
		plane.smoke=true
		sfx(1)
		mkexp(plane.x,plane.y)
		v.crash=0.5
	end
	return true
end

function birdm(v)
	local xx,yy=v.x+v.s*cos(v.d),
	v.y+v.s*sin(v.d)
	local c=mm(xx\8,yy\8)
	if (yy<0 or yy>128) c=1
	if c==0 then
		v.x,v.y=xnorm(xx),yy
	else
		v.d=rnd(1)
		v.s=rnd(0.8)+0.4
	end
	if not plane.land and
		not plane.stp and
	hit(v.x,v.y,plane.x,plane.y,4,4) then
		plane.crash=1
		plane.smoke=true
		sfx(1)
		return false
	end
	return true
end

function expm(v)
	v.t+=1
	for e in all(v) do
		local s=5/v.t
		e.x+=s*cos(e.a)
		e.y+=s*sin(e.a)
		e.y+=v.t/10
	end
	if (v.t>10) return false
	return true
end

function expd(v)
	for e in all(v) do
		spr(e.spr,tos(e.x-4),e.y-4)
	end
end

function _update()
	if type(title)=='number' and title<0 then
		title+=1
		if (title==0) then
			title=false
			music(-1)
		end
	end
	if title and (btnp(4) or btnp(5)) then
		title=-10
		return
	end
	if gameover then
		gameover+=1
	end
	if (gameover or ending) and (btnp(4) or btnp(5)) then
		if ending and ending<200 then
			return
		end
		if (gameover and gameover<30) return
			gameover=false
		start()
		title=true
		ending=false
		return
	end
	if (tm%5==0 and sun<164 and not title) sun+=0.1
	tm+=1
	for v in all(clds) do
		cldm(v)
	end
	ff={}
	for v in all(frnds) do
		if (frndm(v)) add(ff,v)
	end
	frnds=ff
	local e={}
	for v in all(exp) do
		if (expm(v)) add(e,v)
	end
	exp=e
	local b={}
	for v in all(birds) do
		if (birdm(v)) add(b,v)
	end
	birds=b
	local bb={}
	for v in all(bals) do
		if (balm(v)) add(bb,v)
	end
	bals=bb
	local sm={}
	for v in all(smks) do
		if (smkm(v)) add(sm,v)
	end
	smks=sm
	plu(plane)
	cam(plane)
end

sts={}

blink=false
function stars(yy)
	if #sts==0 then
		for i=1,40 do
			add(sts,{x=rnd(128),
				 y=rnd(128),
				 c=flr(rnd(15)+1)})
		end
	end
	if (not blink and tm%30==0) blink=flr(rnd(#sts))+1
	if (blink) sts[blink].b=1
	fillp(0)
	for v in all(sts) do
		if (v.y<yy) pset(v.x,v.y,v.b or v.c)
	end
	if (blink) sts[blink].b=false
	if (blink and tm%19==0) blink=false
end

function sky()
	fillp(0b1010010110100101)
	if sun>55 then
		local sl=64*(((sun-55)/55)^2)
		rectfill(0,0,128,sl,0x11)
		rectfill(0,sl-16,128,sl-8,0xc1)
		rectfill(0,sl-8,128,sl,0xc6)
		stars(sl-24)
	end
	fillp(0b1010010110100101.1)
	circfill(64,sun,12,0x0a)
	fillp(0xffff)
	circfill(64,sun,10,0xaa)
	fillp(0b1111111111111111)
	-- rectfill(0,0,128,16,0xc1)
	if sx<(100+128)*8 and
	sx>(-(100+128)*8) and sun<130 then
		rectfill(0,105,128,112,0xaa)
		rectfill(0,113,128,128,0x99)
	else
		fillp(0b1010010110100101)
		rectfill(0,105,128,112,0xdd)
		rectfill(0,113,128,128,0x1d)
	end
end

function hud()
	if (title) return
		fillp(0xffff)

	rect(0,0,15,2,0x00)
	line(1,1,14,1,0xdd)
	line(1,1,1+ceil(13*plane.t),1,0x88)

	rect(0,4,15,6,0x00)
	line(1,5,14,5,0xdd)
	line(1,5,1+ceil(13*plane.f),5,0x99)

	for i=1,planes do
		spr(196,128-9*i,0)
	end
	for i=1,friends do
		spr(244,128-9*i,8)
	end
	--	print(plane.t,0,6,4)
	-- print(plane.land,0,12,4)
end
local anims={
	[75]={92,15},
	[77]={116,20},
	[89]={117,10},
	[15]={31,15},
	[221]={222,20},
	[236]={252,10},
	[222]={221,20},
	[239]={255,20},
}
function anim(c)
	local a=c and anims[c]
	if a then
		if (tm\a[2]%2==0)return a[1]
	end
	return c
end

function mm(xc,yc,v)
	if (yc<8 or yc>15) return 0
	while (xc>=768) xc-=768
	yc-=8
	if xc<0 then
		xc+=768
	end
	while xc>=128 do
		yc+=8
		xc-=128
	end
	if v then
		mset(xc,yc,v)
	else
		local c=mget(xc,yc)
		return anim(c),c
	end
end

function mkexp(x,y)
	local e={t=0}
	for i=1,rnd(3)+5 do
		add(e,{spr=98+abs(rnd(5)),x=x,y=y,a=rnd(1)})
	end
	sfx(2)
	add(exp,e)
end

function collision(x,y)
	local xx,yy=x\8,y\8
	c=mm(xx,yy)
	if (c==0) return
	if sget((c%16)*8+x%8,
		c\16*8+(y%8))==0 then
		return
	end
	if fget(c,0) then
		local c,rc=mm(xx,yy)
		add(crashes,{rc,xx,yy})
		mm(xx,yy,0)
		mkexp(xx*8+4,yy*8+4)
	end
	return c
end

function scene(x,y,f)
	x-=64
	y-=64
	local dx=x%8
	local dy=y%8
	x=x\8
	y=y\8
	for yy=8,16 do
		for xx=0,16 do
			local c,rc=mm(x+xx,y+yy)
			if (c!=0 and (not f or f==rc)) spr(c,xx*8-dx,yy*8+dy)
		end
	end
end

function help(x,y)
	print("your brother is a polar",x+16,y,1)
	print("explorer. he got in trouble!",x+6,y+8)
	fillp(0b1010010110100101)
	x+=3
	y+=1
	rectfill(x+24,y+16,x+95,y+32,0x10)
	for i=0,8 do
		local c=0
		if (i==1)c=211
		if (i==7)c=243
		if (i>1 and i<7)c=227
		if (c>0) spr(c,x+8*i+24,y+24)
	end
	for i=0,8 do
		spr(89,x+8*i+24,y+32)
	end
	spr(212,x+54,y+16)
	fillp(0)
	line(27,y+15,100,y+15,6)
	line(27,y+15+24,100,y+15+24)
	line(27,y+15,27,y+15+24)
	line(100,y+15,100,y+15+24)
	if tm\15%2==1 then
		print("sos!",x+64,y+17,6)
	end
	x-=3
	print("just take him home!⌂",x+22,y+43,2)
	print("⬆️⬇️⬅️➡️-turning",x+32,y+52,7)
	print("🅾️❎-throttle",x+38,y+58)
	print("hugeping presents",30,0)
	print("v1.2",112,122)
end

function _draw()
	cls(12)
	sky()
	scene(sx,sy)
	for v in all(frnds) do
		frndd(v)
	end
	for v in all(bals) do
		bald(v)
	end
	pld(plane)
	for v in all(birds) do
		birdd(v)
	end
	for v in all(exp) do
		expd(v)
	end
	for v in all(clds) do
		cldd(v)
	end
	for v in all(smks) do
		smkd(v)
	end
	hud()
	scene(sx,sy,89)
	if ending then
		local y=128-ending\2
		if (y<54)y=54
		print("the end!",50,y,7)
	end
	if title then
		spr(200,36,16,7,1)
		print("adventure",46,28,2)
		help(1,40)
	end
	if gameover then
		print("game over!",45,63,7)
	end
end

__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005000
00077000000000000000000000000000000d00000000000080d00000000000000000000000000000000000000000000000000000000036000000000000055500
000770000036000088880000000000008800d0000000000880f400000008888888888888088888888888888000888888888888800003e6000088000000568650
00700700003660002c200d000000000880ff40000000000802ff0000000660200cc002000000260cc00200000000200ccc0020000003ee6d0028800000567650
00000000003ee6662626f40000000000262ff0000000000c2628000000ee662666fd2000000e226ffd220000000002efdfe200000002666662c020d000067600
00000000000666662626f00000600006262f000000000006628e00000006666266f400000000626ff42000000000020f4f0200000000006662626fd000095a00
0066000000020dde888f000003660666688000000000006668e0200000002d8888ff88000088888eff8888000008888efe8888000000000088626f4000000000
00776000000000000020000003ee66668802000000000666d0029200000000002020000000000020002000000000002000200000000000000886f00000000000
00777600000000000292000000666dd0002920000036ee6d00002000000000029292000000000290029000000000009000900000000000000020000000005000
06777600000000000020000000020000000200000036e60000000000000000002020000000000020002000000000002000200000000000000292000000055500
07777760000000000000000000000000000000000003620000000000000000000000000000000000000000000000000000000000000000000020000000568650
07777770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005067605
67777776000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000067600
677777760000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a5900
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
55555555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
55555555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
66666666000000000000000000000000000000000000000080000000000000000000000000000000000000000000000000000000000036000000000000000000
77777777003600008888000000000000880000000000000880f400000008888888888888088888888888888000888888888888800003e6000088000000000000
77777777003660002c2000000000000880ff40000000000802ffd000000660200cc002000000260cc00200000000200ccc0020000003ee6d0028800000000000
77777777003ee6662626f00000000000262ffd000000000c2628000000ee662666ff2000000e226fff220000000002efffe200000002666662c0200000000000
77777777000666662626f40000600006262f0d0000000006628e00000006666266f400000000626ff42000000000020f4f0200000000006662626f0000000000
0077770000020dde888f0d0003660666688000000000006668e0200000002d8888fd88000088888efd8888000008888ede8888000000000088626f4033333311
07766770000000000020000003ee66668802000000000666d0029200000000002020000000000020002000000000002000200000000000000886f0d044444431
76262277000000000292000000666dd0002920000036ee6d000020000000000292920000000002900290000000000090009000000000000000200d0044444443
74366367000000000020000000020000000200000036e60000000000000000002020000000000020002000000000002000200000000000000292000044444443
62555227000000000000000000000000000000000003620000000000000000000000000000000000000000000000000000000000000000000020000044444443
42555227000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000044444443
42555224000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000044444443
42555224000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000044444443
00000000000000000000000000088060abcbeb8b0000bb0000003000000000000033333333333300000440000000400000020000000f00000000000006666666
00033000000000000505000000888870bbbbbbbb000b4bb0000333005555555503bbbbbbbbbbbb30004224000008800000727000001d10000000300066767666
00336000000000000050050508888880bbbbbbbb004b44b000033300555555553bbbbbbbbbbbbbb3042222400088400000727000001f1000000b3b0067777767
006ee000000000000000005088888888bbbbbbbb00b44bb00033333033333333bbbbbbbbbbbbbbbb443333440088400007727700008880000003300067777777
0026e60000000000000000004554d6d4bbbbbbbb00bb4b4000033300bbbbbbbbbbbbbbbbbbbbbbbb4255522400ee400007727770009f600000b3300067777777
0000666000000000000000004554d6d4bbbbbbbb000b440000333330bbbbbbbbbbbbbbbbbbbbbbbb4255522400e0400077020000009f6000000b300067777777
0000d666c8800000000050504554d6d4bbbbbbbb0000400000033300bbbbbbbbbbbbbbbbbbbbbbbb425552240000400022222222009f600000033b0067777777
00000d66208800000000050045544444bbbbbbbb0000400000004000bbbbbbbbbbbbbbbbbbbbbbbb425552240000400004444440009f6000000b300067777777
0000008262f00000000000000000000000333330300000000000000333333333bbbbbbbb11116611000880600000000000004000009f60009000000000000009
000000082ff60000005000000000000003bbbbb3b33000000000033bbbbbbbbbbbbbbbbb111111110084487000000000000e8000009f6000a99000000000099a
000000206f40000005050050000000003bbbbbbbbbb3000000003bbbbbbbbbbbbbbbbbbb11611111084444800000000008884000009f6000aaa9000000009aaa
00000292000000000000050500000000bbbbbbbbbbbb30000003bbbbbbbbbbbbbbbbbbbb1111111184bbbb4800000000e88e4000009f6000aaaa90000009aaaa
00000020000000000000000000000000bbbbbbbbbbbbb300003bbbbbbbbbbbbbbbbbbbbb1111111144d6dd44000000000e004000009f6000aaaaa900009aaaaa
00000000000000000000000000000000bbbbbbbbbbbbb300003bbbbbbbbbbbbbbbbbbbbb1111111144d6dd444242424200004000009f6000aaaaa900009aaaaa
00000000000000000000050000000000bbbbbbbbbbbbbb3003bbbbbbbbbbbbbbbbbbbbbb1111111144d6dd444242424200004000009f6000aaaaaa9009aaaaaa
00000000000000000000505000000000bbbbbbbbbbbbbbb33bbbbbbbbbbbbbbbbbbbbbbb11111111444444444444444400004000009f6000aaaaaaa99aaaaaaa
000000000000000000000000000000000000000000000000000000007777777744444444bbbbbbbbbbbbbbbbbbbbbbbb3333331111333333aaaaaaaa9a9a9a9a
0003300000000000000000000000000000000000000000000000000077777777444444444bbb4bbbbb4b4bbbbbb4b4bbbbbbbb3113bbbbbbaaaaaaaaaaaaaaaa
003360000000000000009400008800000036e0000000200000010000777777774444444444b444b4bb4444b44b4444bbbbbbbbb33bbbbbbbaaaaaaaaaaaaaaaa
006ee0000000000000099400000830000033e0000002920000d3d000777777774444444444444444bb444444444444bbbbbbbbb33bbbbbbbaaaaaaaaaaaaaaaa
0026e6000000000000999000000883000003320000002000000d5500777777774444444444444444b44444444444444bbbbbbbb33bbbbbbbaaaaaaaaaaaaaaaa
00006660000000000099000000008800000000000000000000005000777777774444444444444444b44444444444444bbbbbbbb33bbbbbbbaaaaaaaaaaaaaaaa
0000d666c88000000000000000000000000000000000000000000000777777774444444444444444b44444444444444bbbbbbbb33bbbbbbbaaaaaaaaaaaaaaaa
00000d66208800000000000000000000000000000000000000000000777777774444444444444444b44444444444444bbbbbbbb33bbbbbbbaaaaaaaaaaaaaaaa
0000008262f00000000000001133333300090000166111110000000066666666000000033000000033333333443333343333334444333333119a9a9a9a9a9a11
000000082ff100005555555513444444009a900011111111000000007677766700000334433000004444444443bbbbb3bbbbbb3443bbbbbb13aaaaaaaaaaaa31
000000206f400000555555553444444409a7a9001111161100000000777777670000344444430000444444443bbbbbbbbbbbbbb33bbbbbbb3aaaaaaaaaaaaaa3
00000292060000009a9a9a9a34444444009a9000111111110000000077777777000344444444300044444444bbbbbbbbbbbbbbbbbbbbbbbb3aaaaaaaaaaaaaa3
0000002000000000aaaaaaaa3444444400996000111111110004400077777777003444444444430044444444bbbbbbbbbbbbbbbbbbbbbbbb3aaaaaaaaaaaaaa3
0000000000000000aaaaaaaa34444444009f6000111111110041140077777777003444444444430044444444bbbbbbbbbbbbbbbbbbbbbbbb3aaaaaaaaaaaaaa3
0000000000000000aaaaaaaa34444444009f6000111111110441544077777777034444444444443044444444bbbbbbbbbbbbbbbbbbbbbbbb3aaaaaaaaaaaaaa3
0000000000000000aaaaaaaa34444444009f6000111111110041540077777777344444444444444344444444bbbbbbbbbbbbbbbbbbbbbbbb3aaaaaaaaaaaaaa3
0000000000000000000000000000000000000000000000000000a567fe00bea50064646464646400000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000087a7a7a7a7a7a7a7a7a7a7a7a7a7a7a7970000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000008786868686868686868686868686868686869700000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000878686868686868686868686868686868686868697000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000bfb4000000000000000000af0000000000
0000000000000000000000000000000000000000008786868686868686868686868686868686868686868697000000000000000000000000000000000e1e1e1e
1e1e1e1e1e1e2e00000e1e1e1e1e1e1e1e1e1e2e0000000000000000000000000000000000000000000000000000f5f6f62727272727272727f6f6e500000000
0000000000000000000000000000000000000000878686868686868686868686868686868686868686868686970000000000000000000000000087a797003c00
003c00003c0087a7a797003c00003c00003c0087a7a7970000000000000000000000000000000000000000aeaef5e6e6e6e6e6e6e6e6e6e6e6e6e6e6e5000000
00000000646464646464a4b5a5b5a464645454878686868686868686868686868686868686868686868686868697b4000000000000000000a487868686973c00
003c00003c8786868686973c00003cfe003c87868686869700000000c40000c40000c400000000af00aff5f6f6e6e6e6e6e6e6e6e6e6e6e6e6e6e6e6e6e5ae00
7c7c7c7ccdbdbdbdbdbdbda7a7a7bdbdbdbdbd868686868686868686868686868686868686868686868686868686bd7c7c7c7c7c7c7c7ccda78686868686f395
9595959537868686868686a7a7a7a7a7a7a7868686868686f395959595959595959595959595e7f6f6f6e6e6e6e6e6e6e6e6e6e6e6e6e6e6e6e6e6e6e6e6f6f6
000000000000000000000000000000000000000000000000000000000000000000000000002f0000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000002f002f1f2f00000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000001f2f1f1f1f2f000000000000000000ddeddd000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000001f1f1f1f1f1f000000000000000000dedede000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000005400000000000000000000000000000000000000
0000000000000000000000d4000000000000000000000000000000000000000000001f1f1f1f1f1f000000000000000087a7a7a7970000000000000000000000
0000000000000000000000000000000000000000000000008e00000000000000000000000000000000000065ef55000000000000000000000000000000000000
00000000000000000000005c0000000000000000000000000000000000009f0000001f1f1f1f1f1f000000000000008786868686869700000000000000000067
54a5fe000000000000000000000000b400000000000000008f000000000000000000000000000000655565858585550000000000000000000000000000000000
afaf000000c40000000087a7970000000000c400c400c400000000000087a79700000f0f0f0f0f0f0000646464648786868686868686970000c400000000be84
44444455a4000000000000000000657555a5540000000065755500009d7d7d7d8d00b5b5a567546585858585858585550000df545454545400a4b40000000000
f6f6f795959595959537868686f39595959595959595959595959595379696969696969696969696969696969696868686868686868686f395959595959595a6
96969696967c7c7c7c7c7c7c7c969696b67544cecece444444444444c6959595d6444444444444858585858585858585efefef75757575754475947474747474
d77777777777777d66666660000565000007f000009f600077777776000000000088888188888188881008881088881088100088881881088188888100000000
d77777777777777d666767660006650088888888009f600077777767555555550881088188100088188188188188188188100881881881088188100000a9a900
d77777777777777d767777760005650088888888009f60007777767755555555088108818810008818818818818818818810088188188808818810000a9a9a90
d77777777777777d7777777600066500eee5deee009f6000777767773333333308888881888810888810881881888810881008888818818881888800a9a9a9a9
d77777777777777d77777776000565000006d000009f600077767777444444440881088188100088188188188188100088100881881881088188100099999999
d77777777777777d7777777600066500000dd000009f6000776777774444444403310331991000ff1ff1bb1bb1dd100066100991991ee10ee1331000aaa2aa99
d77777777777777d77777776000565000003800000888000767777774444444403310331991000ff1ff1bb1bb1dd100066100991991ee10ee13310002aa2a992
d77777777777777d77777776000665000083880000888000677777774444444403310331999991ff1ff10bbb10dd100066661991991ee10ee133333120a29902
00000006600000000000000016666666000000000008806067777777000000000000000000000000000000003333333003333333000000000006000020020502
00000067760000000000000066777677000000000088887076777777000000000000000000000000000000004444444334444444070007000007000002020520
000006777760000000000000677776770f05550f0888888077677777000000000000000000000000000000004444444444444444007070000007000002020520
00006777777600000000000067776777002fff208888888877767777444444440000000000000000000000004444444444444444000f0000677f776000444400
00067777777760000000000067767777000444004554a6a477776777040004000000000000000000000000004444444444444444007970000007000000422200
00677777777776000000000067767777000333004554a6a477777677444444444400000000000044000000004444444444444444070207000007000000422200
06777777777777600000000067676777000202004554a6a477777767545554555444000000004445000000004444444444444444000900000009000000000000
67777777777777760000000067777667000404004554444477777776540054000004440000444000000000004444444444444444000200000002000000000000
000000077666666660000000666666660000000000000000dddddddd677777760000000000000000000400000000000011611111000950000000000000000000
000000656555555f760000007777777700000000000000007777777767777776000500000000000000433000000000001b1b1b1b000990000000000000000000
000006506000006565600000777777770005550000055500777777770777777000565000000000000033400000000000bbbbbbbb000950000000000000000000
00006500600006506506000077777777000fff00000fff00777777770677777000090000000000000334330040040040bbbbbbbb000990000000000004000440
0006500060006500650060007777777700244420002444207777777700677760009a9000000000000333330044444444bbbbbbbb000950000000000004000442
006500006006500065000600777777770f03330f00f333f0777777770067770000aaa000000000000343430045545545bbbbbbbb000990000000000000444420
5755555575f55555655555657777777700020200000202007777777700067700009a9000000000000034300040040040bbbbbbbb000880000000000000444400
666666666666666666666676777777770004040000020000777777770000660000242000000000000004000040040040bbbbbbbb006666000000000000400400
6565656565656565060060006666666100000000000000007777777667777777002420000804400000020000000500001111611100000000b3b3b3b300000000
666666656666666555555555776777660000000000000000777777600677777700242000050f40000893d100005950001b1b1b1b00000000bbbbbbbb00000000
6565656565656565656565657767777600055500000555007777760000677777066666000f66650089bc3d1005999500bbbbbbbb00000000bbbbbbbb00000000
66666665666666656666666577767776000fff00000fff007777600000067777622222600506660089bc3d105feeef50bbbbbbbb06060000bbbbbbbb00000440
65656565656565656565656577776776002444200024442077760000000067772439d42005066f00000200009e555e90bbbbbbbb06760000bbbbbbbb00000442
6666666566666665666666657777677600f333f000f333f0776000000000067724ca644400066000000200009e555e90bbbbbbbb07776750bbbbbbbb04444420
656666656565656565656565777676760002020000020200760000000000006724dbd45200666600400200009e555e90bbbbbbbb00667650bbbbbbbb40444400
656666656666666566666665766777760004040000000200600000000000000624444452099999902202024295555590bbbbbbbb00600600bbbbbbbb00400400
__label__
0000000000000000cccccccccccccccccccccccccccccccccccccccccccccccccccccccc7c7c7c7ccccccccccccccccccccccccc7fccccccc7fccccccc7fcccc
0888888888888880ccccccccccccccccccccccccccccccccccccccccccccccccccccc7c7c7c7c7c7c7ccccccccccccccccccc88888888c88888888c88888888c
0000000000000000cccccccccccccccccccccccccccccccccccccccccccccccccccc7c7c7c7c7c7c7c7cccccccccccccccccc88888888c88888888c88888888c
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc7c7c7c7c7c7c7c7c7ccccccccccccccccceee5deeeceee5deeeceee5deeec
0000000000000000cccccccccccccccccccccccccccccccccccccccccc7c7c7c7c7c7c7c7c7c7c7c7c7c7ccccccccccccccccccc6dccccccc6dccccccc6dcccc
0999999999999990ccccccccccccccccccccccccccccccccccccccccc7c7c7c7c7c7c7c7c7c7c7c7c7c7c7ccccccccccccccccccddcccccccddcccccccddcccc
0000000000000000cccccccccccccccccccccccccccccccccccccccc7c7c7c7c7c7c7c7c7c7c7c7c7c7c7c7ccccccccccccccccc38ccccccc38ccccccc38cccc
ccccccccccccccccccccccccccccccccccccccccccccccccccccc7c7c7c7c7c7c7c7c7c7c7c7c7c7c7c7c7c7ccccccccccccccc8388ccccc8388ccccc8388ccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccc7c7c7c7c7c7c7c7c7c7c7c7c7c7c7c7c7c7c7ccccccccccccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccccccccc7c7c7c7c7c7c7c7c7c7c7c7c7c7c7c7c7c7c7c7c7c7c7cccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccc7c7c7c7c7c7c7c7c7c7c7c7c7c7c7c7c7c7c7c7c7c7c7c7ccc7c7ccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccccccc7c7c7c7c7c7c7c7c7c7c7c7c7c7c7c7c7c7c7c7c7c7c7c7c7c7c7c7cccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccc7c7c7c7c7c7c7c7c7c7c7c7c7c7c7c7c7c7c7c7c7c7c7c7c7c7c7c7c7ccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccccc7c7c7c7c7c7c7c7c7a7a7a7c7c7c7c7c7c7c7c7c7c7c7c7c7c7c7c7c7c7cccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccc7c7c7c7c7c7c7c7a7a7a7a7a7a7c7c7c7c7c7c7c7c7c7c7c7c7c7c7c7c7c7ccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccccc7c7c7c7c7c7c7a7a7a7a7a7a7a7c7c7c7c7c7c7c7c7c7c7c7c7c7c7c7c7cccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccc7c7c7c7c7c7c7a7a7a7a7a7a7a7a7c7c7c7c7c7c7c7c7c7c7c7c7c7c7c7c7ccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccccc7c7c7c7c7c7a7a7a7a7a7a7a7a7a7c7c7c7c7c7c7c7c7c7c7c7c7c7c7c7cccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccc7c7c7c7c7a7a7a7a7a7a7a7a7a7a7c7c7c7c7c7c7c7c7c7c7c7c7c7c7ccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccccccc7c7c7c7a7a7a7a7a7a7a7a7a7a7a7c7c7c7c7c7c7c7c7c7c7c7c7c7cccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccc7c7c7a7a7a7a7a7a7a7a7a7a7a7a7c7c7c7c7c7c7c7c7c7c7c7c7ccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccccccccc7c7c7a7a7a7a7a7a7a7a7a7a7a7c7c7c7c7c7c7c7c7c7c7c7cccccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccccccccccccca7a7a7a7a7a7a7a7a7a7a7a7c7c7c7c7c7c7c7c7c7c7ccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccca7a7a7a7a7a7a7a7a7a7a7a7a7c7c7c7c7c7c7c7c7c7cccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccaaa7a7a7a7a7a7a7a7a7a7a7c7c7c7c7c7c7c7c7c7ccccccccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccccccccccccacaaa7a7a7a7a7a7a7a7a7a7a7c7c7c7c7c7c7c7c7cccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccaaaaa7a7a7a7aaa7a7a7a7a7c7c7c7ccccc7c7ccccccccccccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccccccccccccacaaaaaaaaaaaaaaa7a7a7a7a7c7c7cccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccaaaaaaaaaaaaaaaaaaa7a7a7c7ccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccccccccccccccaaaaaaaaaaaaaaaaaaaaaccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccacaaaaaaaaaaaaaaaaaaacacccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccccccccccccccacaaaaaaaaaaaaaaaaacaccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccacaaaaaaaaaaaaaaacacccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccacaaaaaaaaaaaaacaccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccacaaaaaaaaaaacacccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccacaaaaaaaaacaccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccacacacacacacccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccacacaccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccb
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccb4
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc4b4
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccb44
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccbb4
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccb4
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc4
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc4
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc333333
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc33bbbbbb
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc3bbbbbbbb
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc3bbbbbbbbb
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc3bbbbbbbbbb
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc3bbbbbbbbbb
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc3bbbbbbbbbbb
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc3bbbbbbbbbbbb
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc3bbbbbbbbbbbbb
aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa33bbbbbbbbbbbbbb
aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa88aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa3bbbbbbbbbbbbbbbb
aaaaaaaaaaaaaaaaaaaaaaaaaaaaaa88aff4aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa3bbbbbbbbbbbbbbbbb
aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa262ffdaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa3bbbbbbbbbbbbbbbbbb
aaaaaaaaaaaaaaaaaaaaaaaaa6aaaa6262fadaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa3bbbbbbbbbbbbbbbbbb
aaaaaaaaaaaaaaaaaaaaaaaa366a666688aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa3bbbbbbbbbbbbbbbbbbb
aaaaaaaaaaaaaaaaaaaaaaaa3ee666688a2aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa3bbbbbbbbbbbbbbbbbbbb
aaaaaaaaaaaaaaaaaaaaaaaaa666ddaaa292aaaaaaaaaaaaaaaaaa88a6aaaaabbaaaaaabbaaaaaa3aaaaaaa3aaaaaaa3aaaaaaaaaa3bbbbbbbbbbbbbbbbbbbbb
99999999999999999999999999299999992999999999999999999888879999b4bb9999b4bb99993339999933399999333999999933bbbbbbbbbbbbbbbbbbbbbb
99999999999999999999999999999999999999999999999999998888889994b44b9994b44b999933399999333999993339999993bbbbbbbbbbbbbbbbbbbbbbbb
9999999999999999999999999999999999999999999999999998888888899b44bb999b44bb99933333999333339993333399993bbbbbbbbbbbbbbbbbbbbbbbbb
9999999999999999999999999999999999999999999999999994554d6d499bb4b4999bb4b49999333999993339999933399993bbbbbbbbbbbbbbbbbbbbbbbbbb
9999999999999999999999999999999999999999999999999994554d6d4999b4499999b4499993333399933333999333339993bbbbbbbbbbbbbbbbbbbbbbbbbb
9999999999999999999999999999999999999999999999999994554d6d4999949999999499999933399999333999993339993bbbbbbbbbbbbbbbbbbbbbbbbbbb
9999999999999999999999999999999999999999999999999994554444499994999999949999999499999994999999949993bbbbbbbbbbbbbbbbbbbbbbbbbbbb
9999999999999999999999999999999999999333333abcbeb8babcbeb8b3333333333333333333333333333333333333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbb
5555555555555555555555555555555555593bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
555555555555555555555555555555555553bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
33333333333333333333333333333333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb

__gff__
0000000000000000000000000000000101000000000000000000000000000001020000000000000000000000000000000100000000000000000000000000000000000000000101020000010101010100000000000000000000040101010000000000000000000000000800000000000000000200000401080000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010000000200000000000000000000000a0000000000000000000101000101010a0000080100010000000000010000000a000000000001010000010101
__map__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000464646465b5a5b5a5b5a5b4600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005657575757575757575757575744550000000000000000000000000000000000000000000000004d00000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000056586a69696969696969696969696b585500000000000000000000000000000000000000000000005d00000000000000000000000000000000000000
0000000000000000000000000000450000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000056586a686868686868686868686868686b585500000000000000000000000000000000000000000000c500000000000000000000000000000000000000
00000000000000000000000000565744445500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000056586a6868686868686868686868686868686b5855000000000000000000000000000000000000005a787a79450000000000000000000000000000000000
0000000000000000000000005658585858585500000000000000000000000000000000000000005a4545000000000000000000000000004b4a000000000000000056586a68686868686868686868686868686868686b58550000000000000000000000000000000000787a7a7a7a7a7900000000000000000000000000000000
00000000004345454646465658585858585858554545464656550000004c00000000000000564457495449485757494747474747474747485757575757575757576a69686868686868686868686868686868686868686b585500000000000000000000004b000000786868686868686879000000000000004c004c00004c0000
47474748444457575757575858585858585858584948575758586c595959595959595959596a696969696969696969696969696969696969696969696969696969686868686868686868686868686868686868686868686b5854545447474747474747474844447c7b7b7b7b7b7b7b7b7b7d6c59595959595959595959595959
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f2f200000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f2f1f100f2f2f2000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000046464600e0e1e1e1e1e1e20045f0f0f045f0f0f0454500
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004a4b000000000000000048575757574900c300c30048575757575757575757575749
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000464646464646000000000000000000000000000000000000000000005657574747474747474747585858586a6b00c300c3006a69696969696969696969696b
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000787a7a7a7a7a7a79000000000000000000000000000000000000005657585858585858586a69696969696969686800c300c30068686868686868686868686868
00000000000000000000000000005f6f6f5e4e004e4e004b0000000000000000fb4e5bfb004e004e00000000000000000000000000000000000000000000787a686868686868686879000000000000765a5b5a5b5a5b5a4545005658585858585858586a6868686868686868686800c300c30068686868686868686868686868
595959595959595959595959597e6e6e6e6e6f6f6f6f6f6f72727272727272726f6f6f6f6f6f6f6f6f7f5959595959595959595959595959595959595973696969696969696969696b495454544444444444444444444444445758585858585858586a6868686868686868686868595959595968686868686868686868686868
000000000000000000000000000000000000000000000000000000000000000000000000000000004fc20000000000000000000000004fc2000000000000000000000000000000000000000000000000d00000000000004f77c20000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000c0c1000000000000000000000000c0c1000000000000000000000000d0d1000000000000000000d067000000000000c067c10000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000c0c14b0000000000000000300010c0c10000000000000000000000d067c1d0d100000000000000c067d0d100000000c067c10000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000c06777202020202020202077777767c10000000000000000d0d1d067676767c100000000000000c067c067d1000000c067c10000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000004d0000000000000000000000000000000000000000000000000000c06767676767676767676767676767c10000000000000000c067676767676767c20000000f0000c067c06767d10000c067c10000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000005d0000000000000000000000000000000000000f00000000000000c06767676767676767676767676767c10000000000000000c067676767676767c10000004f7777777777777777c200c067c100000000000000000000000000000000000000000000000000000f00000f0000000000000000
00000000000000000000000000c500000000000000000010000000000000004f77c2000000000000c06767676767676767676767676767c100000000100000d06767676767676767c1000000c06767676767676767c100c067c100000000000010000000000000000000000000000000000000004f7777c20000100000000000
595959595959595959595959737a3f59595959595959595959595959595959595959595959595959c06767676767676767676767676767675959595959595959595959595959595959595959595959595959595959595959595959595959595959595959595959595959595959595959595959595959595959594fe3e3e3e3e3
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004f77777777777777c2000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000d077d100d0d100000000000000000000000000000000000000000000000000000000c06767f6e7e700e7e7000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000d0676767d1c067d10000000000000000000000000000000000000000000000000000d0c067c1000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000d067676767c6676767d1000000000000000000000000000000000000000000000000d067c067f6000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000d067676767c667676767c10000000000000000000000000000000000000000000000d06767c0c100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000004b0000000000000000104a0f000000000000000000d06767676767c067676767c1000000000000000000000000000000000f0000000000d0676767c0c1000000000000000000000030004b000000000000000000000000000000000000000000000000000000000000dd00000000000000
0000000000000000000000001000004f20202020202020207777c20000000000000000d06767676767c6676767676767d100000000000000004c000000004f777777c20000d067676767c06720202020202020207777777777c20000000000000000000000100000000000000000000000465a76460000fdedeb4a4b00000000
e3e3e3f35959595959595959595959c067676767676767676767c15959595959595959c067676767c667676767676767c1595959595959595959595959595959595959595959595959595959595959595959595959595959595959595959595959595959595959595959595959595959696969696969696969696969c7c7c7c7
__sfx__
010100001164001600006000460004600046000460003600036000260002600036000360004600046000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000100003365032650306502e6502c6502965025650206501c6501665011650106500465001650006500065000650000000000000000000000000000000000000000000000000000000000000000000000000000
000100003c65039650356503265030650356502d6502b650296502d65025650206501d6501c6501965017650166501165012650106500f6500e6500d6500b6500a65009650086500865007650076500565005650
000100000a250152501a25021250282502d2503225035250392503c2503d250295002b500315003550038500385001f0002300000000010000100001000000003a10000000000000000000000000000000000000
000100000c6501a6502165026650296502c6502c6502f6502f650306502e6502c6502a6502565022650206501d65019650166501465012650106500f6500d6500c65009650066500565004650026500265001650
000100002b350353503a3503f3503f3503a350353502e35029350223501b3501835016350113500f3500a3500a350053500535003350033500335003350033500035000350033500335000150022500025000000
00010000030500b05011050180501d05023050280502f050360503b05000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010c000015155131551115513155111551015511155101550e1550c1520c1520c1520c15200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010c000018042000001f042000001c042000001f0420000024052000001f052000001c052000001f0520000018042000001f042000001d042000001f0420000023052000001f052000001d052000001f05200000
010c0000180521805218052180521805218052180521805200000000000000000000000000000000000000001a0521a0521a0521a0521a0521a0521a0521a0520000000000000000000000000000000000000000
010c00001f0521f0521f0521f0521f0521f0521f0521f0521d0521d0521d0521d0521c0521c0521c0521c0521a0521a0521a0521a0521a0521a0521a0521a0520000000000000000000000000000000000000000
010c00001c0521c0521c0521c0521c0521c0521c0521c05200000000000000000000000000000000000000001d0521d0521d0521d0521d0521d0521d0521d0520000000000000000000000000000000000000000
010c00001f0521f0521f0521f0521f0521f0521f0521f0521d0521d0521d0521d0521c0521c0521c0521c0521d0521d0521d0521d0521d0521d0521d0521d0520000000000000000000000000000000000000000
010c00001805300000000000000000000000000000000000266230000000000000002422300000000000000018053000000000000000000000000000000000002662300000000000000000000000000000000000
010c000018233182001d2001a2001c2001c2001d233182001a233262001d200000001c200000001d2330000018233000001d233000001c233000001d233000001a233000001d200000001c200000001d20000000
__music__
04 07424344
00 08424344
00 08094d44
00 080a4344
00 080b4344
00 080c4344
01 08090d44
00 080a0d44
00 080b0d44
00 080c0d44
00 08420d0e
02 08420d0e

