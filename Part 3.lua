local P=game:GetService("Players")
local R=game:GetService("RunService")
local W=game:GetService("Workspace")
local L,S=P.LocalPlayer,getgenv().FEC
local C;pcall(function()C=require(L.PlayerScripts:WaitForChild("PlayerModule")):GetControls()end)
local A,V=CFrame.Angles,Vector3.new

local T=Instance.new("Tool",L:WaitForChild("Backpack"))
T.Name,T.RequiresHandle="🧗 Climb",false
local loop,curCF,t,sway,fwd=nil,nil,0,0,V(0,0,-1)
local velL,velR=Vector2.zero,Vector2.zero

local function cleanup()
 S.active=false
 if loop then loop:Disconnect()loop=nil end
 if S.gui then S.gui:Destroy()S.gui=nil end
 S.resetState(L.Character)
end

T.Equipped:Connect(function()
 local c=L.Character
 local h=c and c:FindFirstChildOfClass("Humanoid")
 local hr=c and c:FindFirstChild("HumanoidRootPart")
 if not h or not hr or h.RigType~=Enum.HumanoidRigType.R15 then return end
 cleanup()S.active=true S.buildUI()S.loadTracks(h)h:SetStateEnabled(12,false)
 local j={}
 for _,n in ipairs({"Root","Waist","Neck","LeftShoulder",
  "RightShoulder","LeftElbow","RightElbow","LeftWrist",
  "RightWrist","LeftHip","RightHip","LeftKnee",
  "RightKnee","LeftAnkle","RightAnkle"})do j[n]=c:FindFirstChild(n,true)end
 local rp=RaycastParams.new()rp.FilterType=Enum.RaycastFilterType.Exclude
 local cam=W.CurrentCamera

 loop=R.Stepped:Connect(function(_,dt)
  if not S.active or not c or not c.Parent or not hr then cleanup()return end
  h:SetStateEnabled(12,false)rp.FilterDescendantsInstances={c,S.rig,S.cursors.L,S.cursors.R}
  t=t+dt*2.2

  if not S.grabbed then
   S.setControls(true)S.stopTracks()S.clearCursors()
   local an=c:FindFirstChild("Animate")if an then an.Disabled=false end
   S.padL.Visible,S.padR.Visible,S.stickL.Visible,S.stickR.Visible=false,false,false,false
   S.pullBtn.Visible=false S.jmpBtn.Text="⬆️ JUMP"
   if S.lbl then S.lbl.Text="🕹️ FE CLIMB: STANDBY"S.lbl.TextColor3=Color3.fromRGB(210,210,220)end
   local wH=W:Raycast(hr.Position+V(0,1.1,0),hr.CFrame.LookVector*2.5,rp)
   local cH=W:Raycast(hr.Position,V(0,3.2,0),rp)
   if cH and h.FloorMaterial==Enum.Material.Air and hr.AssemblyLinearVelocity.Y>1 then
    S.grabbed,S.wNorm=true,cH.Normal S.makePhys(hr)S.makeRig(c)S.makeCursors()S.loadTracks(h)
    fwd=V(hr.CFrame.LookVector.X,0,hr.CFrame.LookVector.Z).Unit local rt=fwd:Cross(Vector3.yAxis).Unit
    S.handL,S.handR=cH.Position+cH.Normal*0.35-rt+fwd*0.8,cH.Position+cH.Normal*0.35+rt+fwd*0.8
    S.posL,S.posR,curCF=S.handL,S.handR,hr.CFrame
   elseif wH and(h.FloorMaterial==Enum.Material.Air or hr.AssemblyLinearVelocity.Magnitude>2)then
    S.grabbed,S.wNorm,fwd=true,wH.Normal,-wH.Normal S.makePhys(hr)S.makeRig(c)S.makeCursors()S.loadTracks(h)
    local wR=Vector3.yAxis:Cross(wH.Normal)wR=wR.Magnitude>0.01 and wR.Unit or hr.CFrame.RightVector
    local wU=wH.Normal:Cross(wR).Unit
    S.handL,S.handR=wH.Position+wH.Normal*0.35-wR+wU*1.35,wH.Position+wH.Normal*0.35+wR+wU*1.35
    S.posL,S.posR=S.handL,S.handR curCF=CFrame.lookAt(wH.Position+wH.Normal*1.75,wH.Position,wU)
   end
   return
  end

  local isDir,isStk=(S.mode=="Direct"),(S.mode=="Sticks")
  S.setControls(not isDir and not isStk)
  local an=c:FindFirstChild("Animate")if an then an.Disabled=true end
  hr.Anchored=false h.PlatformStand,h.AutoRotate=true,false
  if not S.ap or not S.ao then S.makePhys(hr)end
  if not S.rig then S.makeRig(c)end
  if not S.cursors.L then S.makeCursors()end
  hr.AssemblyLinearVelocity,hr.AssemblyAngularVelocity=V(0,0.05*math.sin(t*10),0),V()

  local onCeil=(S.wNorm.Y<-0.55)local pR,pU
  if onCeil then pU=V(fwd.X,0,fwd.Z)pU=pU.Magnitude>0.01 and pU.Unit or V(0,0,-1)pR=pU:Cross(Vector3.yAxis).Unit
  else pR=Vector3.yAxis:Cross(S.wNorm)pR=pR.Magnitude>0.01 and pR.Unit or hr.CFrame.RightVector pU=S.wNorm:Cross(pR).Unit fwd=-S.wNorm end

  if S.vaulting then
   S.vaultT=S.vaultT+dt local prg=math.clamp(S.vaultT/0.45,0,1)
   local vCF=S.vStart:Lerp(S.vEnd,prg)+V(0,math.sin(prg*math.pi)*1.45,0)
   S.ap.Position,S.ao.CFrame=vCF.Position,vCF
   S.syncReanim(j,vCF,t,0,0,false,pR,pU,true,true,nil,nil,1)
   if prg>=1 then local eCF=S.vEnd S.resetState(c)h:SetStateEnabled(12,false)hr.CFrame=eCF end
   return
  end

  S.jmpBtn.Text="⚡ KICK OFF"
  local pvL,pvR,hA,mvg,armSpd=S.posL,S.posR,1-math.exp(-16*dt),false,0
  S.padL.Visible,S.padR.Visible=isDir,isDir
  S.stickL.Visible,S.stickR.Visible=isStk,isStk

  if isStk then
   local damp=1-math.exp(-11*dt)velL=velL:Lerp(S.joyL,damp)velR=velR:Lerp(S.joyR,damp)
   local spd=15.5 armSpd=math.max(velL.Magnitude,velR.Magnitude)
   if velL.Magnitude>0.06 then
    mvg=true local mv=(pR*velL.X+pU*velL.Y)*(spd*dt)
    if(S.handL+mv-S.handR).Magnitude<6.4 then
     local hp,hn,sw=S.traceSurface(S.handL,S.handL+mv,mv,S.wNorm,pR,rp)
     if hp then S.handL,S.wNorm=hp,hn S.phase=S.phase+mv.Magnitude*0.22 if sw then S.turnT=0.45 end end
    end
   end
   if velR.Magnitude>0.06 then
    mvg=true local mv=(pR*velR.X+pU*velR.Y)*(spd*dt)
    if(S.handR+mv-S.handL).Magnitude<6.4 then
     local hp,hn,sw=S.traceSurface(S.handR,S.handR+mv,mv,S.wNorm,pR,rp)
     if hp then S.handR,S.wNorm=hp,hn S.phase=S.phase+mv.Magnitude*0.22 if sw then S.turnT=0.45 end end
    end
   end
  elseif isDir then
   local spL,visL=cam:WorldToViewportPoint(S.posL)local spR,visR=cam:WorldToViewportPoint(S.posR)
   if visL and not S.dragL then S.padL.Position=UDim2.new(0,spL.X-30,0,spL.Y-30)end
   if visR and not S.dragR then S.padR.Position=UDim2.new(0,spR.X-30,0,spR.Y-30)end
   if S.dragL and S.dL.Magnitude>0.5 then
    mvg=true local mv=(pR*(S.dL.X*0.036)+pU*(-S.dL.Y*0.036))S.dL=Vector2.zero
    if(S.handL+mv-S.handR).Magnitude<6.4 then
     local hp,hn,sw=S.traceSurface(S.handL,S.handL+mv,mv,S.wNorm,pR,rp)
     if hp then S.handL,S.wNorm=hp,hn S.phase=S.phase+mv.Magnitude*0.22 if sw then S.turnT=0.45 end end
    end
   end
   if S.dragR and S.dR.Magnitude>0.5 then
    mvg=true local mv=(pR*(S.dR.X*0.036)+pU*(-S.dR.Y*0.036))S.dR=Vector2.zero
    if(S.handR+mv-S.handL).Magnitude<6.4 then
     local hp,hn,sw=S.traceSurface(S.handR,S.handR+mv,mv,S.wNorm,pR,rp)
     if hp then S.handR,S.wNorm=hp,hn S.phase=S.phase+mv.Magnitude*0.22 if sw then S.turnT=0.45 end end
    end
   end
  else
   local mv=C and C.GetMoveVector and C:GetMoveVector()or V()local fI,sI=-mv.Z,mv.X
   if math.abs(fI)>0.15 or math.abs(sI)>0.15 then
    mvg=true local spd=(S.mode=="Spider")and 15 or 12.5
    local step=(pR*sI+pU*fI).Unit*(spd*dt)S.phase=S.phase+(spd*dt)*0.22
    local hpL,hnL,swL=S.traceSurface(S.handL,S.handL+step,step,S.wNorm,pR,rp)
    local hpR,hnR,swR=S.traceSurface(S.handR,S.handR+step,step,S.wNorm,pR,rp)
    if hpL then S.handL=hpL S.wNorm=hnL end if hpR then S.handR=hpR S.wNorm=hnR end
    if swL or swR then S.turnT=0.45 end
   end
  end

  if S.turnT>0 then S.turnT=math.max(0,S.turnT-dt)end
  S.posL,S.posR=S.posL:Lerp(S.handL,hA),S.posR:Lerp(S.handR,hA)

  local showRing=(S.mode~="Spider")
  if S.cursors.L and S.cursors.R then
   S.cursors.L.Transparency,S.cursors.R.Transparency=showRing and 0.3 or 1,showRing and 0.3 or 1
   S.cursors.L.CFrame=CFrame.lookAt(S.handL-S.wNorm*0.25,S.handL+S.wNorm,pU)*A(0,math.pi*0.5,0)
   S.cursors.R.CFrame=CFrame.lookAt(S.handR-S.wNorm*0.25,S.handR+S.wNorm,pU)*A(0,math.pi*0.5,0)
  end

  local hL=W:Raycast(S.posL+S.wNorm*0.9,-S.wNorm*1.8,rp)or W:Raycast(S.posL+V(0,0.8,0),V(0,-1.5,0),rp)
  local hR=W:Raycast(S.posR+S.wNorm*0.9,-S.wNorm*1.8,rp)or W:Raycast(S.posR+V(0,0.8,0),V(0,-1.5,0),rp)
  if not hL and not hR then S.resetState(c)h:SetStateEnabled(12,false)return end
  if S.lbl then S.lbl.Text="🟢 LIVE | "..string.upper(S.mode)S.lbl.TextColor3=Color3.fromRGB(110,240,145)end

  local mid=(hL and hR and(S.posL+S.posR)*0.5)or(hL and S.posL)or S.posR
  S.atLedge=(not onCeil)and(not W:Raycast(mid+V(0,1.35,0)+S.wNorm*0.6,-S.wNorm*2.2,rp))and(W:Raycast(mid+V(0,2.8,0)-S.wNorm*1.2,V(0,-4,0),rp)~=nil)
  S.pullBtn.Visible=S.atLedge and not S.autoVault
  if S.atLedge and S.autoVault and mvg then S.startVault()return end

  sway=math.clamp(sway*math.exp(-6*dt)-((S.posL-pvL)+(S.posR-pvR)):Dot(pR)*1.6,-0.4,0.4)
  local tilt=math.clamp((S.posR-S.posL):Dot(pU)*0.2,-0.35,0.35)+sway
  local tCF=(S.mode=="Spider")and(CFrame.lookAt(mid-pU*0.75+S.wNorm*1.05,mid+pU*0.25+S.wNorm*1.05,S.wNorm)*A(0,0,tilt*0.5))
   or(onCeil and(CFrame.lookAt(mid-V(0,2.25,0),mid-V(0,2.25,0)+pU,Vector3.yAxis)*A(0.18,0,tilt))
   or(CFrame.lookAt(mid-pU*1.95+S.wNorm*1.75,mid-pU*1.95-S.wNorm,pU)*A(-0.08,0,tilt)))
  curCF=curCF:Lerp(tCF,1-math.exp(-20*dt))S.ap.Position,S.ao.CFrame=curCF.Position,curCF
  S.syncReanim(j,curCF,t,sway,tilt,onCeil,pR,pU,false,mvg,hL,hR,armSpd)
 end)
end)
T.Unequipped:Connect(cleanup)
L.CharacterAdded:Connect(function()cleanup()task.wait(0.5)T.Parent=L:WaitForChild("Backpack")end)
print("Part 3 Loaded!")
