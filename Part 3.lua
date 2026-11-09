local P=game:GetService("Players")
local R=game:GetService("RunService")
local W=game:GetService("Workspace")
local L,S=P.LocalPlayer,getgenv().FEC
local A,V,N=CFrame.Angles,Vector3.new,CFrame.new
local C;pcall(function()
 local m=L.PlayerScripts:WaitForChild("PlayerModule")
 C=require(m):GetControls()
end)

local function ik(rp,j1,j2,tgt,pol)
 if not rp or not j1 or not j2 then return end
 local b=rp.CFrame*j1.C0
 local lT=b:PointToObjectSpace(tgt)
 local lP=b:VectorToObjectSpace(pol)
 local d=lT.Magnitude if d<0.05 then return end
 local cD=math.clamp(d,0.2,2.2)
 local c1=math.acos(math.clamp(cD/2.3,-1,1))
 local c2=math.acos(math.clamp((2.645-cD^2)/2.645,-1,1))
 local dir=lT.Unit local rt=dir:Cross(lP)
 rt=rt.Magnitude<0.001 and V(1,0,0)or rt.Unit
 local cf=CFrame.fromMatrix(V(),rt,-dir,-rt:Cross(dir).Unit)
 j1.Transform=cf*A(c1,0,0)
 j2.Transform=A(math.pi-c2,0,0)
end

local function surf(oP,cP,mv,nrm,wR,rp)
 if mv.Magnitude<0.001 then return end
 local d=mv.Unit
 local w=W:Raycast(oP+nrm*0.45,d*(mv.Magnitude+1.35),rp)
 if w and w.Normal:Dot(nrm)<0.72 then
  return w.Position+w.Normal*0.35,w.Normal,true
 end
 local h=W:Raycast(cP+nrm*1.6,-nrm*3.8,rp)
 if h then
  return h.Position+h.Normal*0.35,h.Normal,
   h.Normal:Dot(nrm)<0.72
 end
 local sD=d:Dot(wR)
 if math.abs(sD)>0.08 and nrm.Y>-0.5 then
  local g=sD>0 and 1 or -1
  local c=W:Raycast(cP-nrm*1.4+wR*(g*1.85),
   -wR*(g*3.6),rp)
  if c then
   return c.Position+c.Normal*0.35,c.Normal,true
  end
 end
end

local function sync(rj,cf,t,sw,tl,cl,pR,pU,vl,mv,hL,hR,dt,rp)
 local trk=S.tracks
 for _,tr in pairs(trk)do
  if not tr.IsPlaying then tr:Play(0.1)end
 end
 local tn,sp=(S.turnT>0),(S.mode=="Spider")
 local function w(tr,wt,s)
  if tr then
   tr:AdjustWeight(wt,0.08)
   if s then tr:AdjustSpeed(s)end
  end
 end
 if vl or tn then
  w(trk.ClimbOver,1,vl and 1.65 or 1.45)
  w(trk.Climb,0.01,0)w(trk.SpiderRun,0.01,0)
 elseif sp then
  w(trk.ClimbOver,0.01,0)w(trk.Climb,0.01,0)
  w(trk.SpiderRun,mv and 1 or 0.05,mv and 2.5 or 0)
  w(trk.SpiderIdle,mv and 0.05 or 1,1)
 else
  w(trk.ClimbOver,0.01,0)w(trk.SpiderRun,0.01,0)
  if trk.Climb then
   trk.Climb:AdjustWeight(mv and 1 or 0.45,0.08)
   trk.Climb:AdjustSpeed(0)
   if trk.Climb.Length>0 then
    trk.Climb.TimePosition=(S.phase%1)*trk.Climb.Length
   end
  end
 end
 if not S.rig then return end
 S.rig.HumanoidRootPart.CFrame=cf
 local r=S.rigJ for _,m in pairs(r)do m.Transform=N()end
 local uT=S.rig:FindFirstChild("UpperTorso")
 local lT=S.rig:FindFirstChild("LowerTorso")
 if sp and not vl then
  S.phase=S.phase+dt*(mv and 8.5 or 1.4)
  local g={FL={-1.6,1.3,0},FR={1.6,1.3,3.14},
   RL={-1.6,-1.3,3.14},RR={1.6,-1.3,0}}
  for k,v in pairs(g)do
   local st,c=S.spLimbs[k],S.phase+v[3]
   local lft=mv and math.max(0,math.cos(c))*0.4 or 0
   local sw=mv and math.sin(c)*0.55 or 0
   local og=cf.Position+pR*v[1]+pU*(v[2]+sw)
    +S.smoothNorm*1.1
   local hit=W:Raycast(og,-S.smoothNorm*3.8,rp)
   local tg=hit and(hit.Position+hit.Normal*0.18)
    or(og-S.smoothNorm*1.1)
   local cur=(st and st.cur or tg):Lerp(tg,
    1-math.exp(-22*dt))
   S.spLimbs[k]={cur=cur,lift=lft}
  end
  local fl,fr=S.spLimbs.FL,S.spLimbs.FR
  local rl,rr=S.spLimbs.RL,S.spLimbs.RR
  local pol=S.smoothNorm*2.2
  if fl then ik(uT,r.LeftShoulder,r.LeftElbow,
   fl.cur+S.smoothNorm*fl.lift,pol-pR*0.8)end
  if fr then ik(uT,r.RightShoulder,r.RightElbow,
   fr.cur+S.smoothNorm*fr.lift,pol+pR*0.8)end
  if rl then ik(lT,r.LeftHip,r.LeftKnee,
   rl.cur+S.smoothNorm*rl.lift,pol-pR*0.8)end
  if rr then ik(lT,r.RightHip,r.RightKnee,
   rr.cur+S.smoothNorm*rr.lift,pol+pR*0.8)end
 else
  local lg=cf:VectorToObjectSpace(V(0,-1,0))
  local hP=math.clamp(math.atan2(-lg.Z,-lg.Y)*0.5,-0.5,0.6)
  local hR2=math.clamp(-sw*1.6,-0.5,0.5)
  if r.Waist then r.Waist.Transform=A(hP*0.6,0,hR2*0.7)end
  if r.LeftHip then r.LeftHip.Transform=A(hP*0.8,0,hR2)end
  if r.RightHip then r.RightHip.Transform=A(hP*0.9,0,hR2)end
  local pL=-pU*0.95+S.smoothNorm*0.3-pR*0.2
  local pR2=-pU*0.95+S.smoothNorm*0.3+pR*0.2
  if hL then ik(uT,r.LeftShoulder,r.LeftElbow,S.posL,pL)end
  if hR then ik(uT,r.RightShoulder,r.RightElbow,S.posR,pR2)end
 end
 for nm,m in pairs(r)do
  if rj[nm]then rj[nm].Transform=m.Transform end
 end
end

local T=Instance.new("Tool",L:WaitForChild("Backpack"))
T.Name,T.RequiresHandle="🧗 Climb",false
local loop,curCF,t,sway,fwd=nil,nil,0,0,V(0,0,-1)
local vL,vR=Vector2.zero,Vector2.zero
local function cln()
 S.active=false
 if loop then loop:Disconnect()loop=nil end
 if S.gui then S.gui:Destroy()S.gui=nil end
 S.resetState(L.Character)
end

T.Equipped:Connect(function()
 local c=L.Character
 local h=c and c:FindFirstChildOfClass("Humanoid")
 local hr=c and c:FindFirstChild("HumanoidRootPart")
 if not h or not hr then return end
 cln()S.active=true S.buildUI()S.loadTracks(h)
 local j={}
 local jn={"Root","Waist","Neck","LeftShoulder",
  "RightShoulder","LeftElbow","RightElbow",
  "LeftHip","RightHip","LeftKnee","RightKnee"}
 for _,n in ipairs(jn)do j[n]=c:FindFirstChild(n,true)end
 local rp=RaycastParams.new()
 rp.FilterType=Enum.RaycastFilterType.Exclude
 local cam=W.CurrentCamera

 loop=R.Stepped:Connect(function(_,dt)
  if not S.active or not c.Parent then cln()return end
  h:SetStateEnabled(12,false)
  rp.FilterDescendantsInstances={c,S.rig,S.cursors.L,S.cursors.R}
  t=t+dt*2.2
  if not S.grabbed then
   S.setControls(true)S.stopTracks()S.clearCursors()
   local an=c:FindFirstChild("Animate")
   if an then an.Disabled=false end
   for _,v in pairs({S.padL,S.padR,S.stickL,
    S.stickR,S.pullBtn})do if v then v.Visible=false end end
   S.jmpBtn.Text="⬆️ JUMP"
   local wH=W:Raycast(hr.Position+V(0,1,0),
    hr.CFrame.LookVector*2.5,rp)
   if wH and(h.FloorMaterial==Enum.Material.Air
    or hr.AssemblyLinearVelocity.Magnitude>2)then
    S.grabbed,S.wNorm,S.smoothNorm=true,wH.Normal,wH.Normal
    fwd=-wH.Normal S.makePhys(hr)S.makeRig(c)
    S.makeCursors()S.loadTracks(h)
    local wR=Vector3.yAxis:Cross(wH.Normal).Unit
    local wU=wH.Normal:Cross(wR).Unit
    S.handL=wH.Position+wH.Normal*0.35-wR+wU*1.3
    S.handR=wH.Position+wH.Normal*0.35+wR+wU*1.3
    S.posL,S.posR=S.handL,S.handR
    curCF=CFrame.lookAt(wH.Position+wH.Normal*1.7,
     wH.Position,wU)
   end return
  end
  local dir,stk=(S.mode=="Direct"),(S.mode=="Sticks")
  S.setControls(not dir and not stk)
  local an=c:FindFirstChild("Animate")
  if an then an.Disabled=true end
  hr.Anchored=false h.PlatformStand,h.AutoRotate=true,false
  if not S.ap then S.makePhys(hr)end
  if not S.rig then S.makeRig(c)end
  hr.AssemblyLinearVelocity=V(0,0.05*math.sin(t*10),0)
  S.smoothNorm=S.smoothNorm:Lerp(S.wNorm,1-math.exp(-12*dt)).Unit
  local ceil=(S.smoothNorm.Y<-0.55)
  local pR=Vector3.yAxis:Cross(S.smoothNorm).Unit
  local pU=S.smoothNorm:Cross(pR).Unit
  if S.vaulting then
   S.vaultT=S.vaultT+dt
   local p=math.clamp(S.vaultT/0.5,0,1)
   local vCF=S.vStart:Lerp(S.vEnd,p)
    +V(0,math.sin(p*math.pi)*1.5,0)
   S.ap.Position,S.ao.CFrame=vCF.Position,vCF
   sync(j,vCF,t,0,0,false,pR,pU,true,true,nil,nil,dt,rp)
   if p>=1 then
    local e=S.vEnd cln()S.active=true S.buildUI()
    hr.CFrame=e
   end return
  end
  S.jmpBtn.Text="⚡ KICK OFF"
  local pvL,pvR,mvg=S.posL,S.posR,false
  S.padL.Visible,S.padR.Visible=dir,dir
  S.stickL.Visible,S.stickR.Visible=stk,stk
  if stk then
   vL=vL:Lerp(S.joyL,1-math.exp(-11*dt))
   vR=vR:Lerp(S.joyR,1-math.exp(-11*dt))
   if vL.Magnitude>0.06 then
    mvg=true local mv=(pR*vL.X+pU*vL.Y)*(15.5*dt)
    local hp,hn,sw=surf(S.handL,S.handL+mv,mv,S.wNorm,pR,rp)
    if hp then S.handL,S.wNorm=hp,hn
     S.phase=S.phase+mv.Magnitude*0.22
     if sw then S.turnT=0.45 end end
   end
   if vR.Magnitude>0.06 then
    mvg=true local mv=(pR*vR.X+pU*vR.Y)*(15.5*dt)
    local hp,hn,sw=surf(S.handR,S.handR+mv,mv,S.wNorm,pR,rp)
    if hp then S.handR,S.wNorm=hp,hn
     S.phase=S.phase+mv.Magnitude*0.22
     if sw then S.turnT=0.45 end end
   end
  else
   local mv=C and C.GetMoveVector and C:GetMoveVector()or V()
   if math.abs(mv.Z)>0.15 or math.abs(mv.X)>0.15 then
    mvg=true local sp=(S.mode=="Spider"and 15.5 or 12.5)*dt
    local st=(pR*mv.X+pU*(-mv.Z)).Unit*sp
    S.phase=S.phase+st.Magnitude*0.22
    local h1,n1,w1=surf(S.handL,S.handL+st,st,S.wNorm,pR,rp)
    local h2,n2,w2=surf(S.handR,S.handR+st,st,S.wNorm,pR,rp)
    if h1 then S.handL,S.wNorm=h1,n1 end
    if h2 then S.handR,S.wNorm=h2,n2 end
    if w1 or w2 then S.turnT=0.45 end
   end
  end
  if S.turnT>0 then S.turnT=math.max(0,S.turnT-dt)end
  S.posL=S.posL:Lerp(S.handL,1-math.exp(-15*dt))
  S.posR=S.posR:Lerp(S.handR,1-math.exp(-15*dt))
  local hL=W:Raycast(S.posL+S.smoothNorm*0.9,-S.smoothNorm*1.8,rp)
  local hR=W:Raycast(S.posR+S.smoothNorm*0.9,-S.smoothNorm*1.8,rp)
  if not hL and not hR then S.resetState(c)return end
  local mid=(hL and hR and(S.posL+S.posR)*0.5)
   or(hL and S.posL)or S.posR
  S.atLedge=(not ceil)and(not W:Raycast(mid+V(0,1.3,0)
   +S.smoothNorm*0.6,-S.smoothNorm*2.2,rp))
  S.pullBtn.Visible=S.atLedge and not S.autoVault
  if S.atLedge and S.autoVault and mvg then
   S.startVault()return end
  local tCF
  if S.mode=="Spider"then
   local bH=W:Raycast(mid+S.smoothNorm*1.2,
    -S.smoothNorm*2.6,rp)
   local bS=bH and bH.Position or(mid-S.smoothNorm*0.35)
   local sP=bS-pU*0.65+S.smoothNorm*0.85
   tCF=CFrame.lookAt(sP,sP+pU,S.smoothNorm)
  else
   local wP=mid-pU*1.95+S.smoothNorm*1.75
   tCF=CFrame.lookAt(wP,wP-S.smoothNorm,pU)
  end
  curCF=curCF:Lerp(tCF,1-math.exp(-16*dt))
  S.ap.Position,S.ao.CFrame=curCF.Position,curCF
  sync(j,curCF,t,sway,0,ceil,pR,pU,false,mvg,hL,hR,dt,rp)
 end)
end)
T.Unequipped:Connect(cln)
print("Part 3 Loaded!")
